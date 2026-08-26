#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h}
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Info.plist")
DIST_DIR="$PROJECT_DIR/dist"
APP_PATH="$PROJECT_DIR/build/Floaties.app"
DMG_PATH="$DIST_DIR/Floaties-$VERSION-macOS.dmg"
ZIP_PATH="$DIST_DIR/Floaties-$VERSION-macOS.zip"
SIGN_IDENTITY=${FLOATIES_SIGN_IDENTITY:--}
STAGING_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$PROJECT_DIR/build.sh"
codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH" "$ZIP_PATH" "$DIST_DIR/SHA256SUMS.txt"

ditto "$APP_PATH" "$STAGING_DIR/Floaties.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "Floaties $VERSION" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ -n ${FLOATIES_NOTARY_PROFILE:-} ]]; then
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$FLOATIES_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$DMG_PATH"
fi

(
    cd "$DIST_DIR"
    shasum -a 256 "${DMG_PATH:t}" "${ZIP_PATH:t}" > SHA256SUMS.txt
)

echo "Packaged $DMG_PATH"
echo "Packaged $ZIP_PATH"
