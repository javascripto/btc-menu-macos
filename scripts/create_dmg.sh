#!/bin/zsh

set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_NAME="BTCMenu"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
DMG_DIR="$ROOT_DIR/dist/dmg"
STAGING_DIR="$DMG_DIR/staging"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
    "$ROOT_DIR/scripts/build_app.sh"
fi

echo "==> Preparing DMG staging directory"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Created DMG at: $DMG_PATH"
