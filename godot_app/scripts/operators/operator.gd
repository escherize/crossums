class_name Operator
extends RefCounted
## Base class for all operators (Balatro-style jokers).
## Override hook methods to implement operator effects.

# =============================================================================
# METADATA
# =============================================================================

var id: String = ""
var display_name: String = ""
var description: String = ""
var rarity: int = 0  # 0=common, 1=uncommon, 2=rare, 3=legendary
var price: int = 5

# =============================================================================
# HOOKS - Override in subclasses
# =============================================================================

## Called for each kept (non-deleted) cell during scoring
## Return: {"score_bonus": int, "mult_bonus": float}
func on_cell_kept(_row: int, _col: int, _value: int, _puzzle: PuzzleState) -> Dictionary:
	return {}


## Called for each row that matches its target
## Return: {"score_bonus": int, "mult_bonus": float}
func on_row_complete(_row: int, _puzzle: PuzzleState) -> Dictionary:
	return {}


## Called for each column that matches its target
## Return: {"score_bonus": int, "mult_bonus": float}
func on_col_complete(_col: int, _puzzle: PuzzleState) -> Dictionary:
	return {}


## Called once at end of puzzle scoring
## Return: {"score_bonus": int, "mult_bonus": float, "money_bonus": int}
func on_puzzle_end(_puzzle: PuzzleState) -> Dictionary:
	return {}


## Called when puzzle starts (for setup effects)
func on_puzzle_start(_puzzle: PuzzleState) -> void:
	pass


## Called after each action to check for auto-actions
## Return: {"auto_delete": Vector2i(col, row)} to auto-delete a cell
func get_auto_action(_puzzle: PuzzleState) -> Dictionary:
	return {}

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
	return {"id": id}


func get_tooltip() -> String:
	return "%s\n%s" % [display_name, description]
