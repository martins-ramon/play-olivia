#!/bin/bash
# Source this file to select an installed Xcode for this process only.
# Does not change the machine's xcode-select setting.

olivia_select_xcode() {
  if [[ -n "${DEVELOPER_DIR:-}" && -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
    return 0
  fi
  local active_dir
  active_dir="$(xcode-select -p 2>/dev/null || true)"
  if [[ -x "$active_dir/usr/bin/xcodebuild" ]]; then
    export DEVELOPER_DIR="$active_dir"
    return 0
  fi
  local candidate
  for candidate in /Applications/Xcode.app/Contents/Developer /Applications/Xcode*.app/Contents/Developer "$HOME"/Applications/Xcode*.app/Contents/Developer; do
    if [[ -x "$candidate/usr/bin/xcodebuild" ]]; then
      export DEVELOPER_DIR="$candidate"
      return 0
    fi
  done
  return 1
}
