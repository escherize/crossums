#!/bin/bash
# Deploy Crossums to iOS
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_PROJECT="$SCRIPT_DIR/godot_app"
EXPORT_DIR="$GODOT_PROJECT/exports/ios"
VERSION_FILE="$GODOT_PROJECT/scripts/core/game_config.gd"

echo "=== Crossums iOS Deploy ==="

# Bump patch version (e.g., 0.2.1 -> 0.2.2)
CURRENT_VERSION=$(grep 'const VERSION' "$VERSION_FILE" | sed 's/.*"\(.*\)".*/\1/')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
sed -i '' "s/const VERSION := \"$CURRENT_VERSION\"/const VERSION := \"$NEW_VERSION\"/" "$VERSION_FILE"
echo "Version: $CURRENT_VERSION -> $NEW_VERSION"

# Clean previous export
rm -rf "$EXPORT_DIR"/*
mkdir -p "$EXPORT_DIR"

# Run Godot export
echo "Exporting iOS build..."
/Applications/Godot.app/Contents/MacOS/Godot \
    --headless \
    --path "$GODOT_PROJECT" \
    --export-debug "iOS" \
    "$EXPORT_DIR/crossums.ipa"

# Check result
if [ -f "$EXPORT_DIR/crossums.ipa" ]; then
    SIZE=$(du -h "$EXPORT_DIR/crossums.ipa" | cut -f1)
    echo ""
    echo "✓ Export successful: $EXPORT_DIR/crossums.ipa ($SIZE)"
    echo ""
    echo "To install on iPad:"
    echo "  1. Connect iPad via USB"
    echo "  2. Open Xcode → Window → Devices and Simulators"
    echo "  3. Drag crossums.ipa onto your iPad"
else
    echo "✗ Export failed"
    exit 1
fi
