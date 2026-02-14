# Retrospective: Web Layout Bug (v0.2.3 - v0.2.5)

**Date**: 2026-01-26
**Duration**: ~2 hours of debugging
**Severity**: Critical (web build completely broken)

## The Problem

After implementing landscape layout and various UI improvements, the web build became severely broken:
- v0.2.3: Almost entirely blank screen, only partial UI visible at far left edge
- Buttons cut off ("mit" instead of "Submit")
- Grid not rendering at all
- Native builds worked fine

## Root Cause

**`DisplayServer.screen_get_size()` returns different values on web vs native.**

In `main.gd`, the `_apply_safe_area()` function used:
```gdscript
var screen_size := DisplayServer.screen_get_size()
var safe_rect := DisplayServer.get_display_safe_area()
```

- **Native**: Returns the game window size (e.g., 1280x720)
- **Web**: Returns the **full monitor resolution** (e.g., 2560x1440)

This caused margins of 500-1000+ pixels to be applied, pushing the entire UI off-screen.

## Failed Approaches

1. **AspectRatioContainer** - Broke web build completely (blank screen)
2. **Async waiting for container sizing** - Added complexity, still broke web
3. **Using 80% of viewport height** - Grid too large, pushed UI off screen
4. **Various sizing tweaks** - Didn't address the core issue

## The Fix

1. **Removed script-based layout modification** - Deleted `_apply_safe_area()`
2. **Set margins in .tscn file** - Fixed 16px margins via `theme_override_constants`
3. **Reverted to conservative grid sizing** - `minf(viewport_size.x, viewport_size.y) * 0.55`

## Lessons Learned

### 1. DisplayServer APIs are platform-specific
`DisplayServer.screen_get_size()` and `get_display_safe_area()` behave differently on web. Always test web builds when using these APIs.

### 2. Prefer declarative layout over script modifications
Setting layout properties in `.tscn` files is more reliable than modifying them at runtime. Godot's container system handles cross-platform sizing correctly when configured properly.

### 3. Web builds need explicit testing
The Godot editor and native builds can mask web-specific issues. Always deploy and test web builds after layout changes.

### 4. Keep layout logic vanilla
Avoid:
- Async/await in layout code
- DisplayServer APIs for sizing
- Complex parent-child size dependencies

Prefer:
- Anchors and container settings in .tscn
- Viewport-relative sizing when needed
- Fixed values where appropriate

### 5. Version numbers are essential for debugging
Adding `GameConfig.VERSION` and auto-bumping in `deploy.sh` made it immediately clear which version was deployed, saving confusion.

## Configuration That Works

**project.godot:**
```ini
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_height"
```

**Root Control nodes:**
```
anchors_preset = 15  # Full Rect
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
```

**Grid sizing (viewport-based, works everywhere):**
```gdscript
var viewport_size := get_viewport().get_visible_rect().size
var available_space := minf(viewport_size.x, viewport_size.y) * 0.55
```

## Future Considerations

If iOS safe area support is needed later:
1. Use `OS.get_name()` to detect platform
2. Only apply safe area margins on iOS/Android
3. Or use Godot's built-in safe area handling if available in future versions
