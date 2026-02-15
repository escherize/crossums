class_name RunState
extends RefCounted
## Tracks progression through a single run.
## Serializable for save/load.

# =============================================================================
# SEED VERSIONING
# =============================================================================

## Bump this when puzzle generation algorithm changes to invalidate old seeds.
## Tests using seeded runs will need baselines regenerated.
const SEED_VERSION := 1

## FUTURE: Isolated RNG Streams
## -----------------------------
## Current approach: single run_seed → puzzle_seed via get_puzzle_seed()
## Limitation: adding new random-consuming features (shop, operators) would
## shift puzzle sequences for existing seeds.
##
## When needed, refactor to isolated RNG streams:
##   func get_puzzle_rng(stage, puzzle_index) -> RNG seeded by
##       hash(run_seed + "_puzzle_" + stage + "_" + puzzle_index)
##   func get_shop_rng(stage) -> RNG seeded by hash(run_seed + "_shop_" + stage)
##   func get_operator_rng() -> RNG seeded by hash(run_seed + "_operators")
##
## Each system gets its own deterministic stream. Adding features to one
## system doesn't affect others. See Balatro's approach: pre-generate
## entire deck order at run start.

# =============================================================================
# PROGRESSION
# =============================================================================

var stage: int = 1              # 1-8
var puzzle_index: int = 0       # 0-2 within stage
var run_seed: int = 0           # 0 = random, else deterministic

# =============================================================================
# RESOURCES
# =============================================================================

var lives: int = 5
var max_lives: int = 5
var money: int = 0
var total_score: int = 0
var stage_score: int = 0  # Accumulated score within current stage

# =============================================================================
# COMPUTED
# =============================================================================

var puzzles_completed: int:
	get: return (stage - 1) * 3 + puzzle_index

var is_final_stage: bool:
	get: return stage >= 8

# =============================================================================
# METHODS
# =============================================================================

func advance_puzzle() -> void:
	puzzle_index += 1
	if puzzle_index >= 3:
		puzzle_index = 0
		stage += 1


func lose_life() -> bool:
	lives -= 1
	EventBus.life_lost.emit(lives)
	return lives <= 0  # Returns true if game over


func add_money(amount: int) -> void:
	money += amount
	EventBus.money_changed.emit(money, amount)


func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		EventBus.money_changed.emit(money, -amount)
		return true
	return false


func add_score(amount: int) -> void:
	total_score += amount


func add_stage_score(amount: int) -> void:
	stage_score += amount


func reset_stage_score() -> void:
	stage_score = 0


func get_puzzle_seed() -> int:
	## Compute deterministic seed for current puzzle.
	## Returns 0 (random) if run_seed is 0.
	if run_seed == 0:
		return 0
	# Combine run_seed, version, stage, puzzle_index into unique seed
	# Using prime multipliers to reduce collisions
	return (run_seed * SEED_VERSION * 31337) + (stage * 997) + (puzzle_index * 13)


func get_shop_rng(reroll_count: int = 0) -> RandomNumberGenerator:
	## Get deterministic RNG for shop at current stage.
	## Returns null if run_seed is 0 (random mode).
	## reroll_count ensures different results on each reroll.
	if run_seed == 0:
		return null
	var rng = RandomNumberGenerator.new()
	# Isolated seed stream for shop - doesn't affect puzzles
	# Include reroll_count to get different results on reroll
	rng.seed = (run_seed * SEED_VERSION * 7919) + (stage * 1009) + (reroll_count * 17) + 999999
	return rng

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
	return {
		"stage": stage,
		"puzzle_index": puzzle_index,
		"lives": lives,
		"max_lives": max_lives,
		"money": money,
		"total_score": total_score,
		"stage_score": stage_score,
		"run_seed": run_seed,
	}


static func deserialize(data: Dictionary):
	var script = load("res://scripts/core/run_state.gd")
	var rs = script.new()
	rs.stage = data.get("stage", 1)
	rs.puzzle_index = data.get("puzzle_index", 0)
	rs.lives = data.get("lives", 5)
	rs.max_lives = data.get("max_lives", 5)
	rs.money = data.get("money", 0)
	rs.total_score = data.get("total_score", 0)
	rs.stage_score = data.get("stage_score", 0)
	rs.run_seed = data.get("run_seed", 0)
	return rs
