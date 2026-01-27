extends Control
## Main game scene - puzzle solving with run progression.
## Controlled by RunManager for run flow.

# =============================================================================
# SCENE REFERENCES
# =============================================================================

const PuzzleGridScene = preload("res://scenes/puzzle/puzzle_grid.tscn")
const ScoringEngineScript = preload("res://scripts/core/scoring_engine.gd")
const RunHUDScene = preload("res://scenes/ui/run_hud.tscn")
const ResultPopupScene = preload("res://scenes/ui/result_popup.tscn")
const ShopPlaceholderScene = preload("res://scenes/ui/shop_placeholder.tscn")
const GameOverScene = preload("res://scenes/ui/game_over.tscn")
const VictoryScene = preload("res://scenes/ui/victory.tscn")

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var puzzle_container: CenterContainer = %PuzzleContainer
@onready var status_label: Label = %StatusLabel
@onready var undo_button: Button = %UndoButton
@onready var timer_label: Label = %TimerLabel
@onready var timer_bar: ProgressBar = %TimerBar
@onready var overlay_container: CanvasLayer = %OverlayContainer
@onready var hud_container: Control = %HUDContainer
@onready var title_label: Label = %Title

# Owned StyleBox for runtime color changes (avoid modifying shared resources)
var _timer_fill_style: StyleBoxFlat

var puzzle_grid: PuzzleGrid = null
var puzzle_solved: bool = false

# Overlay instances
var _run_hud: Control = null
var _current_overlay: Control = null

# =============================================================================
# TIME MULTIPLIER (values from GameConfig)
# =============================================================================

var puzzle_start_time: int = 0
var time_multiplier: float = GameConfig.TIME_MULT_START

# =============================================================================
# PRECISION TRACKING
# =============================================================================

var restore_count: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_setup_hud()
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


func _setup_hud() -> void:
	_run_hud = RunHUDScene.instantiate()
	hud_container.add_child(_run_hud)


func _connect_signals() -> void:
	undo_button.pressed.connect(_on_undo_pressed)

	# EventBus connections
	EventBus.cell_deleted.connect(_on_cell_deleted)
	EventBus.cell_restored.connect(_on_cell_restored)
	EventBus.mistake_made.connect(_on_mistake_made)

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
	var decay_progress := clampf(elapsed_sec / GameConfig.TIME_MULT_DECAY_SECONDS, 0.0, 1.0)
	time_multiplier = lerpf(GameConfig.TIME_MULT_START, GameConfig.TIME_MULT_FLOOR, decay_progress)


func _update_timer_display() -> void:
	# Calculate progress (1.0 = full bonus, 0.0 = no bonus)
	var mult_range := GameConfig.TIME_MULT_START - GameConfig.TIME_MULT_FLOOR
	var progress := (time_multiplier - GameConfig.TIME_MULT_FLOOR) / mult_range if mult_range > 0 else 0.0

	# Update bar value
	timer_bar.value = progress

	# Update bar fill color: cyan (full) → white (empty)
	var cyan := Color(0.4, 0.8, 0.9, 1.0)
	var fill_color := cyan.lerp(Color.WHITE, 1.0 - progress)
	_timer_fill_style.bg_color = fill_color

	# Update label
	timer_label.text = "%.1fx" % time_multiplier

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
	if _run_hud:
		_run_hud.refresh()

# =============================================================================
# RUNMANAGER SIGNAL HANDLERS
# =============================================================================

func _on_puzzle_ready(_stage_config) -> void:
	## RunManager has prepared a new puzzle
	_clear_overlay()
	await _load_puzzle_grid()
	if _run_hud:
		_run_hud.refresh()


func _on_show_result(won: bool, score: int, target: int, reward: int) -> void:
	## Show result popup after puzzle completion
	_clear_overlay()
	var popup = ResultPopupScene.instantiate()
	popup.continue_pressed.connect(_on_result_continue)
	overlay_container.add_child(popup)
	popup.show_result(won, score, target, reward)
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


func _on_cell_deleted(row: int, col: int, value: int) -> void:
	if puzzle_solved:
		return
	_update_status("Deleted %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()


func _on_cell_restored(row: int, col: int, value: int) -> void:
	if puzzle_solved:
		return
	restore_count += 1
	_update_status("Restored %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()


func _on_mistake_made(_row: int, _col: int) -> void:
	## Called when player deletes a solution cell (mistake)
	if puzzle_solved:
		return
	if GameState.run == null:
		return

	# Lose a life
	var game_over_flag: bool = GameState.run.lose_life()

	if game_over_flag:
		# Immediate game over - no more lives
		puzzle_solved = true  # Stop further input
		EventBus.game_over.emit()
		RunManager._end_run(false)
	else:
		# Still have lives - show feedback
		_update_status("Mistake! Lives: %d" % GameState.run.lives)


func _check_auto_win() -> void:
	if puzzle_solved:
		return
	if not GameState.puzzle:
		return

	var result = PuzzleLogic.validate(GameState.puzzle)
	if result.is_valid:
		_complete_puzzle()


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

	# Notify RunManager
	RunManager.on_puzzle_complete(breakdown.final_score)
