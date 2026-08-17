#!/usr/bin/env bash
# Builds Typestamp.app from the SwiftPM release binary.
# Usage: scripts/bundle.sh [output-dir]   (default: dist)
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="0.2.0"
OUT="${1:-dist}"
APP="$OUT/Typestamp.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/Typestamp "$APP/Contents/MacOS/Typestamp"

# SwiftPM resource bundles (KeyboardShortcuts localizations, etc.) are
# looked up relative to the app's Resources directory. Note: .build/release
# is a symlink, so glob rather than find (which won't follow it).
for bundle in .build/release/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# Regenerate with scripts/make-icon.sh after changing Assets/icon.png.
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Small copy of the icon that the first-launch onboarding seeds into the
# log as a demo image (see OnboardingSeeder).
sips -z 512 512 Assets/icon.png --out "$APP/Contents/Resources/onboarding-logo.png" >/dev/null

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Typestamp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.suraj-xd.typestamp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Typestamp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Developer ID with hardened runtime when the certificate is present
# (required for notarization); ad-hoc otherwise (CI, contributors).
# Sign by certificate hash: duplicate keychain entries make the name form
# ambiguous.
IDENTITY=$(security find-identity -v -p codesigning \
    | awk '/Developer ID Application/ {print $2; exit}')
if [ -n "$IDENTITY" ]; then
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
    echo "Signed with Developer ID ($IDENTITY)"
else
    codesign --force --sign - "$APP"
    echo "Signed ad-hoc (no Developer ID certificate found)"
fi

echo "Built $APP"
