class_name GameConfig
extends RefCounted
## Central configuration for all tunable game parameters.
## Operators and consumables can modify these values to affect gameplay.

# =============================================================================
# VERSION (bumped by deploy.sh)
# =============================================================================

const VERSION := "0.2.36"

# =============================================================================
# SCORING - BASE POINTS
# =============================================================================

## Base points per cell (base = dimension × dimension × this)
static var BASE_POINTS_PER_CELL := 10

## Bonus points per kept cell (rewards optimization)
static var KEPT_BONUS_PER_CELL := 25

# =============================================================================
# TIME LIMIT (Timer-as-fail-condition)
# =============================================================================

## Base time limit for stage 1 (seconds)
static var TIME_LIMIT_BASE := 75.0

## Time reduction per stage (seconds)
static var TIME_LIMIT_STAGE_REDUCTION := 5.0

## Minimum time limit (floor)
static var TIME_LIMIT_FLOOR := 45.0

## Extra time for boss puzzles (puzzle index 2)
static var TIME_LIMIT_BOSS_BONUS := 15.0

## Calculate time limit for a given stage and puzzle
static func get_time_limit(stage: int, puzzle_index: int) -> float:
	var base := TIME_LIMIT_BASE
	var stage_reduction := (stage - 1) * TIME_LIMIT_STAGE_REDUCTION
	var boss_bonus := TIME_LIMIT_BOSS_BONUS if puzzle_index == 2 else 0.0
	return maxf(base - stage_reduction + boss_bonus, TIME_LIMIT_FLOOR)

# =============================================================================
# TIME MULTIPLIER (score bonus for speed)
# =============================================================================

## Starting time multiplier (max bonus for instant solve)
static var TIME_MULT_START := 2.0

## Floor time multiplier (no penalty, just no bonus)
static var TIME_MULT_FLOOR := 1.0

## Seconds for multiplier to decay from start to floor (now relative to time limit)
static var TIME_MULT_DECAY_SECONDS := 60.0

# =============================================================================
# ECONOMY
# =============================================================================

## Starting money for a run
static var STARTING_MONEY := 10

## Score to money conversion: money = floor(score / divisor)
## Lower = more money per puzzle. 400 means 500 points = $1.
static var SCORE_TO_MONEY_DIVISOR := 400

## Interest rate ($ per $5 held)
static var INTEREST_RATE := 1

## Max interest per round
static var INTEREST_CAP := 5

## Minimum money to earn interest
static var INTEREST_THRESHOLD := 5

# =============================================================================
# LETTER GRADES
# =============================================================================

## Grade thresholds as multiplier of "par score" for puzzle
static var GRADE_THRESHOLDS := {
	"D": 0.0,    # Any completion
	"C": 0.5,    # 50% of par
	"B": 0.75,   # 75% of par
	"A": 1.0,    # 100% of par (solve perfectly with good time)
	"S": 1.5,    # 150% of par
	"SS": 2.0    # 200% of par (requires speed + operators)
}

## Money multipliers per grade
static var GRADE_MONEY_MULT := {
	"D": 0.5,
	"C": 0.75,
	"B": 1.0,
	"A": 1.5,
	"S": 2.5,
	"SS": 4.0
}

## Flat bonus per grade
static var GRADE_MONEY_BONUS := {
	"D": 0,
	"C": 0,
	"B": 1,
	"A": 3,
	"S": 8,
	"SS": 15
}

# =============================================================================
# TIME POOL (shop purchase)
# =============================================================================

## Seconds added per time purchase
static var TIME_PURCHASE_AMOUNT := 15

## Get escalating price for time purchase
## Formula: $(N+1) for Nth purchase in the run
static func get_time_purchase_price(purchases_this_run: int) -> int:
	return purchases_this_run + 1

# =============================================================================
# HELPERS
# =============================================================================

## Reset all values to defaults (useful for testing or new runs)
static func reset_to_defaults() -> void:
	BASE_POINTS_PER_CELL = 10
	KEPT_BONUS_PER_CELL = 25
	TIME_LIMIT_BASE = 75.0
	TIME_LIMIT_STAGE_REDUCTION = 5.0
	TIME_LIMIT_FLOOR = 45.0
	TIME_LIMIT_BOSS_BONUS = 15.0
	TIME_MULT_START = 2.0
	TIME_MULT_FLOOR = 1.0
	TIME_MULT_DECAY_SECONDS = 60.0
	STARTING_MONEY = 10
	INTEREST_RATE = 1
	INTEREST_CAP = 5
	INTEREST_THRESHOLD = 5
	TIME_PURCHASE_AMOUNT = 15
	# Note: Dictionaries (GRADE_*) don't need resetting as they're constants


## Check if running in test mode (debug server active)
static func is_test_mode() -> bool:
	return OS.get_environment("CS_DEBUG_SERVER").to_lower() in ["1", "true", "yes"]
