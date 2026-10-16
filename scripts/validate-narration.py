#!/usr/bin/env python3
"""Validate the production narration catalogue and every bundled recording.

Usage: python3 scripts/validate-narration.py [--catalog PATH] [--audio-dir PATH]
Requires ffmpeg and ffprobe. Writes a machine-readable report under build/narration.
"""

import argparse
from array import array
from concurrent.futures import ThreadPoolExecutor
import json
import hashlib
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent


def decibels(amplitude):
    return round(20 * math.log10(amplitude), 2) if amplitude > 0 else None


def inspect_audio(path):
    result = {"id": path.stem, "file": str(path), "errors": []}
    try:
        probe = subprocess.run(
            ["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)],
            check=True, capture_output=True, text=True, timeout=30,
        )
        metadata = json.loads(probe.stdout)
        streams = metadata.get("streams", [])
        audio = [stream for stream in streams if stream.get("codec_type") == "audio"]
        if len(audio) != 1:
            raise ValueError(f"Esperado um fluxo de áudio; encontrados {len(audio)}")
        stream = audio[0]
        codec = stream.get("codec_name")
        sample_rate = int(stream.get("sample_rate", 0))
        channels = int(stream.get("channels", 0))
        duration = float(metadata.get("format", {}).get("duration", 0))
        result.update(codec=codec, sample_rate=sample_rate, channels=channels, duration=round(duration, 3))
        if codec != "mp3":
            result["errors"].append(f"Codec inesperado: {codec}")
        if not 16000 <= sample_rate <= 96000:
            result["errors"].append(f"Taxa de amostragem inválida: {sample_rate}")
        if channels not in (1, 2):
            result["errors"].append(f"Número de canais inválido: {channels}")
        if not 0.15 <= duration <= 30:
            result["errors"].append(f"Duração fora de 0,15–30 segundos: {duration}")

        # Decode to floating point, preserving the original channel count and sample
        # rate so that clipping cannot be hidden by downmixing or resampling.
        decoded = subprocess.run(
            ["ffmpeg", "-hide_banner", "-v", "error", "-xerror", "-i", str(path),
             "-map", "0:a:0", "-f", "f32le", "-acodec", "pcm_f32le", "-"],
            check=True, capture_output=True, timeout=30,
        )
        samples = array("f")
        samples.frombytes(decoded.stdout)
        if sys.byteorder != "little":
            samples.byteswap()
        if not samples or any(not math.isfinite(value) for value in samples):
            raise ValueError("Áudio vazio ou com amostras não finitas")
        peak = max(abs(value) for value in samples)
        rms = math.sqrt(sum(value * value for value in samples) / len(samples))
        clipped = sum(abs(value) >= 0.9999 for value in samples) / len(samples)
        result.update(rms_dbfs=decibels(rms), peak_dbfs=decibels(peak),
                      clipping_fraction=round(clipped, 7), decoded_samples=len(samples))
        if rms < 10 ** (-50 / 20) or peak < 10 ** (-40 / 20):
            result["errors"].append("Gravação silenciosa ou com volume insuficiente")
        # MP3 reconstruction can briefly exceed its source peak. Reject sustained
        # full-scale samples or overshoot beyond 5%, not harmless isolated rounding.
        if clipped > 0.001 or peak > 1.05:
            result["errors"].append("Clipping excessivo ou pico acima do limite")
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        if isinstance(error, subprocess.CalledProcessError):
            diagnostic = error.stderr
            if isinstance(diagnostic, bytes):
                diagnostic = diagnostic.decode("utf-8", errors="replace")
            result["errors"].append(f"Falha ao inspecionar/decodificar: {str(diagnostic).strip()[:600]}")
        else:
            result["errors"].append(str(error))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=ROOT / "build/narration/catalog.json")
    parser.add_argument("--audio-dir", type=Path, default=ROOT / "OliviaPlay/Resources/Narration")
    parser.add_argument("--report", type=Path, default=ROOT / "build/narration/validation.json")
    args = parser.parse_args()
    for executable in ("ffmpeg", "ffprobe"):
        if not shutil.which(executable):
            parser.error(f"{executable} não encontrado no PATH")
    try:
        cues = json.loads(args.catalog.read_text())
    except (OSError, ValueError) as error:
        parser.error(f"Catálogo indisponível: {error}")
    errors = []
    ids = []
    if not isinstance(cues, list) or not cues:
        parser.error("O catálogo deve ser uma lista não vazia de id/text/kind")
    for index, cue in enumerate(cues):
        if not isinstance(cue, dict):
            errors.append(f"Item {index}: objeto esperado")
            continue
        cue_id = cue.get("id")
        if not isinstance(cue_id, str) or not re.fullmatch(r"[a-z0-9-]+", cue_id):
            errors.append(f"Item {index}: identificador inválido {cue_id!r}")
            continue
        if cue_id in ids:
            errors.append(f"Identificador duplicado: {cue_id}")
        ids.append(cue_id)
        if not isinstance(cue.get("text"), str) or not cue["text"].strip():
            errors.append(f"{cue_id}: texto vazio")
        if cue.get("kind") not in ("instruction", "feedback", "count"):
            errors.append(f"{cue_id}: categoria inválida {cue.get('kind')!r}")
    expected = set(ids)
    actual = {path.stem for path in args.audio_dir.glob("*.mp3")}
    errors.extend(f"Gravação ausente: {cue_id}.mp3" for cue_id in sorted(expected - actual))
    errors.extend(f"Gravação sem item no catálogo: {cue_id}.mp3" for cue_id in sorted(actual - expected))
    manifest_path = args.audio_dir / "narration-manifest.json"
    try:
        manifest = json.loads(manifest_path.read_text())
        if not isinstance(manifest, dict) or manifest.get("version") != 1:
            raise ValueError("Versão ou estrutura inválida")
        if manifest.get("language") != "pt-BR" or not manifest.get("voice") or not manifest.get("model"):
            errors.append("Manifesto sem idioma pt-BR, voz ou modelo")
        clips = manifest.get("clips")
        if not isinstance(clips, list):
            raise ValueError("O campo clips deve ser uma lista")
        indexed_clips = {}
        for clip in clips:
            if not isinstance(clip, dict) or not isinstance(clip.get("id"), str):
                errors.append("Item inválido no manifesto")
                continue
            if clip["id"] in indexed_clips:
                errors.append(f"Identificador duplicado no manifesto: {clip['id']}")
            indexed_clips[clip["id"]] = clip
        errors.extend(f"Manifesto sem gravação: {cue_id}" for cue_id in sorted(expected - indexed_clips.keys()))
        errors.extend(f"Manifesto com gravação órfã: {cue_id}" for cue_id in sorted(indexed_clips.keys() - expected))
        for cue in cues:
            if not isinstance(cue, dict) or not isinstance(cue.get("id"), str):
                continue
            cue_id = cue["id"]
            clip = indexed_clips.get(cue_id)
            if not clip:
                continue
            if clip.get("text") != cue.get("text") or clip.get("kind") != cue.get("kind"):
                errors.append(f"{cue_id}: gravação desatualizada; texto/categoria diverge do catálogo")
            if cue_id not in actual:
                continue
            recorded_hash = clip.get("sha256")
            actual_hash = hashlib.sha256((args.audio_dir / f"{cue_id}.mp3").read_bytes()).hexdigest()
            if recorded_hash != actual_hash:
                errors.append(f"{cue_id}: SHA-256 do arquivo diverge do manifesto")
    except (OSError, ValueError) as error:
        errors.append(f"Manifesto indisponível ou inválido: {error}")
    paths = [args.audio_dir / f"{cue_id}.mp3" for cue_id in sorted(actual)]
    with ThreadPoolExecutor(max_workers=4) as executor:
        recordings = list(executor.map(inspect_audio, paths))
    for recording in recordings:
        errors.extend(f"{recording['id']}: {error}" for error in recording["errors"])
    report = {"catalog_count": len(cues), "audio_count": len(actual),
              "passed": not errors, "errors": errors, "recordings": recordings}
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    if errors:
        for error in errors:
            print(f"ERRO: {error}", file=sys.stderr)
        print(f"Validação reprovada: {len(errors)} erro(s). Relatório: {args.report}", file=sys.stderr)
        return 1
    total_duration = sum(recording["duration"] for recording in recordings)
    print(f"Narração validada: {len(cues)} falas, {total_duration:.1f}s; "
          "catálogo completo, MP3 decodificável, volume e picos válidos.")
    print(f"Relatório: {args.report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
