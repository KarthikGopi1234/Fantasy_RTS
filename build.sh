#!/bin/bash
# Local build script for Aether Empires v1.0.11+
# Properly signed APK with persistent keystore and custom logo

set -e

VERSION=$(cat VERSION 2>/dev/null || grep -oP 'config/version="\K[^"]+' project.godot || echo "1.0.11")
echo "Building Aether Empires v$VERSION"

# Generate assets
echo "Generating assets..."
python3 tools/generate_assets.py

# Build signed APK with real Godot export
echo "Building signed APK..."
python3 tools/build_release_apk.py

echo "=== Build Results ==="
ls -lh builds/
if [ -f builds/AetherEmpires.apk ]; then
    echo "APK ready: builds/AetherEmpires.apk"
    file builds/AetherEmpires.apk
    # Verify if apksigner available
    if [ -f "$HOME/android-sdk/build-tools/34.0.0/apksigner" ]; then
        $HOME/android-sdk/build-tools/34.0.0/apksigner verify --verbose builds/AetherEmpires.apk || true
    fi
fi

echo "Build complete! Install via: adb install builds/AetherEmpires.apk"
