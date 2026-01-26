extends Node
## TCP debug server for MCP integration.
## Allows external tools to query game state and perform actions.
## Only runs in debug builds or when explicitly enabled.

const PORT: int = 9999
const BIND_ADDRESS: String = "127.0.0.1"

var _server: TCPServer = null
var _connection: StreamPeerTCP = null
var _buffer: String = ""
var _enabled: bool = false

# API version for compatibility checking
const API_VERSION: String = "1.0.0"


func _ready() -> void:
	# Only start in debug builds or with explicit command line flag
	if OS.is_debug_build() or OS.has_feature("debug_server"):
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


func _execute_action(action: String, params: Dictionary):
	match action:
		"ping":
			return {}

		# Cell manipulation actions
		"delete_cell":
			return _action_delete_cell(params)
		"keep_cell":
			return _action_keep_cell(params)
		"restore_cell":
			return _action_restore_cell(params)

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
			return _action_new_puzzle(params)
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

		# Screenshot and utilities
		"screenshot":
			return await _action_screenshot(params)
		"wait_frames":
			return await _action_wait_frames(params)
		"wait_idle":
			return await _action_wait_idle(params)

		# Test recording
		"dump_test":
			return _action_dump_test(params)

		_:
			return {"error": "not_implemented", "message": "Action '%s' not yet implemented" % action}


# =============================================================================
# CELL MANIPULATION ACTIONS
# =============================================================================

func _action_delete_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	if cell_data.state != PuzzleState.CellState.ACTIVE:
		return {"error": "invalid_state", "message": "Cell at (%d, %d) is not active (current: %s)" % [row, col, _cell_state_to_string(cell_data.state)]}

	if puzzle_state.delete_cell(row, col):
		_refresh_puzzle_grid(main_scene)
		EventBus.cell_deleted.emit(row, col, cell_data.value)
		return {"cell": {"row": row, "col": col, "value": cell_data.value, "state": "deleted"}}
	else:
		return {"error": "delete_failed", "message": "Failed to delete cell at (%d, %d)" % [row, col]}


func _action_keep_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	if cell_data.state != PuzzleState.CellState.ACTIVE:
		return {"error": "invalid_state", "message": "Cell at (%d, %d) is not active (current: %s)" % [row, col, _cell_state_to_string(cell_data.state)]}

	if puzzle_state.keep_cell(row, col):
		_refresh_puzzle_grid(main_scene)
		EventBus.cell_kept.emit(row, col, cell_data.value)
		return {"cell": {"row": row, "col": col, "value": cell_data.value, "state": "kept"}}
	else:
		return {"error": "keep_failed", "message": "Failed to keep cell at (%d, %d)" % [row, col]}


func _action_restore_cell(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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
	else:
		return {"error": "restore_failed", "message": "Failed to restore cell at (%d, %d)" % [row, col]}


# =============================================================================
# UNDO/REDO ACTIONS
# =============================================================================

func _action_undo(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	if puzzle_state.deletion_history.is_empty():
		return {"error": "nothing_to_undo", "message": "No actions to undo"}

	var pos := puzzle_state.undo_last_deletion()
	if pos.x >= 0:
		_refresh_puzzle_grid(main_scene)
		var cell_data := puzzle_state.get_cell(pos.y, pos.x)
		return {
			"undone": {"row": pos.y, "col": pos.x, "value": cell_data.value},
			"remaining_undo_count": puzzle_state.deletion_history.size()
		}
	else:
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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
	else:
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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
		"valid": current_sum == target
	}


func _action_get_col_sum(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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
		"valid": current_sum == target
	}


func _action_check_complete(_params: Dictionary) -> Dictionary:
	## Quick check if puzzle is in a solved state
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

func _action_new_puzzle(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	# Get parameters
	var grid_size := int(params.get("size", params.get("grid_size", 3)))
	var seed_val := int(params.get("seed", 0))

	# Validate grid size
	if grid_size < 2 or grid_size > 9:
		return {"error": "invalid_size", "message": "Grid size must be between 2 and 9"}

	# Create puzzle config
	var config := PuzzleLogic.PuzzleConfig.new()
	config.grid_size = Vector2i(grid_size, grid_size)
	config.cells_to_delete_ratio = 0.5
	if seed_val != 0:
		config.puzzle_seed = seed_val

	# Generate new puzzle
	var new_puzzle := PuzzleLogic.generate_puzzle(config)

	# Update main scene
	main_scene.set("current_puzzle", new_puzzle)
	main_scene.set("puzzle_solved", false)

	# Reset timer tracking if available
	if main_scene.has_method("get") and main_scene.get("puzzle_start_time") != null:
		main_scene.set("puzzle_start_time", Time.get_ticks_msec())
		main_scene.set("restore_count", 0)

	# Reload grid visually
	var puzzle_grid = main_scene.get("puzzle_grid")
	if puzzle_grid and puzzle_grid.has_method("load_puzzle"):
		puzzle_grid.load_puzzle(new_puzzle)

	return {
		"seed": new_puzzle.puzzle_seed,
		"size": grid_size,
		"targets": {
			"rows": Array(new_puzzle.row_targets),
			"cols": Array(new_puzzle.col_targets)
		}
	}


func _action_restart_puzzle(_params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	# Reset the puzzle state
	puzzle_state.reset()

	# Reset game flags
	main_scene.set("puzzle_solved", false)

	# Reset timer tracking if available
	if main_scene.get("puzzle_start_time") != null:
		main_scene.set("puzzle_start_time", Time.get_ticks_msec())
		main_scene.set("restore_count", 0)

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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var row := int(params.get("row", -1))
	var col := int(params.get("col", -1))
	var state_str: String = str(params.get("state", "active"))

	if not _is_valid_cell(puzzle_state, row, col):
		return {"error": "invalid_cell", "message": "Invalid cell position: (%d, %d)" % [row, col]}

	var cell_data := puzzle_state.get_cell(row, col)
	var new_state := _string_to_cell_state(state_str)

	# Track in deletion history if changing to deleted
	if new_state == PuzzleState.CellState.DELETED and cell_data.state != PuzzleState.CellState.DELETED:
		puzzle_state.deletion_history.append(Vector2i(col, row))
	elif new_state != PuzzleState.CellState.DELETED and cell_data.state == PuzzleState.CellState.DELETED:
		# Remove from deletion history if restoring
		var pos := Vector2i(col, row)
		var idx := puzzle_state.deletion_history.rfind(pos)
		if idx >= 0:
			puzzle_state.deletion_history.remove_at(idx)

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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var cells_param = params.get("cells", [])
	if typeof(cells_param) != TYPE_ARRAY:
		return {"error": "invalid_params", "message": "cells must be a 2D array of state strings"}

	# Clear deletion history
	puzzle_state.deletion_history.clear()

	var rows_set := 0
	var cols_set := 0

	for row in range(mini(cells_param.size(), puzzle_state.grid_size.y)):
		var row_data = cells_param[row]
		if typeof(row_data) != TYPE_ARRAY:
			continue

		for col in range(mini(row_data.size(), puzzle_state.grid_size.x)):
			var state_str: String = str(row_data[col])
			var new_state := _string_to_cell_state(state_str)
			var cell_data := puzzle_state.get_cell(row, col)
			cell_data.state = new_state

			if new_state == PuzzleState.CellState.DELETED:
				puzzle_state.deletion_history.append(Vector2i(col, row))

			cols_set = maxi(cols_set, col + 1)
		rows_set = maxi(rows_set, row + 1)

	_refresh_puzzle_grid(main_scene)

	return {
		"rows_set": rows_set,
		"cols_set": cols_set,
		"message": "Grid state updated"
	}


func _action_apply_solution(_params: Dictionary) -> Dictionary:
	## Apply the known solution to the grid (delete all non-solution cells)
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var cells_deleted := 0

	for row in range(puzzle_state.grid_size.y):
		for col in range(puzzle_state.grid_size.x):
			var cell_data := puzzle_state.get_cell(row, col)
			if not cell_data.is_solution and cell_data.state == PuzzleState.CellState.ACTIVE:
				cell_data.state = PuzzleState.CellState.DELETED
				puzzle_state.deletion_history.append(Vector2i(col, row))
				cells_deleted += 1

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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var cells_cleared := 0

	for row in range(puzzle_state.grid_size.y):
		for col in range(puzzle_state.grid_size.x):
			var cell_data := puzzle_state.get_cell(row, col)
			if cell_data.state != PuzzleState.CellState.ACTIVE:
				cell_data.state = PuzzleState.CellState.ACTIVE
				cells_cleared += 1

	puzzle_state.deletion_history.clear()
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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
		"is_solution": cell_data.is_solution
	}


func _query_get_grid() -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	return _serialize_grid(puzzle_state)


func _query_get_targets() -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	return {
		"deletion_count": puzzle_state.deletion_history.size(),
		"deletions": _serialize_positions(puzzle_state.deletion_history),
		"can_undo": not puzzle_state.deletion_history.is_empty()
	}


func _query_get_config() -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")

	return {
		"grid_size": puzzle_state.grid_size.x if puzzle_state else 3,
		"api_version": API_VERSION,
		"debug_build": OS.is_debug_build()
	}


# =============================================================================
# ASSERTION HELPERS
# =============================================================================

func _action_assert_cell_state(params: Dictionary) -> Dictionary:
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"pass": false, "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"pass": false, "message": "No active puzzle"}

	var is_valid := puzzle_state.is_solved()
	return {
		"pass": not is_valid,
		"message": "Puzzle is invalid (as expected)" if not is_valid else "Puzzle is unexpectedly valid"
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
	else:
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


func _action_dump_test(params: Dictionary) -> Dictionary:
	## Dump current game state as a test case JSON
	var main_scene := _get_main_scene()
	if main_scene == null:
		return {"error": "no_game", "message": "Game not running"}

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
	if puzzle_state == null:
		return {"error": "no_puzzle", "message": "No active puzzle"}

	var test_name: String = str(params.get("name", "recorded_%d" % Time.get_unix_time_from_system()))
	var include_final_assert: bool = params.get("include_assert", true)

	# Build steps from deletion history
	var steps: Array = []
	for pos in puzzle_state.deletion_history:
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
		"validation": null
	}

	var main_scene := _get_main_scene()
	if main_scene == null:
		return state

	var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
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

	if main_scene.get("current_puzzle") != null:
		return "playing"

	return "menu"


func _get_main_scene() -> Node:
	var root := get_tree().root
	if root.get_child_count() == 0:
		return null

	# Main scene is the last child of root (after autoloads)
	for i in range(root.get_child_count() - 1, -1, -1):
		var child := root.get_child(i)
		if child.has_method("_generate_new_puzzle"):  # Duck-type check for main scene
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
			"deletion_count": puzzle_state.deletion_history.size(),
			"deletions": _serialize_positions(puzzle_state.deletion_history)
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
				"is_solution": cell_data.is_solution
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
		PuzzleState.CellState.KEPT:
			return "kept"
		PuzzleState.CellState.LOCKED:
			return "locked"
		_:
			return "unknown"


func _string_to_cell_state(state_str: String) -> PuzzleState.CellState:
	match state_str.to_lower():
		"active", "normal":
			return PuzzleState.CellState.ACTIVE
		"deleted":
			return PuzzleState.CellState.DELETED
		"kept":
			return PuzzleState.CellState.KEPT
		"locked":
			return PuzzleState.CellState.LOCKED
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
