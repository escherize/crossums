# gdlint: disable=max-public-methods
class_name PuzzleState
extends RefCounted
## Represents the current state of a puzzle grid.
## Contains all cell data, targets, and tracks deletions.

# =============================================================================
# ENUMS
# =============================================================================

enum CellState {
	ACTIVE,    ## Cell is available to delete or circle
	DELETED,   ## Cell has been deleted
	CIRCLED    ## Cell has been marked as "keeper" by player
}

# =============================================================================
# CELL DATA
# =============================================================================

class CellData:
	var value: int = 0
	var state: CellState = CellState.ACTIVE
	var modifiers: Array[String] = []  ## Applied modifier effect IDs

	func _init(v: int = 0) -> void:
		value = v

	func duplicate() -> CellData:
		var copy = CellData.new(value)
		copy.state = state
		copy.modifiers = modifiers.duplicate()
		return copy

# =============================================================================
# PROPERTIES
# =============================================================================

## Grid dimensions
var grid_size: Vector2i = Vector2i(3, 3)

## 2D array of CellData [row][col]
var cells: Array = []

## Target sums for each row
var row_targets: Array[int] = []

## Target sums for each column
var col_targets: Array[int] = []

## History of deleted cell positions (for undo)
var deletion_history: Array[Vector2i] = []

## Puzzle seed for reproducibility
var puzzle_seed: int = 0

## Number of cells in the solution (set during generation)
var solution_cell_count: int = 0

## Misstep count (restore after delete, uncircle after circle)
## Used for "clean solve" bonus in pace rating
var misstep_count: int = 0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(size: Vector2i = Vector2i(3, 3)) -> void:
	grid_size = size
	_initialize_empty_grid()


func _initialize_empty_grid() -> void:
	cells.clear()
	for row in range(grid_size.y):
		var row_data: Array = []
		for col in range(grid_size.x):
			row_data.append(CellData.new())
		cells.append(row_data)

	row_targets.clear()
	row_targets.resize(grid_size.y)
	row_targets.fill(0)

	col_targets.clear()
	col_targets.resize(grid_size.x)
	col_targets.fill(0)

# =============================================================================
# CELL ACCESS
# =============================================================================

func get_cell(row: int, col: int) -> CellData:
	if not _is_valid_position(row, col):
		push_error("Invalid cell position: (%d, %d)" % [row, col])
		return null
	return cells[row][col]


func get_cell_value(row: int, col: int) -> int:
	var cell = get_cell(row, col)
	return cell.value if cell else 0


func get_cell_state(row: int, col: int) -> CellState:
	var cell = get_cell(row, col)
	return cell.state if cell else CellState.ACTIVE


func set_cell_value(row: int, col: int, value: int) -> void:
	var cell = get_cell(row, col)
	if cell:
		cell.value = value


func is_cell_active(row: int, col: int) -> bool:
	return get_cell_state(row, col) == CellState.ACTIVE


func is_cell_deleted(row: int, col: int) -> bool:
	return get_cell_state(row, col) == CellState.DELETED


func is_cell_kept(row: int, col: int) -> bool:
	## Returns true if cell contributes to sums (not deleted)
	var state = get_cell_state(row, col)
	return state == CellState.CIRCLED or state == CellState.ACTIVE


func is_cell_circled(row: int, col: int) -> bool:
	return get_cell_state(row, col) == CellState.CIRCLED

# =============================================================================
# CELL OPERATIONS
# =============================================================================

func delete_cell(row: int, col: int) -> bool:
	var cell = get_cell(row, col)
	if not cell:
		return false

	if cell.state != CellState.ACTIVE:
		return false  # Can only delete active cells

	cell.state = CellState.DELETED
	deletion_history.append(Vector2i(col, row))
	return true


func restore_cell(row: int, col: int) -> bool:
	var cell = get_cell(row, col)
	if not cell:
		return false

	if cell.state != CellState.DELETED:
		return false

	cell.state = CellState.ACTIVE
	misstep_count += 1  # Restoring = player changed their mind
	# Remove from history
	var pos = Vector2i(col, row)
	var idx = deletion_history.rfind(pos)
	if idx >= 0:
		deletion_history.remove_at(idx)
	return true


func circle_cell(row: int, col: int) -> bool:
	## Mark a cell as "keeper" - visual planning aid
	var cell = get_cell(row, col)
	if not cell:
		return false

	if cell.state != CellState.ACTIVE:
		return false  # Can only circle active cells

	cell.state = CellState.CIRCLED
	return true


func uncircle_cell(row: int, col: int) -> bool:
	## Remove circle marking, return to active
	var cell = get_cell(row, col)
	if not cell:
		return false

	if cell.state != CellState.CIRCLED:
		return false

	cell.state = CellState.ACTIVE
	misstep_count += 1  # Uncircling = player changed their mind
	return true


func undo_last_deletion() -> Vector2i:
	if deletion_history.is_empty():
		return Vector2i(-1, -1)

	var last_pos = deletion_history.pop_back()
	var row = last_pos.y
	var col = last_pos.x

	var cell = get_cell(row, col)
	if cell:
		cell.state = CellState.ACTIVE
		misstep_count += 1  # Undo = player changed their mind

	return Vector2i(col, row)

# =============================================================================
# SUM CALCULATIONS
# =============================================================================

func get_current_row_sum(row: int) -> int:
	if row < 0 or row >= grid_size.y:
		return 0

	var sum = 0
	for col in range(grid_size.x):
		var cell = cells[row][col]
		if cell.state != CellState.DELETED:
			sum += get_effective_value(row, col)
	return sum


func get_current_col_sum(col: int) -> int:
	if col < 0 or col >= grid_size.x:
		return 0

	var sum = 0
	for row in range(grid_size.y):
		var cell = cells[row][col]
		if cell.state != CellState.DELETED:
			sum += get_effective_value(row, col)
	return sum


func get_effective_value(row: int, col: int) -> int:
	## Returns the cell value after applying any transformation operators.
	## Override point for operator effects like Doubler, Flipper, etc.
	var cell = get_cell(row, col)
	if not cell:
		return 0
	return cell.value  # Base implementation - operators will modify this

# =============================================================================
# VALIDATION
# =============================================================================

func is_row_valid(row: int) -> bool:
	return get_current_row_sum(row) == row_targets[row]


func is_col_valid(col: int) -> bool:
	return get_current_col_sum(col) == col_targets[col]


func is_solved() -> bool:
	for row in range(grid_size.y):
		if not is_row_valid(row):
			return false

	for col in range(grid_size.x):
		if not is_col_valid(col):
			return false

	return true


func get_circled_row_sum(row: int) -> int:
	## Sum of only CIRCLED cells in this row
	if row < 0 or row >= grid_size.y:
		return 0
	var sum = 0
	for col in range(grid_size.x):
		var cell = cells[row][col]
		if cell.state == CellState.CIRCLED:
			sum += cell.value
	return sum


func get_circled_col_sum(col: int) -> int:
	## Sum of only CIRCLED cells in this column
	if col < 0 or col >= grid_size.x:
		return 0
	var sum = 0
	for row in range(grid_size.y):
		var cell = cells[row][col]
		if cell.state == CellState.CIRCLED:
			sum += cell.value
	return sum


func is_row_solved_by_circles(row: int) -> bool:
	## Check if circled cells in this row alone sum to the target
	var circled_sum = get_circled_row_sum(row)
	return circled_sum > 0 and circled_sum == row_targets[row]


func is_col_solved_by_circles(col: int) -> bool:
	## Check if circled cells in this column alone sum to the target
	var circled_sum = get_circled_col_sum(col)
	return circled_sum > 0 and circled_sum == col_targets[col]


func is_solved_by_circles() -> bool:
	## Check if circled cells alone form a valid solution
	# Must have at least one circled cell
	var has_circles = false
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			if cells[row][col].state == CellState.CIRCLED:
				has_circles = true
				break
		if has_circles:
			break
	if not has_circles:
		return false

	# Check all row sums
	for row in range(grid_size.y):
		if get_circled_row_sum(row) != row_targets[row]:
			return false

	# Check all col sums
	for col in range(grid_size.x):
		if get_circled_col_sum(col) != col_targets[col]:
			return false

	return true


func get_row_delta(row: int) -> int:
	## Returns difference between current sum and target (negative = under, positive = over)
	return get_current_row_sum(row) - row_targets[row]


func get_col_delta(col: int) -> int:
	return get_current_col_sum(col) - col_targets[col]

# =============================================================================
# STATISTICS
# =============================================================================

func get_kept_cells() -> Array[Vector2i]:
	var kept: Array[Vector2i] = []
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			if cells[row][col].state != CellState.DELETED:
				kept.append(Vector2i(col, row))
	return kept


func get_deleted_cells() -> Array[Vector2i]:
	var deleted: Array[Vector2i] = []
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			if cells[row][col].state == CellState.DELETED:
				deleted.append(Vector2i(col, row))
	return deleted


func get_kept_count() -> int:
	var count = 0
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			if cells[row][col].state != CellState.DELETED:
				count += 1
	return count


func get_deleted_count() -> int:
	return deletion_history.size()


func get_total_cells() -> int:
	return grid_size.x * grid_size.y


func get_solution_cell_count() -> int:
	## Returns the number of cells in the puzzle's solution.
	## If not set during generation, estimates based on kept cells.
	if solution_cell_count > 0:
		return solution_cell_count
	# Fallback: estimate ~50% of cells (typical for generated puzzles)
	return int(get_total_cells() * 0.5)

# =============================================================================
# UTILITY
# =============================================================================

func _is_valid_position(row: int, col: int) -> bool:
	return row >= 0 and row < grid_size.y and col >= 0 and col < grid_size.x


func duplicate_state() -> PuzzleState:
	var copy = PuzzleState.new(grid_size)
	copy.puzzle_seed = puzzle_seed
	copy.row_targets = row_targets.duplicate()
	copy.col_targets = col_targets.duplicate()
	copy.deletion_history = deletion_history.duplicate()
	copy.misstep_count = misstep_count

	for row in range(grid_size.y):
		for col in range(grid_size.x):
			copy.cells[row][col] = cells[row][col].duplicate()

	return copy


func reset() -> void:
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			cells[row][col].state = CellState.ACTIVE
	deletion_history.clear()
	misstep_count = 0
