extends Operator
## Zero Hero: x2 score if any kept cell contains 0

func _init() -> void:
	id = "zero_hero"
	display_name = "Zero Hero"
	description = "×2 score if you keep a 0"
	rarity = 1
	price = 8


func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
	# Check if any kept cell has value 0
	for row in range(puzzle.grid_size.y):
		for col in range(puzzle.grid_size.x):
			if not puzzle.is_cell_deleted(row, col) and puzzle.get_cell_value(row, col) == 0:
				return {"mult_bonus": 1.0}  # Adds 1.0 to multiplier (making it x2)
	return {}
