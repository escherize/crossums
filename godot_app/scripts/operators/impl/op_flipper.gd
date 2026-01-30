extends Operator
## Flipper: Bonus points for keeping 6s and 9s

func _init() -> void:
	id = "flipper"
	display_name = "Flipper"
	description = "+40 points for each 6 or 9 kept"
	rarity = 1
	price = 7


func on_cell_kept(_row: int, _col: int, value: int, _puzzle: PuzzleState) -> Dictionary:
	if value == 6 or value == 9:
		return {"score_bonus": 40}
	return {}
