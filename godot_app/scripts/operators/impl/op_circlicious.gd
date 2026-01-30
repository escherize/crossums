extends Operator
## Circlicious: +$2 for each circled cell, -$1 for each deleted cell

func _init() -> void:
	id = "circlicious"
	display_name = "Circlicious"
	description = "+$2 per circled, -$1 per deleted"
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

	var money = (circled_count * 2) - deleted_count
	return {"money_bonus": money}
