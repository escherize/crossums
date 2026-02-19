extends Node
## Manages run state machine and progression.
## Controls flow: puzzle → result → shop → next puzzle → victory/game over

# =============================================================================
# SIGNALS
# =============================================================================

signal state_changed(new_state: State)
signal puzzle_ready(stage_config)
signal show_result(won: bool, breakdown, target: int, reward: int)
signal show_result_rating(won: bool, breakdown)  # New pace rating signal
signal show_shop()
signal show_game_over(total_score: int, stages_cleared: int)
signal show_victory(total_score: int)

# =============================================================================
# STATE MACHINE
# =============================================================================

enum State {
	IDLE,           # No run active, at title screen
	PUZZLE_ACTIVE,  # Player solving a puzzle
	PUZZLE_RESULT,  # Showing result popup
	SHOP,           # Between-stage shop (Sprint 5, placeholder for now)
	GAME_OVER,      # Lost all lives
	VICTORY,        # Completed all stages
}

# =============================================================================
# CONSTANTS
# =============================================================================

const StageConfigScript = preload("res://scripts/core/stage_config.gd")
const ScoringEngineScript = preload("res://scripts/core/scoring_engine.gd")

# =============================================================================
# STATE
# =============================================================================

var current_state: State = State.IDLE
var _current_stage_config = null  # StageConfig instance
var _last_puzzle_score: int = 0

# =============================================================================
# RUN CONTROL
# =============================================================================

func start_run(run_seed: int = 0) -> void:
	## Begin a new run from stage 1, puzzle 1
	## run_seed: 0 = random puzzles, else deterministic sequence
	GameState.reset()
	GameState.start_new_run(run_seed)

	_start_next_puzzle()


func _start_next_puzzle() -> void:
	## Generate and start the next puzzle based on current run state
	if GameState.run == null:
		push_error("Cannot start puzzle: no active run")
		return

	_current_stage_config = StageConfigScript.get_config(
		GameState.run.stage,
		GameState.run.puzzle_index
	)

	var puzzle_config = _current_stage_config.to_puzzle_config()
	GameState.start_new_puzzle(puzzle_config)

	current_state = State.PUZZLE_ACTIVE
	state_changed.emit(current_state)
	puzzle_ready.emit(_current_stage_config)

	EventBus.stage_started.emit(GameState.run.stage)
	EventBus.puzzle_started.emit(GameState.run.puzzle_index + 1, false)


func on_puzzle_complete_rating(time_used: float) -> void:
	## Called when player completes a puzzle using new pace rating system.
	## time_used: seconds taken to solve the puzzle
	if _current_stage_config == null:
		push_error("No stage config for puzzle completion")
		return

	# Calculate rating breakdown
	var breakdown = ScoringEngineScript.calculate_rating(
		GameState.puzzle,
		time_used,
		GameState.operators,
		GameState.run.streak
	)

	# Update streak: only continues if solve was clean enough
	if breakdown.misstep_count < GameConfig.STREAK_MISSTEP_THRESHOLD:
		GameState.run.increment_streak()
	else:
		GameState.run.reset_streak()

	# Store grade for display
	GameState.run.last_grade = breakdown.grade

	# Calculate interest BEFORE adding reward
	var money_before: int = GameState.run.money
	var interest: int = _calculate_interest(money_before)

	# Add reward money
	var reward: int = breakdown.final_money
	GameState.run.add_money(reward)

	# Add interest (if any)
	if interest > 0:
		GameState.run.add_money(interest)
		GameState.run.interest_earned_this_stage += interest
		EventBus.interest_earned.emit(interest)

	# Track a "score" for display (rating × 100 for display purposes)
	var display_score: int = int(breakdown.total_rating * 100)
	_last_puzzle_score = display_score
	GameState.run.add_stage_score(display_score)
	GameState.run.add_score(display_score)

	EventBus.puzzle_completed.emit(true, display_score, reward + interest)

	# Remember if this was the boss puzzle before advancing
	var was_boss: bool = GameState.run.puzzle_index == 2
	GameState.run.advance_puzzle()

	# Check for victory (completed all stages)
	if GameState.run.stage > 8:
		_end_run(true)
		return

	# Boss puzzle: reset stage score for next stage
	if was_boss:
		GameState.run.reset_stage_score()

	# Show result
	current_state = State.PUZZLE_RESULT
	state_changed.emit(current_state)
	show_result_rating.emit(true, breakdown)


func on_puzzle_complete(breakdown_or_score) -> void:
	## DEPRECATED: Use on_puzzle_complete_rating() for new code.
	## Kept for backwards compatibility with tests.
	if _current_stage_config == null:
		push_error("No stage config for puzzle completion")
		return

	var breakdown = breakdown_or_score
	var score: int
	var money_bonus: int = 0
	if breakdown_or_score is int:
		score = breakdown_or_score
		breakdown = _create_mock_breakdown(score)
	else:
		score = breakdown.final_score
		money_bonus = breakdown.money_bonus if "money_bonus" in breakdown else 0

	_last_puzzle_score = score

	# Simple money calculation for legacy
	var reward: int = int(score / GameConfig.SCORE_TO_MONEY_DIVISOR) + money_bonus

	GameState.run.last_grade = breakdown.grade if "grade" in breakdown else "B"
	GameState.run.add_stage_score(score)
	GameState.run.add_score(score)

	var money_before: int = GameState.run.money
	var interest: int = _calculate_interest(money_before)
	GameState.run.add_money(reward)

	if interest > 0:
		GameState.run.add_money(interest)
		GameState.run.interest_earned_this_stage += interest
		EventBus.interest_earned.emit(interest)

	EventBus.puzzle_completed.emit(true, score, reward + interest)

	var was_boss: bool = GameState.run.puzzle_index == 2
	GameState.run.advance_puzzle()

	if GameState.run.stage > 8:
		_end_run(true)
		return

	if was_boss:
		GameState.run.reset_stage_score()

	current_state = State.PUZZLE_RESULT
	state_changed.emit(current_state)
	show_result.emit(true, breakdown, breakdown.par_score if "par_score" in breakdown else score, reward)


func continue_from_result() -> void:
	## Player clicked Continue on result popup
	if current_state != State.PUZZLE_RESULT:
		return

	# Check if shop time (after completing a stage = puzzle_index wrapped to 0)
	if GameState.run.puzzle_index == 0 and GameState.run.stage > 1:
		current_state = State.SHOP
		state_changed.emit(current_state)
		SaveManager.save_run()  # Auto-save at shop
		show_shop.emit()
	else:
		_start_next_puzzle()


func continue_from_shop() -> void:
	## Player finished with shop, continue to next puzzle
	if current_state != State.SHOP:
		return

	_start_next_puzzle()


func _end_run(won: bool) -> void:
	## End the run with victory or game over
	SaveManager.delete_save()  # Clear save on run end
	var total_score: int = GameState.run.total_score if GameState.run else 0
	var stages_cleared: int = GameState.run.stage - 1 if GameState.run else 0

	if won:
		current_state = State.VICTORY
		state_changed.emit(current_state)
		show_victory.emit(total_score)
		EventBus.run_ended.emit(true, total_score)
	else:
		current_state = State.GAME_OVER
		state_changed.emit(current_state)
		show_game_over.emit(total_score, stages_cleared)
		EventBus.run_ended.emit(false, total_score)


func return_to_title() -> void:
	## Reset state for returning to title screen
	current_state = State.IDLE
	state_changed.emit(current_state)
	_current_stage_config = null
	_last_puzzle_score = 0
	# Also reset GameState to ensure clean slate
	GameState.reset()

# =============================================================================
# ACCESSORS
# =============================================================================

func get_current_stage_config():
	return _current_stage_config


func is_run_active() -> bool:
	var inactive_states := [State.IDLE, State.GAME_OVER, State.VICTORY]
	return current_state not in inactive_states


# =============================================================================
# HELPERS
# =============================================================================

func _calculate_interest(money: int) -> int:
	## Calculate interest earned on money held.
	## Returns $1 per $5 held, capped at $5.
	if money < GameConfig.INTEREST_THRESHOLD:
		return 0
	var raw_interest := int(money / GameConfig.INTEREST_THRESHOLD) * GameConfig.INTEREST_RATE
	return mini(raw_interest, GameConfig.INTEREST_CAP)


func _create_mock_breakdown(score: int) -> ScoringEngineScript.ScoreBreakdown:
	## Create a mock ScoreBreakdown for testing purposes
	var b = ScoringEngineScript.ScoreBreakdown.new()
	b.final_score = score
	b.base_points = score
	b.subtotal = score
	b.operator_bonus = 0
	b.operator_mult = 1.0
	b.money_bonus = 0
	b.par_score = score
	b.grade = "B"
	b.grade_mult = 1.0
	b.grade_bonus = 1
	return b
