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
	# Check each row for completed sums
	for row in range(puzzle.grid_size.y):
		if puzzle.get_current_row_sum(row) == puzzle.row_targets[row]:
			var active_cells := _get_active_cells_in_row(puzzle, row)
			if not active_cells.is_empty():
				return {"auto_circle_cells": active_cells, "operator_id": id}

	# Check each column for completed sums
	for col in range(puzzle.grid_size.x):
		if puzzle.get_current_col_sum(col) == puzzle.col_targets[col]:
			var active_cells := _get_active_cells_in_col(puzzle, col)
			if not active_cells.is_empty():
				return {"auto_circle_cells": active_cells, "operator_id": id}

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
