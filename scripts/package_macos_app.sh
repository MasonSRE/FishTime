#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MoyuCounter"
APP_DISPLAY_NAME="摸鱼统计器"
BUNDLE_ID="com.moyucounter.app"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
EXECUTABLE_PATH="$ROOT_DIR/.build/release/$APP_NAME"
ICON_VARIANT="${APP_ICON_VARIANT:-detailed}"

case "$ICON_VARIANT" in
    detailed)
        ICON_BASENAME="AppIcon"
        ;;
    flat)
        ICON_BASENAME="AppIconFlat"
        ;;
    *)
        echo "Unsupported APP_ICON_VARIANT: $ICON_VARIANT (expected detailed or flat)" >&2
        exit 1
        ;;
esac

ICON_PATH="$ROOT_DIR/MoyuCounter/Resources/${ICON_BASENAME}.icns"

cd "$ROOT_DIR"

if [[ ! -f "$ICON_PATH" ]]; then
    "$ROOT_DIR/scripts/generate_app_icon.sh" --style "$ICON_VARIANT" --output "$ICON_PATH"
fi

swift build -c release --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cat >"$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_DISPLAY_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_DISPLAY_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleIconFile</key>
    <string>$ICON_BASENAME</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

cp "$ICON_PATH" "$APP_DIR/Contents/Resources/${ICON_BASENAME}.icns"

echo "Packaged app bundle at: $APP_DIR"
