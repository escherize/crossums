class_name RunState
extends RefCounted
## Tracks progression through a single run.
## Serializable for save/load.

# =============================================================================
# PROGRESSION
# =============================================================================

var stage: int = 1              # 1-8
var puzzle_index: int = 0       # 0-2 within stage

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
	return rs
