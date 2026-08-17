#!/usr/bin/env bash
# Builds dist/Typestamp-<version>.dmg from a fresh app bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/bundle.sh

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    dist/Typestamp.app/Contents/Info.plist)
DMG="dist/Typestamp-$VERSION.dmg"

STAGE=$(mktemp -d)
cp -R dist/Typestamp.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "Typestamp" -srcfolder "$STAGE" -format UDZO "$DMG"
rm -rf "$STAGE"

IDENTITY=$(security find-identity -v -p codesigning \
    | awk '/Developer ID Application/ {print $2; exit}')
if [ -n "$IDENTITY" ]; then
    codesign --sign "$IDENTITY" "$DMG"
fi

# One-time setup: xcrun notarytool store-credentials <profile> \
#   --apple-id <apple-id> --team-id <team-id>  (uses an app-specific
#   password from appleid.apple.com), then: NOTARY_PROFILE=<profile> scripts/make-dmg.sh
if [ -n "${NOTARY_PROFILE:-}" ]; then
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    echo "Notarized and stapled"
fi

echo "Built $DMG"
