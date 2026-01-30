extends Operator
## Column Master: +50 points for each completed column

func _init() -> void:
	id = "column_master"
	display_name = "Column Master"
	description = "+50 points for each completed column"
	rarity = 0
	price = 5


func on_col_complete(_col: int, _puzzle: PuzzleState) -> Dictionary:
	return {"score_bonus": 50}
