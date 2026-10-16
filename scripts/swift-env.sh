#!/bin/bash
# Local workaround for CLT installations containing duplicate SwiftBridging maps.
# The overlay changes only the compiler's view; no SDK/system file is modified.
olivia_swift_flags=(-swift-version 5)
olivia_prepare_swift() {
  local active_dir="${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || true)}"
  if [[ "$active_dir" != /Library/Developer/CommandLineTools ]]; then return 0; fi
  local overlay_path
  overlay_path="$(python3 - "$PROJECT_DIR" "$active_dir" <<'PY'
import json, sys
from pathlib import Path
root, developer = map(Path, sys.argv[1:])
maps = [developer / 'usr/include/swift' / name for name in ('module.modulemap', 'bridging.modulemap')]
if all(path.is_file() and 'module SwiftBridging' in path.read_text() for path in maps):
    folder = root / 'build/toolchain-overlay'
    folder.mkdir(parents=True, exist_ok=True)
    empty = folder / 'empty.modulemap'
    empty.write_text('// Duplicate legacy module hidden for this compiler process only.\n')
    overlay = folder / 'overlay.json'
    overlay.write_text(json.dumps({'version': 0, 'roots': [{'type': 'file', 'name': str(maps[0]), 'external-contents': str(empty)}]}))
    print(overlay)
PY
)"
  if [[ -n "$overlay_path" ]]; then
    olivia_swift_flags=(-swift-version 5 -vfsoverlay "$overlay_path")
    echo 'Compilador: overlay local para módulo SwiftBridging duplicado no CLT.' >&2
  fi
}
