# Crosssums Development Worklog

**Engine:** Godot 4.5.1
**Platform:** macOS (Apple M1 Max)

---

## 2026-02-20

### Session Summary
Attempted shader-based tile state system for NORMAL/DELETED/CIRCLED visual states. Abandoned after ~2 hours of debugging UV/border issues.

---

### Failed Experiment: Tile State Shader

**Goal:** Replace multiple tile images with a single shader that handles all visual states (normal, deleted, circled) with juicy transitions.

**Files created (now deleted):**
- `assets/shaders/tile_state.gdshader` - Canvas item shader with state uniforms
- `scripts/vfx/tile_state_material.gd` - Helper class for material management
- `scenes/test/tile_shader_test.tscn` - 3x3 test grid scene
- `scenes/test/tile_shader_test.gd` - Click-to-cycle test script
- `assets/textures/tile.png` - 1024→256 resized birch wood tile

**What worked:**
- Basic shader applied correctly (solid blue test worked)
- UV gradient visualization worked (proved UVs are 0-1)
- 40% border with `step()` function worked

**What didn't work:**
- `smoothstep()` for borders never rendered (unknown reason)
- Borders below ~27% width invisible (UV scaling issue?)
- Borders not centered (stretch_mode = 5 caused offset)
- Lighting-based "selected" effect looked washed out/ugly

**Key learnings:**
1. Godot shaders don't support `return` in fragment() - causes silent compile failure
2. TextureRect `stretch_mode` affects UV mapping unpredictably
3. `smoothstep()` conditionals don't work the same as `step()` in this context
4. Wood grain texture scaling during tile animations looks unnatural

**Decision:** Abandon shader approach. Will use separate images or simpler visual distinction for circled state.

---

## 2026-02-14

### Session Summary
Simplified game design by embracing determinism: removed operators that conflict with puzzle solving, made all puzzles single-solution, and added progressive difficulty via cell value ranges.

---

### Design Insight: Accepting Determinism

From the memory file design notes:
> Current approach (picking shapes on board) is problematic for Crossums because:
> - Highly deterministic which cells are required
> - Adding wiggle room changes the game too much

**Key realization:** The game is fundamentally deterministic about which cells must be deleted. Rather than fighting this, we now embrace it. Operators should change the game in OTHER ways (like Gimme auto-solving endgame), not reward keeping specific cells that may need to be deleted.

---

### Removed: 6 "Keep Specific Cells" Operators

These operators created frustrating conflicts between bonus goals and required solutions:

| Operator | Mechanic | Problem |
|----------|----------|---------|
| `corner_keeper` | +200 if all 4 corners kept | Corners may need deleting |
| `lucky_seven` | +77 per 7 kept | 7s may need deleting |
| `flipper` | +40 per 6 or 9 kept | 6s/9s may need deleting |
| `prime_time` | +30 per prime kept | Primes may need deleting |
| `square_peg` | +100/+1000 for 2×2/3×3 uniform squares | Shape conflicts with solution |
| `zero_hero` | ×2 if you keep a 0 | Zero may need deleting |

**Remaining operators (7):**
- `counter` - +10 per kept cell (generic, no conflict)
- `row_master` / `column_master` - rewards completing the puzzle
- `circlicious` / `elite_delete` - economy modifiers (player strategy)
- `purist` - +300 if no circles used (player strategy)
- `gimme` - auto-solves when 1 row + 1 col remain (changes gameplay)

---

### Removed: Multi-Solution Puzzle Generation

Previously had two generation strategies:
- `generate_single_solution()` - for boss stages
- `generate_multi_solution()` - exchange patterns giving 2-16 solutions

Now all puzzles use `generate_single_solution()`. Multi-solution implied player choice where there wasn't meaningful choice - the deterministic nature means one solution is usually clearly optimal.

**Files changed:**
- `puzzle_generator.gd` - removed `generate_multi_solution()`, exchange pattern helpers
- `game_state.gd` - removed boss stage special-casing

---

### Feature: Progressive Cell Value Ranges

Cell values now scale with stage progression:

| Stage | Range | Notes |
|-------|-------|-------|
| 1 | 1-3 | Very simple, tutorial-friendly |
| 2 | 1-4 | Still easy |
| 3 | 1-5 | |
| 4 | 1-6 | |
| 5 | 1-7 | |
| 6 | 1-9 | Full positive range |
| 7 | -2 to 9 | Introduce negatives |
| 8 | -5 to 9 | Full difficulty |

**Implementation (`stage_config.gd`):**
```gdscript
const VALUE_RANGES := [
    [1, 3], [1, 4], [1, 5], [1, 6],
    [1, 7], [1, 9], [-2, 9], [-5, 9],
]
```

---

### Removed: Zeros from Puzzles

Zeros no longer appear in any puzzle. Rationale:
- Deleting a 0 has no effect on sums
- Keeping a 0 has no effect on sums
- Zero cells are meaningless decisions

**Implementation:** Added `_random_nonzero()` helper to both `puzzle_generator.gd` and `puzzle_logic.gd` that skips 0 when generating values in ranges that include it.

---

### Files Modified

| File | Changes |
|------|---------|
| `scripts/operators/impl/op_*.gd` | Deleted 6 operator files |
| `scripts/operators/operator_registry.gd` | Removed 6 operators from registry |
| `scripts/core/puzzle_generator.gd` | Removed multi-solution, added value range params |
| `scripts/core/puzzle_logic.gd` | Added `_random_nonzero()`, default min=1 |
| `scripts/core/stage_config.gd` | Added `VALUE_RANGES`, `min/max_cell_value` |
| `autoload/game_state.gd` | Always use single-solution, pass value range |
| `tests/corpus/op_*.json` | Deleted 3 test files for removed operators |

---

### Commits

1. `7987083` - Remove 6 operators that conflict with deterministic puzzle solving
2. `fa2e28c` - Make all puzzles deterministic (single-solution only)
3. `dd801e4` - Add configurable cell value ranges per stage

---

## 2026-01-29

### Session Summary
Implemented slack progression and stage-level score gates to make puzzles easier and give operators room to shine. Design influenced by Schell's "Art of Game Design" (Chapter 12: Balance, Chapter 14: Puzzles).

---

### Feature: Slack Progression (Tight → Loose)

Each stage now has 3 puzzles with increasing slack (room for optimization):

| Puzzle | Slack | Feel | Purpose |
|--------|-------|------|---------|
| 0 | Tight | Constrained | Test core puzzle skill |
| 1 | Medium | Balanced | Building tension |
| 2 (Boss) | Loose | Open | Operator playground, epic moves |

**Implementation (`stage_config.gd`):**
```gdscript
var base_slack := clampf(0.7 - (p_stage - 1) * 0.06, 0.2, 0.7)
var puzzle_adjustment := p_puzzle_index * 0.15  # 0, 0.15, 0.30
config.slack = clampf(base_slack + puzzle_adjustment, 0.2, 0.85)
```

Slack now integrates into puzzle generation via `to_puzzle_config()`:
```gdscript
pc.cells_to_delete_ratio = clampf(0.55 - (slack - 0.2) * 0.4, 0.25, 0.55)
```

---

### Feature: Stage-Level Score Gates

Scores now accumulate across 3 puzzles; gate check only after boss puzzle.

**Old behavior:** Each puzzle checked against target → miss = instant game over
**New behavior:** Stage total checked after puzzle 2 → miss = game over

**Files modified:**
- `run_state.gd` - Added `stage_score`, `add_stage_score()`, `reset_stage_score()`
- `run_manager.gd` - Refactored `on_puzzle_complete()` for stage gating
- `main.gd` - HUD shows "Stage: X/Y" (accumulated vs target)
- `debug_server.gd` - Updated API for `stage_score` and `passed` logic

**New score targets (~3x old values for 3-puzzle accumulation):**
```gdscript
const SCORE_TARGETS := [900, 1500, 2400, 3600, 6000, 10500, 18000, 30000]
```

---

### Difficulty Tuning Knobs

All in `stage_config.gd`:

| Knob | Location | Current | Effect |
|------|----------|---------|--------|
| `SCORE_TARGETS` | const | [900, 1500, ...] | Stage gate thresholds |
| `GRID_SIZES` | const | [3,3,4,4,5,5,6,6] | Grid size per stage |
| `base_slack` | `get_config()` | 0.7 → 0.28 | Fewer solutions as stages progress |
| `puzzle_adjustment` | `get_config()` | +0.15 per puzzle | Boss gets most slack |
| `cells_to_delete_ratio` | `to_puzzle_config()` | 0.25–0.55 | How many cells removed |
| `allow_negatives` | `get_config()` | stage >= 4 | Negative numbers in later stages |
| `money_reward` | `get_config()` | 3 + stage | Shop currency per puzzle |

**Scoring multipliers (`scoring_engine.gd`):**
- Time multiplier: 2.0 → 1.0 over 60 seconds
- Precision multiplier: 1.5x (perfect) / 1.25x (1-2 restores) / 1.0x (3+)
- Kept bonus: 25 points per cell kept
- Line multiplier: 1.0 + 0.2 per valid line

**Future knobs to consider:**
- Boss puzzle score weight (2x?)
- Grid size per puzzle (not just stage)
- Slack curve shape (linear vs exponential)

---

### Design Rationale (from Schell)

From Chapter 14 (Puzzles):
> "A puzzle is a game with a dominant strategy."

Multi-solution puzzles fight this — players find *their* optimal path.

> Principle #5: "Increase difficulty gradually"

Slack tight→loose within stage creates rhythm: constraint → constraint → payoff.

> Principle #7: "Pyramid structure extends interest"

Stage gates = pyramid. Small puzzles feed into stage goal.

From Chapter 12 (Balance):
> "Expected value is an excellent tool for game balancing"

If basic solve > target, operators have no room. Raised targets so operators become necessary.

---

### Tests Updated

- `run_game_over.json` - Now tests stage-level gating (3 puzzles × 100 < 900 = fail)
- `run_start.json` - Updated expected score_target to 900, added stage_score check

31 tests passing.

---

### Deployed

v0.2.18 - Slack progression + stage-level score gates live.

---

### Technical Notes

1. **GDScript type inference** - `:=` failed for boolean comparisons (`var was_boss := x == 2`). Used explicit `var was_boss: bool = x == 2` instead.

2. **Godot 4.5 parse errors** - Not caught by gdlint. Consider adding headless compile check to test framework.

---

## 2026-01-27

### Session Summary
Fixed circle vulnerability, removed legacy `is_solution` field, added gdlint to test framework.

---

### Feature: Circling Invalid Cell is a Mistake

Previously, players could avoid mistakes by only circling cells (never deleting). Fixed by:
- Added `has_solution_including_cell()` to `puzzle_logic.gd` - checks if any valid solution includes a specific cell
- If no solution includes the cell, circling it triggers `mistake_made` signal (same as deleting a critical cell)
- Tests added: `circle_invalid_is_mistake.json`, `circle_alternate_valid.json`

---

### Refactor: Removed `is_solution` Field

The `is_solution` flag on cells was legacy from before the backtracking solver. Now redundant since the solver determines validity dynamically.

**Removed from:**
- `puzzle_state.gd` - CellData class
- `puzzle_logic.gd` - generation code, `get_cells_to_delete()`, `is_puzzle_solvable()`
- `debug_server.gd` - serialization, `_action_apply_solution()` (now uses solver)
- `game_state.gd` - save/load
- All 27 test JSON files

---

### Added: gdlint to Test Framework

Integrated GDScript linter into `tests/run-tests.ts` - runs before Godot tests.

**Config (`godot_app/gdlintrc`):**
```yaml
disable:
  - max-line-length
  - class-variable-name  # Allow SCREAMING_SNAKE for constants

# Raised limits for large files
max-file-lines: 2000
max-returns: 10
max-public-methods: 20
```

**Inline disables:**
- `debug_server.gd`: `# gdlint: disable=max-returns` (dispatcher with 49 cases)
- `puzzle_state.gd`: `# gdlint: disable=max-public-methods` (34 methods in core data model)

---

### Lint Fixes Applied

**Rules enabled and fixed:**
- `duplicated-load` - consolidated `load("res://scenes/main.tscn")` into `MAIN_SCENE` constant
- `class-definitions-order` - reordered declarations in 8 files (signals → enums → consts → vars → @onready)
- `no-else-return` / `no-elif-return` - removed 10 unnecessary else blocks
- `unused-argument` - prefixed unused `delta` with `_`

---

### Tests

31 tests passing (including gdlint check).

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
