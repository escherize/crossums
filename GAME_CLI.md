# Crossums Game CLI

A command-line interface for interacting with a running Crossums game via TCP.

## Requirements

- [Bun](https://bun.sh/) runtime
- Crossums game running (debug build)

## Quick Start

```bash
# Start the game first (it runs a debug server on localhost:9999)

# Check connection
bun game-cli.ts ping

# Get full game state
bun game-cli.ts state

# Take a screenshot
bun game-cli.ts screenshot /tmp/game.png
```

## Commands

### Basic Commands

| Command | Description |
|---------|-------------|
| `ping` | Check if game is running |
| `state` | Get full game state |
| `screenshot [path]` | Capture screenshot (default: `/tmp/crossums_screenshot.png`) |

### Query Commands

```bash
bun game-cli.ts query <query_name> [params_json]
```

| Query | Params | Description |
|-------|--------|-------------|
| `get_state` | - | Full game state |
| `get_cell` | `{"row": N, "col": N}` | Single cell info |
| `get_grid` | - | Grid data only |
| `get_targets` | - | Row/column targets and current sums |
| `get_history` | - | Deletion history |
| `get_config` | - | Game configuration |
| `get_version` | - | API and game version |
| `ping` | - | Connection check |

### Action Commands

```bash
bun game-cli.ts action <action_name> [params_json]
```

#### Cell Manipulation

| Action | Params | Description |
|--------|--------|-------------|
| `delete_cell` | `{"row": N, "col": N}` | Mark cell as deleted |
| `keep_cell` | `{"row": N, "col": N}` | Mark cell as kept |
| `restore_cell` | `{"row": N, "col": N}` | Restore deleted cell |
| `undo` | - | Undo last deletion |

#### Validation

| Action | Params | Description |
|--------|--------|-------------|
| `validate` | - | Check if puzzle is solved (no side effects) |
| `submit` | - | Submit puzzle for scoring |
| `check_complete` | - | Quick completion check |
| `get_row_sum` | `{"row": N}` | Get row's current/target sum |
| `get_col_sum` | `{"col": N}` | Get column's current/target sum |

#### Puzzle Management

| Action | Params | Description |
|--------|--------|-------------|
| `new_puzzle` | `{"size": N, "seed": N}` | Generate new puzzle (size: 2-9) |
| `restart_puzzle` | - | Reset current puzzle |

#### Testing / State Manipulation

| Action | Params | Description |
|--------|--------|-------------|
| `set_cell_state` | `{"row": N, "col": N, "state": "active\|deleted\|kept"}` | Set cell state directly |
| `set_grid_state` | `{"cells": [["active", "deleted"], ...]}` | Set entire grid state |
| `apply_solution` | - | Auto-solve (delete all non-solution cells) |
| `clear_all_marks` | - | Reset all cells to active |

#### Assertions (for testing)

| Action | Params | Description |
|--------|--------|-------------|
| `assert_cell_state` | `{"row": N, "col": N, "state": "..."}` | Assert cell state |
| `assert_row_sum` | `{"row": N, "expected": N}` | Assert row sum |
| `assert_col_sum` | `{"col": N, "expected": N}` | Assert column sum |
| `assert_valid` | - | Assert puzzle is solved |
| `assert_invalid` | - | Assert puzzle is NOT solved |

#### Utilities

| Action | Params | Description |
|--------|--------|-------------|
| `screenshot` | `{"path": "..."}` | Capture viewport to PNG |
| `wait_frames` | `{"count": N}` | Wait N frames (max 300) |
| `wait_idle` | - | Wait for animations |

## Examples

### Play a game programmatically

```bash
# Get current state
bun game-cli.ts state

# Delete cell at row 0, col 1
bun game-cli.ts action delete_cell '{"row": 0, "col": 1}'

# Check if solved
bun game-cli.ts action validate

# Undo if wrong
bun game-cli.ts action undo
```

### Test a specific puzzle

```bash
# Generate puzzle with known seed
bun game-cli.ts action new_puzzle '{"size": 3, "seed": 12345}'

# Apply solution automatically
bun game-cli.ts action apply_solution

# Verify it's solved
bun game-cli.ts action assert_valid
```

### Debug workflow

```bash
# Take screenshot before
bun game-cli.ts screenshot /tmp/before.png

# Make changes
bun game-cli.ts action delete_cell '{"row": 1, "col": 2}'

# Take screenshot after
bun game-cli.ts screenshot /tmp/after.png

# Check row/col sums
bun game-cli.ts action get_row_sum '{"row": 1}'
bun game-cli.ts action get_col_sum '{"col": 2}'
```

## Response Format

All responses are JSON:

```json
{
  "id": "uuid",
  "ok": true,
  ...data
}
```

Error responses:

```json
{
  "id": "uuid",
  "ok": false,
  "error": "error_code",
  "message": "Human readable message"
}
```

## Cell States

- `active` - Default state, clickable
- `deleted` - Marked for removal (grayed out)
- `kept` - Marked to keep (green)
- `locked` - Cannot be changed

## Exit Codes

- `0` - Success (`ok: true`)
- `1` - Error (`ok: false` or connection failed)

## Troubleshooting

**Connection refused**: Game must be running in debug mode. The TCP server listens on `127.0.0.1:9999`.

**Timeout**: If the game is busy, commands may timeout (5s default). Try `wait_idle` first.
