#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != --run ) ]]; then
  echo 'Uso: ./scripts/preview-mac.sh [--run]' >&2
  exit 1
fi
source scripts/xcode-env.sh
olivia_select_xcode || true
source scripts/swift-env.sh
olivia_prepare_swift
app_path="$PROJECT_DIR/build/preview/Mundo da Olivia.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
swift_files=()
while IFS= read -r -d '' source_file; do swift_files+=("$source_file"); done < <(python3 -c 'from pathlib import Path; import sys; [sys.stdout.write(str(p) + "\0") for p in sorted(Path("OliviaPlay").rglob("*.swift"))]')
xcrun swiftc -parse-as-library -target arm64-apple-macosx14.0 "${olivia_swift_flags[@]}" \
  -module-cache-path /private/tmp/olivia-preview-module-cache \
  -module-name OliviaPlayPreview "${swift_files[@]}" \
  -o "$app_path/Contents/MacOS/OliviaPlayPreview"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Mundo da Olívia — Prévia</string>
<key>CFBundleDisplayName</key><string>Mundo da Olívia — Prévia</string>
<key>CFBundleIdentifier</key><string>br.com.oliviaplay.preview</string>
<key>CFBundleExecutable</key><string>OliviaPlayPreview</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
hero_path='OliviaPlay/Resources/Assets.xcassets/OliviaHero.imageset/olivia-hero.png'
if [[ -f "$hero_path" ]]; then
  cp "$hero_path" "$app_path/Contents/Resources/olivia-hero.png"
else
  echo 'Ilustração da Olívia ainda não disponível; a prévia usará a personagem de apoio.' >&2
fi
if [[ -d OliviaPlay/Resources/Narration ]]; then
  # Xcode copies individual narration resources into the root of the app bundle.
  while IFS= read -r -d '' narration_file; do
    cp "$narration_file" "$app_path/Contents/Resources/"
  done < <(find OliviaPlay/Resources/Narration -name '*.mp3' -print0)
  if [[ -f OliviaPlay/Resources/Narration/narration-manifest.json ]]; then
    cp OliviaPlay/Resources/Narration/narration-manifest.json "$app_path/Contents/Resources/"
  fi
fi
plutil -lint "$app_path/Contents/Info.plist"
echo "Prévia macOS compilada: $app_path"
echo 'A prévia valida SwiftUI no Mac; não substitui o build e o teste em iPadOS.'
if [[ "${1:-}" == --run ]]; then
  open "$app_path"
fi
