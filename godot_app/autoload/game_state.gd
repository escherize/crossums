extends Node
## Centralized game state singleton.
## Holds all game data for serialization, save/load, and testing.

const RunStateScript = preload("res://scripts/core/run_state.gd")
const PuzzleGeneratorScript = preload("res://scripts/core/puzzle_generator.gd")
const MAX_OPERATORS := 5

# All puzzles are now single-solution (deterministic)
# Multi-solution puzzles were removed because the game is highly deterministic
# about which cells must be deleted, making "choice" operators frustrating.

# =============================================================================
# STATE
# =============================================================================

var run = null  # RunState instance
var puzzle: PuzzleState = null
var operators: Array = []  # Array[Operator], typed in Sprint 2
var functions: Array = []  # Array[GameFunction], typed later

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	pass


func reset() -> void:
	run = null
	puzzle = null
	operators.clear()
	functions.clear()


func start_new_run(run_seed: int = 0) -> void:
	run = RunStateScript.new()
	run.run_seed = run_seed
	EventBus.run_started.emit("standard", 1)


func start_new_puzzle(config: PuzzleLogic.PuzzleConfig) -> void:
	# Apply run seed if available and config doesn't have one
	if run and config.puzzle_seed == 0:
		config.puzzle_seed = run.get_puzzle_seed()

	var rng = RandomNumberGenerator.new()
	if config.puzzle_seed != 0:
		rng.seed = config.puzzle_seed
	else:
		rng.randomize()

	# All puzzles use single-solution generation (deterministic)
	# Multi-solution was removed - see design notes in memory file
	puzzle = PuzzleGeneratorScript.generate_single_solution(
		config.grid_size, rng, config.min_cell_value, config.max_cell_value
	)

	# Notify operators of puzzle start
	for op in operators:
		op.on_puzzle_start(puzzle)
	EventBus.puzzle_loaded.emit(puzzle)


# =============================================================================
# OPERATOR MANAGEMENT (Sprint 2)
# =============================================================================

func add_operator(op: Operator) -> bool:
	if operators.size() >= MAX_OPERATORS:
		return false
	operators.append(op)
	EventBus.operator_acquired.emit(op)
	return true


func remove_operator(index: int) -> Operator:
	if index < 0 or index >= operators.size():
		return null
	var op = operators.pop_at(index)
	EventBus.operator_sold.emit(op, op.price / 2)
	return op


func has_operator(id: String) -> bool:
	for op in operators:
		if op.id == id:
			return true
	return false


func get_operator_by_id(id: String) -> Operator:
	for op in operators:
		if op.id == id:
			return op
	return null


# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
	return {
		"version": 1,
		"run": run.serialize() if run else null,
		"puzzle": _serialize_puzzle() if puzzle else null,
		"operators": operators.map(func(o): return o.serialize()),
		"functions": [],  # Later
	}


func deserialize(data: Dictionary) -> bool:
	var version = data.get("version", 0)
	if version != 1:
		push_error("Unknown save version: %d" % version)
		return false

	if data.has("run") and data.run != null:
		run = RunStateScript.deserialize(data.run)
	else:
		run = null

	if data.has("puzzle") and data.puzzle != null:
		puzzle = _deserialize_puzzle(data.puzzle)
	else:
		puzzle = null

	# Restore operators
	operators.clear()
	for op_data in data.get("operators", []):
		var op = OperatorRegistry.deserialize(op_data)
		if op:
			operators.append(op)

	EventBus.state_changed.emit()
	return true


func _serialize_puzzle() -> Dictionary:
	if puzzle == null:
		return {}

	var cells := []
	for row in range(puzzle.grid_size.y):
		var row_data := []
		for col in range(puzzle.grid_size.x):
			var cell = puzzle.get_cell(row, col)
			row_data.append({
				"value": cell.value,
				"state": cell.state,
			})
		cells.append(row_data)

	# Serialize action history (new batched format)
	var action_history_data: Array = []
	for batch in puzzle.action_history:
		action_history_data.append({
			"type": batch.type,
			"cells": batch.cells.map(func(v): return {"x": v.x, "y": v.y}),
			"auto": batch.get("auto", false),
			"operator_id": batch.get("operator_id", "")
		})

	return {
		"grid_size": {"x": puzzle.grid_size.x, "y": puzzle.grid_size.y},
		"cells": cells,
		"row_targets": Array(puzzle.row_targets),
		"col_targets": Array(puzzle.col_targets),
		"action_history": action_history_data,
		"puzzle_seed": puzzle.puzzle_seed,
	}


func _deserialize_puzzle(data: Dictionary) -> PuzzleState:
	var size = Vector2i(data.grid_size.x, data.grid_size.y)
	var ps = PuzzleState.new(size)

	ps.row_targets.assign(data.row_targets)
	ps.col_targets.assign(data.col_targets)
	ps.puzzle_seed = data.get("puzzle_seed", 0)

	for row in range(size.y):
		for col in range(size.x):
			var cell_data = data.cells[row][col]
			var cell = ps.get_cell(row, col)
			cell.value = cell_data.value
			cell.state = cell_data.state

	# Deserialize action history (new batched format)
	ps.action_history.clear()
	if data.has("action_history"):
		for batch_data in data.action_history:
			var cells: Array[Vector2i] = []
			for pos in batch_data.get("cells", []):
				cells.append(Vector2i(pos.x, pos.y))
			ps.action_history.append({
				"type": batch_data.get("type", "delete"),
				"cells": cells,
				"auto": batch_data.get("auto", false),
				"operator_id": batch_data.get("operator_id", "")
			})
	elif data.has("deletion_history"):
		# Backward compat: convert old deletion_history to action_history
		for pos in data.deletion_history:
			ps.action_history.append({
				"type": "delete",
				"cells": [Vector2i(pos.x, pos.y)] as Array[Vector2i],
				"auto": false,
				"operator_id": ""
			})

	return ps
