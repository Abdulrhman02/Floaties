#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h}
APP_DIR="$PROJECT_DIR/build/Floaties.app"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swiftc \
  -swift-version 5 \
  -O \
  -framework AppKit \
  -framework SwiftUI \
  -framework UniformTypeIdentifiers \
  "$PROJECT_DIR/Sources/main.swift" \
  -o "$APP_DIR/Contents/MacOS/Floaties"

cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod +x "$APP_DIR/Contents/MacOS/Floaties"
codesign --force --deep --sign - "$APP_DIR"

echo "Built $APP_DIR"
