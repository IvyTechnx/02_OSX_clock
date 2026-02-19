#!/bin/bash
set -e

APP="FloatClock"
BUILD="build"
BUNDLE="$BUILD/$APP.app/Contents"
ARCH=$(uname -m)

rm -rf "$BUILD"
mkdir -p "$BUNDLE/MacOS" "$BUNDLE/Resources"

swiftc Sources/main.swift \
    -o "$BUNDLE/MacOS/$APP" \
    -framework Cocoa \
    -framework SwiftUI \
    -target "${ARCH}-apple-macos14.0" \
    -Osize

cp Info.plist "$BUNDLE/"

echo "✓ ビルド完了: $BUILD/$APP.app"
echo "  実行: open $BUILD/$APP.app"
