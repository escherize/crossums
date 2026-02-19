extends Operator
## Click Clique: Auto-circles all active cells in a row/col when
## active+circled cells sum to the target.

func _init() -> void:
	id = "click_clique"
	display_name = "Click Clique"
	description = "When active cells hit a target, auto-circle them"
	rarity = 2
	price = 15


func get_auto_action(puzzle: PuzzleState) -> Dictionary:
	# Collect ALL active cells from ALL satisfied rows and columns
	var cells_to_circle: Array[Vector2i] = []
	var seen := {}  # Prevent duplicates (intersection of row & col)

	# Check each row for completed sums
	for row in range(puzzle.grid_size.y):
		if puzzle.get_current_row_sum(row) == puzzle.row_targets[row]:
			for cell in _get_active_cells_in_row(puzzle, row):
				var key := "%d,%d" % [cell.x, cell.y]
				if not seen.has(key):
					seen[key] = true
					cells_to_circle.append(cell)

	# Check each column for completed sums
	for col in range(puzzle.grid_size.x):
		if puzzle.get_current_col_sum(col) == puzzle.col_targets[col]:
			for cell in _get_active_cells_in_col(puzzle, col):
				var key := "%d,%d" % [cell.x, cell.y]
				if not seen.has(key):
					seen[key] = true
					cells_to_circle.append(cell)

	if not cells_to_circle.is_empty():
		return {"auto_circle_cells": cells_to_circle, "operator_id": id}
	return {}


func _get_active_cells_in_row(puzzle: PuzzleState, row: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for col in range(puzzle.grid_size.x):
		if puzzle.get_cell_state(row, col) == PuzzleState.CellState.ACTIVE:
			cells.append(Vector2i(col, row))
	return cells


func _get_active_cells_in_col(puzzle: PuzzleState, col: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in range(puzzle.grid_size.y):
		if puzzle.get_cell_state(row, col) == PuzzleState.CellState.ACTIVE:
			cells.append(Vector2i(col, row))
	return cells
