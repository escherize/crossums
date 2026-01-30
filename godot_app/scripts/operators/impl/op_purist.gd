extends Operator
## Purist: Big bonus if you win without using any circles

func _init() -> void:
	id = "purist"
	display_name = "Purist"
	description = "+300 points if no circles used"
	rarity = 1
	price = 7


func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
	# Check if any cells are circled
	for row in range(puzzle.grid_size.y):
		for col in range(puzzle.grid_size.x):
			if puzzle.is_cell_circled(row, col):
				return {}

	return {"score_bonus": 300}
