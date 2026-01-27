class_name StageConfig
extends RefCounted
## Configuration for a specific stage/puzzle combination.
## Determines difficulty parameters like grid size, score target, etc.

# =============================================================================
# CONFIGURATION VALUES
# =============================================================================

var stage: int
var puzzle_index: int
var grid_size: int
var score_target: int
var allow_negatives: bool
var slack: float
var money_reward: int

# =============================================================================
# CONSTANTS
# =============================================================================

## Score targets per stage (1-8)
const SCORE_TARGETS := [300, 500, 800, 1200, 2000, 3500, 6000, 10000]

## Grid sizes per stage: 3,3,4,4,5,5,6,6
const GRID_SIZES := [3, 3, 4, 4, 5, 5, 6, 6]

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

	# Negatives enabled from stage 4+
	config.allow_negatives = p_stage >= 4

	# Slack decreases as stages progress (tighter puzzles)
	# Stage 1: 0.7, Stage 8: ~0.28
	config.slack = clampf(0.7 - (p_stage - 1) * 0.06, 0.2, 0.7)

	# Money reward increases with stage
	config.money_reward = 3 + p_stage

	return config


# =============================================================================
# HELPERS
# =============================================================================

func to_puzzle_config() -> PuzzleLogic.PuzzleConfig:
	## Convert to PuzzleLogic.PuzzleConfig for puzzle generation
	var pc = PuzzleLogic.PuzzleConfig.new()
	pc.grid_size = Vector2i(grid_size, grid_size)
	pc.cells_to_delete_ratio = 0.5
	# Note: allow_negatives and slack are defined in Sprint 3
	# For now, just set basic config
	return pc


func get_description() -> String:
	## Human-readable description for debugging
	return "Stage %d Puzzle %d: %dx%d grid, target %d, reward $%d" % [
		stage, puzzle_index + 1, grid_size, grid_size, score_target, money_reward
	]
