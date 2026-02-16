# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Crossums is a Balatro-inspired roguelike number puzzle game built in Godot 4.5. Players delete numbers from a grid so each row and column sums to its target, with higher scores for keeping more numbers.

## Development Commands

```bash
# Install dependencies (first time only)
bun install

# Run all tests (lint + logic + visual)
bun test

# Run filtered/partial tests
bun tests/run-tests.ts --lint-only       # Just gdlint (fast)
bun tests/run-tests.ts --logic-only      # Logic tests only, no visual
bun tests/run-tests.ts --visual-only     # Visual regression tests only
bun tests/run-tests.ts --no-lint         # Skip lint, run all tests
bun tests/run-tests.ts solve_4x4         # Filter by name

# Test rubric - which to run when:
#   After editing .gd files:    --lint-only     (fast, catches syntax/style)
#   After logic changes:        --logic-only    (tests game mechanics)
#   After UI/layout changes:    --visual-only   (catches visual regressions)
#   Before commit:              (no flags)      full suite

# Lint GDScript directly
~/Library/Python/3.9/bin/gdlint godot_app/**/*.gd

# Run game CLI against running game (debug server on localhost:9999)
bun game-cli.ts state               # Get game state
bun game-cli.ts action delete_cell '{"row": 0, "col": 1}'
bun game-cli.ts screenshot /tmp/shot.png

# Visual baseline management
bun tests/update-baselines.ts                 # List all baselines
bun tests/update-baselines.ts title_screen    # Update specific baseline
bun tests/update-baselines.ts --delete old    # Delete a baseline
bun tests/update-baselines.ts --clean-diffs   # Remove diff images
```

## Architecture

### Singletons (Autoloads)
- **EventBus** (`autoload/event_bus.gd`) - Decoupled signal communication
- **GameState** (`autoload/game_state.gd`) - Persistent game state
- **RunManager** (`autoload/run_manager.gd`) - Run/stage progression
- **DebugServer** (`autoload/debug_server.gd`) - TCP server for game-cli
- **SoundManager** (`autoload/sound_manager.gd`) - SFX with configurable mappings

### Core Data Layer
- **PuzzleState** (`scripts/core/puzzle_state.gd`) - Grid data, cell states, targets
- **PuzzleLogic** (`scripts/core/puzzle_logic.gd`) - Generation, validation
- **ScoringEngine** (`scripts/core/scoring_engine.gd`) - Score calculation

### UI Components
- **PuzzleGrid** (`scenes/puzzle/puzzle_grid.gd`) - Main grid controller
- **GridCell** (`scenes/puzzle/grid_cell.gd`) - Individual cell buttons
- **TargetDisplay** (`scenes/puzzle/target_display.gd`) - Row/col target labels

### Data Flow: Cell Click
1. GridCell emits `cell_clicked(row, col)`
2. PuzzleGrid calls `puzzle_state.delete_cell()` or `restore_cell()`
3. PuzzleGrid updates cell visuals and target colors
4. EventBus emits `cell_deleted`/`cell_restored`
5. main.gd checks for auto-win

## Godot Workarounds

**ScoringEngine class not globally recognized** - Use preload:
```gdscript
const ScoringEngineScript = preload("res://scripts/core/scoring_engine.gd")
var breakdown = ScoringEngineScript.calculate_score(puzzle)
```

**Scene transitions fail when returning to starting scene** - Use file path:
```gdscript
# BAD - fails when returning
get_tree().change_scene_to_packed(TitleScene)

# GOOD - always works
get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")
```

**Control mouse_filter doesn't affect children** - Input goes to topmost visible control first. To block input, place a Control with STOP that spatially covers the target.

**Don't override custom_minimum_size in _ready()** - Check if already set:
```gdscript
if custom_minimum_size == Vector2.ZERO:
    custom_minimum_size = DEFAULT_SIZE
```

## Test Framework

Tests are JSON files in `tests/corpus/`. Test runner starts Godot, runs gdlint, then executes test steps via debug server.

**Functional test:**
```json
{
  "name": "test_name",
  "setup": {"size": 3, "seed": 12345},
  "steps": [
    {"action": "delete_cell", "params": {"row": 0, "col": 1}},
    {"assert": "assert_valid"}
  ]
}
```

**Visual regression test:**
```json
{
  "name": "visual_example",
  "setup": {"size": 3, "seed": 12345},
  "steps": [
    {"action": "wait_idle"},
    {"visual": "my_baseline_name", "max_diff_pixels": 2000}
  ]
}
```

Visual tests compare screenshots against baselines in `tests/baselines/`. First run creates the baseline; subsequent runs compare and fail if pixels differ beyond `max_diff_pixels`. Diff images are saved to `tests/diffs/`. Use seeds for deterministic puzzle generation.

**Seeded runs** for deterministic testing:
```json
{
  "setup": {"action": "start_run", "seed": 12345},
  "steps": [...]
}
```

## Run Seeding Architecture

Runs can be seeded for deterministic puzzle generation:
- `run_seed = 0` → random puzzles (default)
- `run_seed > 0` → deterministic sequence via `SEED_VERSION * run_seed + stage/puzzle offsets`

**Current limitation**: Single RNG stream. Adding random-consuming features (shop inventory, operator effects) would shift puzzle sequences for existing seeds.

**Future path** (when needed): Isolated RNG streams per system. See `run_state.gd` comments for implementation pattern. Each system (puzzles, shop, operators) gets its own RNG seeded by `hash(run_seed + "_system_" + context)`. This ensures adding features to one system doesn't affect others.

## Key Documentation

- `godot_app/DEVELOPMENT.md` - Detailed architecture and data flow
- `docs/30-technical/GAME_CLI.md` - Full CLI reference
- `docs/10-design/GAME_DESIGN_IDEAS.md` - Current game design decisions
