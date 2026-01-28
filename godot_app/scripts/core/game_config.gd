class_name GameConfig
extends RefCounted
## Central configuration for all tunable game parameters.
## Operators and consumables can modify these values to affect gameplay.

# =============================================================================
# VERSION (bumped by deploy.sh)
# =============================================================================

const VERSION := "0.2.13"

# =============================================================================
# SCORING - BASE POINTS
# =============================================================================

## Base points awarded by grid size
static var BASE_POINTS := {
	3: 100,
	4: 200,
	5: 350,
	6: 500,
}

## Bonus points per kept cell (rewards optimization)
static var KEPT_BONUS_PER_CELL := 25

## Multiplier added per valid row/column
static var LINE_MULT_PER_VALID := 0.2

# =============================================================================
# TIME MULTIPLIER
# =============================================================================

## Starting time multiplier (max bonus for instant solve)
static var TIME_MULT_START := 2.0

## Floor time multiplier (no penalty, just no bonus)
static var TIME_MULT_FLOOR := 1.0

## Seconds for multiplier to decay from start to floor
static var TIME_MULT_DECAY_SECONDS := 60.0

# =============================================================================
# PRECISION MULTIPLIER
# =============================================================================

## Multiplier for perfect solve (0 restores)
static var PRECISION_PERFECT := 1.5

## Multiplier for good solve (1-2 restores)
static var PRECISION_GOOD := 1.25

## Multiplier for base solve (3+ restores)
static var PRECISION_BASE := 1.0

## Threshold for "good" precision (restores <= this get PRECISION_GOOD)
static var PRECISION_GOOD_THRESHOLD := 2

# =============================================================================
# PUZZLE GENERATION
# =============================================================================

## Ratio of cells to mark for deletion in generated puzzles
static var CELLS_TO_DELETE_RATIO := 0.5

## Minimum value for generated cell numbers
static var CELL_VALUE_MIN := 1

## Maximum value for generated cell numbers
static var CELL_VALUE_MAX := 9

# =============================================================================
# FUTURE: ECONOMY
# =============================================================================

## Starting money for a run
static var STARTING_MONEY := 10

## Interest rate ($ per $5 held)
static var INTEREST_RATE := 1

## Max interest per round
static var INTEREST_CAP := 5

# =============================================================================
# FUTURE: LIVES
# =============================================================================

## Starting lives for a run
static var STARTING_LIVES := 3

## Max lives
static var MAX_LIVES := 5

# =============================================================================
# FUTURE: STREAK
# =============================================================================

## Multiplier bonus per consecutive win
static var STREAK_MULT_PER_WIN := 0.1

## Max streak multiplier bonus
static var STREAK_MULT_CAP := 1.0

# =============================================================================
# HELPERS
# =============================================================================

## Reset all values to defaults (useful for testing or new runs)
static func reset_to_defaults() -> void:
	BASE_POINTS = { 3: 100, 4: 200, 5: 350, 6: 500 }
	KEPT_BONUS_PER_CELL = 25
	LINE_MULT_PER_VALID = 0.2
	TIME_MULT_START = 2.0
	TIME_MULT_FLOOR = 1.0
	TIME_MULT_DECAY_SECONDS = 60.0
	PRECISION_PERFECT = 1.5
	PRECISION_GOOD = 1.25
	PRECISION_BASE = 1.0
	PRECISION_GOOD_THRESHOLD = 2
	CELLS_TO_DELETE_RATIO = 0.5
	CELL_VALUE_MIN = 1
	CELL_VALUE_MAX = 9
	STARTING_MONEY = 10
	INTEREST_RATE = 1
	INTEREST_CAP = 5
	STARTING_LIVES = 3
	MAX_LIVES = 5
	STREAK_MULT_PER_WIN = 0.1
	STREAK_MULT_CAP = 1.0
