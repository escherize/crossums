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

# =============================================================================
# STATE
# =============================================================================

var puzzle_grid: PuzzleGrid = null
var puzzle_solved: bool = false
var puzzle_start_time: int = 0
var current_time_limit: float = 75.0  # Set per puzzle based on stage
var time_multiplier: float = GameConfig.TIME_MULT_START
var restore_count: int = 0
var _timer_fill_style: StyleBoxFlat
var _current_overlay: Control = null

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

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
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

	# Circle mode button (touchscreen only - hidden on desktop)
	if circle_mode_button.visible:
		circle_mode_button.circle_mode_changed.connect(_on_circle_mode_changed)

	# EventBus connections
	EventBus.cell_deleted.connect(_on_cell_deleted)
	EventBus.cell_restored.connect(_on_cell_restored)
	EventBus.cell_circled.connect(func(_r, _c): _check_auto_win())
	EventBus.mistake_made.connect(_on_mistake_made)
	EventBus.state_changed.connect(_refresh_hud)
	EventBus.money_changed.connect(func(_a, _b): _refresh_hud())

	# RunManager connections
	RunManager.puzzle_ready.connect(_on_puzzle_ready)
	RunManager.show_result.connect(_on_show_result)
	RunManager.show_shop.connect(_on_show_shop)
	RunManager.show_game_over.connect(_on_show_game_over)
	RunManager.show_victory.connect(_on_show_victory)


func _process(_delta: float) -> void:
	if GameState.puzzle and not puzzle_solved:
		_update_time_multiplier()
		_update_timer_display()


func _update_time_multiplier() -> void:
	var elapsed_sec := (Time.get_ticks_msec() - puzzle_start_time) / 1000.0
	var time_remaining := current_time_limit - elapsed_sec

	# Check for timeout (but not if puzzle already solved - prevents race condition)
	if time_remaining <= 0 and not puzzle_solved:
		_on_time_expired()
		return

	# Calculate time multiplier based on how much time is left relative to limit
	# Faster solve = higher multiplier (2.0x at start, 1.0x when time runs out)
	var time_progress := clampf(elapsed_sec / current_time_limit, 0.0, 1.0)
	time_multiplier = lerpf(GameConfig.TIME_MULT_START, GameConfig.TIME_MULT_FLOOR, time_progress)


func _update_timer_display() -> void:
	# In test mode, freeze timer display for deterministic visual tests
	var is_test_mode := OS.get_environment("CS_DEBUG_SERVER").to_lower() in ["1", "true", "yes"]
	if is_test_mode:
		timer_bar.value = 1.0
		_timer_fill_style.bg_color = Color(0.4, 0.8, 0.9, 1.0)  # Cyan
		timer_label.text = "1:15"
		return

	var elapsed_sec := (Time.get_ticks_msec() - puzzle_start_time) / 1000.0
	var time_remaining := maxf(current_time_limit - elapsed_sec, 0.0)

	# Calculate progress (1.0 = full time, 0.0 = no time)
	var progress := time_remaining / current_time_limit if current_time_limit > 0 else 0.0

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

	# Update label to show remaining time
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

	# Calculate time limit based on stage and puzzle index
	var stage := 1
	var puzzle_index := 0
	if GameState.run:
		stage = GameState.run.stage
		puzzle_index = GameState.run.puzzle_index
	current_time_limit = GameConfig.get_time_limit(stage, puzzle_index)

	# Reset timer and precision tracking
	puzzle_start_time = Time.get_ticks_msec()
	time_multiplier = GameConfig.TIME_MULT_START
	restore_count = 0
	puzzle_solved = false
	_update_timer_display()

	_update_status("Delete cells to match row/column targets.")


func _update_status(text: String) -> void:
	status_label.text = text


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
	## Show result popup after puzzle completion
	_clear_overlay()
	var popup = ResultPopupScene.instantiate()
	popup.continue_pressed.connect(_on_result_continue)
	overlay_container.add_child(popup)
	popup.show_result(won, breakdown, target, reward)
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

	var pos = GameState.puzzle.undo_last_deletion()
	if pos.x >= 0:
		puzzle_grid.refresh()
		_update_status("Undid deletion at (%d, %d)" % [pos.x + 1, pos.y + 1])


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
	restore_count += 1
	_update_status("Restored %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()
	_check_operator_auto_actions()


func _on_mistake_made(_row: int, _col: int) -> void:
	## Legacy handler - mistakes no longer cause life loss
	## Kept for potential future use (e.g., time penalties)
	pass


func _on_time_expired() -> void:
	## Called when puzzle timer runs out - instant game over
	if puzzle_solved:
		return
	if GameState.run == null:
		return

	puzzle_solved = true  # Stop further input
	_update_status("Time's up!")
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
	## Check operators for auto-actions (e.g., Gimme auto-click)
	if puzzle_solved:
		return
	if not GameState.puzzle or not puzzle_grid:
		return
	if GameState.operators.is_empty():
		return

	for op in GameState.operators:
		var action = op.get_auto_action(GameState.puzzle)
		if action.has("auto_delete"):
			var pos: Vector2i = action.auto_delete
			# Delay slightly so animations don't overlap
			await get_tree().create_timer(0.15).timeout
			if puzzle_solved:
				return
			puzzle_grid.simulate_click(pos.y, pos.x)  # row, col
			return  # Only one auto-action per frame


func _complete_puzzle() -> void:
	## Called when puzzle is solved (auto-win or submit)
	puzzle_solved = true
	var breakdown = ScoringEngineScript.calculate_score(
		GameState.puzzle,
		time_multiplier,
		restore_count,
		GameState.operators
	)
	_update_status("Score: %d  |  %s" % [breakdown.final_score, breakdown.get_summary()])

	# Notify RunManager with full breakdown
	RunManager.on_puzzle_complete(breakdown)
