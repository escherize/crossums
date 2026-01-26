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
		_:
			_send_error("unknown_query", "Unknown query: %s" % query, id)


func _handle_action(id: String, msg: Dictionary) -> void:
	var action: String = str(msg.get("action", ""))
	var params: Dictionary = msg.get("params", {})

	if typeof(params) != TYPE_DICTIONARY:
		params = {}

	var result := _execute_action(action, params)

	if result.has("error"):
		_send_error(result.get("error", "unknown"), result.get("message", ""), id)
	else:
		_send_response(id, result)


func _execute_action(action: String, params: Dictionary) -> Dictionary:
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
