extends Operator
## Elite Delete: +$2 for each deleted cell, -$1 for each circled cell

func _init() -> void:
	id = "elite_delete"
	display_name = "Elite Delete"
	description = "+$2 per deleted, -$1 per circled"
	rarity = 1
	price = 6


func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
	var circled_count := 0
	var deleted_count := 0

	for row in range(puzzle.grid_size.y):
		for col in range(puzzle.grid_size.x):
			if puzzle.is_cell_circled(row, col):
				circled_count += 1
			elif puzzle.is_cell_deleted(row, col):
				deleted_count += 1

	var money = (deleted_count * 2) - circled_count
	return {"money_bonus": money}
