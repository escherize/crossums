# Circle Mode UX: Design Decision

> **Decision:** Side-mounted "shift key" button for circle mode.
> **Date:** 2026-02-15
> **Status:** Approved

**Scope:** Touchscreen only (iOS/Android). Web users right-click to circle.

---

## The Design

A button positioned near the edge of the screen that acts as a modifier key:

```
┌─────────────────────────────────────┐
│                                     │
│     ┌─────────────────────┐         │
│     │                     │         │
│     │    Puzzle Grid      │    ○    │  ← Circle mode button
│     │                     │    ↑    │    (right edge, thumb reach)
│     │                     │  HOLD   │
│     └─────────────────────┘         │
│                                     │
└─────────────────────────────────────┘
```

### Behavior

| Button State | Cell Appearance | Tap Action |
|--------------|-----------------|------------|
| **Not held** (lowercase) | Normal | Delete cell |
| **Held** (uppercase) | Circle-tinted | Circle cell |

### Visual Feedback When Held

- Button changes color (e.g., cyan glow)
- All active cells get subtle circle-mode tint
- Cursor/touch indicator changes
- Optional: grid border pulses cyan

---

## Why This Approach

### 1. Ergonomic Placement

Side-of-screen placement means:
- Thumb naturally rests there when holding device
- No reaching across the screen
- Works for both left and right hand (mirror option)
- Doesn't obscure puzzle grid

### 2. Shift-Key Mental Model

Everyone understands shift:
- Hold for temporary mode change
- Release to return to normal
- No mode confusion ("am I in circle mode?")
- Muscle memory transfers from keyboards

### 3. Fast Multi-Circle

To circle multiple cells:
1. Hold circle button with thumb
2. Tap cells rapidly with other hand
3. Release when done

Much faster than hold-per-cell (current) or tap-toggle-tap-toggle.

### 4. Clear State Indication

Visual changes while held prevent mode errors:
- Can't forget you're in circle mode—everything looks different
- Releasing immediately returns to normal visuals
- No "oops I was still in circle mode" mistakes

---

## Implementation

### Button Component

```gdscript
# circle_mode_button.gd
extends TouchScreenButton

signal circle_mode_changed(active: bool)

func _ready():
    # Emit on press/release, not toggle
    pressed.connect(func(): circle_mode_changed.emit(true))
    released.connect(func(): circle_mode_changed.emit(false))
```

### Puzzle Grid Integration

```gdscript
# In puzzle_grid.gd or parent scene
var circle_mode_active: bool = false

func _on_circle_mode_changed(active: bool):
    circle_mode_active = active
    _update_cell_visuals()

func _on_cell_clicked(row: int, col: int):
    if circle_mode_active:
        _on_cell_circle_requested(row, col)
    else:
        _on_cell_delete_requested(row, col)

func _update_cell_visuals():
    for row in grid_cells:
        for cell in row:
            cell.set_circle_mode_hint(circle_mode_active)
```

### Cell Visual Hint

```gdscript
# In grid_cell.gd
var circle_mode_hint: bool = false

func set_circle_mode_hint(active: bool):
    circle_mode_hint = active
    _update_appearance()

func _update_appearance():
    # ... existing logic ...

    # Circle mode visual hint (only for active/circled cells)
    if circle_mode_hint and cell_state in [ACTIVE, CIRCLED]:
        # Subtle cyan tint to indicate "tapping will circle"
        bg_color = bg_color.lerp(Color(0.3, 0.7, 0.9), 0.15)
```

### Placement Options

```gdscript
# Settings option for handedness
enum CircleButtonSide { LEFT, RIGHT }

var circle_button_side: CircleButtonSide = CircleButtonSide.RIGHT

func _position_circle_button():
    if circle_button_side == CircleButtonSide.RIGHT:
        circle_button.anchor_left = 1.0
        circle_button.anchor_right = 1.0
        circle_button.offset_left = -80
    else:
        circle_button.anchor_left = 0.0
        circle_button.anchor_right = 0.0
        circle_button.offset_right = 80
```

---

## Web / Desktop Behavior

**Web users right-click to circle.** No shift-key button needed.

- Right-click on cell = circle/uncircle (already implemented)
- Left-click = delete/restore
- Shift+click = circle (optional enhancement)

The touchscreen button is hidden on web/desktop builds.

---

## Button Design

### Visual States

```
┌───────┐
│   ○   │  Normal (not held)
│ CIRCLE│  Gray/muted
└───────┘

┌───────┐
│   ◉   │  Held (active)
│ CIRCLE│  Cyan glow, filled circle
└───────┘
```

### Size & Touch Target

- Minimum 60x80px for comfortable thumb press
- Slightly taller than wide (vertical thumb motion)
- Rounded corners for friendly feel

---

## Accessibility Notes

- Button must be large enough for motor impairment
- Color change shouldn't be only indicator (also icon change: ○ → ◉)
- Setting to swap sides for left-handed users
- Long-press-to-circle still available as alternative for users who prefer it

---

## Removed Alternatives

Previous analysis considered these options (now rejected):

- **Hold-to-circle (current):** Too slow, not discoverable
- **Mode toggle:** Risk of mode confusion, extra tap to activate
- **Swipe gesture:** Unreliable on small cells, conflicts with scroll
- **Two-finger tap:** Niche, hard to execute accurately
- **Reduced hold time:** Still slower than shift-key approach

The shift-key button is superior for speed, clarity, and ergonomics.
