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

	# Update row targets
	for row in range(puzzle_state.grid_size.y):
		var current_sum = puzzle_state.get_current_row_sum(row)
		row_targets[row].update_current_sum(current_sum)

	# Update column targets
	for col in range(puzzle_state.grid_size.x):
		var current_sum = puzzle_state.get_current_col_sum(col)
		col_targets[col].update_current_sum(current_sum)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_cell_clicked(row: int, col: int) -> void:
	## Toggle cell state on click (touch-friendly: no right-click needed)
	if not puzzle_state:
		return

	var cell_data = puzzle_state.get_cell(row, col)
	var value = cell_data.value
	var cell = grid_cells[row][col] as GridCell

	match cell_data.state:
		PuzzleState.CellState.ACTIVE:
			# Check if deleting this cell would make the puzzle unsolvable
			cell_data.state = PuzzleState.CellState.DELETED
			var still_solvable := PuzzleLogic.has_any_solution(puzzle_state)
			cell_data.state = PuzzleState.CellState.ACTIVE

			if not still_solvable:
				# Deleting this cell would make puzzle unsolvable - it's a mistake
				EventBus.mistake_made.emit(row, col)
				cell.play_error_animation()
			else:
				# Safe to delete - puzzle remains solvable
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
				EventBus.cell_uncircled.emit(row, col)

		_:
			pass  # LOCKED cells can't be toggled


func _on_cell_long_pressed(row: int, col: int) -> void:
	## Long press or right-click = toggle circle state
	if not puzzle_state:
		return

	var cell_data = puzzle_state.get_cell(row, col)
	var cell = grid_cells[row][col] as GridCell

	match cell_data.state:
		PuzzleState.CellState.ACTIVE:
			# Circle the cell
			if puzzle_state.circle_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.CIRCLED)
				cell.play_circle_animation()
				EventBus.cell_circled.emit(row, col)

		PuzzleState.CellState.CIRCLED:
			# Uncircle the cell
			if puzzle_state.uncircle_cell(row, col):
				cell.set_cell_state(PuzzleState.CellState.ACTIVE)
				cell.play_circle_animation()
				EventBus.cell_uncircled.emit(row, col)

		_:
			pass  # Can't circle deleted or locked cells
