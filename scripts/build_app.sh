#!/bin/zsh

set -euo pipefail

ROOT_DIR="${0:A:h:h}"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_NAME="BTCMenu"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_WORK_DIR="$ROOT_DIR/.build/app-icon"
ICON_ICNS="$ICON_WORK_DIR/BTCMenu.icns"
ICON_SOURCE="$ROOT_DIR/scripts/generate_app_icon.swift"

echo "==> Building Swift executable"
cd "$ROOT_DIR"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"
swift build --disable-sandbox -c release

if [[ ! -f "$ICON_ICNS" || "$ICON_SOURCE" -nt "$ICON_ICNS" ]]; then
    echo "==> Generating app icon"
    mkdir -p "$ICON_WORK_DIR"
    swift "$ICON_SOURCE" "$ICON_ICNS"
else
    echo "==> Reusing app icon"
fi

echo "==> Creating app bundle"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$ICON_ICNS" "$RESOURCES_DIR/BTCMenu.icns"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>BTCMenu</string>
    <key>CFBundleIdentifier</key>
    <string>com.yuri.btcmenu</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>BTCMenu</string>
    <key>CFBundleName</key>
    <string>BTCMenu</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if command -v codesign >/dev/null 2>&1; then
    echo "==> Applying ad-hoc signature"
    codesign --force --deep --sign - "$APP_DIR"
fi

echo "Built app bundle at: $APP_DIR"
