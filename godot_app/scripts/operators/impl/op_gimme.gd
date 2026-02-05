extends Operator
## Gimme: Auto-clicks the last cell when only 1 red row and 1 red column remain

func _init() -> void:
	id = "gimme"
	display_name = "Gimme"
	description = "Auto-solves when 1 row and 1 column remain"
	rarity = 1
	price = 6


func get_auto_action(puzzle: PuzzleState) -> Dictionary:
	# Find incomplete rows (red targets)
	var incomplete_rows: Array[int] = []
	for row in range(puzzle.grid_size.y):
		if puzzle.get_current_row_sum(row) != puzzle.row_targets[row]:
			incomplete_rows.append(row)

	# Find incomplete columns (red targets)
	var incomplete_cols: Array[int] = []
	for col in range(puzzle.grid_size.x):
		if puzzle.get_current_col_sum(col) != puzzle.col_targets[col]:
			incomplete_cols.append(col)

	# Check if exactly 1 of each
	if incomplete_rows.size() != 1 or incomplete_cols.size() != 1:
		return {}

	var row = incomplete_rows[0]
	var col = incomplete_cols[0]

	# Check if the intersection cell is active (clickable)
	var cell = puzzle.get_cell(row, col)
	if cell.state != PuzzleState.CellState.ACTIVE:
		return {}

	# Auto-delete this cell
	return {"auto_delete": Vector2i(col, row)}
