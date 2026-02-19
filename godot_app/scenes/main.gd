extends Control
## Main game scene - puzzle solving with run progression.
## Controlled by RunManager for run flow.

# =============================================================================
# SCENE REFERENCES
# =============================================================================

const PuzzleGridScene = preload("res://scenes/puzzle/puzzle_grid.tscn")
const ScoringEngineScript = preload("res://scripts/core/scoring_engine.gd")
const ResultPopupScene = preload("res://scenes/ui/result_popup.tscn")
const ShopPlaceholderScene = preload("res://scenes/ui/shop_placeholder.tscn")
const GameOverScene = preload("res://scenes/ui/game_over.tscn")
const VictoryScene = preload("res://scenes/ui/victory.tscn")
const PauseOverlayScene = preload("res://scenes/ui/pause_overlay.tscn")

# =============================================================================
# STATE
# =============================================================================

var puzzle_grid: PuzzleGrid = null
var puzzle_solved: bool = false
var puzzle_start_time: int = 0
var time_multiplier: float = GameConfig.TIME_MULT_START
var _timer_fill_style: StyleBoxFlat
var _current_overlay: Control = null
var _time_at_puzzle_start: float = 0.0  # Pool value when puzzle started (for time mult calc)
var _executing_auto_action: bool = false  # Prevents recursive auto-action checks
var _is_paused: bool = false
var _pause_overlay: Control = null
var _pause_time_offset: int = 0  # Accumulated pause time to subtract from elapsed
var _pause_start_time: int = 0  # When current pause started

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var puzzle_container: CenterContainer = %PuzzleContainer
@onready var status_label: Label = %StatusLabel
@onready var undo_button: Button = %UndoButton
@onready var timer_label: Label = %TimerLabel
@onready var timer_bar: ProgressBar = %TimerBar
@onready var overlay_container: CanvasLayer = %OverlayContainer
@onready var title_label: Label = %Title
@onready var stage_label: Label = %StageLabel
@onready var puzzle_label: Label = %PuzzleLabel
@onready var money_label: Label = %MoneyLabel
@onready var score_label: Label = %ScoreLabel
@onready var target_label: Label = %TargetLabel
@onready var circle_mode_button: Button = %CircleModeButton
@onready var buy_time_button: Button = %BuyTimeButton
@onready var pause_button: Button = %PauseButton

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	puzzle_start_time = Time.get_ticks_msec()  # Prevent instant timeout before puzzle loads
	_setup_ui()
	_connect_signals()
	title_label.text = "CROSSSUMS v%s" % GameConfig.VERSION

	# Start first puzzle if run is active (coming from title screen)
	if RunManager.is_run_active() or GameState.run != null:
		# RunManager.start_run() was already called, just need to trigger puzzle
		await get_tree().process_frame
		RunManager._start_next_puzzle()


func _setup_ui() -> void:
	# Create owned StyleBox for timer bar (best practice: don't modify shared resources)
	_timer_fill_style = StyleBoxFlat.new()
	_timer_fill_style.bg_color = Color(0.4, 0.8, 0.9, 1.0)  # Cyan
	_timer_fill_style.corner_radius_top_left = 4
	_timer_fill_style.corner_radius_top_right = 4
	_timer_fill_style.corner_radius_bottom_left = 4
	_timer_fill_style.corner_radius_bottom_right = 4
	timer_bar.add_theme_stylebox_override("fill", _timer_fill_style)


func _connect_signals() -> void:
	undo_button.pressed.connect(_on_undo_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	# Note: buy_time_button is now just a status display, not clickable

	# Circle mode button (touchscreen only - hidden on desktop)
	if circle_mode_button.visible:
		circle_mode_button.circle_mode_changed.connect(_on_circle_mode_changed)

	# Auto-pause when app loses focus
	get_tree().root.focus_exited.connect(_on_focus_lost)

	# EventBus connections
	EventBus.cell_deleted.connect(_on_cell_deleted)
	EventBus.cell_restored.connect(_on_cell_restored)
	EventBus.cell_circled.connect(_on_cell_circled)
	EventBus.cell_uncircled.connect(_on_cell_uncircled)
	EventBus.state_changed.connect(_refresh_hud)
	EventBus.money_changed.connect(func(_a, _b): _refresh_hud())

	# RunManager connections
	RunManager.puzzle_ready.connect(_on_puzzle_ready)
	RunManager.show_result.connect(_on_show_result)
	RunManager.show_result_rating.connect(_on_show_result_rating)
	RunManager.show_shop.connect(_on_show_shop)
	RunManager.show_game_over.connect(_on_show_game_over)
	RunManager.show_victory.connect(_on_show_victory)


func _process(_delta: float) -> void:
	if GameState.puzzle and not puzzle_solved and not _is_paused:
		_update_time_multiplier()
		_update_timer_display()


func _update_time_multiplier() -> void:
	if GameState.run == null:
		return
	# Don't count down until puzzle is actually loaded
	if GameState.puzzle == null or _time_at_puzzle_start <= 0.0:
		return

	var elapsed_sec := (Time.get_ticks_msec() - puzzle_start_time - _pause_time_offset) / 1000.0

	# Decrease time pool by elapsed time (but not below 0)
	GameState.run.time_pool = maxf(_time_at_puzzle_start - elapsed_sec, 0.0)

	# Check for timeout (but not if puzzle already solved - prevents race condition)
	if GameState.run.time_pool <= 0.0 and not puzzle_solved:
		_on_time_expired()
		return

	# Calculate time multiplier based on solve speed relative to puzzle's base time
	# Faster solve = higher multiplier (2.0x at start, 1.0x after decay seconds)
	var time_progress := clampf(elapsed_sec / GameConfig.TIME_MULT_DECAY_SECONDS, 0.0, 1.0)
	time_multiplier = lerpf(GameConfig.TIME_MULT_START, GameConfig.TIME_MULT_FLOOR, time_progress)


func _update_timer_display() -> void:
	# In test mode, freeze timer display for deterministic visual tests
	if GameConfig.is_test_mode():
		timer_bar.value = 1.0
		_timer_fill_style.bg_color = Color(0.4, 0.8, 0.9, 1.0)  # Cyan
		timer_label.text = "1:15"
		return

	if GameState.run == null:
		return

	var time_remaining := maxf(GameState.run.time_pool, 0.0)

	# Progress bar shows pool relative to a reasonable "full" amount (2 min = healthy)
	var max_display := 120.0  # 2 minutes = "full" bar
	var progress := clampf(time_remaining / max_display, 0.0, 1.0)

	# Update bar value
	timer_bar.value = progress

	# Update bar fill color: cyan (lots of time) → red (low time)
	var cyan := Color(0.4, 0.8, 0.9, 1.0)
	var red := Color(0.9, 0.3, 0.3, 1.0)
	var fill_color: Color
	if progress > 0.3:
		# Cyan → White transition (100% → 30%)
		var t := (progress - 0.3) / 0.7
		fill_color = cyan.lerp(Color.WHITE, 1.0 - t)
	else:
		# White → Red transition (30% → 0%)
		var t := progress / 0.3
		fill_color = red.lerp(Color.WHITE, t)
	_timer_fill_style.bg_color = fill_color

	# Update label to show remaining time from pool
	var secs := int(time_remaining)
	timer_label.text = "%d:%02d" % [secs / 60, secs % 60]


func _refresh_hud() -> void:
	if GameState.run == null:
		return
	var run = GameState.run
	stage_label.text = "Stage %d" % run.stage
	puzzle_label.text = "Puzzle %d/3" % (run.puzzle_index + 1)
	money_label.text = "$%d" % run.money
	score_label.text = "Score: %d" % run.total_score
	var config = RunManager.get_current_stage_config()
	# Show stage accumulated score vs target
	if config:
		target_label.text = "Stage: %d/%d" % [run.stage_score, config.score_target]
	else:
		target_label.text = "Stage: ---"

	# Hide buy time button (only available in shop)
	buy_time_button.visible = false

	# Enable pause button during puzzle play
	pause_button.disabled = _is_paused or puzzle_solved

# =============================================================================
# PUZZLE MANAGEMENT
# =============================================================================

func _load_puzzle_grid() -> void:
	## Load the puzzle grid from GameState.puzzle
	if GameState.puzzle == null:
		return

	# Create or update grid
	if puzzle_grid:
		puzzle_grid.queue_free()

	puzzle_grid = PuzzleGridScene.instantiate()
	puzzle_container.add_child(puzzle_grid)

	# Wait a frame for the grid to initialize, then load puzzle
	await get_tree().process_frame
	await puzzle_grid.load_puzzle(GameState.puzzle)

	# Add this puzzle's time allocation to the shared pool (capped)
	var stage := 1
	var puzzle_index := 0
	if GameState.run:
		stage = GameState.run.stage
		puzzle_index = GameState.run.puzzle_index
		var puzzle_time := GameConfig.get_time_limit(stage, puzzle_index)
		GameState.run.time_pool = minf(
			GameState.run.time_pool + puzzle_time,
			GameConfig.TIME_POOL_CAP
		)

	# Track state for time multiplier calculation
	puzzle_start_time = Time.get_ticks_msec()
	_time_at_puzzle_start = GameState.run.time_pool if GameState.run else 75.0
	time_multiplier = GameConfig.TIME_MULT_START
	puzzle_solved = false
	_pause_time_offset = 0  # Reset pause tracking for new puzzle
	_update_timer_display()

	_update_status("Delete cells to match row/column targets.")


func _update_status(text: String) -> void:
	status_label.text = text


func _pulse_undo_button() -> void:
	## Visual feedback when auto-action happens - draws attention to undo
	if not undo_button:
		return
	var tween = create_tween()
	tween.tween_property(undo_button, "modulate", Color(1.5, 1.5, 0.5), 0.15)
	tween.tween_property(undo_button, "modulate", Color.WHITE, 0.3)


func refresh_from_state() -> void:
	## Refresh UI after GameState has been modified externally (e.g., deserialization)
	if GameState.puzzle == null:
		return

	await _load_puzzle_grid()
	_update_status("State restored.")
	_refresh_hud()

# =============================================================================
# RUNMANAGER SIGNAL HANDLERS
# =============================================================================

func _on_puzzle_ready(_stage_config) -> void:
	## RunManager has prepared a new puzzle
	_clear_overlay()
	await _load_puzzle_grid()
	_refresh_hud()


func _on_show_result(won: bool, breakdown, target: int, reward: int) -> void:
	## Show result popup after puzzle completion (legacy)
	_clear_overlay()
	var popup = ResultPopupScene.instantiate()
	popup.continue_pressed.connect(_on_result_continue)
	overlay_container.add_child(popup)
	popup.show_result(won, breakdown, target, reward)
	_current_overlay = popup


func _on_show_result_rating(won: bool, breakdown) -> void:
	## Show result popup with pace rating breakdown
	_clear_overlay()
	var popup = ResultPopupScene.instantiate()
	popup.continue_pressed.connect(_on_result_continue)
	overlay_container.add_child(popup)
	popup.show_result_rating(won, breakdown)
	_current_overlay = popup


func _on_show_shop() -> void:
	## Show shop placeholder between stages
	_clear_overlay()
	var shop = ShopPlaceholderScene.instantiate()
	shop.continue_pressed.connect(_on_shop_continue)
	overlay_container.add_child(shop)
	_current_overlay = shop


func _on_show_game_over(total_score: int, stages_cleared: int) -> void:
	## Show game over screen
	_clear_overlay()
	var game_over = GameOverScene.instantiate()
	overlay_container.add_child(game_over)
	game_over.show_game_over(total_score, stages_cleared)
	_current_overlay = game_over


func _on_show_victory(total_score: int) -> void:
	## Show victory screen
	_clear_overlay()
	var victory = VictoryScene.instantiate()
	overlay_container.add_child(victory)
	victory.show_victory(total_score)
	_current_overlay = victory


func _clear_overlay() -> void:
	if _current_overlay:
		_current_overlay.queue_free()
		_current_overlay = null

# =============================================================================
# OVERLAY BUTTON HANDLERS
# =============================================================================

func _on_result_continue() -> void:
	RunManager.continue_from_result()


func _on_shop_continue() -> void:
	RunManager.continue_from_shop()

# =============================================================================
# PUZZLE INTERACTION HANDLERS
# =============================================================================

func _on_undo_pressed() -> void:
	if puzzle_solved:
		return
	if not GameState.puzzle:
		return

	var result = GameState.puzzle.undo_last_action()
	if not result.is_empty() and not result.cells.is_empty():
		puzzle_grid.refresh()
		var count = result.cells.size()
		if count == 1:
			var pos = result.cells[0]
			_update_status("Undid %s at (%d, %d)" % [result.type, pos.x + 1, pos.y + 1])
		else:
			_update_status("Undid %d %ss" % [count, result.type])


func _on_circle_mode_changed(active: bool) -> void:
	## Called when circle mode button is pressed/released
	if puzzle_grid:
		puzzle_grid.set_circle_mode(active)


func _on_cell_deleted(row: int, col: int, value: int) -> void:
	if puzzle_solved:
		return
	_update_status("Deleted %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()
	_check_operator_auto_actions()


func _on_cell_restored(row: int, col: int, value: int) -> void:
	if puzzle_solved:
		return
	_update_status("Restored %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()
	_check_operator_auto_actions()


func _on_cell_circled(_row: int, _col: int) -> void:
	if puzzle_solved:
		return
	_check_auto_win()
	_check_operator_auto_actions()


func _on_cell_uncircled(_row: int, _col: int) -> void:
	if puzzle_solved:
		return
	_check_auto_win()
	_check_operator_auto_actions()


func _on_time_expired() -> void:
	## Called when time pool runs out - game over
	if puzzle_solved:
		return
	if GameState.run == null:
		return

	# Time pool depleted - game over
	puzzle_solved = true  # Stop further input
	_update_status("Time's up!")
	SoundManager.play("time_up")
	EventBus.puzzle_timeout.emit()
	EventBus.game_over.emit()
	RunManager._end_run(false)


func _check_auto_win() -> void:
	if puzzle_solved:
		return
	if not GameState.puzzle:
		return

	# Win condition 1: All sums match (via deletion)
	var result = PuzzleLogic.validate(GameState.puzzle)
	if result.is_valid:
		_complete_puzzle()
		return

	# Win condition 2: Circled cells alone match targets
	if GameState.puzzle.is_solved_by_circles():
		_complete_puzzle()


func _check_operator_auto_actions() -> void:
	## Check operators for auto-actions (e.g., Gimme auto-click, Click Clique, Garbage Collector)
	if puzzle_solved or not GameState.puzzle or not puzzle_grid:
		return
	if GameState.operators.is_empty():
		return
	if _executing_auto_action:
		return  # Prevent recursive calls during auto-action execution

	for op in GameState.operators:
		var action = op.get_auto_action(GameState.puzzle)
		if not action.is_empty():
			_execute_auto_action(action)
			return  # Only one auto-action per check


func _execute_auto_action(action: Dictionary) -> void:
	## Execute an operator auto-action immediately.
	## All cells in the action are batched into one undo-able action.
	_executing_auto_action = true

	var operator_id: String = action.get("operator_id", "")

	# Emit trigger signal for visual feedback (operator card pulse)
	if operator_id:
		EventBus.operator_triggered.emit(operator_id, 0)

	# Single cell auto-delete (Gimme)
	if action.has("auto_delete"):
		var pos: Vector2i = action.auto_delete
		GameState.puzzle.begin_action_batch("delete", true, operator_id)
		puzzle_grid.simulate_click(pos.y, pos.x)
		GameState.puzzle.end_action_batch()
		_pulse_undo_button()

	# Batch auto-circle (Click Clique)
	elif action.has("auto_circle_cells"):
		GameState.puzzle.begin_action_batch("circle", true, operator_id)
		for pos in action.auto_circle_cells:
			if not puzzle_solved:
				puzzle_grid.simulate_circle(pos.y, pos.x)
		GameState.puzzle.end_action_batch()
		_pulse_undo_button()

	# Batch auto-delete (Garbage Collector)
	elif action.has("auto_delete_cells"):
		GameState.puzzle.begin_action_batch("delete", true, operator_id)
		for pos in action.auto_delete_cells:
			if not puzzle_solved:
				puzzle_grid.simulate_click(pos.y, pos.x)
		GameState.puzzle.end_action_batch()
		_pulse_undo_button()

	_executing_auto_action = false


func _complete_puzzle() -> void:
	## Called when puzzle is solved (auto-win or submit)
	puzzle_solved = true

	# Calculate time used for pace rating (excluding pause time)
	var time_used: float = (Time.get_ticks_msec() - puzzle_start_time - _pause_time_offset) / 1000.0

	# Update status with pace info
	var cell_count: int = GameState.puzzle.grid_size.x * GameState.puzzle.grid_size.y
	var pace: float = time_used / cell_count
	_update_status("Solved in %.1fs (%.1fs/cell)" % [time_used, pace])

	# Notify RunManager with time used (calculates rating internally)
	RunManager.on_puzzle_complete_rating(time_used)

# =============================================================================
# PAUSE
# =============================================================================

func _on_pause_pressed() -> void:
	if puzzle_solved or _current_overlay != null:
		return
	_pause_game()


func _on_focus_lost() -> void:
	## Auto-pause when app loses focus (mobile background, window unfocused)
	if puzzle_solved or _is_paused or _current_overlay != null:
		return
	_pause_game()


func _pause_game() -> void:
	if _is_paused:
		return
	_is_paused = true
	_pause_start_time = Time.get_ticks_msec()

	# Hide the puzzle grid to prevent "pause to think" exploit
	if puzzle_grid:
		puzzle_grid.visible = false

	# Show pause overlay
	_pause_overlay = PauseOverlayScene.instantiate()
	var resume_btn = _pause_overlay.get_node("%ResumeButton")
	if resume_btn:
		resume_btn.pressed.connect(_resume_game)
	overlay_container.add_child(_pause_overlay)

	# Disable pause button while paused
	pause_button.disabled = true


func _resume_game() -> void:
	if not _is_paused:
		return

	# Accumulate pause duration
	_pause_time_offset += Time.get_ticks_msec() - _pause_start_time

	_is_paused = false

	# Show the puzzle grid again
	if puzzle_grid:
		puzzle_grid.visible = true

	# Remove pause overlay
	if _pause_overlay:
		_pause_overlay.queue_free()
		_pause_overlay = null

	# Re-enable pause button
	pause_button.disabled = false
