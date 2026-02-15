extends Operator
## Sum Sight: Shows sum of circled cells on target displays.
## A board-reading super power that helps players verify their theories.

func _init() -> void:
	id = "sum_sight"
	display_name = "Sum Sight"
	description = "Circled cells show their sum on targets"
	rarity = 0  # Common - foundational utility
	price = 4
