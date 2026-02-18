extends Operator
## Garbage Collector: Auto-deletes all active cells in a row/col when
## circled cells alone sum to the target.

func _init() -> void:
	id = "garbage_collector"
	display_name = "Garbage Collector"
	description = "When circled cells hit a target, auto-delete the rest"
	rarity = 2
	price = 15


func get_auto_action(puzzle: PuzzleState) -> Dictionary:
	# Check each row - if circled cells sum to target, delete active cells
	for row in range(puzzle.grid_size.y):
		if puzzle.is_row_solved_by_circles(row):
			var active_cells := _get_active_cells_in_row(puzzle, row)
			if not active_cells.is_empty():
				return {"auto_delete_cells": active_cells, "operator_id": id}

	# Check each column - if circled cells sum to target, delete active cells
	for col in range(puzzle.grid_size.x):
		if puzzle.is_col_solved_by_circles(col):
			var active_cells := _get_active_cells_in_col(puzzle, col)
			if not active_cells.is_empty():
				return {"auto_delete_cells": active_cells, "operator_id": id}

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
