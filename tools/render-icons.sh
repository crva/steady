#!/bin/sh
# Regenerates the app icon PNGs from Steady/Features/Supporter/IconArtwork.swift.
set -e
cd "$(dirname "$0")/.."
BUILD="${TMPDIR:-/tmp}/steady-icons"
mkdir -p "$BUILD"
cp tools/render-icons.swift "$BUILD/main.swift"
swiftc -o "$BUILD/render-icons" "$BUILD/main.swift" \
  Steady/Features/Supporter/IconArtwork.swift Shared/Palette.swift
"$BUILD/render-icons" Steady/Resources/Assets.xcassets
