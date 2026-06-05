#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/saver"
BINARY_NAME="WeReadScreenSaver"
BUNDLE_NAME="WeReadScreenSaver.saver"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
ARCH_BUILD_DIR="$BUILD_DIR/arch"
INSTALL_FLAG="${1:-}"
source "$ROOT_DIR/scripts/release-config.sh"

mkdir -p "$BUNDLE_DIR/Contents/MacOS" "$BUNDLE_DIR/Contents/Resources"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SWIFT_FILES=()
while IFS= read -r -d '' file; do
  SWIFT_FILES+=("$file")
done < <(find "$ROOT_DIR/Sources/WeReadScreenSaver" -name '*.swift' ! -name 'main.swift' -print0 | sort -z)

rm -rf "$ARCH_BUILD_DIR"
mkdir -p "$ARCH_BUILD_DIR"

build_slice() {
  local target="$1"
  local output="$2"

  xcrun swiftc \
    -emit-library \
    -Xlinker -bundle \
    -parse-as-library \
    -module-name WeReadScreenSaver \
    -sdk "$SDK_PATH" \
    -target "$target" \
    -framework AppKit \
    -framework SwiftUI \
    -framework ScreenSaver \
    -o "$output" \
    "${SWIFT_FILES[@]}"
}

build_slice "arm64e-apple-macosx15.0" "$ARCH_BUILD_DIR/$BINARY_NAME-arm64e"
build_slice "x86_64-apple-macosx15.0" "$ARCH_BUILD_DIR/$BINARY_NAME-x86_64"

xcrun lipo -create \
  "$ARCH_BUILD_DIR/$BINARY_NAME-arm64e" \
  "$ARCH_BUILD_DIR/$BINARY_NAME-x86_64" \
  -output "$BUNDLE_DIR/Contents/MacOS/$BINARY_NAME"

cat > "$BUNDLE_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_IDENTIFIER}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>BNDL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_BUILD}</string>
  <key>NSPrincipalClass</key>
  <string>WeReadScreenSaverView</string>
</dict>
</plist>
PLIST

cp "$ROOT_DIR/README.md" "$BUNDLE_DIR/Contents/Resources/README.md"

echo "$BUNDLE_DIR"

if [[ "$INSTALL_FLAG" == "--install" ]]; then
  INSTALL_DIR="$HOME/Library/Screen Savers"
  mkdir -p "$INSTALL_DIR"
  rm -rf "$INSTALL_DIR/$BUNDLE_NAME"
  cp -R "$BUNDLE_DIR" "$INSTALL_DIR/$BUNDLE_NAME"
  echo "Installed to $INSTALL_DIR/$BUNDLE_NAME"
fi
