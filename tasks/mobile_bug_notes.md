# Mobile Touch Bug Investigation

## Status: Under Investigation (Code Analysis)

## Export Settings Review

**Web export preset (`export_presets.cfg`):**
- Platform: Web
- Thread support: disabled (single-threaded)
- Virtual keyboard: disabled (not needed for this game)
- Canvas resize policy: 2 (adaptive)

## Code Analysis

### Touch Input Handling in `grid_cell.gd` (lines 76-91)

The code already has explicit `InputEventScreenTouch` handling:
```gdscript
func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.index == 0:  # Primary touch only
            if touch.pressed:
                _is_pressing = true
                _long_press_triggered = false
                _press_start_time = Time.get_ticks_msec()
            else:
                # Touch released - emit click if not long press
                if _is_pressing and not _long_press_triggered:
                    cell_clicked.emit(row, col)
                _is_pressing = false
            accept_event()
            return
```

This code handles touch events directly, bypassing the Button's mouse emulation. The comment says it "bypasses unreliable button_up emulation on mobile web".

### Touch Input in `puzzle_grid.gd` (lines 56-83)

Multitouch (touch index > 0) is handled in `_input()`. Touch index 0 is expected to go through mouse emulation to Button.

### Project Settings (`project.godot`)

No `[input_devices]` section exists. The settings for touch emulation:
- `emulate_touch_from_mouse` - Default: true
- `emulate_mouse_from_touch` - Default: true

In Godot 4.x web exports, these defaults should work, but explicit settings may be needed.

## Potential Issues

1. **Mouse emulation not enabled**: If `emulate_mouse_from_touch` isn't active, touch index 0 won't trigger mouse events for the Button, but the explicit `InputEventScreenTouch` handling in `_gui_input` should still work.

2. **Event consumption**: The `accept_event()` call may prevent the touch from being properly processed by parent controls.

3. **Button action mode**: GridCell extends Button but the `_gui_input` directly handles touch and emits `cell_clicked`, bypassing the Button's normal press handling.

## Proposed Fix

Add explicit input device settings to `project.godot`:

```ini
[input_devices]

pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=true
```

This ensures touch events are properly emulated as mouse events on web, which provides a fallback if the explicit touch handling fails.

## Testing Required

1. Export web build
2. Test on desktop browser with mouse - verify clicking works
3. Test on mobile browser (iOS Safari, Android Chrome):
   - Does tap register on cells?
   - Does tap register on title screen buttons?
   - Does tap register on shop buttons?
   - Does long press work for circling cells?
4. Check browser console for JavaScript errors

## Files to Check

- [x] `godot_app/scenes/puzzle/grid_cell.gd` - Has explicit touch handling
- [x] `godot_app/scenes/puzzle/puzzle_grid.gd` - Has multitouch handling
- [x] `godot_app/project.godot` - Missing input device settings
- [ ] `godot_app/export_presets.cfg` - Web preset looks standard
