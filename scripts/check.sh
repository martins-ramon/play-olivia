#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
source scripts/xcode-env.sh
source scripts/swift-env.sh
xcode_available=false
if olivia_select_xcode; then xcode_available=true; fi
olivia_prepare_swift
mkdir -p "$PROJECT_DIR/build/narration"
xcrun swiftc "${olivia_swift_flags[@]}" -module-cache-path "$PROJECT_DIR/build/swift-module-cache" \
  OliviaPlay/Core/*.swift scripts/export-narration.swift -o "$PROJECT_DIR/build/narration/export-catalog"
"$PROJECT_DIR/build/narration/export-catalog" > "$PROJECT_DIR/build/narration/catalog.json"
python3 scripts/validate-narration.py
python3 scripts/generate-project.py
plutil -lint OliviaPlay/Info.plist OliviaPlay.xcodeproj/project.pbxproj
python3 - <<'PY'
import json
from pathlib import Path
from xml.etree import ElementTree
ElementTree.parse('OliviaPlay.xcodeproj/xcshareddata/xcschemes/OliviaPlay.xcscheme')
for path in Path('OliviaPlay/Resources').rglob('Contents.json'):
    data = json.loads(path.read_text())
    for image in data.get('images', []):
        if 'filename' in image:
            assert (path.parent / image['filename']).is_file(), f'Recurso ausente: {path.parent / image["filename"]}'
print('Esquema e catálogos válidos.')
PY
swift_files=()
while IFS= read -r -d '' source_file; do swift_files+=("$source_file"); done < <(python3 -c 'from pathlib import Path; import sys; [sys.stdout.write(str(p) + "\0") for p in Path("OliviaPlay").rglob("*.swift")]')
if [[ ${#swift_files[@]} -eq 0 ]]; then
  echo 'ERRO: nenhum código Swift encontrado.' >&2
  exit 1
fi
xcrun swiftc -parse "${swift_files[@]}"
if [[ -f Package.swift ]]; then
  mkdir -p "$PROJECT_DIR/build"
  if xcrun swift test --scratch-path "$PROJECT_DIR/build/swift-tests" > "$PROJECT_DIR/build/swift-test.log" 2>&1; then
    cat "$PROJECT_DIR/build/swift-test.log"
  elif ! $xcode_available && [[ -f Tests/CoreChecks.swift ]]; then
    echo 'SwiftPM/XCTest indisponível neste Command Line Tools; executando verificações diretas do núcleo.' >&2
    echo 'Diagnóstico completo: build/swift-test.log' >&2
    olivia_prepare_swift
    xcrun swiftc -D CORE_CHECKS "${olivia_swift_flags[@]}" -module-cache-path "$PROJECT_DIR/build/swift-module-cache" \
      OliviaPlay/Core/*.swift Tests/CoreChecks.swift -o "$PROJECT_DIR/build/core-checks"
    "$PROJECT_DIR/build/core-checks"
  else
    cat "$PROJECT_DIR/build/swift-test.log" >&2
    exit 1
  fi
fi
if $xcode_available; then
  xcodebuild -project OliviaPlay.xcodeproj -scheme OliviaPlay -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PROJECT_DIR/build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO build
  echo 'Validação e build para iPad Simulator concluídos.'
else
  echo 'Validações locais concluídas. Build iPad não executado: Xcode completo não foi encontrado.' >&2
  echo 'Command Line Tools não inclui o SDK do iPad. Instale/abra o Xcode e execute novamente.' >&2
  exit 2
fi
