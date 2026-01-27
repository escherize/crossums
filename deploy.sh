#!/bin/bash
# Deploy Crossums to astro_blog
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_PROJECT="$SCRIPT_DIR/godot_app"
EXPORT_DIR="$GODOT_PROJECT/exports/web"
DEPLOY_DIR="/Users/bcm/dv/astro_blog/public/crossums"
VERSION_FILE="$GODOT_PROJECT/scripts/core/game_config.gd"

echo "=== Crossums Deploy ==="

# Bump patch version (e.g., 0.2.1 -> 0.2.2)
CURRENT_VERSION=$(grep 'const VERSION' "$VERSION_FILE" | sed 's/.*"\(.*\)".*/\1/')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
sed -i '' "s/const VERSION := \"$CURRENT_VERSION\"/const VERSION := \"$NEW_VERSION\"/" "$VERSION_FILE"
echo "Version: $CURRENT_VERSION -> $NEW_VERSION"

# Run tests first
echo "Running tests..."
cd "$SCRIPT_DIR"
if ! bun tests/run-tests.ts; then
    echo "ERROR: Tests failed - aborting deploy"
    exit 1
fi
echo ""

# Clean export directory
echo "Cleaning export directory..."
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

# Export with Godot in headless mode
echo "Exporting web build..."
godot --headless --path "$GODOT_PROJECT" --export-release "Web" "$EXPORT_DIR/index.html"

# Verify export succeeded
if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "ERROR: Export failed - index.html not found"
    exit 1
fi

# Clean deploy directory
echo "Cleaning deploy directory..."
rm -rf "$DEPLOY_DIR"/*

# Copy exported files
echo "Copying to $DEPLOY_DIR..."
cp -r "$EXPORT_DIR"/* "$DEPLOY_DIR/"

echo "=== Deploy complete ==="
echo "Files deployed to: $DEPLOY_DIR"
ls -la "$DEPLOY_DIR"
