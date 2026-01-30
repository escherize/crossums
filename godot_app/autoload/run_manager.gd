extends Node
## Manages run state machine and progression.
## Controls flow: puzzle → result → shop → next puzzle → victory/game over

# =============================================================================
# SIGNALS
# =============================================================================

signal state_changed(new_state: State)
signal puzzle_ready(stage_config)
signal show_result(won: bool, score: int, target: int, reward: int)
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


func on_puzzle_complete(score: int) -> void:
	## Called when player completes a puzzle.
	## Scores accumulate across stage; gate check only on boss puzzle (index 2).
	if _current_stage_config == null:
		push_error("No stage config for puzzle completion")
		return

	_last_puzzle_score = score
	var reward: int = _current_stage_config.money_reward

	# Always add score (no per-puzzle gate)
	GameState.run.add_stage_score(score)
	GameState.run.add_score(score)
	GameState.run.add_money(reward)
	EventBus.puzzle_completed.emit(true, score, reward)

	# Remember if this was the boss puzzle before advancing
	var was_boss: bool = GameState.run.puzzle_index == 2
	GameState.run.advance_puzzle()

	# Check for victory (completed all stages)
	if GameState.run.stage > 8:
		_end_run(true)
		return

	# Boss puzzle (index was 2): check stage gate
	if was_boss:
		var stage_target: int = _current_stage_config.score_target
		if GameState.run.stage_score < stage_target:
			# Failed stage gate = game over
			EventBus.game_over.emit()
			_end_run(false)
			return
		# Passed! Reset stage score for next stage
		GameState.run.reset_stage_score()

	# Show result
	current_state = State.PUZZLE_RESULT
	state_changed.emit(current_state)
	show_result.emit(true, score, _current_stage_config.score_target, reward)


func continue_from_result() -> void:
	## Player clicked Continue on result popup
	if current_state != State.PUZZLE_RESULT:
		return

	# Check if shop time (after completing a stage = puzzle_index wrapped to 0)
	if GameState.run.puzzle_index == 0 and GameState.run.stage > 1:
		current_state = State.SHOP
		state_changed.emit(current_state)
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
	return current_state != State.IDLE and current_state != State.GAME_OVER and current_state != State.VICTORY
