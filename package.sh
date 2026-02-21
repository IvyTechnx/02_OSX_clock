#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP="FloatClock"
BUILD="build"
VERSION="1.0"
DMG_NAME="${APP}_v${VERSION}.dmg"

# Build the app first
./build.sh

echo ""
echo "=== Creating DMG ==="

# Create a temporary directory for DMG contents
DMG_TMP="$BUILD/dmg_tmp"
rm -rf "$DMG_TMP"
mkdir -p "$DMG_TMP"

# Copy the app
cp -R "$BUILD/$APP.app" "$DMG_TMP/"

# Create a symlink to /Applications
ln -s /Applications "$DMG_TMP/Applications"

# Create the DMG
hdiutil create \
    -volname "$APP" \
    -srcfolder "$DMG_TMP" \
    -ov \
    -format UDZO \
    "$BUILD/$DMG_NAME"

rm -rf "$DMG_TMP"

echo ""
echo "✓ DMG作成完了: $BUILD/$DMG_NAME"
echo "  配布: $BUILD/$DMG_NAME を共有してください"
