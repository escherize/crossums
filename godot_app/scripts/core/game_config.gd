class_name GameConfig
extends RefCounted
## Central configuration for all tunable game parameters.
## Operators and consumables can modify these values to affect gameplay.

# =============================================================================
# VERSION (bumped by deploy.sh)
# =============================================================================

const VERSION := "0.2.57"

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
## Lower = more money per puzzle. 250 means 500 points = $2.
static var SCORE_TO_MONEY_DIVISOR := 250

## Interest rate ($ per $5 held)
static var INTEREST_RATE := 1

## Max interest per round
static var INTEREST_CAP := 5

## Minimum money to earn interest
static var INTEREST_THRESHOLD := 5

# =============================================================================
# PACE RATING SYSTEM
# =============================================================================
# Formula: rating = (RATING_BASE - pace) + clean_bonus + operator_bonus
# Money = round(rating³ / 1000) × streak_mult

## Divisor for money calculation (higher = less money)
static var MONEY_DIVISOR := 500.0

## Base value for pace calculation (rating = this - seconds_per_cell)
static var RATING_BASE := 12.0

## Rating penalty per misstep (restore/uncircle)
static var MISSTEP_PENALTY := 0.5

## Maximum clean solve bonus (0 missteps)
static var MAX_CLEAN_BONUS := 2.0

## Divisor to convert operator score bonuses to rating points
## +50 operator bonus = +1.0 rating
static var OPERATOR_RATING_DIVISOR := 50.0

## Streak multipliers by consecutive solve count [0, 1, 2, 3, 4+]
static var STREAK_MULTIPLIERS: Array[float] = [1.0, 1.0, 1.5, 2.0, 3.0]

## Maximum missteps allowed to continue streak (4+ missteps = streak breaks)
static var STREAK_MISSTEP_THRESHOLD := 4

## Get streak multiplier for given streak count
static func get_streak_multiplier(streak: int) -> float:
	var index = mini(streak, STREAK_MULTIPLIERS.size() - 1)
	return STREAK_MULTIPLIERS[index]

## Calculate clean bonus based on missteps
static func get_clean_bonus(missteps: int) -> float:
	return maxf(0.0, MAX_CLEAN_BONUS - missteps * MISSTEP_PENALTY)

# =============================================================================
# LETTER GRADES (for display, derived from rating)
# =============================================================================

## Rating thresholds for letter grades
static var RATING_GRADE_THRESHOLDS := {
	"SS": 14.0,   # Exceptional (very fast + operators)
	"S": 12.0,    # Excellent (fast solve)
	"A": 10.0,    # Great (good pace)
	"B": 8.0,     # Good (average pace)
	"C": 6.0,     # Okay (slow pace)
	"D": 0.0      # Complete (any finish)
}

## Get letter grade from rating
static func get_grade_from_rating(rating: float) -> String:
	if rating >= RATING_GRADE_THRESHOLDS["SS"]:
		return "SS"
	if rating >= RATING_GRADE_THRESHOLDS["S"]:
		return "S"
	if rating >= RATING_GRADE_THRESHOLDS["A"]:
		return "A"
	if rating >= RATING_GRADE_THRESHOLDS["B"]:
		return "B"
	if rating >= RATING_GRADE_THRESHOLDS["C"]:
		return "C"
	return "D"

# =============================================================================
# TIME POOL (shop purchase)
# =============================================================================

## Maximum time pool (prevents infinite accumulation)
static var TIME_POOL_CAP := 180.0  # 3 minutes max

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
	TIME_POOL_CAP = 180.0
	TIME_PURCHASE_AMOUNT = 15
	# Pace rating
	RATING_BASE = 12.0
	MISSTEP_PENALTY = 0.5
	MAX_CLEAN_BONUS = 2.0
	OPERATOR_RATING_DIVISOR = 50.0


## Check if running in test mode (debug server active)
static func is_test_mode() -> bool:
	return OS.get_environment("CS_DEBUG_SERVER").to_lower() in ["1", "true", "yes"]
