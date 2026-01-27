extends Operator
## Corner Keeper: +200 points if all 4 corners are kept

func _init() -> void:
	id = "corner_keeper"
	display_name = "Corner Keeper"
	description = "+200 points if all 4 corners are kept"
	rarity = 1
	price = 7


func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
	var size = puzzle.grid_size
	var corners = [
		Vector2i(0, 0),
		Vector2i(size.x - 1, 0),
		Vector2i(0, size.y - 1),
		Vector2i(size.x - 1, size.y - 1),
	]

	for corner in corners:
		var cell = puzzle.get_cell(corner.y, corner.x)
		if cell.state == PuzzleState.CellState.DELETED:
			return {}

	return {"score_bonus": 200}
