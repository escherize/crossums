class_name OperatorRegistry
extends RefCounted
## Registry for creating and managing operators.
## All operators must be registered here to be usable.

const OPERATORS := {
	# Original operators
	"counter": preload("res://scripts/operators/impl/op_counter.gd"),
	"lucky_seven": preload("res://scripts/operators/impl/op_lucky_seven.gd"),
	"prime_time": preload("res://scripts/operators/impl/op_prime_time.gd"),
	"row_master": preload("res://scripts/operators/impl/op_row_master.gd"),
	"corner_keeper": preload("res://scripts/operators/impl/op_corner_keeper.gd"),
	# New operators
	"column_master": preload("res://scripts/operators/impl/op_column_master.gd"),
	"zero_hero": preload("res://scripts/operators/impl/op_zero_hero.gd"),
	"flipper": preload("res://scripts/operators/impl/op_flipper.gd"),
	"circlicious": preload("res://scripts/operators/impl/op_circlicious.gd"),
	"elite_delete": preload("res://scripts/operators/impl/op_elite_delete.gd"),
	"purist": preload("res://scripts/operators/impl/op_purist.gd"),
	"square_peg": preload("res://scripts/operators/impl/op_square_peg.gd"),
}


static func create(id: String) -> Operator:
	if not OPERATORS.has(id):
		push_error("Unknown operator: %s" % id)
		return null
	return OPERATORS[id].new()


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(OPERATORS.keys())
	return ids


static func get_random_operators(count: int, exclude_ids: Array = [], rng: RandomNumberGenerator = null) -> Array:
	## Get random operators, excluding those already owned.
	## If rng is provided, uses it for deterministic selection.
	var available: Array[String] = []
	for op_id in OPERATORS.keys():
		if op_id not in exclude_ids:
			available.append(op_id)

	# Use provided RNG or fall back to global shuffle
	if rng:
		_shuffle_with_rng(available, rng)
	else:
		available.shuffle()

	var result: Array = []
	for i in range(mini(count, available.size())):
		var op = create(available[i])
		if op:
			result.append(op)
	return result


static func _shuffle_with_rng(arr: Array, rng: RandomNumberGenerator) -> void:
	## Fisher-Yates shuffle with provided RNG
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func deserialize(data: Dictionary) -> Operator:
	return create(data.get("id", ""))
