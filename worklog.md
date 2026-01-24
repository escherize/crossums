# Crosssums Development Worklog

**Engine:** Godot 4.5.1
**Platform:** macOS (Apple M1 Max)

---

## 2026-01-23

### Session Summary
Major progress on core puzzle mechanics, scoring system, and bug fixes.

---

### Completed: Phase 1-3 (Core Puzzle + Generation + Scoring)

**Core puzzle fully functional:**
- 3x3 to 6x6 grid rendering
- Touch-friendly tap-to-toggle cells (delete/restore)
- Real-time target sum display
- Auto-win detection
- Undo functionality

**Puzzle generation algorithm:**
- Guarantees at least 1 solution cell per row/column (no 0 targets)
- Guarantees at least 1 decoy cell per row/column (no winning at start)
- ~50% cells to delete ratio

**Scoring system implemented:**
- Base points by grid size (100/200/350/500)
- +25 points per kept cell (increased from +5 to reward optimization)
- Line multiplier: +0.2x per valid row/column
- Formula: `(Base + KeptBonus) × LineMultiplier`
- Shows breakdown on win: "Kept X/Y | Base + Kept = Subtotal × Multiplier"

---

### Bug Fixes

1. **Cell visual state on restore** - Added `release_focus()` after click to prevent "selected" look

2. **Impossible puzzles** - Rewrote generation to: (1) select solution cells, (2) fill ALL cells randomly, (3) calculate targets from solution cells only

3. **Target alignment** - Fixed spacer width for column targets

4. **Grid centering** - Added `custom_minimum_size` calculation for proper CenterContainer centering

5. **Cell sizes for HiDPI** - Increased from 64→80→96 pixels

6. **Touch behavior** - Changed to `ACTION_MODE_BUTTON_RELEASE` for drag-to-cancel UX

7. **Focus outline removed** - Added `StyleBoxEmpty` for focus style

8. **Target colors not updating** - Added `is_inside_tree()` check and `queue_redraw()`

9. **Target color logic simplified** - Changed from 3-state (under/exact/over) to 2-state:
   - RED = doesn't match (under OR over)
   - GREEN = exact match

10. **Animation pivot point** - Added `pivot_offset = SIZE / 2` so cells scale from center, not top-left

---

### Design Decisions Made

**Chosen direction: Optimization + Roguelike Stakes**
- Multiple valid solutions can exist
- Skill = finding solutions that keep MORE cells for bonus points
- Future: Add tension via lives, score targets, limited resources
- Operators (Balatro-style jokers) planned for Phase 4

**Color scheme:**
- Cells: Dark blue-gray (active), Dark gray (deleted), Dark green (kept)
- Targets: Red (wrong), Green (exact match)

---

### Technical Notes / Workarounds

1. **GDScript enum type issues** - Used `const int` instead of `enum` to avoid type assignment errors in Godot 4.5

2. **ScoringEngine class_name not recognized** - Used `preload()` workaround in main.gd instead of relying on global class registration

3. **Node references** - Used `%UniqueNodeName` syntax with `unique_name_in_owner = true` instead of `$NodePath`

---

### Files Created/Modified

**New files:**
- `autoload/event_bus.gd` - Signal hub
- `scripts/core/puzzle_state.gd` - Grid data structure
- `scripts/core/puzzle_logic.gd` - Generation & validation
- `scripts/core/scoring_engine.gd` - Score calculation
- `scenes/puzzle/grid_cell.gd` + `.tscn` - Clickable cell
- `scenes/puzzle/puzzle_grid.gd` + `.tscn` - Grid container
- `scenes/puzzle/target_display.gd` + `.tscn` - Row/column targets
- `scenes/main.gd` + `.tscn` - Test scene with UI

**Documentation:**
- `/Users/bcm/.claude/plans/spicy-splashing-gizmo.md` - Implementation plan
- Updated design doc with touch screen support note
- Created this worklog

---

### To Verify (End of Session)

- [ ] Target colors update correctly (RED when wrong, GREEN when exact)
- [ ] Cell animations scale from center
- [ ] No rows/columns green at puzzle start
- [ ] No 0 target values

---

### Next Up (Pending)

1. **Step 2: Score Target Display** - Show "Target: 300" before puzzle, PASS/FAIL feedback
2. **Step 3: Basic Run Structure** - Stages, lives, score requirements
3. **Phase 4: Operator System** - 5 MVP operators that modify scoring

---

### Future Ideas Noted

- **Hint system**: Detect when sum becomes unreachable (deleted too much) - could warn player or auto-highlight
- **Multi-solution optimization**: Rework generation to explicitly support multiple valid solutions, calculate "optimal" kept count for comparison
