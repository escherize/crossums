# MCP Interactive Tools for Crossums

This document describes the plan for adding interactive capabilities to the Godot MCP server, enabling Claude to play and test the Crossums puzzle game through semantic-level actions.

## Goals

1. **Fully programmable** - The entire game is controllable via API (no mouse/keyboard needed)
2. **Testable** - API supports writing automated tests for game logic and state
3. **Deterministic** - Puzzles can be seeded or loaded from data for reproducible tests
4. **Inspectable** - Full access to internal game state, not just player-visible state
5. **Claude-friendly** - Semantic actions at the domain level, structured responses

## Quick Reference

| Category | Actions |
|----------|---------|
| **Lifecycle** | `start_run`, `end_run`, `get_run_state`, `set_lives`, `set_score` |
| **Puzzle** | `new_puzzle`, `load_puzzle`, `restart_puzzle`, `get_solution` |
| **Cells** | `select_cell`, `delete_cell`, `keep_cell`, `restore_cell`, `undo`, `redo` |
| **Testing** | `set_cell_state`, `set_grid_state`, `apply_solution`, `clear_all_marks` |
| **Validation** | `submit`, `validate`, `get_row_sum`, `get_col_sum`, `check_complete` |
| **Queries** | `get_state`, `get_cell`, `get_grid`, `get_targets`, `get_history` |
| **Scoring** | `get_score_breakdown`, `get_money`, `set_money`, `add_operator` |
| **Assertions** | `assert_cell_state`, `assert_row_sum`, `assert_valid`, `assert_phase` |
| **Utility** | `screenshot`, `wait_idle`, `ping` |

## Architecture

```
┌─────────────────┐         ┌─────────────────────────────────────┐
│  Claude Code    │         │         Godot Game Process          │
│                 │         │                                     │
│  ┌───────────┐  │  JSON   │  ┌─────────────┐   ┌─────────────┐ │
│  │ MCP Server│◄─┼────────►│  │DebugServer  │◄──│ Game Logic  │ │
│  │ (Node.js) │  │  TCP    │  │ (autoload)  │   │             │ │
│  └───────────┘  │ :9999   │  └─────────────┘   └─────────────┘ │
│                 │         │         │                │         │
│                 │         │         ▼                ▼         │
│                 │         │  ┌─────────────┐   ┌───────────┐   │
│                 │         │  │  EventBus   │   │PuzzleState│   │
│                 │         │  └─────────────┘   └───────────┘   │
└─────────────────┘         └─────────────────────────────────────┘
```

## Protocol

### Transport

- TCP socket on `127.0.0.1:9999`
- Newline-delimited JSON messages
- Request-response pattern (synchronous from MCP's perspective)

### Message Format

**Request (MCP → Game):**
```json
{"id": "req_001", "type": "action", "action": "select_cell", "params": {"row": 1, "col": 2}}
{"id": "req_002", "type": "query", "query": "get_state"}
{"id": "req_003", "type": "action", "action": "screenshot", "params": {"path": "/tmp/capture.png"}}
```

**Response (Game → MCP):**
```json
{"id": "req_001", "ok": true}
{"id": "req_002", "ok": true, "data": {...game state...}}
{"id": "req_003", "ok": true, "path": "/tmp/capture.png"}
{"id": "req_004", "ok": false, "error": "No cell selected"}
```

## Game State Schema

The `get_state` query returns the complete game state:

```json
{
  "phase": "playing",           // "menu" | "playing" | "validated" | "paused" | "game_over"

  "run": {                      // null if no active run
    "seed": 12345,              // For reproducibility
    "stage": 2,
    "puzzle_num": 1,
    "is_boss": false,
    "lives": 3,
    "max_lives": 3,
    "total_score": 4500,
    "money": 150,
    "operators": ["mult_2x", "bonus_row"],
    "difficulty": 2
  },

  "puzzle": {                   // null if no active puzzle
    "seed": 67890,              // Puzzle-specific seed
    "grid": {
      "rows": 3,
      "cols": 3,
      "cells": [
        [
          {"value": 5, "state": "normal"},
          {"value": 3, "state": "deleted"},
          {"value": 7, "state": "kept"}
        ]
        // ... more rows
      ]
    },
    "targets": {
      "rows": [8, 12, 7],
      "cols": [9, 11, 6]
    },
    "selection": {"row": 1, "col": 2},  // null if none
    "history": {
      "actions": [
        {"type": "delete", "row": 0, "col": 1, "timestamp": 1234567890}
      ],
      "undo_stack_size": 1,
      "redo_stack_size": 0
    }
  },

  "validation": {               // null if not yet validated
    "success": false,
    "row_results": [true, false, true],
    "col_results": [true, true, false],
    "row_sums": [8, 15, 7],     // Actual sums achieved
    "col_sums": [9, 10, 6]
  },

  "scoring": {                  // Last score calculation
    "base_score": 1000,
    "time_bonus": 250,
    "precision_bonus": 100,
    "operator_effects": [
      {"id": "mult_2x", "effect": "multiply", "value": 2}
    ],
    "total": 2700
  },

  "config": {
    "grid_type": "3x3",
    "time_limit": null,         // null = no limit
    "hints_enabled": true
  }
}
```

## Complete API Reference

The API is organized into categories. All actions return `{ok: true, ...data}` on success or `{ok: false, error: string, message: string}` on failure.

---

### Game Lifecycle

Control the overall game state, runs, and sessions.

| Action | Params | Description |
|--------|--------|-------------|
| `start_run` | `{grid_type?, difficulty?, seed?}` | Start a new run with optional seed for determinism |
| `end_run` | `{}` | End current run |
| `get_run_state` | `{}` | Get run metadata (stage, lives, score, etc.) |
| `advance_stage` | `{}` | Move to next stage (for testing) |
| `set_lives` | `{lives: int}` | Set remaining lives (testing) |
| `set_score` | `{score: int}` | Set current score (testing) |
| `trigger_game_over` | `{}` | Force game over state (testing) |

---

### Puzzle Management

Load, generate, and configure puzzles.

| Action | Params | Description |
|--------|--------|-------------|
| `new_puzzle` | `{difficulty?, seed?}` | Generate new puzzle, optionally seeded |
| `load_puzzle` | `{puzzle: PuzzleData}` | Load puzzle from exact specification |
| `get_puzzle_seed` | `{}` | Get seed of current puzzle (if generated) |
| `restart_puzzle` | `{}` | Reset puzzle to initial state |
| `get_solution` | `{}` | Get the known solution (for test verification) |

**PuzzleData format:**
```json
{
  "grid": [[5, 3, 4], [2, 7, 1], [6, 2, 8]],
  "row_targets": [8, 8, 8],
  "col_targets": [7, 10, 9],
  "solution": {
    "kept": [[0,0], [0,1], [1,0], ...],
    "deleted": [[0,2], [1,2], ...]
  }
}
```

---

### Cell Manipulation

Player-level actions on cells.

| Action | Params | Description |
|--------|--------|-------------|
| `select_cell` | `{row, col}` | Select a cell in the grid |
| `delete_cell` | `{row?, col?}` | Delete selected cell, or specify cell directly |
| `keep_cell` | `{row?, col?}` | Keep/lock selected cell, or specify directly |
| `restore_cell` | `{row?, col?}` | Restore deleted cell to normal |
| `clear_selection` | `{}` | Deselect current cell |
| `undo` | `{}` | Undo last action |
| `redo` | `{}` | Redo undone action |

---

### State Manipulation (Testing)

Directly manipulate game state for test setup.

| Action | Params | Description |
|--------|--------|-------------|
| `set_cell_state` | `{row, col, state}` | Set cell to "normal", "deleted", or "kept" |
| `set_grid_state` | `{cells: [[state, ...], ...]}` | Set entire grid state at once |
| `clear_all_marks` | `{}` | Reset all cells to normal |
| `apply_solution` | `{}` | Apply the known solution to the grid |
| `set_selection` | `{row, col}` or `null` | Set selection without triggering UI |

---

### Validation & Submission

| Action | Params | Description |
|--------|--------|-------------|
| `submit` | `{}` | Submit puzzle for validation |
| `validate` | `{}` | Check validity without submitting (no side effects) |
| `get_row_sum` | `{row: int}` | Get current sum of non-deleted cells in row |
| `get_col_sum` | `{col: int}` | Get current sum of non-deleted cells in column |
| `check_complete` | `{}` | Check if puzzle is in a solved state |

---

### Queries

Read-only inspection of game state.

| Query | Params | Description |
|-------|--------|-------------|
| `get_state` | `{}` | Full game state (see schema below) |
| `get_cell` | `{row, col}` | State of a specific cell |
| `get_grid` | `{}` | Just the grid portion of state |
| `get_targets` | `{}` | Row and column targets |
| `get_history` | `{}` | Action history for undo/redo |
| `get_config` | `{}` | Current game configuration |

---

### Scoring & Economy

| Action | Params | Description |
|--------|--------|-------------|
| `get_score_breakdown` | `{}` | Detailed scoring calculation |
| `get_money` | `{}` | Current money amount |
| `set_money` | `{amount: int}` | Set money (testing) |
| `add_operator` | `{operator_id: string}` | Add operator to inventory (testing) |
| `remove_operator` | `{operator_id: string}` | Remove operator (testing) |
| `get_operators` | `{}` | List active operators |

---

### Utility

| Action | Params | Description |
|--------|--------|-------------|
| `screenshot` | `{path: string}` | Capture viewport to PNG file |
| `wait_frames` | `{count: int}` | Wait N frames (for animations) |
| `wait_idle` | `{}` | Wait until no pending animations/transitions |
| `get_version` | `{}` | API and game version info |
| `ping` | `{}` | Connection test, returns `{ok: true}` |

---

### Test Assertions (Convenience)

These return `{ok: true, pass: bool, message?: string}` for test frameworks.

| Action | Params | Description |
|--------|--------|-------------|
| `assert_cell_state` | `{row, col, state}` | Assert cell is in expected state |
| `assert_row_sum` | `{row, expected}` | Assert row sum equals expected |
| `assert_col_sum` | `{col, expected}` | Assert column sum equals expected |
| `assert_valid` | `{}` | Assert current state is a valid solution |
| `assert_invalid` | `{}` | Assert current state is NOT valid |
| `assert_phase` | `{phase: string}` | Assert game is in expected phase |

## MCP Tool Definitions

### `game_connect`

Establish connection to running game's debug server.

```typescript
{
  name: 'game_connect',
  description: 'Connect to the running Godot game debug server',
  inputSchema: {
    type: 'object',
    properties: {
      port: { type: 'number', description: 'Port number (default: 9999)' }
    }
  }
}
```

### `game_state`

Query the current game state.

```typescript
{
  name: 'game_state',
  description: 'Get the current game state including grid, targets, and selection',
  inputSchema: {
    type: 'object',
    properties: {}
  }
}
```

### `game_action`

Perform a game action.

```typescript
{
  name: 'game_action',
  description: 'Perform a game action (select_cell, delete_cell, keep_cell, submit, etc.)',
  inputSchema: {
    type: 'object',
    properties: {
      action: {
        type: 'string',
        enum: ['select_cell', 'delete_cell', 'keep_cell', 'restore_cell',
               'clear_selection', 'submit', 'undo', 'new_puzzle', 'restart']
      },
      params: {
        type: 'object',
        description: 'Action parameters (e.g., {row: 1, col: 2} for select_cell)'
      }
    },
    required: ['action']
  }
}
```

### `game_screenshot`

Capture a screenshot for visual verification.

```typescript
{
  name: 'game_screenshot',
  description: 'Capture a screenshot of the current game state',
  inputSchema: {
    type: 'object',
    properties: {
      path: {
        type: 'string',
        description: 'Path to save screenshot (default: /tmp/crossums_capture.png)'
      }
    }
  }
}
```

## Implementation Plan

### Phase 1: Game-Side Debug Server

**File:** `godot_app/autoload/debug_server.gd`

```gdscript
extends Node

signal command_received(command: Dictionary)

var server: TCPServer
var connection: StreamPeerTCP
var buffer: String = ""

const PORT = 9999

func _ready() -> void:
    if OS.is_debug_build() or OS.has_feature("debug_server"):
        start_server()

func start_server() -> void:
    server = TCPServer.new()
    var err = server.listen(PORT, "127.0.0.1")
    if err == OK:
        print("[DebugServer] Listening on port ", PORT)
    else:
        push_error("[DebugServer] Failed to start: ", err)

func _process(_delta: float) -> void:
    if server == null:
        return

    # Accept new connections
    if server.is_connection_available():
        connection = server.take_connection()
        print("[DebugServer] Client connected")

    # Handle existing connection
    if connection and connection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        var available = connection.get_available_bytes()
        if available > 0:
            buffer += connection.get_utf8_string(available)
            process_buffer()

func process_buffer() -> void:
    # Process newline-delimited JSON
    while "\n" in buffer:
        var idx = buffer.find("\n")
        var line = buffer.substr(0, idx)
        buffer = buffer.substr(idx + 1)

        if line.strip_edges().length() > 0:
            handle_message(line)

func handle_message(json_str: String) -> void:
    var json = JSON.new()
    if json.parse(json_str) != OK:
        send_error("invalid_json", "Failed to parse JSON")
        return

    var msg = json.data
    var id = msg.get("id", "")

    match msg.get("type"):
        "query":
            handle_query(id, msg)
        "action":
            handle_action(id, msg)
        _:
            send_error("unknown_type", "Unknown message type", id)

func handle_query(id: String, msg: Dictionary) -> void:
    match msg.get("query"):
        "get_state":
            send_response(id, {"data": get_game_state()})
        _:
            send_error("unknown_query", "Unknown query", id)

func handle_action(id: String, msg: Dictionary) -> void:
    var action = msg.get("action", "")
    var params = msg.get("params", {})

    var result = execute_action(action, params)
    if result.has("error"):
        send_error(result.error, result.get("message", ""), id)
    else:
        send_response(id, result)

func execute_action(action: String, params: Dictionary) -> Dictionary:
    # Dispatch to appropriate handler
    # ... implementation details below

func get_game_state() -> Dictionary:
    # Build state from PuzzleState, PuzzleGrid, etc.
    # ... implementation details below

func send_response(id: String, data: Dictionary) -> void:
    var response = {"id": id, "ok": true}
    response.merge(data)
    send_json(response)

func send_error(code: String, message: String, id: String = "") -> void:
    send_json({"id": id, "ok": false, "error": code, "message": message})

func send_json(data: Dictionary) -> void:
    if connection and connection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        var json_str = JSON.stringify(data) + "\n"
        connection.put_utf8_string(json_str)
```

**Tasks:**
1. Create `debug_server.gd` autoload
2. Register in `project.godot`
3. Implement `get_game_state()` by reading from existing game systems
4. Implement `execute_action()` by calling existing game methods/signals
5. Add screenshot capture using viewport texture

### Phase 2: Game State Integration

Connect DebugServer to existing game systems:

```gdscript
# In debug_server.gd

func get_game_state() -> Dictionary:
    var puzzle_grid = get_tree().get_first_node_in_group("puzzle_grid")
    var puzzle_state = puzzle_grid.puzzle_state if puzzle_grid else null

    if not puzzle_state:
        return {"error": "no_active_puzzle"}

    return {
        "phase": get_game_phase(),
        "grid": serialize_grid(puzzle_state),
        "targets": {
            "rows": puzzle_state.row_targets,
            "cols": puzzle_state.col_targets
        },
        "selection": get_current_selection(),
        "validation": get_validation_results(),
        "score": get_score_info()
    }

func serialize_grid(state: PuzzleState) -> Dictionary:
    var cells = []
    for row in range(state.grid_size.y):
        var row_cells = []
        for col in range(state.grid_size.x):
            row_cells.append({
                "value": state.get_cell_value(row, col),
                "state": state.get_cell_state(row, col),  # "normal", "deleted", "kept"
                "position": {"row": row, "col": col}
            })
        cells.append(row_cells)

    return {
        "rows": state.grid_size.y,
        "cols": state.grid_size.x,
        "cells": cells
    }
```

**Tasks:**
1. Add node groups or references for DebugServer to find game objects
2. Expose necessary state from `PuzzleState` (may need new getters)
3. Implement action handlers that call `EventBus` signals or direct methods

### Phase 3: MCP Server Extension

**File:** `/Users/bcm/dv/godot-mcp/src/index.ts`

Add new tool handlers and TCP client logic:

```typescript
// Add to GodotServer class

private gameConnection: net.Socket | null = null;
private pendingRequests: Map<string, {resolve: Function, reject: Function}> = new Map();
private requestCounter: number = 0;
private responseBuffer: string = "";

private async connectToGame(port: number = 9999): Promise<boolean> {
  return new Promise((resolve, reject) => {
    if (this.gameConnection?.readyState === 'open') {
      resolve(true);
      return;
    }

    this.gameConnection = new net.Socket();

    this.gameConnection.on('connect', () => {
      this.logDebug('Connected to game debug server');
      resolve(true);
    });

    this.gameConnection.on('data', (data) => {
      this.responseBuffer += data.toString();
      this.processResponseBuffer();
    });

    this.gameConnection.on('error', (err) => {
      this.logDebug(`Game connection error: ${err.message}`);
      reject(err);
    });

    this.gameConnection.on('close', () => {
      this.gameConnection = null;
    });

    this.gameConnection.connect(port, '127.0.0.1');
  });
}

private processResponseBuffer(): void {
  while (this.responseBuffer.includes('\n')) {
    const idx = this.responseBuffer.indexOf('\n');
    const line = this.responseBuffer.substring(0, idx);
    this.responseBuffer = this.responseBuffer.substring(idx + 1);

    try {
      const response = JSON.parse(line);
      const pending = this.pendingRequests.get(response.id);
      if (pending) {
        this.pendingRequests.delete(response.id);
        if (response.ok) {
          pending.resolve(response);
        } else {
          pending.reject(new Error(response.message || response.error));
        }
      }
    } catch (e) {
      this.logDebug(`Failed to parse response: ${line}`);
    }
  }
}

private async sendGameCommand(type: string, payload: any): Promise<any> {
  if (!this.gameConnection) {
    await this.connectToGame();
  }

  const id = `req_${++this.requestCounter}`;
  const message = JSON.stringify({id, type, ...payload}) + '\n';

  return new Promise((resolve, reject) => {
    this.pendingRequests.set(id, {resolve, reject});
    this.gameConnection!.write(message);

    // Timeout after 5 seconds
    setTimeout(() => {
      if (this.pendingRequests.has(id)) {
        this.pendingRequests.delete(id);
        reject(new Error('Request timeout'));
      }
    }, 5000);
  });
}
```

**Tasks:**
1. Add `net` import for TCP client
2. Implement connection management (connect, reconnect, disconnect)
3. Implement request/response correlation
4. Add tool handlers: `handleGameConnect`, `handleGameState`, `handleGameAction`, `handleGameScreenshot`
5. Register new tools in `setupToolHandlers`
6. Build and test

### Phase 4: Screenshot Integration

**Game side:**
```gdscript
func capture_screenshot(path: String) -> Dictionary:
    await RenderingServer.frame_post_draw
    var viewport = get_viewport()
    var img = viewport.get_texture().get_image()
    var err = img.save_png(path)
    if err == OK:
        return {"path": path}
    else:
        return {"error": "save_failed", "message": "Failed to save screenshot"}
```

**MCP side:**
- `game_screenshot` tool returns the path
- Claude uses `Read` tool to view the image

## Testing Strategy

### Manual Testing

1. Start game with `run_project`
2. Call `game_connect` to establish connection
3. Call `game_state` to verify state serialization
4. Call `game_action` with various actions
5. Verify state changes with `game_state`
6. Test `game_screenshot` and view with `Read`

### Automated Testing

```gdscript
# tests/test_debug_server.gd
extends GutTest

func test_state_serialization():
    var state = DebugServer.get_game_state()
    assert_has(state, "grid")
    assert_has(state, "targets")
    assert_eq(state.grid.rows, 3)

func test_select_cell_action():
    var result = DebugServer.execute_action("select_cell", {"row": 0, "col": 0})
    assert_true(result.ok)
    var state = DebugServer.get_game_state()
    assert_eq(state.selection.row, 0)
    assert_eq(state.selection.col, 0)
```

## Testing Patterns

### Test Structure

Tests use the API to:
1. **Arrange** - Set up specific game state
2. **Act** - Perform actions
3. **Assert** - Verify expected outcomes

### Example: Unit Test for Row Sum Validation

```python
# Test that row sum validation works correctly

# Arrange: Load a known puzzle
game.action("load_puzzle", {
    "grid": [[5, 3, 4], [2, 7, 1], [6, 2, 8]],
    "row_targets": [8, 8, 8],
    "col_targets": [7, 10, 9]
})

# Act: Delete cells to make row 0 sum to 8 (5+3=8, delete 4)
game.action("delete_cell", {"row": 0, "col": 2})

# Assert
result = game.action("assert_row_sum", {"row": 0, "expected": 8})
assert result["pass"] == True

result = game.action("get_row_sum", {"row": 0})
assert result["sum"] == 8
```

### Example: Integration Test for Puzzle Completion

```python
# Test full puzzle solve flow

# Arrange
game.action("load_puzzle", {
    "grid": [[5, 3, 4], [2, 7, 1], [6, 2, 8]],
    "row_targets": [8, 8, 8],
    "col_targets": [7, 10, 9],
    "solution": {
        "deleted": [[0, 2], [1, 1], [2, 0]]
    }
})

# Act: Apply the solution
game.action("apply_solution")
game.action("submit")

# Assert
state = game.query("get_state")
assert state["validation"]["success"] == True
assert state["phase"] == "validated"
```

### Example: Scoring System Test

```python
# Test that scoring calculates correctly

# Arrange
game.action("start_run", {"seed": 42})
game.action("set_score", {"score": 0})
game.action("add_operator", {"operator_id": "mult_2x"})

# Load and solve puzzle
game.action("load_puzzle", {"grid": [[1, 2], [3, 4]], ...})
game.action("apply_solution")
game.action("submit")

# Assert
breakdown = game.query("get_score_breakdown")
assert breakdown["base_score"] == 1000
assert breakdown["operator_effects"][0]["id"] == "mult_2x"
assert breakdown["total"] == 2000  # Base * 2x multiplier
```

### Example: Edge Case Test

```python
# Test undo/redo at boundaries

# Arrange
game.action("load_puzzle", {...})

# Act & Assert: Undo with empty stack
result = game.action("undo")
assert result["ok"] == False
assert result["error"] == "nothing_to_undo"

# Make a change, then undo
game.action("delete_cell", {"row": 0, "col": 0})
state_after_delete = game.query("get_cell", {"row": 0, "col": 0})
assert state_after_delete["state"] == "deleted"

game.action("undo")
state_after_undo = game.query("get_cell", {"row": 0, "col": 0})
assert state_after_undo["state"] == "normal"

# Redo
game.action("redo")
state_after_redo = game.query("get_cell", {"row": 0, "col": 0})
assert state_after_redo["state"] == "deleted"
```

### Example: Deterministic Puzzle Generation

```python
# Test that seeded puzzles are reproducible

seed = 12345

# Generate puzzle twice with same seed
game.action("new_puzzle", {"seed": seed})
state1 = game.query("get_state")

game.action("new_puzzle", {"seed": seed})
state2 = game.query("get_state")

# Should be identical
assert state1["puzzle"]["grid"] == state2["puzzle"]["grid"]
assert state1["puzzle"]["targets"] == state2["puzzle"]["targets"]
```

### Example: Game Over Flow

```python
# Test that losing all lives triggers game over

# Arrange
game.action("start_run", {"seed": 42})
game.action("set_lives", {"lives": 1})

# Act: Fail a puzzle
game.action("load_puzzle", {...})
game.action("delete_cell", {"row": 0, "col": 0})  # Wrong move
game.action("submit")

# Assert
state = game.query("get_state")
assert state["phase"] == "game_over"
assert state["run"]["lives"] == 0
```

---

## Example Claude Interaction

```
Claude: Let me check the current game state.
[calls game_state]

Response:
{
  "phase": "playing",
  "puzzle": {
    "grid": {
      "cells": [
        [{"value": 5, "state": "normal"}, {"value": 3, "state": "normal"}, {"value": 4, "state": "normal"}],
        [{"value": 2, "state": "normal"}, {"value": 7, "state": "normal"}, {"value": 1, "state": "normal"}],
        [{"value": 6, "state": "normal"}, {"value": 2, "state": "normal"}, {"value": 8, "state": "normal"}]
      ]
    },
    "targets": {"rows": [8, 8, 8], "cols": [7, 10, 9]}
  }
}

Claude: I need row 0 to sum to 8. Currently 5+3+4=12, so I need to delete 4.
[calls game_action with {action: "delete_cell", params: {row: 0, col: 2}}]

Claude: Let me verify the change.
[calls game_action with {action: "assert_row_sum", params: {row: 0, expected: 8}}]

Response: {"ok": true, "pass": true}

Claude: Row 0 now sums to 8. Correct! Let me continue solving...
```

## Security Considerations

1. **Debug-only** - Server only starts in debug builds or with explicit flag
2. **Localhost-only** - Binds to 127.0.0.1, not accessible from network
3. **No file system access** - Screenshot path is validated/sanitized
4. **No code execution** - Only predefined actions are allowed

## Design Principles

### 1. Complete Coverage

Every game action the player can take should be exposed via API. If something can be done via mouse/keyboard, it should be doable via API.

### 2. State Inspection > Screenshot Parsing

Always prefer structured state queries over parsing screenshots. Screenshots are for human verification, not programmatic logic.

### 3. Determinism by Default

Tests should be reproducible. Provide seeds for any randomness. Time-based features should be mockable.

### 4. Minimal Side Effects for Queries

Queries (`get_*`) should never modify state. Actions can be separated into:
- **Player actions** - Things a real player would do
- **Test actions** - Direct state manipulation for test setup

### 5. Fail Explicitly

Return clear error codes and messages. Never silently succeed when something went wrong.

### 6. API Versioning

Include version in responses. Breaking changes bump major version. Deprecate before removing.

```json
{"api_version": "1.0.0", "game_version": "0.2.0", ...}
```

---

## Feature API Checklist

Use this checklist when adding new features. Each game system should have complete API coverage.

### Core Puzzle
- [x] `select_cell` - Select cell by position
- [x] `delete_cell` - Mark cell as deleted
- [x] `keep_cell` - Lock cell as kept
- [x] `restore_cell` - Undo cell deletion
- [x] `undo` / `redo` - Action history
- [x] `get_grid` - Read grid state
- [x] `get_cell` - Read single cell
- [x] `set_cell_state` - Direct state manipulation (testing)
- [x] `load_puzzle` - Load from specification
- [x] `new_puzzle` - Generate with optional seed

### Validation
- [x] `submit` - Submit for validation
- [x] `validate` - Check without side effects
- [x] `get_row_sum` / `get_col_sum` - Current sums
- [x] `assert_row_sum` / `assert_col_sum` - Test assertions
- [x] `assert_valid` / `assert_invalid` - Solution assertions

### Scoring
- [x] `get_score_breakdown` - Detailed calculation
- [x] `set_score` - Override score (testing)
- [ ] `get_score_history` - Score over time (if tracked)

### Run Progression
- [x] `start_run` - Begin new run with seed
- [x] `end_run` - End current run
- [x] `get_run_state` - Run metadata
- [x] `advance_stage` - Skip to next stage (testing)
- [x] `set_lives` - Override lives (testing)
- [x] `trigger_game_over` - Force game over (testing)
- [ ] `get_stage_info` - Current stage details

### Operators (Modifiers)
- [x] `get_operators` - List active operators
- [x] `add_operator` - Add to inventory (testing)
- [x] `remove_operator` - Remove from inventory (testing)
- [ ] `trigger_operator` - Manually trigger effect (testing)
- [ ] `get_operator_info` - Operator details/stats

### Shop (TODO)
- [ ] `open_shop` - Enter shop phase
- [ ] `close_shop` - Exit shop phase
- [ ] `get_shop_inventory` - List available items
- [ ] `buy_item` - Purchase item
- [ ] `sell_operator` - Sell owned operator
- [ ] `reroll_shop` - Refresh inventory
- [ ] `set_shop_inventory` - Force items (testing)
- [ ] `set_shop_prices` - Override prices (testing)
- [ ] `get_shop_state` - Full shop state

### Economy
- [x] `get_money` - Current balance
- [x] `set_money` - Override balance (testing)
- [ ] `add_money` - Add to balance
- [ ] `spend_money` - Deduct from balance
- [ ] `get_economy_history` - Transaction log

### Functions (Consumables) (TODO)
- [ ] `get_functions` - List owned functions
- [ ] `use_function` - Activate a function
- [ ] `add_function` - Add to inventory (testing)
- [ ] `remove_function` - Remove from inventory (testing)
- [ ] `get_function_info` - Function details

### Boss Puzzles (TODO)
- [ ] `is_boss_puzzle` - Check if current is boss
- [ ] `get_boss_modifiers` - Active boss effects
- [ ] `set_boss_modifiers` - Override modifiers (testing)
- [ ] `skip_to_boss` - Jump to boss (testing)

### UI/Navigation
- [ ] `get_current_screen` - Which screen is active
- [ ] `navigate_to` - Change screens
- [ ] `get_ui_state` - Button states, visibility
- [ ] `trigger_ui_action` - Click button by ID (if needed)

### Settings/Config
- [x] `get_config` - Current configuration
- [ ] `set_config` - Modify settings (testing)
- [ ] `reset_config` - Restore defaults

### Meta/Persistence (TODO)
- [ ] `get_save_data` - Current save state
- [ ] `load_save_data` - Restore from save
- [ ] `clear_save_data` - Reset all progress (testing)
- [ ] `get_unlocks` - Unlocked content
- [ ] `set_unlocks` - Override unlocks (testing)

### Debug/Utility
- [x] `screenshot` - Capture viewport
- [x] `ping` - Connection test
- [x] `get_version` - API/game versions
- [x] `wait_idle` - Wait for animations
- [ ] `set_time_scale` - Speed up/slow down (testing)
- [ ] `get_performance_stats` - FPS, memory, etc.

---

## Extending the API

To add a new action:

1. **Define the action** in this document first
2. **Add handler** in `debug_server.gd`:
   ```gdscript
   func execute_action(action: String, params: Dictionary) -> Dictionary:
       match action:
           "my_new_action":
               return handle_my_new_action(params)
   ```
3. **Wire to game logic** - call existing methods/signals or add new ones
4. **Add tests** - both for the API itself and using the API
5. **Document** - update this file

---

## Future Enhancements

### Near-term
1. **Batch actions** - Send multiple actions in one request for efficiency
2. **Event streaming** - Game pushes events to MCP (puzzle solved, game over, score changed)
3. **Replay recording** - Record action sequences, replay for regression tests
4. **Snapshot/restore** - Save and restore complete game state

### Long-term
1. **Headless mode** - Run game logic without rendering for faster tests
2. **AI training mode** - Faster game loop, reward signals for RL training
3. **Fuzzing support** - Generate random valid action sequences
4. **Coverage tracking** - Track which game states/paths have been tested
