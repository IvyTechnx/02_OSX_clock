#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP="FloatClock"
BUILD="build"
BUNDLE="$BUILD/$APP.app/Contents"

rm -rf "$BUILD"
mkdir -p "$BUNDLE/MacOS" "$BUNDLE/Resources"

echo "=== Building FloatClock.app ==="

# Build for Apple Silicon (arm64)
echo "  [1/4] Compiling arm64..."
swiftc Sources/main.swift \
    -o "$BUILD/${APP}_arm64" \
    -framework Cocoa \
    -framework SwiftUI \
    -target "arm64-apple-macos14.0" \
    -Osize

# Build for Intel (x86_64)
echo "  [2/4] Compiling x86_64..."
swiftc Sources/main.swift \
    -o "$BUILD/${APP}_x86_64" \
    -framework Cocoa \
    -framework SwiftUI \
    -target "x86_64-apple-macos14.0" \
    -Osize

# Create Universal Binary
echo "  [3/4] Creating Universal Binary..."
lipo -create \
    "$BUILD/${APP}_arm64" \
    "$BUILD/${APP}_x86_64" \
    -output "$BUNDLE/MacOS/$APP"

rm "$BUILD/${APP}_arm64" "$BUILD/${APP}_x86_64"

# Copy Info.plist
cp Info.plist "$BUNDLE/"

# Ad-hoc code sign
echo "  [4/4] Code signing..."
codesign --force --deep --sign - "$BUILD/$APP.app"

echo ""
echo "✓ ビルド完了: $BUILD/$APP.app"
echo "  実行: open $BUILD/$APP.app"
