extends Operator
## Row Master: +50 points for each completed row

func _init() -> void:
	id = "row_master"
	display_name = "Row Master"
	description = "+50 points for each completed row"
	rarity = 0
	price = 5


func on_row_complete(_row: int, _puzzle: PuzzleState) -> Dictionary:
	return {"score_bonus": 50}
