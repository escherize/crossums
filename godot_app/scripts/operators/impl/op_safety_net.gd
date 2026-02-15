extends Operator
## Safety Net: Highlights cells in solved rows/columns with a green tint.
## Helps players see which areas are "safe" and don't need further changes.

func _init() -> void:
	id = "safety_net"
	display_name = "Safety Net"
	description = "Cells in solved rows/cols glow green"
	rarity = 1  # Uncommon - nice utility
	price = 5
