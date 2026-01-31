#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Crossums iOS Export ==="

# Clean previous export
rm -rf exports/ios/*
mkdir -p exports/ios

# Run Godot export
echo "Exporting iOS build..."
/Applications/Godot.app/Contents/MacOS/Godot \
    --headless \
    --path "$SCRIPT_DIR" \
    --export-debug "iOS" \
    exports/ios/crossums.ipa

# Check result
if [ -f "exports/ios/crossums.ipa" ]; then
    SIZE=$(du -h exports/ios/crossums.ipa | cut -f1)
    echo ""
    echo "✓ Export successful: exports/ios/crossums.ipa ($SIZE)"
    echo ""
    echo "To install on iPad:"
    echo "  1. Connect iPad via USB"
    echo "  2. Open Xcode → Window → Devices and Simulators"
    echo "  3. Drag crossums.ipa onto your iPad"
else
    echo "✗ Export failed"
    exit 1
fi
