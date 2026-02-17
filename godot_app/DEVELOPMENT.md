# Crosssums Development Guide

## Quick Start

```bash
# Open in Godot 4.5.1+
# Run main scene (F5) - starts with 3x3 puzzle
# Click cells to toggle delete/restore
# All targets GREEN = win
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        main.gd                               │
│  (Test harness - buttons, grid size selector, status)        │
└─────────────────────┬───────────────────────────────────────┘
                      │ creates & loads
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    PuzzleGrid                                │
│  - Creates GridCells and TargetDisplays                      │
│  - Handles cell click → updates PuzzleState → refreshes UI   │
└──────┬──────────────────────────────────────┬───────────────┘
       │                                      │
       ▼                                      ▼
┌──────────────┐                    ┌─────────────────┐
│  GridCell    │                    │  TargetDisplay  │
│  (Button)    │                    │  (PanelContainer)│
│  - tap toggle│                    │  - RED/GREEN    │
└──────────────┘                    └─────────────────┘

Data Layer:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  PuzzleState    │    │  PuzzleLogic    │    │  ScoringEngine  │
│  - grid data    │◄───│  - generation   │    │  - score calc   │
│  - cell states  │    │  - validation   │    │  - breakdown    │
│  - targets      │    └─────────────────┘    └─────────────────┘
└─────────────────┘

Singleton:
┌─────────────────┐
│   EventBus      │  (autoload - signals for decoupled communication)
└─────────────────┘
```

## Key Files

| File | Purpose | Key Functions |
|------|---------|---------------|
| `scripts/core/puzzle_state.gd` | Grid data structure | `delete_cell()`, `restore_cell()`, `get_current_row_sum()` |
| `scripts/core/puzzle_logic.gd` | Generation & validation | `generate_puzzle()`, `validate()` |
| `scripts/core/scoring_engine.gd` | Score calculation | `calculate_score()` → `ScoreBreakdown` |
| `scenes/puzzle/puzzle_grid.gd` | Main grid controller | `load_puzzle()`, `_on_cell_clicked()` |
| `scenes/puzzle/grid_cell.gd` | Individual cell UI | `setup()`, `set_cell_state()` |
| `scenes/puzzle/target_display.gd` | Row/col target UI | `update_current_sum()` |

## Data Flow: Cell Click

```
1. User taps cell
2. GridCell._on_pressed() → emits cell_clicked(row, col)
3. PuzzleGrid._on_cell_clicked() receives signal
4. PuzzleGrid calls puzzle_state.delete_cell() or restore_cell()
5. PuzzleGrid calls cell.set_cell_state() to update visual
6. PuzzleGrid calls _update_all_targets() to refresh target colors
7. EventBus.cell_deleted/restored emitted for other listeners
8. main.gd receives event, calls _check_auto_win()
```

## Puzzle Generation Algorithm

```
1. Decide total cells to delete (~50%)
2. Guarantee ≥1 solution cell per row AND column (prevents 0 targets)
3. Guarantee ≥1 decoy cell per row AND column (prevents winning at start)
4. Fill ALL cells with random values 1-9
5. Calculate targets from solution cells only
6. Player can find ANY valid solution (not just the generated one)
```

## Scoring Formula

```
Score = (Base + KeptBonus + OperatorBonus) × TimeMultiplier × OperatorMultiplier

Base = dim² × 10  (90/160/250/360 for 3x3-6x6)
KeptBonus = kept_cells × 25
TimeMultiplier = 2.0 → 1.0 (decays over puzzle duration)
```

## Known Workarounds & Godot Gotchas

1. **ScoringEngine class not recognized globally** - Use `preload()`:
   ```gdscript
   const ScoringEngineScript = preload("res://scripts/core/scoring_engine.gd")
   var breakdown = ScoringEngineScript.calculate_score(puzzle)
   ```

2. **Enum type errors** - Use `const int` instead of `enum`:
   ```gdscript
   const STATUS_WRONG := 0
   const STATUS_EXACT := 1
   ```

3. **Node paths** - Use unique names:
   ```gdscript
   @onready var label: Label = %StatusLabel  # not $StatusLabel
   ```

4. **Scene transitions fail when returning to starting scene** - `change_scene_to_packed()`
   silently fails with ERR_CANT_CREATE when switching back to the scene you started in.
   Use `change_scene_to_file()` instead:
   ```gdscript
   # BAD - fails when returning to title from main
   const TitleScene = preload("res://scenes/title/title_screen.tscn")
   get_tree().change_scene_to_packed(TitleScene)

   # GOOD - always works
   get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")
   ```
   Source: https://github.com/godotengine/godot/issues/72921

5. **Control mouse_filter doesn't affect children** - A parent's `mouse_filter` setting
   does NOT block input to its children. Input goes to the topmost visible control at the
   click position first (based on draw order), then `mouse_filter` determines propagation:
   - `MOUSE_FILTER_STOP` (0) = consume event, don't pass to parent
   - `MOUSE_FILTER_PASS` (1) = consume, but also pass to parent
   - `MOUSE_FILTER_IGNORE` (2) = don't receive event at all

   To block input to an area, place a Control with STOP that **spatially covers**
   the controls you want to block.
   Sources:
   - https://docs.godotengine.org/en/stable/classes/class_control.html
   - https://godotforums.org/d/37631-the-mouse-filters-are-driving-me-crazy

6. **Don't override custom_minimum_size in _ready()** - If you set `custom_minimum_size`
   in a component's `_ready()`, it will override any size set by the parent before
   instantiation. Check if already set:
   ```gdscript
   func _ready() -> void:
       if custom_minimum_size == Vector2.ZERO:
           custom_minimum_size = DEFAULT_SIZE
   ```

## Testing Checklist

- [ ] Generate new puzzle → all targets RED (none should be GREEN at start)
- [ ] Delete a cell → target colors update immediately
- [ ] Restore a cell → target colors update immediately
- [ ] Solve puzzle → all targets GREEN, win message shows score
- [ ] Cell animations scale from center (not top-left)
- [ ] Grid sizes 3x3 through 6x6 all work
- [ ] Undo button restores last deleted cell

## Important Paths

- **Design doc**: `docs/10-design/GAME_DESIGN_IDEAS.md`
- **Implementation status**: `docs/30-technical/implementation_status.md`
- **Worklog**: `docs/00-meta/worklog.md`

## EventBus Signals Status

Currently connected:
- `cell_deleted` - main.gd listens for status updates
- `cell_restored` - main.gd listens for status updates

Defined but not yet used (for future phases):
- `puzzle_submitted`, `puzzle_validated`, `puzzle_loaded`
- `score_calculation_started`, `score_step`, `score_finalized`
- `operator_triggered`
- `run_started`, `stage_started`, `puzzle_started`, `puzzle_completed`, `run_ended`
- `game_over`, `timeout`
- `money_changed`, `operator_acquired`, `operator_sold`, `function_used`
- `tooltip_requested`, `tooltip_hidden`
- `screen_transition_requested`, `screen_transition_completed`
- `game_state_changed`

---

## Git Workflow

**Commit after completing each major feature or phase.** Don't let work pile up uncommitted.

Examples of commit points:
- Completed a phase (e.g., "Phase 3: Scoring System")
- Fixed a batch of related bugs
- Added a new system (operators, shop, etc.)
- Before starting risky refactors

---

## Current Status

Core systems implemented:
- ✅ Puzzle solving with single-solution generation
- ✅ 8-stage run progression
- ✅ Timer as fail condition (no lives system)
- ✅ 9 operators with scoring hooks
- ✅ Shop system with buy/sell/reroll
- ✅ Score animation (Balatro-style breakdown)
- ✅ Sound effects via SoundManager

See `docs/30-technical/implementation_status.md` for detailed feature status.
