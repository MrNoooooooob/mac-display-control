#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
UPSTREAM="https://github.com/ac50/machidpi.git"
PIN="3d105b0f18cc2522e27028bc1a1ee4b6ff1ef7d6"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo 'Diese App muss auf macOS (Apple Silicon) gebaut werden.' >&2
    exit 1
fi
if [[ "$(uname -m)" != "arm64" ]]; then
    echo 'macOS mit Apple Silicon (arm64) erforderlich.' >&2
    exit 1
fi
if ! command -v swift >/dev/null || ! command -v git >/dev/null || ! command -v python3 >/dev/null; then
    echo 'Swift, Git und Python3 fehlen. Bitte Xcode Command Line Tools installieren: xcode-select --install' >&2
    exit 1
fi
mkdir -p "$ROOT/_build"
if [[ ! -d "$ROOT/_build/upstream/.git" ]]; then
    echo 'Original-MIT-Quellcode von machidpi wird geladen …'
    git clone --no-checkout "$UPSTREAM" "$ROOT/_build/upstream"
fi
cd "$ROOT/_build/upstream"
if ! git rev-parse --verify "${PIN}^{commit}" >/dev/null 2>&1; then
    git fetch --no-tags origin "$PIN"
fi
git checkout --force "$PIN"
git clean -fd -- Sources/machidpi
if [[ "$(git rev-parse HEAD)" != "$PIN" ]]; then
    echo 'Fehler: Git-Commit stimmt nicht mit der geprüften Version überein.' >&2
    exit 1
fi
cp "$ROOT/UI/DisplayDashboard.swift" Sources/machidpi/DisplayDashboard.swift
cp "$ROOT/Core/DisplayStabilityPolicy.swift" Sources/machidpi/DisplayStabilityPolicy.swift
python3 "$ROOT/tools/patch_machidpi.py" .

echo 'Baue Mac Display Control (mit originalem machidpi-HiDPI-Kern) …'
swift build -c release --arch arm64
APP="$ROOT/Mac Display Control.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
cp "$BIN_DIR/machidpi" "$APP/Contents/MacOS/MacDisplayControl"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>MacDisplayControl</string>
<key>CFBundleIdentifier</key><string>io.github.MrNoooooooob.MacDisplayControl</string>
<key>CFBundleName</key><string>Mac Display Control</string>
<key>CFBundleDisplayName</key><string>Mac Display Control</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.0.2</string>
<key>CFBundleVersion</key><string>2</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 MrNoooooooob. Includes machidpi © 2026 ac50 (MIT).</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
cp "$ROOT/LICENSE" "$APP/Contents/Resources/LICENSE-Mac-Display-Control.txt"
cp "$ROOT/LICENSE-machidpi.txt" "$APP/Contents/Resources/LICENSE-machidpi.txt"
cp "$ROOT/NOTICE.md" "$APP/Contents/Resources/NOTICE.md"
codesign --force --sign - "$APP"

echo
printf '\033[32mMac Display Control.app erstellt: %s\033[0m\n' "$APP"
echo 'Vor dem Start unbedingt die ursprüngliche machidpi-App beenden.'
if [[ -z "${CI:-}" ]]; then
    open -R "$APP" || true
fi
