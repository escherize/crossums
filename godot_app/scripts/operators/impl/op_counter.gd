extends Operator
## Counter: +10 points for each kept cell

func _init() -> void:
	id = "counter"
	display_name = "Counter"
	description = "+10 points for each kept cell"
	rarity = 0
	price = 5


func on_cell_kept(_row: int, _col: int, _value: int, _puzzle: PuzzleState) -> Dictionary:
	return {"score_bonus": 10}
