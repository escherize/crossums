class_name PuzzleGrid
extends Control
## Main puzzle grid component. Manages the NxN grid of cells and target displays.
## Handles player interactions and communicates via EventBus.

# =============================================================================
# CONSTANTS
# =============================================================================

const GridCellScene = preload("res://scenes/puzzle/grid_cell.tscn")
const TargetDisplayScene = preload("res://scenes/puzzle/target_display.tscn")

const MIN_CELL_SIZE := 80
const MAX_CELL_SIZE := 250
const CELL_GAP := 8
const GRID_PADDING := 16

# Dynamic sizing based on grid dimensions and screen size
var cell_size: int = MAX_CELL_SIZE
var target_size: int = MAX_CELL_SIZE

# =============================================================================
# PROPERTIES
# =============================================================================

var puzzle_state: PuzzleState = null
var grid_cells: Array = []  ## 2D array of GridCell nodes
var row_targets: Array[TargetDisplay] = []
var col_targets: Array[TargetDisplay] = []
var circle_mode_active: bool = false  ## When true, taps circle instead of delete

# Touch tracking for multitouch support (index > 0 only)
# Touch index 0 uses Button's native mouse emulation
var _multitouch_cells: Dictionary = {}  ## touch_index -> GridCell (for index > 0)

# =============================================================================
# NODE REFERENCES
# =============================================================================

var main_container: HBoxContainer
var grid_area: VBoxContainer
var col_target_container: HBoxContainer
var col_spacer: Control
var grid_with_row_targets: HBoxContainer
var row_target_container: VBoxContainer
var cell_grid_container: GridContainer

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_build_layout()


func _input(event: InputEvent) -> void:
	## Handle MULTITOUCH input directly (touch index > 0).
	## Touch index 0 uses Godot's touch-to-mouse emulation, handled by Button natively.
	## This enables holding o-shift button (touch 0) while tapping cells (touch 1+).
	if not puzzle_state:
		return
	if grid_cells.is_empty():
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch

		# Only handle multitouch (index > 0)
		# Touch index 0 goes through mouse emulation -> Button -> _on_cell_clicked
		if touch.index == 0:
			return

		if touch.pressed:
			# Multitouch DOWN - track which cell this finger is on
			var touched_cell := _get_cell_at_position(touch.position)
			if touched_cell:
				_multitouch_cells[touch.index] = touched_cell
		else:
			# Multitouch UP - act on the tracked cell
			if _multitouch_cells.has(touch.index):
				var cell: GridCell = _multitouch_cells[touch.index]
				_multitouch_cells.erase(touch.index)
				_handle_cell_click(cell.row, cell.col)


func _get_cell_at_position(global_pos: Vector2) -> GridCell:
	## Find which cell contains the given global position
	for row in range(puzzle_state.grid_size.y):
		for col in range(puzzle_state.grid_size.x):
			var cell := grid_cells[row][col] as GridCell
			var cell_rect := cell.get_global_rect()
			if cell_rect.has_point(global_pos):
				return cell
	return null


# =============================================================================
# PUBLIC METHODS
# =============================================================================

func load_puzzle(state: PuzzleState) -> void:
	puzzle_state = state
	_clear_grid()
	_build_grid()
	_update_all_targets()


func refresh() -> void:
	## Refresh all visual states from puzzle_state
	if not puzzle_state:
		return

	for row in range(puzzle_state.grid_size.y):
		for col in range(puzzle_state.grid_size.x):
			var cell = grid_cells[row][col] as GridCell
			var cell_data = puzzle_state.get_cell(row, col)
			cell.set_cell_state(cell_data.state)

	_update_all_targets()

# =============================================================================
# PRIVATE METHODS - LAYOUT
# =============================================================================

func _build_layout() -> void:
	# Main horizontal container
	main_container = HBoxContainer.new()
	main_container.add_theme_constant_override("separation", CELL_GAP)
	add_child(main_container)

	# Grid area (column targets + row targets + cells)
	grid_area = VBoxContainer.new()
	grid_area.add_theme_constant_override("separation", CELL_GAP)
	main_container.add_child(grid_area)

	# Column targets row (with spacer for alignment)
	col_target_container = HBoxContainer.new()
	col_target_container.add_theme_constant_override("separation", CELL_GAP)
	grid_area.add_child(col_target_container)

	# Spacer to align column targets with cells (accounts for row target width)
	# Size will be updated in _build_grid when we know the actual cell size
	col_spacer = Control.new()
	col_spacer.custom_minimum_size = Vector2(MAX_CELL_SIZE, MAX_CELL_SIZE)
	col_target_container.add_child(col_spacer)

	# Grid with row targets
	grid_with_row_targets = HBoxContainer.new()
	grid_with_row_targets.add_theme_constant_override("separation", CELL_GAP)
	grid_area.add_child(grid_with_row_targets)

	# Row targets column
	row_target_container = VBoxContainer.new()
	row_target_container.add_theme_constant_override("separation", CELL_GAP)
	grid_with_row_targets.add_child(row_target_container)

	# Cell grid
	cell_grid_container = GridContainer.new()
	cell_grid_container.add_theme_constant_override("h_separation", CELL_GAP)
	cell_grid_container.add_theme_constant_override("v_separation", CELL_GAP)
	grid_with_row_targets.add_child(cell_grid_container)


func _clear_grid() -> void:
	# Clear cells
	for row_arr in grid_cells:
		for cell in row_arr:
			cell.queue_free()
	grid_cells.clear()

	# Clear row targets
	for target in row_targets:
		target.queue_free()
	row_targets.clear()

	# Clear column targets (except spacer)
	for target in col_targets:
		target.queue_free()
	col_targets.clear()


func _calculate_cell_size(grid_dim: int) -> void:
	## Calculate cell size based on smallest viewport dimension
	var viewport_size := get_viewport().get_visible_rect().size

	# Use 70% of smallest dimension for better visibility
	var available_space := minf(viewport_size.x, viewport_size.y) * 0.70

	# Account for target row/column and gaps
	var total_cells := grid_dim + 1  # +1 for target column/row
	var total_gaps := grid_dim * CELL_GAP
	var available_for_cells := available_space - total_gaps
	var calculated_size := int(available_for_cells / total_cells)

	# Clamp to reasonable bounds
	cell_size = clampi(calculated_size, MIN_CELL_SIZE, MAX_CELL_SIZE)
	target_size = cell_size


func _build_grid() -> void:
	if not puzzle_state:
		return

	var grid_size_vec = puzzle_state.grid_size

	# Calculate appropriate cell size for this grid
	_calculate_cell_size(grid_size_vec.x)

	# Update spacer size to match
	col_spacer.custom_minimum_size = Vector2(target_size, target_size)

	# Set grid columns
	cell_grid_container.columns = grid_size_vec.x

	# Create column targets
	for col in range(grid_size_vec.x):
		var target = TargetDisplayScene.instantiate() as TargetDisplay
		target.setup(col, puzzle_state.col_targets[col], TargetDisplay.ORIENTATION_COLUMN)
		target.custom_minimum_size = Vector2(cell_size, target_size)
		col_target_container.add_child(target)
		col_targets.append(target)

	# Create rows (row target + cells)
	for row in range(grid_size_vec.y):
		# Row target
		var row_target = TargetDisplayScene.instantiate() as TargetDisplay
		row_target.setup(row, puzzle_state.row_targets[row], TargetDisplay.ORIENTATION_ROW)
		row_target.custom_minimum_size = Vector2(target_size, cell_size)
		row_target_container.add_child(row_target)
		row_targets.append(row_target)

		# Cells for this row
		var row_cells: Array = []
		for col in range(grid_size_vec.x):
			var cell = GridCellScene.instantiate() as GridCell
			var cell_data = puzzle_state.get_cell(row, col)
			cell.setup(row, col, cell_data.value)
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.cell_clicked.connect(_on_cell_clicked)
			cell.cell_right_clicked.connect(_on_cell_long_pressed)  # Right-click = circle
			cell.cell_long_pressed.connect(_on_cell_long_pressed)   # Long press = circle
			cell_grid_container.add_child(cell)
			row_cells.append(cell)

		grid_cells.append(row_cells)

	# Set minimum size so CenterContainer can center us
	var total_width = target_size + CELL_GAP + (cell_size * grid_size_vec.x) + (CELL_GAP * (grid_size_vec.x - 1))
	var total_height = target_size + CELL_GAP + (cell_size * grid_size_vec.y) + (CELL_GAP * (grid_size_vec.y - 1))
	custom_minimum_size = Vector2(total_width, total_height)


func _update_all_targets() -> void:
	if not puzzle_state:
		return

	# Check operator states
	var show_circled_sums := GameState.has_operator("sum_sight")
	var show_safety_net := GameState.has_operator("safety_net")

	# Track which rows/cols are solved (for Safety Net)
	var solved_rows: Array[bool] = []
	var solved_cols: Array[bool] = []

	# Update row targets
	for row in range(puzzle_state.grid_size.y):
		var current_sum = puzzle_state.get_current_row_sum(row)
		row_targets[row].update_current_sum(current_sum)
		row_targets[row].update_circle_solved(puzzle_state.is_row_solved_by_circles(row))
		solved_rows.append(current_sum == puzzle_state.row_targets[row])
		if show_circled_sums:
			row_targets[row].update_circled_sum(puzzle_state.get_circled_row_sum(row))
		else:
			row_targets[row].update_circled_sum(0)

	# Update column targets
	for col in range(puzzle_state.grid_size.x):
		var current_sum = puzzle_state.get_current_col_sum(col)
		col_targets[col].update_current_sum(current_sum)
		col_targets[col].update_circle_solved(puzzle_state.is_col_solved_by_circles(col))
		solved_cols.append(current_sum == puzzle_state.col_targets[col])
		if show_circled_sums:
			col_targets[col].update_circled_sum(puzzle_state.get_circled_col_sum(col))
		else:
			col_targets[col].update_circled_sum(0)

	# Apply Safety Net visual effect
	if show_safety_net:
		for row in range(puzzle_state.grid_size.y):
			for col in range(puzzle_state.grid_size.x):
				var cell = grid_cells[row][col] as GridCell
				var protected = solved_rows[row] or solved_cols[col]
				cell.set_protected(protected)
	else:
		# Clear all protected states
		for row in range(puzzle_state.grid_size.y):
			for col in range(puzzle_state.grid_size.x):
				var cell = grid_cells[row][col] as GridCell
				cell.set_protected(false)


func simulate_click(row: int, col: int) -> void:
	## Simulate a cell click (for operator auto-actions)
	_handle_cell_click(row, col)


func set_circle_mode(active: bool) -> void:
	## Enable/disable circle mode (shift-key button)
	if circle_mode_active == active:
		return
	circle_mode_active = active
	_update_circle_mode_visuals()


func _update_circle_mode_visuals() -> void:
	## Update all cells to show circle mode hint
	if not puzzle_state:
		return
	for row in range(puzzle_state.grid_size.y):
		for col in range(puzzle_state.grid_size.x):
			var cell = grid_cells[row][col] as GridCell
			cell.set_circle_mode_hint(circle_mode_active)


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_cell_clicked(row: int, col: int) -> void:
	## Called from Button's pressed signal (via mouse or touch-to-mouse emulation)
	## This handles touch index 0 (single touch) and mouse clicks
	_handle_cell_click(row, col)


func _handle_cell_click(row: int, col: int) -> void:
	## Toggle cell state on click
	## If circle_mode_active, taps circle instead of delete
	if not puzzle_state:
		return

	# Circle mode: redirect to circle logic
	if circle_mode_active:
		_on_cell_long_pressed(row, col)
		return

	var cell_data = puzzle_state.get_cell(row, col)
	var value = cell_data.value
	var cell = grid_cells[row][col] as GridCell

	match cell_data.state:
		PuzzleState.CellState.ACTIVE:
			# Delete the cell (no solvability check - timer is the fail condition)
			if puzzle_state.delete_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.DELETED)
				cell.play_delete_animation()
				_update_all_targets()
				EventBus.cell_deleted.emit(row, col, value)

		PuzzleState.CellState.DELETED:
			# Restore the cell
			if puzzle_state.restore_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.ACTIVE)
				cell.play_restore_animation()
				_update_all_targets()
				EventBus.cell_restored.emit(row, col, value)

		PuzzleState.CellState.CIRCLED:
			# Uncircle the cell (return to active)
			if puzzle_state.uncircle_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.ACTIVE)
				cell.play_circle_animation()
				_update_all_targets()
				EventBus.cell_uncircled.emit(row, col)

		_:
			pass  # DELETED cells can't be toggled


func _on_cell_long_pressed(row: int, col: int) -> void:
	## Long press or right-click = toggle circle state
	if not puzzle_state:
		return

	var cell_data = puzzle_state.get_cell(row, col)
	var cell = grid_cells[row][col] as GridCell

	match cell_data.state:
		PuzzleState.CellState.ACTIVE:
			# Circle the cell (no validation - circling is a player tool, not a testable action)
			if puzzle_state.circle_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.CIRCLED)
				cell.play_circle_animation()
				_update_all_targets()
				EventBus.cell_circled.emit(row, col)

		PuzzleState.CellState.CIRCLED:
			# Uncircle the cell
			if puzzle_state.uncircle_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.ACTIVE)
				cell.play_circle_animation()
				_update_all_targets()
				EventBus.cell_uncircled.emit(row, col)

		_:
			pass  # Can't circle deleted cells
