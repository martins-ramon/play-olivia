#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
source scripts/xcode-env.sh
olivia_select_xcode || true
source scripts/swift-env.sh
olivia_prepare_swift
render_app="$PROJECT_DIR/build/render-previews/RenderPreviews.app"
mkdir -p "$render_app/Contents/MacOS" "$render_app/Contents/Resources"
swift_files=()
while IFS= read -r -d '' source_file; do swift_files+=("$source_file"); done < <(python3 -c 'from pathlib import Path; import sys; [sys.stdout.write(str(p) + "\0") for p in sorted(Path("OliviaPlay").rglob("*.swift")) if p.name != "OliviaPlayApp.swift"]')
xcrun swiftc -parse-as-library -target arm64-apple-macosx14.0 "${olivia_swift_flags[@]}" \
  -module-cache-path /private/tmp/olivia-preview-module-cache \
  -module-name OliviaRenderPreviews "${swift_files[@]}" scripts/RenderPreviews.swift \
  -o "$render_app/Contents/MacOS/RenderPreviews"
cat > "$render_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Olivia Render Previews</string>
<key>CFBundleIdentifier</key><string>br.com.oliviaplay.renderpreviews</string>
<key>CFBundleExecutable</key><string>RenderPreviews</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
PLIST
cp OliviaPlay/Resources/Assets.xcassets/OliviaHero.imageset/olivia-hero.png "$render_app/Contents/Resources/olivia-hero.png"
if [[ -d OliviaPlay/Resources/Narration ]]; then
  while IFS= read -r -d '' narration_file; do
    cp "$narration_file" "$render_app/Contents/Resources/"
  done < <(find OliviaPlay/Resources/Narration -name '*.mp3' -print0)
  if [[ -f OliviaPlay/Resources/Narration/narration-manifest.json ]]; then
    cp OliviaPlay/Resources/Narration/narration-manifest.json "$render_app/Contents/Resources/"
  fi
fi
if [[ "${1:-}" != --build-only ]]; then
  "$render_app/Contents/MacOS/RenderPreviews" "$PROJECT_DIR/output/previews"
fi
