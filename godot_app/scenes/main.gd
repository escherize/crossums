extends Control
## Main scene - Entry point for Crosssums.
## Currently set up as a test scene for the puzzle grid.

# =============================================================================
# SCENE REFERENCES
# =============================================================================

const PuzzleGridScene = preload("res://scenes/puzzle/puzzle_grid.tscn")
const ScoringEngineScript = preload("res://scripts/core/scoring_engine.gd")

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var puzzle_container: CenterContainer = %PuzzleContainer
@onready var status_label: Label = %StatusLabel
@onready var submit_button: Button = %SubmitButton
@onready var new_puzzle_button: Button = %NewPuzzleButton
@onready var undo_button: Button = %UndoButton
@onready var grid_size_option: OptionButton = %GridSizeOption
@onready var timer_label: Label = %TimerLabel
@onready var timer_bar: ProgressBar = %TimerBar

# Owned StyleBox for runtime color changes (avoid modifying shared resources)
var _timer_fill_style: StyleBoxFlat

var puzzle_grid: PuzzleGrid = null
var current_puzzle: PuzzleState = null
var puzzle_solved: bool = false

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
	_generate_new_puzzle(3)


func _setup_ui() -> void:
	# Grid size options
	grid_size_option.add_item("3x3", 3)
	grid_size_option.add_item("4x4", 4)
	grid_size_option.add_item("5x5", 5)
	grid_size_option.add_item("6x6", 6)
	grid_size_option.select(0)

	# Create owned StyleBox for timer bar (best practice: don't modify shared resources)
	_timer_fill_style = StyleBoxFlat.new()
	_timer_fill_style.bg_color = Color(0.4, 0.8, 0.9, 1.0)  # Cyan
	_timer_fill_style.corner_radius_top_left = 4
	_timer_fill_style.corner_radius_top_right = 4
	_timer_fill_style.corner_radius_bottom_left = 4
	_timer_fill_style.corner_radius_bottom_right = 4
	timer_bar.add_theme_stylebox_override("fill", _timer_fill_style)


func _connect_signals() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	new_puzzle_button.pressed.connect(_on_new_puzzle_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	grid_size_option.item_selected.connect(_on_grid_size_changed)

	# EventBus connections
	EventBus.cell_deleted.connect(_on_cell_deleted)
	EventBus.cell_restored.connect(_on_cell_restored)


func _process(_delta: float) -> void:
	if current_puzzle and not puzzle_solved:
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

func _generate_new_puzzle(grid_size: int) -> void:
	# Create puzzle config
	var config = PuzzleLogic.PuzzleConfig.new()
	config.grid_size = Vector2i(grid_size, grid_size)
	config.cells_to_delete_ratio = 0.5  # Delete about half the cells

	# Generate puzzle
	current_puzzle = PuzzleLogic.generate_puzzle(config)

	# Create or update grid
	if puzzle_grid:
		puzzle_grid.queue_free()

	puzzle_grid = PuzzleGridScene.instantiate()
	puzzle_container.add_child(puzzle_grid)

	# Wait a frame for the grid to initialize, then load puzzle
	await get_tree().process_frame
	puzzle_grid.load_puzzle(current_puzzle)

	# Reset timer and precision tracking
	puzzle_start_time = Time.get_ticks_msec()
	time_multiplier = GameConfig.TIME_MULT_START
	restore_count = 0
	puzzle_solved = false
	_update_timer_display()

	_update_status("Click numbers to delete them. Make all rows and columns sum to targets.")


func _update_status(text: String) -> void:
	status_label.text = text

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_submit_pressed() -> void:
	if not current_puzzle:
		return

	var result = PuzzleLogic.validate(current_puzzle)

	if result.is_valid:
		puzzle_solved = true
		var breakdown = ScoringEngineScript.calculate_score(current_puzzle, time_multiplier, restore_count)
		_update_status("🎉 SCORE: %d  |  %s" % [breakdown.final_score, breakdown.get_summary()])
	else:
		# Show which rows/columns are wrong
		var wrong_rows: Array[int] = []
		var wrong_cols: Array[int] = []

		for r in result.row_results:
			if not r.valid:
				wrong_rows.append(r.index + 1)

		for c in result.col_results:
			if not c.valid:
				wrong_cols.append(c.index + 1)

		var msg = "INCORRECT! "
		if wrong_rows.size() > 0:
			msg += "Rows %s wrong. " % str(wrong_rows)
		if wrong_cols.size() > 0:
			msg += "Cols %s wrong." % str(wrong_cols)

		_update_status(msg)


func _on_new_puzzle_pressed() -> void:
	var selected_size = grid_size_option.get_selected_id()
	_generate_new_puzzle(selected_size)


func _on_undo_pressed() -> void:
	if not current_puzzle:
		return

	var pos = current_puzzle.undo_last_deletion()
	if pos.x >= 0:
		puzzle_grid.refresh()
		_update_status("Undid deletion at (%d, %d)" % [pos.x + 1, pos.y + 1])


func _on_grid_size_changed(index: int) -> void:
	var selected_size = grid_size_option.get_item_id(index)
	_generate_new_puzzle(selected_size)


func _on_cell_deleted(row: int, col: int, value: int) -> void:
	_update_status("Deleted %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()


func _on_cell_restored(row: int, col: int, value: int) -> void:
	restore_count += 1
	_update_status("Restored %d at row %d, col %d" % [value, row + 1, col + 1])
	_check_auto_win()


func _check_auto_win() -> void:
	if not current_puzzle:
		return

	var result = PuzzleLogic.validate(current_puzzle)
	if result.is_valid:
		puzzle_solved = true
		var breakdown = ScoringEngineScript.calculate_score(current_puzzle, time_multiplier, restore_count)
		_update_status("🎉 WIN! Score: %d  |  %s" % [breakdown.final_score, breakdown.get_summary()])
