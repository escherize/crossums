extends Node
## TCP debug server for MCP integration.
## Allows external tools to query game state and perform actions.
## Only runs in debug builds or when explicitly enabled.

const PORT: int = 9999
const BIND_ADDRESS: String = "127.0.0.1"
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const API_VERSION: String = "1.0.0"
const PuzzleGeneratorScript = preload("res://scripts/core/puzzle_generator.gd")

var _server: TCPServer = null
var _connection: StreamPeerTCP = null
var _buffer: String = ""
var _enabled: bool = false


func _ready() -> void:
	# Start TCP server only when CS_DEBUG_SERVER env var is set
	if GameConfig.is_test_mode():
		_start_server()


func _start_server() -> void:
	_server = TCPServer.new()
	var err := _server.listen(PORT, BIND_ADDRESS)
	if err == OK:
		_enabled = true
		print("[DebugServer] Listening on %s:%d" % [BIND_ADDRESS, PORT])
	else:
		push_error("[DebugServer] Failed to start server: %s" % error_string(err))
		_server = null


func _process(_delta: float) -> void:
	if not _enabled or _server == null:
		return

	_accept_connections()
	_handle_connection()


func _accept_connections() -> void:
	if _server.is_connection_available():
		# Close existing connection if any
		if _connection != null:
			_connection.disconnect_from_host()
			print("[DebugServer] Previous client disconnected")

		_connection = _server.take_connection()
		_buffer = ""
		print("[DebugServer] Client connected")


func _handle_connection() -> void:
	if _connection == null:
		return

	var status := _connection.get_status()

	match status:
		StreamPeerTCP.STATUS_CONNECTED:
			_read_data()
		StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
			print("[DebugServer] Client disconnected")
			_connection = null
			_buffer = ""


func _read_data() -> void:
	var available := _connection.get_available_bytes()
	if available > 0:
		var data := _connection.get_utf8_string(available)
		if data.length() > 0:
			_buffer += data
			_process_buffer()


func _process_buffer() -> void:
	# Process newline-delimited JSON messages
	while "\n" in _buffer:
		var idx := _buffer.find("\n")
		var line := _buffer.substr(0, idx)
		_buffer = _buffer.substr(idx + 1)

		line = line.strip_edges()
		if line.length() > 0:
			_handle_message(line)


func _handle_message(json_str: String) -> void:
	var json := JSON.new()
	var parse_result := json.parse(json_str)

	if parse_result != OK:
		_send_error("invalid_json", "Failed to parse JSON: %s" % json.get_error_message())
		return

	var msg: Dictionary = json.data
	if typeof(msg) != TYPE_DICTIONARY:
		_send_error("invalid_format", "Message must be a JSON object")
		return

	var id: String = str(msg.get("id", ""))
	var msg_type: String = str(msg.get("type", ""))

	match msg_type:
		"query":
			_handle_query(id, msg)
		"action":
			_handle_action(id, msg)
		_:
			_send_error("unknown_type", "Unknown message type: %s" % msg_type, id)


func _handle_query(id: String, msg: Dictionary) -> void:
	var query: String = str(msg.get("query", ""))
	var params: Dictionary = msg.get("params", {})
	if typeof(params) != TYPE_DICTIONARY:
		params = {}

	match query:
		"get_state":
			_send_response(id, {"data": _get_game_state()})
		"ping":
			_send_response(id, {})
		"get_version":
			_send_response(id, {
				"api_version": API_VERSION,
				"game_version": ProjectSettings.get_setting("application/config/version", "0.1.0")
			})
		"get_cell":
			_send_response(id, _query_get_cell(params))
		"get_grid":
			_send_response(id, _query_get_grid())
		"get_targets":
			_send_response(id, _query_get_targets())
		"get_history":
			_send_response(id, _query_get_history())
		"get_config":
			_send_response(id, _query_get_config())
		_:
			_send_error("unknown_query", "Unknown query: %s" % query, id)


func _handle_action(id: String, msg: Dictionary) -> void:
	var action: String = str(msg.get("action", ""))
	var params: Dictionary = msg.get("params", {})

	if typeof(params) != TYPE_DICTIONARY:
		params = {}

	var result = await _execute_action(action, params)

	if result.has("error"):
		_send_error(result.get("error", "unknown"), result.get("message", ""), id)
	else:
		_send_response(id, result)


# gdlint: disable=max-returns
func _execute_action(action: String, params: Dictionary):
	match action:
		"ping":
			return {}

		# Cell manipulation actions
		"delete_cell":
			return _action_delete_cell(params)
		"circle_cell":
			return _action_circle_cell(params)
		"uncircle_cell":
			return _action_uncircle_cell(params)
		"restore_cell":
			return _action_restore_cell(params)
		"click_cell":
			return _action_click_cell(params)
		"set_circle_mode":
			return _action_set_circle_mode(params)

		# Undo/redo actions
		"undo":
			return _action_undo(params)
		"redo":
			return _action_redo(params)

		# Validation actions
		"validate":
			return _action_validate(params)
		"submit":
			return _action_submit(params)
		"get_row_sum":
			return _action_get_row_sum(params)
		"get_col_sum":
			return _action_get_col_sum(params)
		"check_complete":
			return _action_check_complete(params)

		# Puzzle management actions
		"new_puzzle":
			return await _action_new_puzzle(params)
		"load_board":
			return await _action_load_board(params)
		"restart_puzzle":
			return _action_restart_puzzle(params)

		# Testing state manipulation
		"set_cell_state":
			return _action_set_cell_state(params)
		"set_grid_state":
			return _action_set_grid_state(params)
		"apply_solution":
			return _action_apply_solution(params)
		"clear_all_marks":
			return _action_clear_all_marks(params)

		# Assertion helpers
		"assert_cell_state":
			return _action_assert_cell_state(params)
		"assert_row_sum":
			return _action_assert_row_sum(params)
		"assert_col_sum":
			return _action_assert_col_sum(params)
		"assert_valid":
			return _action_assert_valid(params)
		"assert_invalid":
			return _action_assert_invalid(params)
		"assert_puzzle_complete":
			return _action_assert_puzzle_complete(params)
		"assert_no_targets_satisfied":
			return _action_assert_no_targets_satisfied(params)

		# Screenshot and utilities
		"screenshot":
			return await _action_screenshot(params)
		"wait_frames":
			return await _action_wait_frames(params)
		"wait_idle":
			return await _action_wait_idle(params)
		"check_auto_actions":
			return _action_check_auto_actions(params)

		# Test recording
		"dump_test":
			return _action_dump_test(params)

		# State management (Sprint 1)
		"get_full_state":
			return _action_get_full_state(params)
		"set_full_state":
			return _action_set_full_state(params)
		"get_run_state":
			return _action_get_run_state(params)
		"set_run_state":
			return _action_set_run_state(params)

		# Operator management (Sprint 2)
		"add_operator":
			return _action_add_operator(params)
		"remove_operator":
			return _action_remove_operator(params)
		"list_operators":
			return _action_list_operators(params)
		"clear_operators":
			return _action_clear_operators(params)

		# Scoring (Sprint 2)
		"get_score":
			return _action_get_score(params)

		# Run flow (Sprint 4)
		"start_run":
			return await _action_start_run(params)
		"get_run_info":
			return _action_get_run_info(params)
		"set_stage":
			return _action_set_stage(params)
		"complete_puzzle":
			return await _action_complete_puzzle(params)
		"continue_result":
			return await _action_continue_result(params)
		"continue_shop":
			return await _action_continue_shop(params)
		"return_to_title":
			return await _action_return_to_title(params)

		"check_solvable":
			return _action_check_solvable(params)

		"test_generator":
			return _action_test_generator(params)

		"analyze_puzzle":
			return _action_analyze_puzzle(params)

		_:
			return {"error": "not_implemented", "message": "Action '%s' not yet implemented" % action}


# =============================================================================
# CELL MANIPULATION ACTIONS
# =============================================================================

func _action_delete_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	if cell_data.state != PuzzleState.CellState.ACTIVE:
		return {"error": "invalid_state", "message": "Cell at (%d, %d) is not active (current: %s)" % [row, col, _cell_state_to_string(cell_data.state)]}

	# Delete the cell (no solvability check - timer is the fail condition)
	if puzzle_state.delete_cell(row, col):
		_refresh_puzzle_grid(main_scene)
		EventBus.cell_deleted.emit(row, col, cell_data.value)
		return {"cell": {"row": row, "col": col, "value": cell_data.value, "state": "deleted"}}
	return {"error": "delete_failed", "message": "Failed to delete cell at (%d, %d)" % [row, col]}


func _action_circle_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	if cell_data.state != PuzzleState.CellState.ACTIVE:
		return {"error": "invalid_state", "message": "Cell at (%d, %d) is not active (current: %s)" % [row, col, _cell_state_to_string(cell_data.state)]}

	# Circle the cell (no validation - circling is a player tool)
	if puzzle_state.circle_cell(row, col):
		_refresh_puzzle_grid(main_scene)
		EventBus.cell_circled.emit(row, col)
		return {"cell": {"row": row, "col": col, "value": cell_data.value, "state": "circled"}}
	return {"error": "circle_failed", "message": "Failed to circle cell at (%d, %d)" % [row, col]}


func _action_uncircle_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	if cell_data.state != PuzzleState.CellState.CIRCLED:
		return {"error": "invalid_state", "message": "Cell at (%d, %d) is not circled (current: %s)" % [row, col, _cell_state_to_string(cell_data.state)]}

	if puzzle_state.uncircle_cell(row, col):
		_refresh_puzzle_grid(main_scene)
		EventBus.cell_uncircled.emit(row, col)
		return {"cell": {"row": row, "col": col, "value": cell_data.value, "state": "active"}}
	return {"error": "uncircle_failed", "message": "Failed to uncircle cell at (%d, %d)" % [row, col]}


func _action_restore_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	if cell_data.state != PuzzleState.CellState.DELETED:
		return {"error": "invalid_state", "message": "Cell at (%d, %d) is not deleted (current: %s)" % [row, col, _cell_state_to_string(cell_data.state)]}

	if puzzle_state.restore_cell(row, col):
		_refresh_puzzle_grid(main_scene)
		EventBus.cell_restored.emit(row, col, cell_data.value)
		return {"cell": {"row": row, "col": col, "value": cell_data.value, "state": "active"}}
	return {"error": "restore_failed", "message": "Failed to restore cell at (%d, %d)" % [row, col]}


func _action_click_cell(params: Dictionary) -> Dictionary:
	## Simulate clicking a cell (respects circle mode if active)
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_grid = main_scene.get("puzzle_grid")
	if puzzle_grid == null:
		return {"error": "no_grid", "message": "No puzzle grid found"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	# Use simulate_click which respects circle mode state
	if puzzle_grid.has_method("simulate_click"):
		puzzle_grid.simulate_click(row, col)
	else:
		return {"error": "no_method", "message": "puzzle_grid.simulate_click not found"}

	# Return updated cell state
	var cell_data := puzzle_state.get_cell(row, col)
	return {
		"cell": {
			"row": row,
			"col": col,
			"value": cell_data.value,
			"state": _cell_state_to_string(cell_data.state)
		},
		"circle_mode": puzzle_grid.get("circle_mode_active") if puzzle_grid else false
	}


func _action_set_circle_mode(params: Dictionary) -> Dictionary:
	## Enable or disable circle mode on the puzzle grid
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_grid = main_scene.get("puzzle_grid")
	if puzzle_grid == null:
		return {"error": "no_grid", "message": "No puzzle grid found"}

	var active: bool = params.get("active", false)

	if puzzle_grid.has_method("set_circle_mode"):
		puzzle_grid.set_circle_mode(active)
	else:
		return {"error": "no_method", "message": "puzzle_grid.set_circle_mode not found"}

	return {
		"circle_mode": active,
		"message": "Circle mode %s" % ("enabled" if active else "disabled")
	}


# =============================================================================
# UNDO/REDO ACTIONS
# =============================================================================

func _action_undo(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	if not puzzle_state.can_undo():
		return {"error": "nothing_to_undo", "message": "No actions to undo"}

	var result := puzzle_state.undo_last_action()
	if not result.is_empty() and not result.cells.is_empty():
		_refresh_puzzle_grid(main_scene)
		# Return info about first cell in batch (for backward compat)
		var first_pos: Vector2i = result.cells[0]
		var cell_data := puzzle_state.get_cell(first_pos.y, first_pos.x)
		return {
			"undone": {"row": first_pos.y, "col": first_pos.x, "value": cell_data.value},
			"cells_undone": result.cells.size(),
			"batch_type": result.type,
			"was_auto": result.auto,
			"remaining_undo_count": puzzle_state.get_action_count()
		}
	return {"error": "undo_failed", "message": "Failed to undo"}


func _action_redo(_params: Dictionary) -> Dictionary:
	# Note: Current implementation doesn't support redo
	# The PuzzleState only tracks deletion history, not a full undo/redo stack
	return {"error": "not_supported", "message": "Redo is not yet implemented in the game"}


# =============================================================================
# VALIDATION ACTIONS
# =============================================================================

func _action_validate(_params: Dictionary) -> Dictionary:
	## Check if puzzle is solved without any side effects
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var result := PuzzleLogic.validate(puzzle_state)

	return {
		"valid": result.is_valid,
		"row_results": _serialize_validation_results(result.row_results),
		"col_results": _serialize_validation_results(result.col_results),
		"valid_rows": result.get_valid_row_count(),
		"valid_cols": result.get_valid_col_count(),
		"total_rows": puzzle_state.grid_size.y,
		"total_cols": puzzle_state.grid_size.x
	}


func _action_submit(_params: Dictionary) -> Dictionary:
	## Submit puzzle for validation (triggers game logic)
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	# Check if already solved
	if main_scene.get("puzzle_solved"):
		return {"error": "already_solved", "message": "Puzzle has already been solved"}

	var result := PuzzleLogic.validate(puzzle_state)

	if result.is_valid:
		# Mark puzzle as solved in main scene
		main_scene.set("puzzle_solved", true)
		EventBus.puzzle_submitted.emit()
		EventBus.puzzle_validated.emit(true, result.row_results, result.col_results)

		return {
			"success": true,
			"valid": true,
			"message": "Puzzle solved!"
		}

	EventBus.puzzle_submitted.emit()
	EventBus.puzzle_validated.emit(false, result.row_results, result.col_results)

	return {
		"success": false,
		"valid": false,
		"row_results": _serialize_validation_results(result.row_results),
		"col_results": _serialize_validation_results(result.col_results),
		"message": "Puzzle not solved"
	}


func _action_get_row_sum(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	if row < 0 or row >= puzzle_state.grid_size.y:
		return {"error": "invalid_row", "message": "Invalid row index: %d" % row}

	var current_sum := puzzle_state.get_current_row_sum(row)
	var target: int = puzzle_state.row_targets[row]

	return {
		"row": row,
		"current": current_sum,
		"target": target,
		"delta": current_sum - target,
		"valid": current_sum == target,
		"circle_solved": puzzle_state.is_row_solved_by_circles(row)
	}


func _action_get_col_sum(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var col := int(params.get("col", -1))
	if col < 0 or col >= puzzle_state.grid_size.x:
		return {"error": "invalid_col", "message": "Invalid column index: %d" % col}

	var current_sum := puzzle_state.get_current_col_sum(col)
	var target: int = puzzle_state.col_targets[col]

	return {
		"col": col,
		"current": current_sum,
		"target": target,
		"delta": current_sum - target,
		"valid": current_sum == target,
		"circle_solved": puzzle_state.is_col_solved_by_circles(col)
	}


func _action_check_complete(_params: Dictionary) -> Dictionary:
	## Quick check if puzzle is in a solved state
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	return {
		"complete": puzzle_state.is_solved(),
		"already_submitted": main_scene.get("puzzle_solved") == true
	}


func _serialize_validation_results(results: Array) -> Array:
	var serialized := []
	for r in results:
		serialized.append({
			"index": r.index,
			"target": r.target,
			"actual": r.actual,
			"valid": r.valid
		})
	return serialized


# =============================================================================
# PUZZLE MANAGEMENT ACTIONS
# =============================================================================

func _action_new_puzzle(params: Dictionary):
	# Get parameters first
	var grid_size := int(params.get("size", params.get("grid_size", 3)))
	var seed_val := int(params.get("seed", 0))

	# Validate grid size
	if grid_size < 2 or grid_size > 9:
		return {"error": "invalid_size", "message": "Grid size must be between 2 and 9"}

	# Create puzzle config
	var config := PuzzleLogic.PuzzleConfig.new()
	config.grid_size = Vector2i(grid_size, grid_size)
	if seed_val != 0:
		config.puzzle_seed = seed_val

	# If no main scene, start a minimal run and transition
	var main_scene := _get_main_scene()
	if main_scene == null:
		# Reset and start run (use seed if provided for determinism)
		GameState.reset()
		GameState.start_new_run(seed_val)
		# Generate our specific puzzle BEFORE transitioning (overrides run's default)
		GameState.start_new_puzzle(config)

		# Use change_scene_to_file instead of to_packed (Godot workaround)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		# Wait for scene transition
		for i in range(20):
			await get_tree().process_frame
			main_scene = _get_main_scene()
			if main_scene != null:
				break
		if main_scene == null:
			return {"error": "no_game", "message": "Failed to start game"}
	else:
		# Main scene exists - just generate new puzzle
		GameState.start_new_puzzle(config)

	main_scene.set("puzzle_solved", false)

	# Reset timer tracking if available
	if main_scene.has_method("get") and main_scene.get("puzzle_start_time") != null:
		main_scene.set("puzzle_start_time", Time.get_ticks_msec())

	# Reload grid visually
	var puzzle_grid = main_scene.get("puzzle_grid")
	if puzzle_grid and puzzle_grid.has_method("load_puzzle"):
		puzzle_grid.load_puzzle(GameState.puzzle)

	return {
		"seed": GameState.puzzle.puzzle_seed,
		"size": grid_size,
		"targets": {
			"rows": Array(GameState.puzzle.row_targets),
			"cols": Array(GameState.puzzle.col_targets)
		}
	}


func _action_load_board(params: Dictionary):
	## Load a puzzle from a predefined board state (for deterministic tests)
	## Expects: size, row_targets, col_targets, cells (2D array with value)
	var main_scene := _get_main_scene()
	if main_scene == null:
		# Start a run and transition to main scene
		RunManager.start_run()
		# Use change_scene_to_file instead of to_packed (Godot workaround)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		for i in range(20):
			await get_tree().process_frame
			main_scene = _get_main_scene()
			if main_scene != null:
				break
		if main_scene == null:
			return {"error": "no_game", "message": "Failed to start game"}

	var grid_size: int = params.get("size", 3)
	var row_targets: Array = params.get("row_targets", [])
	var col_targets: Array = params.get("col_targets", [])
	var cells: Array = params.get("cells", [])
	var seed_val: int = params.get("seed", 0)

	if row_targets.size() != grid_size or col_targets.size() != grid_size:
		return {"error": "invalid_targets", "message": "Target arrays must match grid size"}

	if cells.size() != grid_size:
		return {"error": "invalid_cells", "message": "Cells array must match grid size"}

	# Create puzzle state manually
	var puzzle_state = PuzzleState.new(Vector2i(grid_size, grid_size))
	puzzle_state.puzzle_seed = seed_val

	# Set targets
	puzzle_state.row_targets.clear()
	puzzle_state.col_targets.clear()
	for t in row_targets:
		puzzle_state.row_targets.append(int(t))
	for t in col_targets:
		puzzle_state.col_targets.append(int(t))

	# Set cells
	for row in range(grid_size):
		var row_data: Array = cells[row] if row < cells.size() else []
		for col in range(grid_size):
			var cell_data = row_data[col] if col < row_data.size() else {}
			var cell = puzzle_state.get_cell(row, col)
			cell.value = int(cell_data.get("value", 0))
			cell.state = PuzzleState.CellState.ACTIVE

	# Set as current puzzle
	GameState.puzzle = puzzle_state
	main_scene.set("puzzle_solved", false)

	# Wait for any pending puzzle generation from _ready() to complete
	for i in range(5):
		await get_tree().process_frame

	# Force our puzzle state (in case _ready() overwrote it)
	GameState.puzzle = puzzle_state

	# Reload grid visually
	var puzzle_grid = main_scene.get("puzzle_grid")
	if puzzle_grid and puzzle_grid.has_method("load_puzzle"):
		puzzle_grid.load_puzzle(GameState.puzzle)

	return {
		"seed": seed_val,
		"size": grid_size,
		"targets": {
			"rows": Array(puzzle_state.row_targets),
			"cols": Array(puzzle_state.col_targets)
		}
	}


func _action_restart_puzzle(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	# Reset the puzzle state
	puzzle_state.reset()

	# Reset game flags
	main_scene.set("puzzle_solved", false)

	# Reset timer tracking if available
	if main_scene.get("puzzle_start_time") != null:
		main_scene.set("puzzle_start_time", Time.get_ticks_msec())

	# Refresh visual grid
	_refresh_puzzle_grid(main_scene)

	return {
		"seed": puzzle_state.puzzle_seed,
		"size": puzzle_state.grid_size.x,
		"message": "Puzzle reset to initial state"
	}


# =============================================================================
# TESTING STATE MANIPULATION
# =============================================================================

func _action_set_cell_state(params: Dictionary) -> Dictionary:
	## Directly set a cell's state (for test setup)
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))
	var state_str: String = str(params.get("state", "active"))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	var new_state := _string_to_cell_state(state_str)
	var old_state := cell_data.state

	# Use proper state change methods to maintain history
	if new_state == PuzzleState.CellState.DELETED and old_state != PuzzleState.CellState.DELETED:
		if old_state == PuzzleState.CellState.CIRCLED:
			puzzle_state.uncircle_cell(row, col)
		puzzle_state.delete_cell(row, col)
	elif new_state == PuzzleState.CellState.ACTIVE and old_state == PuzzleState.CellState.DELETED:
		puzzle_state.restore_cell(row, col)
	elif new_state == PuzzleState.CellState.ACTIVE and old_state == PuzzleState.CellState.CIRCLED:
		puzzle_state.uncircle_cell(row, col)
	elif new_state == PuzzleState.CellState.CIRCLED and old_state == PuzzleState.CellState.ACTIVE:
		puzzle_state.circle_cell(row, col)
	else:
		# Direct state change for edge cases
		cell_data.state = new_state
	_refresh_puzzle_grid(main_scene)

	return {
		"cell": {"row": row, "col": col, "value": cell_data.value, "state": _cell_state_to_string(new_state)}
	}


func _action_set_grid_state(params: Dictionary) -> Dictionary:
	## Set entire grid state at once (for test setup)
	## Expects params.cells as 2D array of state strings: [["active", "deleted"], ["kept", "active"]]
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var cells_param = params.get("cells", [])
	if typeof(cells_param) != TYPE_ARRAY:
		return {"error": "invalid_params", "message": "cells must be a 2D array of state strings"}

	# Reset puzzle to fresh state then apply new states
	puzzle_state.reset()

	var rows_set := 0
	var cols_set := 0

	for row in range(mini(cells_param.size(), puzzle_state.grid_size.y)):
		var row_data = cells_param[row]
		if typeof(row_data) != TYPE_ARRAY:
			continue

		for col in range(mini(row_data.size(), puzzle_state.grid_size.x)):
			var state_str: String = str(row_data[col])
			var new_state := _string_to_cell_state(state_str)

			if new_state == PuzzleState.CellState.DELETED:
				puzzle_state.delete_cell(row, col)
			elif new_state == PuzzleState.CellState.CIRCLED:
				puzzle_state.circle_cell(row, col)
			# ACTIVE is default after reset, no action needed

			cols_set = maxi(cols_set, col + 1)
		rows_set = maxi(rows_set, row + 1)

	_refresh_puzzle_grid(main_scene)

	return {
		"rows_set": rows_set,
		"cols_set": cols_set,
		"message": "Grid state updated"
	}


func _action_apply_solution(_params: Dictionary) -> Dictionary:
	## Apply a valid solution to the grid (delete cells that can be deleted)
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var cells_deleted := 0

	# Iteratively delete cells that can be deleted without breaking solvability
	var made_progress := true
	while made_progress and not puzzle_state.is_solved():
		made_progress = false
		for row in range(puzzle_state.grid_size.y):
			for col in range(puzzle_state.grid_size.x):
				var cell_data := puzzle_state.get_cell(row, col)
				if cell_data.state != PuzzleState.CellState.ACTIVE:
					continue
				# Check if deleting this cell still leaves a valid solution
				cell_data.state = PuzzleState.CellState.DELETED
				if PuzzleLogic.has_any_solution(puzzle_state):
					# Restore then use proper delete to track history
					cell_data.state = PuzzleState.CellState.ACTIVE
					puzzle_state.delete_cell(row, col)
					cells_deleted += 1
					made_progress = true
				else:
					cell_data.state = PuzzleState.CellState.ACTIVE

	_refresh_puzzle_grid(main_scene)

	return {
		"cells_deleted": cells_deleted,
		"is_solved": puzzle_state.is_solved(),
		"message": "Solution applied"
	}


func _action_clear_all_marks(_params: Dictionary) -> Dictionary:
	## Reset all cells to active state
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var cells_cleared := puzzle_state.get_total_cells() - puzzle_state.get_kept_count()
	cells_cleared += puzzle_state.get_kept_count()  # Count circled too
	puzzle_state.reset()
	_refresh_puzzle_grid(main_scene)

	return {
		"cells_cleared": cells_cleared,
		"message": "All marks cleared"
	}


# =============================================================================
# QUERY HANDLERS
# =============================================================================

func _query_get_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	return {
		"row": row,
		"col": col,
		"value": cell_data.value,
		"state": _cell_state_to_string(cell_data.state),
	}


func _query_get_grid() -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	return _serialize_grid(puzzle_state)


func _query_get_targets() -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	return {
		"rows": Array(puzzle_state.row_targets),
		"cols": Array(puzzle_state.col_targets),
		"current_row_sums": _get_current_row_sums(puzzle_state),
		"current_col_sums": _get_current_col_sums(puzzle_state)
	}


func _query_get_history() -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	return {
		"deletion_count": puzzle_state.get_deleted_count(),
		"action_count": puzzle_state.get_action_count(),
		"deletions": _serialize_positions(puzzle_state.get_deletion_history()),
		"can_undo": puzzle_state.can_undo()
	}


func _query_get_config() -> Dictionary:
	return {
		"grid_size": GameState.puzzle.grid_size.x if GameState.puzzle else 3,
		"api_version": API_VERSION,
		"debug_build": OS.is_debug_build(),
		"has_run": GameState.run != null
	}


# =============================================================================
# ASSERTION HELPERS
# =============================================================================

func _action_assert_cell_state(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))
	var expected_state: String = str(params.get("state", ""))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"pass": false, "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	var actual_state := _cell_state_to_string(cell_data.state)

	var passed := actual_state == expected_state.to_lower()
	return {
		"pass": passed,
		"expected": expected_state,
		"actual": actual_state,
		"message": "Cell (%d,%d) state: expected '%s', got '%s'" % [row, col, expected_state, actual_state] if not passed else "OK"
	}


func _action_assert_row_sum(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var expected := int(params.get("expected", -1))

	if row < 0 or row >= puzzle_state.grid_size.y:
		return {"pass": false, "message": "Invalid row index: %d" % row}

	var actual := puzzle_state.get_current_row_sum(row)
	var passed := actual == expected

	return {
		"pass": passed,
		"expected": expected,
		"actual": actual,
		"message": "Row %d sum: expected %d, got %d" % [row, expected, actual] if not passed else "OK"
	}


func _action_assert_col_sum(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	var col := int(params.get("col", -1))
	var expected := int(params.get("expected", -1))

	if col < 0 or col >= puzzle_state.grid_size.x:
		return {"pass": false, "message": "Invalid column index: %d" % col}

	var actual := puzzle_state.get_current_col_sum(col)
	var passed := actual == expected

	return {
		"pass": passed,
		"expected": expected,
		"actual": actual,
		"message": "Column %d sum: expected %d, got %d" % [col, expected, actual] if not passed else "OK"
	}


func _action_assert_valid(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	var is_valid := puzzle_state.is_solved()
	return {
		"pass": is_valid,
		"message": "Puzzle is valid" if is_valid else "Puzzle is not valid"
	}


func _action_assert_invalid(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	var is_valid := puzzle_state.is_solved()
	return {
		"pass": not is_valid,
		"message": "Puzzle is invalid (as expected)" if not is_valid else "Puzzle is unexpectedly valid"
	}


func _action_assert_puzzle_complete(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var is_complete: bool = main_scene.get("puzzle_solved") == true
	return {
		"pass": is_complete,
		"message": "Puzzle is complete" if is_complete else "Puzzle is not complete"
	}


func _action_assert_no_targets_satisfied(_params: Dictionary) -> Dictionary:
	## Assert that NO row or column targets are satisfied at start.
	## This ensures puzzles require at least one deletion per row/column.
	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	# Check rows: sum of ALL cell values should NOT equal target
	for row in range(puzzle_state.grid_size.y):
		var row_sum = 0
		for col in range(puzzle_state.grid_size.x):
			row_sum += puzzle_state.get_cell(row, col).value
		if row_sum == puzzle_state.row_targets[row]:
			return {
				"pass": false,
				"message": "Row %d is already satisfied (sum=%d)" % [row, row_sum]
			}

	# Check columns: sum of ALL cell values should NOT equal target
	for col in range(puzzle_state.grid_size.x):
		var col_sum = 0
		for row in range(puzzle_state.grid_size.y):
			col_sum += puzzle_state.get_cell(row, col).value
		if col_sum == puzzle_state.col_targets[col]:
			return {
				"pass": false,
				"message": "Col %d is already satisfied (sum=%d)" % [col, col_sum]
			}

	return {
		"pass": true,
		"message": "No targets satisfied at start (puzzle requires deletions)"
	}


# =============================================================================
# SCREENSHOT AND UTILITIES
# =============================================================================

func _action_screenshot(params: Dictionary) -> Dictionary:
	var path: String = str(params.get("path", "/tmp/crossums_capture.png"))

	# Wait for the frame to be drawn
	await RenderingServer.frame_post_draw

	var viewport := get_viewport()
	var img := viewport.get_texture().get_image()

	var err := img.save_png(path)
	if err == OK:
		return {"path": path, "width": img.get_width(), "height": img.get_height()}
	return {"error": "save_failed", "message": "Failed to save screenshot: %s" % error_string(err)}


func _action_wait_frames(params: Dictionary) -> Dictionary:
	var count := int(params.get("count", 1))
	count = clampi(count, 1, 300)  # Max 5 seconds at 60fps

	for i in range(count):
		await get_tree().process_frame

	return {"frames_waited": count}


func _action_wait_idle(_params: Dictionary) -> Dictionary:
	# Wait for any animations/tweens to complete
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout  # Brief pause for animations

	return {"message": "Idle"}


func _action_check_auto_actions(_params: Dictionary) -> Dictionary:
	## Manually trigger operator auto-action check (for testing)
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	if main_scene.has_method("_check_operator_auto_actions"):
		main_scene._check_operator_auto_actions()
		return {"message": "Auto-actions checked"}
	return {"error": "not_supported", "message": "Main scene lacks auto-action method"}


func _action_dump_test(params: Dictionary) -> Dictionary:
	## Dump current game state as a test case JSON
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var test_name: String = str(params.get("name", "recorded_%d" % Time.get_unix_time_from_system()))
	var include_final_assert: bool = params.get("include_assert", true)

	# Build steps from deletion history
	var steps: Array = []
	for pos in puzzle_state.get_deletion_history():
		steps.append({
			"action": "delete_cell",
			"params": {"row": pos.y, "col": pos.x}
		})

	# Optionally add final assertion
	if include_final_assert:
		if puzzle_state.is_solved():
			steps.append({"assert": "assert_valid"})
		else:
			steps.append({"assert": "assert_invalid"})

	var test_case := {
		"name": test_name,
		"description": "Recorded from gameplay",
		"setup": {
			"size": puzzle_state.grid_size.x,
			"seed": puzzle_state.puzzle_seed
		},
		"steps": steps
	}

	return {"test": test_case}


# =============================================================================
# STATE MANAGEMENT (Sprint 1)
# =============================================================================

func _action_get_full_state(_params: Dictionary) -> Dictionary:
	return {"state": GameState.serialize()}


func _action_set_full_state(params: Dictionary) -> Dictionary:
	if not params.has("state"):
		return {"error": "missing_state", "message": "state parameter required"}

	if GameState.deserialize(params.state):
		# Refresh UI
		var main_scene = _get_main_scene()
		if main_scene and main_scene.has_method("refresh_from_state"):
			main_scene.refresh_from_state()
		return {"success": true}
	return {"error": "deserialize_failed", "message": "Failed to deserialize state"}


func _action_get_run_state(_params: Dictionary) -> Dictionary:
	if GameState.run == null:
		return {"run": null}
	return {"run": GameState.run.serialize()}


func _action_set_run_state(params: Dictionary) -> Dictionary:
	if params.has("run") and params.run != null:
		GameState.run = GameState.RunStateScript.deserialize(params.run)
	else:
		GameState.run = null
	return {"success": true}


# =============================================================================
# OPERATOR MANAGEMENT (Sprint 2)
# =============================================================================

func _action_add_operator(params: Dictionary) -> Dictionary:
	var id: String = params.get("id", "")
	if id.is_empty():
		return {"error": "missing_id", "message": "Operator id required"}

	var op = OperatorRegistry.create(id)
	if op == null:
		return {"error": "unknown_operator", "message": "Unknown operator: %s" % id}

	if GameState.add_operator(op):
		return {"success": true, "operator": op.serialize(), "count": GameState.operators.size()}
	return {"error": "slots_full", "message": "Operator slots full (max %d)" % GameState.MAX_OPERATORS}


func _action_remove_operator(params: Dictionary) -> Dictionary:
	var index: int = params.get("index", -1)
	var op = GameState.remove_operator(index)
	if op:
		return {"success": true, "removed": op.serialize(), "count": GameState.operators.size()}
	return {"error": "invalid_index", "message": "Invalid operator index: %d" % index}


func _action_list_operators(_params: Dictionary) -> Dictionary:
	return {
		"operators": GameState.operators.map(func(o): return {
			"id": o.id,
			"name": o.display_name,
			"description": o.description,
			"rarity": o.rarity,
			"price": o.price,
		}),
		"count": GameState.operators.size(),
		"max": GameState.MAX_OPERATORS,
		"available": OperatorRegistry.get_all_ids(),
	}


func _action_clear_operators(_params: Dictionary) -> Dictionary:
	var count = GameState.operators.size()
	GameState.operators.clear()
	return {"cleared": count}


func _action_get_score(params: Dictionary) -> Dictionary:
	## Calculate current score without submitting
	## Optional params: time_mult (override)
	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	# Get time multiplier - use override or calculate from main scene
	var time_mult: float = params.get("time_mult", 1.0)

	# Try to get actual value from main scene if not overridden
	if not params.has("time_mult"):
		var main_scene = _get_main_scene()
		if main_scene:
			var tm = main_scene.get("time_multiplier")
			if tm != null:
				time_mult = tm

	var breakdown = ScoringEngine.calculate_score(puzzle_state, time_mult, GameState.operators)

	return {
		"final_score": breakdown.final_score,
		"base_points": breakdown.base_points,
		"kept_bonus": breakdown.kept_bonus,
		"kept_count": breakdown.kept_count,
		"operator_bonus": breakdown.operator_bonus,
		"operator_mult": breakdown.operator_mult,
		"operator_details": breakdown.operator_details,
		"time_multiplier": breakdown.time_multiplier,
		"money_bonus": breakdown.money_bonus,
	}


# =============================================================================
# RUN FLOW (Sprint 4)
# =============================================================================

func _action_start_run(params: Dictionary) -> Dictionary:
	## Start a new run from the beginning
	## Optional params: seed (int) - for deterministic puzzle generation
	var run_seed: int = params.get("seed", 0)
	RunManager.start_run(run_seed)

	# Navigate to main scene if not already there
	var main_scene := _get_main_scene()
	if main_scene == null:
		# Use change_scene_to_file instead of to_packed (Godot workaround)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		for i in range(20):
			await get_tree().process_frame
			main_scene = _get_main_scene()
			if main_scene != null:
				break

	# Wait a frame for state to settle
	await get_tree().process_frame

	if GameState.run == null:
		return {"error": "run_failed", "message": "Failed to start run"}

	return {
		"success": true,
		"run": {
			"stage": GameState.run.stage,
			"puzzle_index": GameState.run.puzzle_index,
			"money": GameState.run.money,
			"total_score": GameState.run.total_score,
			"run_seed": GameState.run.run_seed
		},
		"state": RunManager.State.keys()[RunManager.current_state]
	}


func _action_get_run_info(_params: Dictionary) -> Dictionary:
	## Get current run state information
	if GameState.run == null:
		return {
			"active": false,
			"run": null,
			"state": RunManager.State.keys()[RunManager.current_state]
		}

	return {
		"active": RunManager.is_run_active(),
		"run": {
			"stage": GameState.run.stage,
			"puzzle_index": GameState.run.puzzle_index,
			"money": GameState.run.money,
			"total_score": GameState.run.total_score,
			"stage_score": GameState.run.stage_score,
			"operators": GameState.operators.map(func(o): return o.id)
		},
		"state": RunManager.State.keys()[RunManager.current_state],
		"stage_config": _get_stage_config_info()
	}


func _get_stage_config_info() -> Variant:
	var config = RunManager.get_current_stage_config()
	if config == null:
		return null
	return {
		"stage": config.stage,
		"puzzle_index": config.puzzle_index,
		"grid_size": config.grid_size,
		"score_target": config.score_target,
		"min_cell_value": config.min_cell_value,
		"max_cell_value": config.max_cell_value
	}


func _action_set_stage(params: Dictionary) -> Dictionary:
	## Set stage and puzzle_index for testing
	if GameState.run == null:
		return {"error": "no_run", "message": "No active run"}

	var stage: int = params.get("stage", GameState.run.stage)
	var puzzle_index: int = params.get("puzzle_index", GameState.run.puzzle_index)

	stage = clampi(stage, 1, 9)
	puzzle_index = clampi(puzzle_index, 0, 2)

	GameState.run.stage = stage
	GameState.run.puzzle_index = puzzle_index
	EventBus.state_changed.emit()

	return {
		"success": true,
		"stage": GameState.run.stage,
		"puzzle_index": GameState.run.puzzle_index
	}


func _action_complete_puzzle(params: Dictionary) -> Dictionary:
	## Complete the current puzzle with a given score
	## This triggers RunManager.on_puzzle_complete() which handles win/lose logic
	if GameState.run == null:
		return {"error": "no_run", "message": "No active run"}

	if RunManager.current_state != RunManager.State.PUZZLE_ACTIVE:
		return {"error": "wrong_state", "message": "Not in PUZZLE_ACTIVE state (current: %s)" % RunManager.State.keys()[RunManager.current_state]}

	var score: int = params.get("score", 0)
	var old_stage: int = GameState.run.stage
	var old_puzzle: int = GameState.run.puzzle_index

	# Get target from stage config
	var config = RunManager.get_current_stage_config()
	var target: int = config.score_target if config else 0

	# Stage-level gating: only boss puzzle (index 2) can fail
	var is_boss: bool = old_puzzle == 2
	var stage_total: int = GameState.run.stage_score + score
	var passed: bool = not is_boss or stage_total >= target

	# Trigger the completion
	RunManager.on_puzzle_complete(score)

	# Wait for state to settle
	await get_tree().process_frame

	return {
		"success": true,
		"passed": passed,
		"score": score,
		"target": target,
		"old_stage": old_stage,
		"old_puzzle": old_puzzle,
		"new_stage": GameState.run.stage if GameState.run else old_stage,
		"new_puzzle": GameState.run.puzzle_index if GameState.run else old_puzzle,
		"state": RunManager.State.keys()[RunManager.current_state]
	}


func _action_continue_result(_params: Dictionary) -> Dictionary:
	## Continue from result popup to next puzzle or shop
	if RunManager.current_state != RunManager.State.PUZZLE_RESULT:
		return {"error": "wrong_state", "message": "Not in PUZZLE_RESULT state (current: %s)" % RunManager.State.keys()[RunManager.current_state]}

	RunManager.continue_from_result()

	# Wait for state to settle
	await get_tree().process_frame

	return {
		"success": true,
		"state": RunManager.State.keys()[RunManager.current_state],
		"stage": GameState.run.stage if GameState.run else 0,
		"puzzle_index": GameState.run.puzzle_index if GameState.run else 0
	}


func _action_continue_shop(_params: Dictionary) -> Dictionary:
	## Continue from shop to next puzzle
	if RunManager.current_state != RunManager.State.SHOP:
		return {"error": "wrong_state", "message": "Not in SHOP state (current: %s)" % RunManager.State.keys()[RunManager.current_state]}

	RunManager.continue_from_shop()

	# Wait for state to settle
	await get_tree().process_frame

	return {
		"success": true,
		"state": RunManager.State.keys()[RunManager.current_state],
		"stage": GameState.run.stage if GameState.run else 0,
		"puzzle_index": GameState.run.puzzle_index if GameState.run else 0
	}


func _action_return_to_title(_params: Dictionary) -> Dictionary:
	## Return to title screen and reset state (like Try Again button)
	RunManager.return_to_title()

	# Actually change to title scene to fully reset UI
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")

	# Wait for scene transition
	for i in range(10):
		await get_tree().process_frame

	return {
		"success": true,
		"state": RunManager.State.keys()[RunManager.current_state],
		"run_active": GameState.run != null,
		"puzzle_active": GameState.puzzle != null,
		"operators_count": GameState.operators.size()
	}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _is_valid_cell(puzzle_state: PuzzleState, row: int, col: int) -> bool:
	return row >= 0 and row < puzzle_state.grid_size.y and col >= 0 and col < puzzle_state.grid_size.x


func _refresh_puzzle_grid(main_scene: Node) -> void:
	var puzzle_grid = main_scene.get("puzzle_grid")
	if puzzle_grid and puzzle_grid.has_method("refresh"):
		puzzle_grid.refresh()


func _get_game_state() -> Dictionary:
	var state := {
		"api_version": API_VERSION,
		"phase": _get_game_phase(),
		"puzzle": null,
		"validation": null,
		"run": GameState.run.serialize() if GameState.run else null
	}

	var main_scene := _get_main_scene()
	if main_scene == null:
		return state

	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		state.phase = "no_puzzle"
		return state

	# Serialize puzzle data
	state.puzzle = _serialize_puzzle(puzzle_state)

	# Add validation if puzzle has been solved
	if main_scene.get("puzzle_solved"):
		state.phase = "solved"
		state.validation = _get_validation_data(puzzle_state)

	return state


func _get_game_phase() -> String:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return "unknown"

	if main_scene.get("puzzle_solved"):
		return "solved"

	if GameState.puzzle != null:
		return "playing"

	return "menu"


func _get_main_scene() -> Node:
	var root := get_tree().root
	if root.get_child_count() == 0:
		return null

	# Main scene is the last child of root (after autoloads)
	for i in range(root.get_child_count() - 1, -1, -1):
		var child := root.get_child(i)
		if child.has_method("refresh_from_state"):  # Duck-type check for main scene
			return child

	return null


func _serialize_puzzle(puzzle_state: PuzzleState) -> Dictionary:
	var grid := _serialize_grid(puzzle_state)

	return {
		"seed": puzzle_state.puzzle_seed,
		"grid": grid,
		"targets": {
			"rows": Array(puzzle_state.row_targets),
			"cols": Array(puzzle_state.col_targets)
		},
		"selection": null,  # No persistent selection in current implementation
		"history": {
			"deletion_count": puzzle_state.get_deleted_count(),
			"action_count": puzzle_state.get_action_count(),
			"deletions": _serialize_positions(puzzle_state.get_deletion_history()),
			"can_undo": puzzle_state.can_undo()
		},
		"sums": {
			"rows": _get_current_row_sums(puzzle_state),
			"cols": _get_current_col_sums(puzzle_state)
		}
	}


func _serialize_grid(puzzle_state: PuzzleState) -> Dictionary:
	var cells := []

	for row in range(puzzle_state.grid_size.y):
		var row_cells := []
		for col in range(puzzle_state.grid_size.x):
			var cell_data := puzzle_state.get_cell(row, col)
			row_cells.append({
				"value": cell_data.value,
				"state": _cell_state_to_string(cell_data.state),
			})
		cells.append(row_cells)

	return {
		"rows": puzzle_state.grid_size.y,
		"cols": puzzle_state.grid_size.x,
		"cells": cells
	}


func _cell_state_to_string(state: PuzzleState.CellState) -> String:
	match state:
		PuzzleState.CellState.ACTIVE:
			return "active"
		PuzzleState.CellState.DELETED:
			return "deleted"
		PuzzleState.CellState.CIRCLED:
			return "circled"
		_:
			return "unknown"


func _string_to_cell_state(state_str: String) -> PuzzleState.CellState:
	match state_str.to_lower():
		"active", "normal":
			return PuzzleState.CellState.ACTIVE
		"deleted":
			return PuzzleState.CellState.DELETED
		"circled":
			return PuzzleState.CellState.CIRCLED
		_:
			return PuzzleState.CellState.ACTIVE


func _serialize_positions(positions: Array) -> Array:
	var result := []
	for pos in positions:
		if pos is Vector2i:
			result.append({"row": pos.y, "col": pos.x})
	return result


func _get_current_row_sums(puzzle_state: PuzzleState) -> Array:
	var sums := []
	for row in range(puzzle_state.grid_size.y):
		sums.append(puzzle_state.get_current_row_sum(row))
	return sums


func _get_current_col_sums(puzzle_state: PuzzleState) -> Array:
	var sums := []
	for col in range(puzzle_state.grid_size.x):
		sums.append(puzzle_state.get_current_col_sum(col))
	return sums


func _get_validation_data(puzzle_state: PuzzleState) -> Dictionary:
	var row_results := []
	var col_results := []
	var row_sums := []
	var col_sums := []

	for row in range(puzzle_state.grid_size.y):
		var current := puzzle_state.get_current_row_sum(row)
		var target: int = puzzle_state.row_targets[row]
		row_sums.append(current)
		row_results.append(current == target)

	for col in range(puzzle_state.grid_size.x):
		var current := puzzle_state.get_current_col_sum(col)
		var target: int = puzzle_state.col_targets[col]
		col_sums.append(current)
		col_results.append(current == target)

	var success := row_results.all(func(r: bool) -> bool: return r) and col_results.all(func(r: bool) -> bool: return r)

	return {
		"success": success,
		"row_results": row_results,
		"col_results": col_results,
		"row_sums": row_sums,
		"col_sums": col_sums
	}


func _action_check_solvable(_params: Dictionary) -> Dictionary:
	## Debug action to check if puzzle is solvable
	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var has_any = PuzzleLogic.has_any_solution(puzzle_state)

	return {
		"has_any_solution": has_any,
		"grid_size": puzzle_state.grid_size.x
	}


func _action_test_generator(params: Dictionary) -> Dictionary:
	## Test the single-solution puzzle generator
	var grid_size: int = params.get("size", 3)
	var count: int = params.get("count", 5)

	var results: Array = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(count):
		var start_time = Time.get_ticks_msec()
		var puzzle = PuzzleGeneratorScript.generate_single_solution(
			Vector2i(grid_size, grid_size),
			rng
		)
		var gen_time = Time.get_ticks_msec() - start_time

		if puzzle == null:
			results.append({"error": "generation_failed"})
			continue

		var analysis = PuzzleGeneratorScript.analyze(puzzle)
		# All puzzles should have exactly 1 solution now
		var is_single = analysis.solution_count == 1

		results.append({
			"seed": puzzle.puzzle_seed,
			"solution_count": analysis.solution_count,
			"diversity": analysis.diversity,
			"is_single_solution": is_single,
			"gen_time_ms": gen_time,
			"row_targets": Array(puzzle.row_targets),
			"col_targets": Array(puzzle.col_targets)
		})

	var success_count = results.filter(func(r): return r.get("is_single_solution", false)).size()

	return {
		"grid_size": grid_size,
		"tested": count,
		"single_solution_count": success_count,
		"success_rate": float(success_count) / count if count > 0 else 0.0,
		"results": results
	}


func _action_analyze_puzzle(_params: Dictionary) -> Dictionary:
	## Analyze current puzzle for solution count
	var puzzle_state: PuzzleState = GameState.puzzle
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var analysis = PuzzleGeneratorScript.analyze(puzzle_state)
	var solutions = PuzzleGeneratorScript.find_all_solutions(puzzle_state, 10)

	# Format solutions for output
	var formatted_solutions: Array = []
	for sol in solutions:
		var cells: Array = []
		for pos in sol:
			cells.append({"row": pos.y, "col": pos.x})
		formatted_solutions.append(cells)

	return {
		"solution_count": analysis.solution_count,
		"diversity": analysis.diversity,
		"unique_values": analysis.unique_values,
		"capped": analysis.capped,
		"solutions": formatted_solutions
	}


func _send_response(id: String, data: Dictionary) -> void:
	var response := {"id": id, "ok": true}
	response.merge(data)
	_send_json(response)


func _send_error(code: String, message: String, id: String = "") -> void:
	_send_json({
		"id": id,
		"ok": false,
		"error": code,
		"message": message
	})


func _send_json(data: Dictionary) -> void:
	if _connection == null or _connection.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return

	var json_str := JSON.stringify(data) + "\n"
	_connection.put_utf8_string(json_str)


func _exit_tree() -> void:
	if _connection != null:
		_connection.disconnect_from_host()
		_connection = null

	if _server != null:
		_server.stop()
		_server = null

	print("[DebugServer] Shut down")
