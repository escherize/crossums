extends Operator
## Lucky Seven: +77 points for each 7 kept

func _init() -> void:
	id = "lucky_seven"
	display_name = "Lucky Seven"
	description = "+77 points for each 7 kept"
	rarity = 0
	price = 6


func on_cell_kept(_row: int, _col: int, value: int, _puzzle: PuzzleState) -> Dictionary:
	if value == 7:
		return {"score_bonus": 77}
	return {}
