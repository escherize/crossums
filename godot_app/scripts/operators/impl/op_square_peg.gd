extends Operator
## SquarePeg: Bonus for uniform squares (2x2 = +100, 3x3 = +1000)

func _init() -> void:
	id = "square_peg"
	display_name = "Square Peg"
	description = "+100 per 2×2, +1000 per 3×3"
	rarity = 2
	price = 9


func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
	var bonus := 0

	# Check all possible 2x2 squares
	for row in range(puzzle.grid_size.y - 1):
		for col in range(puzzle.grid_size.x - 1):
			if _is_uniform_square(puzzle, row, col, 2):
				bonus += 100

	# Check all possible 3x3 squares
	for row in range(puzzle.grid_size.y - 2):
		for col in range(puzzle.grid_size.x - 2):
			if _is_uniform_square(puzzle, row, col, 3):
				bonus += 1000

	return {"score_bonus": bonus}


func _is_uniform_square(puzzle: PuzzleState, top_row: int, left_col: int, size: int) -> bool:
	var base_state = puzzle.get_cell_state(top_row, left_col)

	for dr in range(size):
		for dc in range(size):
			if puzzle.get_cell_state(top_row + dr, left_col + dc) != base_state:
				return false

	return true
