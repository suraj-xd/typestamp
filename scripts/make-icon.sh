#!/usr/bin/env bash
# Regenerates Assets/AppIcon.icns from Assets/icon.png (square, alpha).
set -euo pipefail
cd "$(dirname "$0")/.."

ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z $size $size Assets/icon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double Assets/icon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o Assets/AppIcon.icns
echo "Wrote Assets/AppIcon.icns"
