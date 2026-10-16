#!/usr/bin/env python3
"""Download completed narration jobs and prepare the offline app recordings.

Reads build/narration/generations.json from the generation connector. No API
credentials or generation URLs are bundled with the app. Originals stay in build/.
"""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT / "build/narration"
OUTPUT = ROOT / "OliviaPlay/Resources/Narration"


def prepare(job):
    cue_id = job["cue"]
    assert re.fullmatch(r"[a-z0-9-]+", cue_id)
    url = job["result"]["url"]
    assert url.startswith("https://")
    task_id = job["taskId"]
    assert re.fullmatch(r"[a-z0-9-]+", task_id)
    original = WORK / "originals" / f"{cue_id}-{task_id}.mp3"
    if not original.exists():
        with urlopen(url, timeout=60) as response:
            data = response.read()
        assert len(data) > 1000, f"Empty recording: {cue_id}"
        original.write_bytes(data)
    destination = OUTPUT / f"{cue_id}.mp3"
    # Trim only silence at the two ends; preserve every pause inside the phrase.
    # Leave short margins around consonants. Keep the generated voice's pitch/rate.
    filters = (
        "silenceremove=start_periods=1:start_duration=0.02:start_threshold=-52dB:start_silence=0.05,"
        "areverse,"
        "silenceremove=start_periods=1:start_duration=0.02:start_threshold=-52dB:start_silence=0.10,"
        "areverse,loudnorm=I=-18:TP=-2:LRA=11,aresample=44100"
    )
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(original), "-map", "0:a:0", "-af", filters,
                    "-ac", "1", "-codec:a", "libmp3lame", "-b:a", "128k",
                    "-map_metadata", "-1", str(destination)], check=True, timeout=60)
    return {"id": cue_id, "text": job["text"],
            "model": job.get("recordingModel", "eleven_v3"),
            "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()}


def main():
    jobs = json.loads((WORK / "generations.json").read_text())
    cues = {cue["id"]: cue for cue in json.loads((WORK / "catalog.json").read_text())}
    assert len(jobs) == len(cues) and {job["cue"] for job in jobs} == set(cues)
    for job in jobs:
        assert job["text"] == cues[job["cue"]]["text"], f"Changed text: {job['cue']}"
        assert job["result"].get("url"), f"Unfinished generation: {job['cue']}"
    (WORK / "originals").mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as executor:
        clips = list(executor.map(prepare, jobs))
    for clip in clips:
        clip["kind"] = cues[clip["id"]]["kind"]
    manifest = {"version": 1, "voice": "Serene", "language": "pt-BR",
                "model": "eleven_v3", "speed": 0.94,
                "clips": sorted(clips, key=lambda clip: clip["id"])}
    (OUTPUT / "narration-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    total = sum(path.stat().st_size for path in OUTPUT.glob("*.mp3"))
    print(f"Prepared {len(clips)} offline recordings ({total / 1_000_000:.1f} MB).")


if __name__ == "__main__":
    main()
