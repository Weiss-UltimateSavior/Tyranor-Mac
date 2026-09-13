#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-${VERSION:-0.1.0}}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Building TyranorMac $VERSION (release, arm64)"
swift build -c release --arch arm64

DIST="$ROOT/dist"
APP="$DIST/TyranorMac.app"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> Assembling app bundle"
cp ".build/release/TyranorMac" "$APP/Contents/MacOS/TyranorMac"
cp "GalEmu/Resources/AppIcon.png" "$APP/Contents/Resources/AppIcon.png"
cp -R "engine" "$APP/Contents/Resources/engine"

if [ -f "GalEmu/Resources/AppIcon.png" ]; then
    ICONSET="$DIST/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for size in 16 32 64 128 256 512 1024; do
        sips -z "$size" "$size" "GalEmu/Resources/AppIcon.png" \
            --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    done
    cp "$ICONSET/icon_32x32.png"   "$ICONSET/icon_16x16@2x.png"
    cp "$ICONSET/icon_64x64.png"   "$ICONSET/icon_32x32@2x.png"
    cp "$ICONSET/icon_256x256.png" "$ICONSET/icon_128x128@2x.png"
    cp "$ICONSET/icon_512x512.png" "$ICONSET/icon_256x256@2x.png"
    cp "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET"
fi

echo "==> Writing Info.plist"
BUNDLE_VERSION="$(echo "$VERSION" | tr -cd '0-9')"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>TyranorMac</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.weiss.tyranormac</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Tyranor Mac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUNDLE_VERSION:-1}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.entertainment</string>
</dict>
</plist>
PLIST

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

ZIP="$DIST/TyranorMac-${VERSION}.zip"
echo "==> Packaging $ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

DMG="$DIST/TyranorMac-${VERSION}.dmg"
echo "==> Packaging $DMG"
STAGE="$DIST/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Tyranor Mac" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "==> Done:"
echo "    $ZIP"
echo "    $DMG"
