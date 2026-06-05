#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/release-config.sh"

RELEASE_DIR="$ROOT_DIR/.build/release"
SAVER_DIR="$ROOT_DIR/.build/saver/$BUNDLE_NAME"
ZIP_PATH="$RELEASE_DIR/${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.zip"
DMG_STAGE_DIR="$RELEASE_DIR/${APP_NAME}-${APP_VERSION}-${ARM64_TAG}-stage"
DMG_PATH="$RELEASE_DIR/${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.dmg"
CHECKSUMS_PATH="$RELEASE_DIR/${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.sha256"
MANIFEST_PATH="$RELEASE_DIR/${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.json"

mkdir -p "$RELEASE_DIR"

bash "$ROOT_DIR/scripts/package-saver.sh" >/dev/null

rm -rf "$DMG_STAGE_DIR"
mkdir -p "$DMG_STAGE_DIR"
cp -R "$SAVER_DIR" "$DMG_STAGE_DIR/$BUNDLE_NAME"

cat > "$DMG_STAGE_DIR/Install.txt" <<EOF
WeReadScreenSaver ${APP_VERSION}

Install:
1. Double-click ${BUNDLE_NAME}
2. Copy it to ~/Library/Screen Savers
3. Open System Settings > Screen Saver and select it

You can also use the included install script from the source repo.
EOF

rm -f "$ZIP_PATH" "$DMG_PATH" "$CHECKSUMS_PATH" "$MANIFEST_PATH"

ditto -c -k --keepParent "$SAVER_DIR" "$ZIP_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

shasum -a 256 "$ZIP_PATH" "$DMG_PATH" > "$CHECKSUMS_PATH"

cat > "$MANIFEST_PATH" <<EOF
{
  "app": "${APP_NAME}",
  "version": "${APP_VERSION}",
  "build": "${APP_BUILD}",
  "artifacts": [
    {
      "name": "${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.zip",
      "type": "zip",
      "purpose": "Direct install bundle",
      "path": "${ZIP_PATH}"
    },
    {
      "name": "${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.dmg",
      "type": "dmg",
      "purpose": "Disk image installer",
      "path": "${DMG_PATH}"
    },
    {
      "name": "${APP_NAME}-${APP_VERSION}-${ARM64_TAG}.sha256",
      "type": "checksum",
      "purpose": "SHA-256 checksums for release assets",
      "path": "${CHECKSUMS_PATH}"
    }
  ]
}
EOF

echo "$DMG_PATH"
