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

echo "Built $DMG"
