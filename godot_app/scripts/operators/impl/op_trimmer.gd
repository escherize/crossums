extends Operator
## Trimmer: Auto-deletes cells that exceed their row or column target.
## Only works when no negative numbers are present.

func _init() -> void:
	id = "trimmer"
	display_name = "Trimmer"
	description = "Auto-deletes cells too big for their targets"
	rarity = 2
	price = 20


func get_auto_action(puzzle: PuzzleState) -> Dictionary:
	# Find all active cells with value > row_target or > col_target
	var cells_to_delete: Array[Vector2i] = []

	for row in range(puzzle.grid_size.y):
		for col in range(puzzle.grid_size.x):
			if puzzle.get_cell_state(row, col) != PuzzleState.CellState.ACTIVE:
				continue

			var value = puzzle.get_cell_value(row, col)
			var row_target = puzzle.row_targets[row]
			var col_target = puzzle.col_targets[col]

			# Skip if negative numbers could be present
			if value < 0 or row_target < 0 or col_target < 0:
				continue

			# Cell is impossible if it exceeds either target
			if value > row_target or value > col_target:
				cells_to_delete.append(Vector2i(col, row))

	if not cells_to_delete.is_empty():
		return {"auto_delete_cells": cells_to_delete, "operator_id": id}
	return {}
