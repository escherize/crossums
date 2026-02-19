class_name StageConfig
extends RefCounted
## Configuration for a specific stage/puzzle combination.
## Determines difficulty parameters like grid size, score target, etc.

# =============================================================================
# CONSTANTS
# =============================================================================

## Score targets per stage (1-9) - cumulative across 3 puzzles
const SCORE_TARGETS := [400, 600, 900, 1200, 1800, 2500, 3500, 5000, 7000]

## Grid sizes per stage: 3,3,4,5,6, then reset for negatives: 3,4,5,6
const GRID_SIZES := [3, 3, 4, 5, 6, 3, 4, 5, 6]

## Cell value ranges per stage [min, max, exclude_zero]
## Stages 6-9 exclude 0 from the range
const VALUE_RANGES := [
	[1, 3, false],   # Stage 1: 1-3
	[1, 5, false],   # Stage 2: 1-5
	[1, 7, false],   # Stage 3: 1-7
	[1, 9, false],   # Stage 4: 1-9
	[1, 9, false],   # Stage 5: 1-9
	[-1, 9, true],   # Stage 6: -1 to 9, no 0
	[-2, 9, true],   # Stage 7: -2 to 9, no 0
	[-3, 9, true],   # Stage 8: -3 to 9, no 0
	[-3, 9, true],   # Stage 9: -3 to 9, no 0
]

# =============================================================================
# CONFIGURATION VALUES
# =============================================================================

var stage: int
var puzzle_index: int
var grid_size: int
var score_target: int
var min_cell_value: int
var max_cell_value: int
var exclude_zero: bool

# =============================================================================
# FACTORY
# =============================================================================

static func get_config(p_stage: int, p_puzzle_index: int):
	var script = load("res://scripts/core/stage_config.gd")
	var config = script.new()
	config.stage = p_stage
	config.puzzle_index = p_puzzle_index

	# Grid size scales with stage (clamped to valid range)
	var stage_idx := clampi(p_stage - 1, 0, GRID_SIZES.size() - 1)
	config.grid_size = GRID_SIZES[stage_idx]

	# Score target per stage
	config.score_target = SCORE_TARGETS[stage_idx]

	# Cell value range per stage
	var value_idx := clampi(p_stage - 1, 0, VALUE_RANGES.size() - 1)
	config.min_cell_value = VALUE_RANGES[value_idx][0]
	config.max_cell_value = VALUE_RANGES[value_idx][1]
	config.exclude_zero = VALUE_RANGES[value_idx][2]

	return config


# =============================================================================
# HELPERS
# =============================================================================

func to_puzzle_config() -> PuzzleLogic.PuzzleConfig:
	## Convert to PuzzleLogic.PuzzleConfig for puzzle generation
	var pc = PuzzleLogic.PuzzleConfig.new()
	pc.grid_size = Vector2i(grid_size, grid_size)
	pc.min_cell_value = min_cell_value
	pc.max_cell_value = max_cell_value
	pc.exclude_zero = exclude_zero
	return pc


func get_description() -> String:
	## Human-readable description for debugging
	return "Stage %d Puzzle %d: %dx%d grid, target %d" % [
		stage, puzzle_index + 1, grid_size, grid_size, score_target
	]
