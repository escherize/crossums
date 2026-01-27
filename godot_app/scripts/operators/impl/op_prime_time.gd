extends Operator
## Prime Time: +30 points for each prime number kept

const PRIMES := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]

func _init() -> void:
	id = "prime_time"
	display_name = "Prime Time"
	description = "+30 points for each prime number kept"
	rarity = 1
	price = 8


func on_cell_kept(_row: int, _col: int, value: int, _puzzle: PuzzleState) -> Dictionary:
	if value in PRIMES:
		return {"score_bonus": 30}
	return {}
