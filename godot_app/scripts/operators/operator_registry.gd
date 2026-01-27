class_name OperatorRegistry
extends RefCounted
## Registry for creating and managing operators.
## All operators must be registered here to be usable.

const OPERATORS := {
	"counter": preload("res://scripts/operators/impl/op_counter.gd"),
	"lucky_seven": preload("res://scripts/operators/impl/op_lucky_seven.gd"),
	"prime_time": preload("res://scripts/operators/impl/op_prime_time.gd"),
	"row_master": preload("res://scripts/operators/impl/op_row_master.gd"),
	"corner_keeper": preload("res://scripts/operators/impl/op_corner_keeper.gd"),
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


static func deserialize(data: Dictionary) -> Operator:
	return create(data.get("id", ""))
