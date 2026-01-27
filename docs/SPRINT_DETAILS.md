# Sprint Implementation Details

> Detailed breakdown for each sprint. Read ARCHITECTURE_PLAN.md first.

---

## Sprint 1: State Foundation

### Goal
Centralize all game state into a single `GameState` autoload. Enable full serialization for save/load and testing.

### Dependencies
- None (this is foundational)

### Scope

**In scope:**
- Create `GameState` autoload
- Create `RunState` class
- Move `current_puzzle` from `main.gd` to `GameState`
- Add `serialize()` / `deserialize()` methods
- Update `DebugServer` to read from `GameState`
- Update `main.gd` to use `GameState`

**Out of scope:**
- Operators (Sprint 2)
- Run flow/progression (Sprint 4)
- UI changes beyond making current UI work

### Files to Create

#### `autoload/game_state.gd`

```gdscript
extends Node

# =============================================================================
# STATE
# =============================================================================

var run: RunState = null
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

func start_new_run() -> void:
    run = RunState.new()
    # Operators populated in Sprint 2

func start_new_puzzle(config: PuzzleLogic.PuzzleConfig) -> void:
    puzzle = PuzzleLogic.generate_puzzle(config)
    EventBus.puzzle_loaded.emit()

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
    return {
        "version": 1,
        "run": run.serialize() if run else null,
        "puzzle": _serialize_puzzle() if puzzle else null,
        "operators": [],  # Sprint 2
        "functions": [],  # Later
    }

func deserialize(data: Dictionary) -> bool:
    var version = data.get("version", 0)
    if version != 1:
        push_error("Unknown save version: %d" % version)
        return false

    if data.has("run") and data.run != null:
        run = RunState.deserialize(data.run)
    else:
        run = null

    if data.has("puzzle") and data.puzzle != null:
        puzzle = _deserialize_puzzle(data.puzzle)
    else:
        puzzle = null

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
                "is_solution": cell.is_solution,
            })
        cells.append(row_data)

    return {
        "grid_size": {"x": puzzle.grid_size.x, "y": puzzle.grid_size.y},
        "cells": cells,
        "row_targets": Array(puzzle.row_targets),
        "col_targets": Array(puzzle.col_targets),
        "deletion_history": puzzle.deletion_history.map(func(v): return {"x": v.x, "y": v.y}),
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
            cell.is_solution = cell_data.is_solution

    ps.deletion_history.clear()
    for pos in data.get("deletion_history", []):
        ps.deletion_history.append(Vector2i(pos.x, pos.y))

    return ps
```

#### `scripts/core/run_state.gd`

```gdscript
class_name RunState
extends RefCounted

# =============================================================================
# PROGRESSION
# =============================================================================

var stage: int = 1              # 1-8
var puzzle_index: int = 0       # 0-2 within stage

# =============================================================================
# RESOURCES
# =============================================================================

var lives: int = 3
var max_lives: int = 3
var money: int = 0
var total_score: int = 0

# =============================================================================
# COMPUTED
# =============================================================================

var puzzles_completed: int:
    get: return (stage - 1) * 3 + puzzle_index

var is_final_stage: bool:
    get: return stage >= 8

# =============================================================================
# METHODS
# =============================================================================

func advance_puzzle() -> void:
    puzzle_index += 1
    if puzzle_index >= 3:
        puzzle_index = 0
        stage += 1

func lose_life() -> bool:
    lives -= 1
    return lives <= 0  # Returns true if game over

func add_money(amount: int) -> void:
    money += amount

func spend_money(amount: int) -> bool:
    if money >= amount:
        money -= amount
        return true
    return false

func add_score(amount: int) -> void:
    total_score += amount

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
    return {
        "stage": stage,
        "puzzle_index": puzzle_index,
        "lives": lives,
        "max_lives": max_lives,
        "money": money,
        "total_score": total_score,
    }

static func deserialize(data: Dictionary) -> RunState:
    var rs = RunState.new()
    rs.stage = data.get("stage", 1)
    rs.puzzle_index = data.get("puzzle_index", 0)
    rs.lives = data.get("lives", 3)
    rs.max_lives = data.get("max_lives", 3)
    rs.money = data.get("money", 0)
    rs.total_score = data.get("total_score", 0)
    return rs
```

### Files to Modify

#### `project.godot`

Add to autoloads:
```
GameState="*res://autoload/game_state.gd"
```

Order should be: EventBus, GameState, DebugServer

#### `scenes/main.gd`

**Remove:**
```gdscript
var puzzle_grid: PuzzleGrid = null
var current_puzzle: PuzzleState = null  # REMOVE - now in GameState
var puzzle_solved: bool = false
```

**Change to:**
```gdscript
var puzzle_grid: PuzzleGrid = null

# Access puzzle via GameState.puzzle
# Access solved state via... (need to track this)
```

**Update `_generate_new_puzzle()`:**
```gdscript
func _generate_new_puzzle(grid_size: int) -> void:
    var config = PuzzleLogic.PuzzleConfig.new()
    config.grid_size = Vector2i(grid_size, grid_size)
    config.cells_to_delete_ratio = 0.5

    GameState.start_new_puzzle(config)

    # ... rest of visual setup using GameState.puzzle
```

**Update all references:**
- `current_puzzle` → `GameState.puzzle`
- `puzzle_solved` → Track locally or add to GameState

#### `autoload/debug_server.gd`

**Update `_get_main_scene()` usages:**

Many actions currently do:
```gdscript
var puzzle_state: PuzzleState = main_scene.get("current_puzzle")
```

Change to:
```gdscript
var puzzle_state: PuzzleState = GameState.puzzle
```

**Add new actions:**
```gdscript
"get_full_state":
    return {"state": GameState.serialize()}

"set_full_state":
    return _action_set_full_state(params)

"get_run_state":
    return _action_get_run_state(params)

"set_run_state":
    return _action_set_run_state(params)
```

**Implement:**
```gdscript
func _action_set_full_state(params: Dictionary) -> Dictionary:
    if not params.has("state"):
        return {"error": "missing_state", "message": "state parameter required"}

    if GameState.deserialize(params.state):
        # Refresh UI
        var main_scene = _get_main_scene()
        if main_scene and main_scene.has_method("refresh_from_state"):
            main_scene.refresh_from_state()
        return {"success": true}
    else:
        return {"error": "deserialize_failed", "message": "Failed to deserialize state"}

func _action_get_run_state(_params: Dictionary) -> Dictionary:
    if GameState.run == null:
        return {"run": null}
    return {"run": GameState.run.serialize()}

func _action_set_run_state(params: Dictionary) -> Dictionary:
    if params.has("run") and params.run != null:
        GameState.run = RunState.deserialize(params.run)
    else:
        GameState.run = null
    return {"success": true}
```

### EventBus Signals to Add

```gdscript
# In autoload/event_bus.gd

# State signals
signal state_changed()           # Generic "something changed"
signal puzzle_loaded()           # New puzzle ready
signal run_started()             # New run began
signal run_ended(won: bool)      # Run finished
```

### Test Cases

Create `tests/corpus/state_serialization.json`:
```json
{
  "name": "state_serialization",
  "description": "Test that state survives serialize/deserialize round-trip",
  "setup": {
    "size": 3,
    "seed": 99999
  },
  "steps": [
    {"action": "delete_cell", "params": {"row": 0, "col": 0}},
    {"action": "delete_cell", "params": {"row": 1, "col": 1}},
    {"action": "get_full_state", "save_as": "snapshot"},
    {"action": "new_puzzle", "params": {"size": 4}},
    {"action": "set_full_state", "params": {"state": "$snapshot"}},
    {"assert": "assert_cell_state", "params": {"row": 0, "col": 0, "state": "deleted"}},
    {"assert": "assert_cell_state", "params": {"row": 1, "col": 1, "state": "deleted"}}
  ]
}
```

Note: This test requires extending the test runner to support `save_as` and variable interpolation. Could be deferred.

**Simpler test:**
```json
{
  "name": "game_state_puzzle_access",
  "description": "Verify puzzle is accessible via GameState",
  "setup": {"size": 3},
  "steps": [
    {"action": "delete_cell", "params": {"row": 0, "col": 0}},
    {"assert": "assert_cell_state", "params": {"row": 0, "col": 0, "state": "deleted"}}
  ]
}
```

### Acceptance Criteria

- [ ] `GameState` autoload exists and loads
- [ ] `GameState.puzzle` holds the current puzzle
- [ ] `main.gd` no longer has `current_puzzle` variable
- [ ] `GameState.serialize()` returns valid Dictionary
- [ ] `GameState.deserialize()` restores state correctly
- [ ] All existing tests still pass
- [ ] Debug server `get_full_state` action works
- [ ] Game plays exactly as before (no behavior changes)

### Migration Notes

1. Add files first, don't break anything
2. Add GameState to autoloads
3. Gradually move references from `main.gd` to `GameState`
4. Update debug_server last
5. Run tests after each change

---

## Sprint 2: Operators

### Goal
Implement the operator system with 5 starter operators that affect scoring.

### Dependencies
- Sprint 1 complete (GameState exists)

### Scope

**In scope:**
- `Operator` base class with hooks
- `OperatorRegistry` for creating operators
- 5 starter operators
- Scoring engine integration
- Operators stored in GameState
- Debug server actions for operators

**Out of scope:**
- Shop (Sprint 5)
- Operator UI beyond score display
- Transformation operators (change cell values)

### Files to Create

#### `scripts/operators/operator.gd`

```gdscript
class_name Operator
extends RefCounted

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
func on_cell_kept(row: int, col: int, value: int, puzzle: PuzzleState) -> Dictionary:
    return {}

## Called for each row that matches its target
## Return: {"score_bonus": int, "mult_bonus": float}
func on_row_complete(row: int, puzzle: PuzzleState) -> Dictionary:
    return {}

## Called for each column that matches its target
## Return: {"score_bonus": int, "mult_bonus": float}
func on_col_complete(col: int, puzzle: PuzzleState) -> Dictionary:
    return {}

## Called once at end of puzzle scoring
## Return: {"score_bonus": int, "mult_bonus": float, "money_bonus": int}
func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
    return {}

## Called when puzzle starts (for setup effects)
func on_puzzle_start(puzzle: PuzzleState) -> void:
    pass

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
    return {"id": id}

func get_tooltip() -> String:
    return "%s\n%s" % [display_name, description]
```

#### `scripts/operators/operator_registry.gd`

```gdscript
class_name OperatorRegistry
extends RefCounted

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
```

#### `scripts/operators/impl/op_counter.gd`

```gdscript
extends Operator

func _init() -> void:
    id = "counter"
    display_name = "Counter"
    description = "+10 points for each kept cell"
    rarity = 0
    price = 5

func on_cell_kept(_row: int, _col: int, _value: int, _puzzle: PuzzleState) -> Dictionary:
    return {"score_bonus": 10}
```

#### `scripts/operators/impl/op_lucky_seven.gd`

```gdscript
extends Operator

func _init() -> void:
    id = "lucky_seven"
    display_name = "Lucky Seven"
    description = "+77 points for each 7 kept"
    rarity = 0
    price = 6

func on_cell_kept(_row: int, _col: int, value: int, _puzzle: PuzzleState) -> Dictionary:
    if value == 7:
        return {"score_bonus": 77}
    return {}
```

#### `scripts/operators/impl/op_prime_time.gd`

```gdscript
extends Operator

const PRIMES := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]

func _init() -> void:
    id = "prime_time"
    display_name = "Prime Time"
    description = "+30 points for each prime number kept"
    rarity = 1
    price = 8

func on_cell_kept(_row: int, _col: int, value: int, _puzzle: PuzzleState) -> Dictionary:
    if value in PRIMES:
        return {"score_bonus": 30}
    return {}
```

#### `scripts/operators/impl/op_row_master.gd`

```gdscript
extends Operator

func _init() -> void:
    id = "row_master"
    display_name = "Row Master"
    description = "+50 points for each completed row"
    rarity = 0
    price = 5

func on_row_complete(_row: int, _puzzle: PuzzleState) -> Dictionary:
    return {"score_bonus": 50}
```

#### `scripts/operators/impl/op_corner_keeper.gd`

```gdscript
extends Operator

func _init() -> void:
    id = "corner_keeper"
    display_name = "Corner Keeper"
    description = "+200 points if all 4 corners are kept"
    rarity = 1
    price = 7

func on_puzzle_end(puzzle: PuzzleState) -> Dictionary:
    var size = puzzle.grid_size
    var corners = [
        Vector2i(0, 0),
        Vector2i(size.x - 1, 0),
        Vector2i(0, size.y - 1),
        Vector2i(size.x - 1, size.y - 1),
    ]

    for corner in corners:
        if puzzle.get_cell_state(corner.y, corner.x) == PuzzleState.CellState.DELETED:
            return {}

    return {"score_bonus": 200}
```

### Files to Modify

#### `scripts/core/scoring_engine.gd`

```gdscript
class_name ScoringEngine
extends RefCounted

class ScoreBreakdown:
    var base_points: int = 0
    var kept_bonus: int = 0
    var operator_bonus: int = 0
    var time_mult: float = 1.0
    var operator_mult: float = 1.0
    var precision_mult: float = 1.0
    var final_score: int = 0
    var operator_details: Array = []  # [{name, bonus}]

    func get_summary() -> String:
        return "Base:%d + Kept:%d + Ops:%d × %.1f" % [
            base_points, kept_bonus, operator_bonus,
            time_mult * operator_mult * precision_mult
        ]

static func calculate_score(
    puzzle: PuzzleState,
    operators: Array,  # Array[Operator]
    time_multiplier: float = 1.0,
    restore_count: int = 0
) -> ScoreBreakdown:
    var breakdown = ScoreBreakdown.new()

    # Base points by grid size
    breakdown.base_points = _get_base_points(puzzle.grid_size.x)

    # Kept cell bonus (base, without operators)
    var kept_count = puzzle.get_kept_count()
    breakdown.kept_bonus = kept_count * GameConfig.KEPT_CELL_BONUS

    # Time multiplier
    breakdown.time_mult = time_multiplier

    # Precision multiplier
    breakdown.precision_mult = _get_precision_mult(restore_count)

    # Operator bonuses
    var op_score_bonus := 0
    var op_mult_bonus := 0.0

    for op in operators:
        var op_total := 0

        # Cell hooks
        for row in range(puzzle.grid_size.y):
            for col in range(puzzle.grid_size.x):
                if puzzle.get_cell_state(row, col) != PuzzleState.CellState.DELETED:
                    var value = puzzle.get_cell_value(row, col)
                    var result = op.on_cell_kept(row, col, value, puzzle)
                    op_total += result.get("score_bonus", 0)
                    op_mult_bonus += result.get("mult_bonus", 0.0)

        # Row hooks
        for row in range(puzzle.grid_size.y):
            if puzzle.is_row_valid(row):
                var result = op.on_row_complete(row, puzzle)
                op_total += result.get("score_bonus", 0)
                op_mult_bonus += result.get("mult_bonus", 0.0)

        # Column hooks
        for col in range(puzzle.grid_size.x):
            if puzzle.is_col_valid(col):
                var result = op.on_col_complete(col, puzzle)
                op_total += result.get("score_bonus", 0)
                op_mult_bonus += result.get("mult_bonus", 0.0)

        # End hook
        var end_result = op.on_puzzle_end(puzzle)
        op_total += end_result.get("score_bonus", 0)
        op_mult_bonus += end_result.get("mult_bonus", 0.0)

        if op_total > 0:
            breakdown.operator_details.append({
                "name": op.display_name,
                "bonus": op_total
            })

        op_score_bonus += op_total

    breakdown.operator_bonus = op_score_bonus
    breakdown.operator_mult = 1.0 + op_mult_bonus

    # Calculate final
    var subtotal = breakdown.base_points + breakdown.kept_bonus + breakdown.operator_bonus
    var total_mult = breakdown.time_mult * breakdown.operator_mult * breakdown.precision_mult
    breakdown.final_score = int(subtotal * total_mult)

    return breakdown

static func _get_base_points(grid_size: int) -> int:
    match grid_size:
        3: return 100
        4: return 200
        5: return 350
        6: return 500
        _: return 100 + (grid_size - 3) * 100

static func _get_precision_mult(restore_count: int) -> float:
    if restore_count == 0:
        return GameConfig.PRECISION_MULT_PERFECT
    elif restore_count <= 2:
        return GameConfig.PRECISION_MULT_GOOD
    else:
        return GameConfig.PRECISION_MULT_BASE
```

#### `autoload/game_state.gd`

Add:
```gdscript
func add_operator(op: Operator) -> bool:
    if operators.size() >= 5:  # Max slots
        return false
    operators.append(op)
    return true

func remove_operator(index: int) -> Operator:
    if index < 0 or index >= operators.size():
        return null
    return operators.pop_at(index)

func has_operator(id: String) -> bool:
    for op in operators:
        if op.id == id:
            return true
    return false
```

Update serialize/deserialize:
```gdscript
func serialize() -> Dictionary:
    return {
        "version": 1,
        "run": run.serialize() if run else null,
        "puzzle": _serialize_puzzle() if puzzle else null,
        "operators": operators.map(func(o): return o.serialize()),
        "functions": [],
    }

func deserialize(data: Dictionary) -> bool:
    # ... existing code ...

    operators.clear()
    for op_data in data.get("operators", []):
        var op = OperatorRegistry.deserialize(op_data)
        if op:
            operators.append(op)

    return true
```

#### `scenes/main.gd`

Update scoring call:
```gdscript
func _on_submit_pressed() -> void:
    # ...
    if result.is_valid:
        puzzle_solved = true
        var breakdown = ScoringEngine.calculate_score(
            GameState.puzzle,
            GameState.operators,
            time_multiplier,
            restore_count
        )
        _update_status("🎉 SCORE: %d  |  %s" % [breakdown.final_score, breakdown.get_summary()])
```

#### `autoload/debug_server.gd`

Add actions:
```gdscript
"add_operator":
    return _action_add_operator(params)

"remove_operator":
    return _action_remove_operator(params)

"list_operators":
    return _action_list_operators(params)

"clear_operators":
    return _action_clear_operators(params)
```

Implementations:
```gdscript
func _action_add_operator(params: Dictionary) -> Dictionary:
    var id: String = params.get("id", "")
    if id.is_empty():
        return {"error": "missing_id", "message": "Operator id required"}

    var op = OperatorRegistry.create(id)
    if op == null:
        return {"error": "unknown_operator", "message": "Unknown operator: %s" % id}

    if GameState.add_operator(op):
        return {"success": true, "operator": op.serialize()}
    else:
        return {"error": "slots_full", "message": "Operator slots full"}

func _action_remove_operator(params: Dictionary) -> Dictionary:
    var index: int = params.get("index", -1)
    var op = GameState.remove_operator(index)
    if op:
        return {"success": true, "removed": op.serialize()}
    else:
        return {"error": "invalid_index", "message": "Invalid operator index"}

func _action_list_operators(_params: Dictionary) -> Dictionary:
    return {
        "operators": GameState.operators.map(func(o): return {
            "id": o.id,
            "name": o.display_name,
            "description": o.description,
        }),
        "available": OperatorRegistry.get_all_ids(),
    }

func _action_clear_operators(_params: Dictionary) -> Dictionary:
    var count = GameState.operators.size()
    GameState.operators.clear()
    return {"cleared": count}
```

### Test Cases

`tests/corpus/operator_counter.json`:
```json
{
  "name": "operator_counter",
  "description": "Counter operator adds +10 per kept cell",
  "setup": {"size": 3},
  "steps": [
    {"action": "clear_operators"},
    {"action": "add_operator", "params": {"id": "counter"}},
    {"action": "apply_solution"},
    {"action": "validate"}
  ]
}
```

Note: Need to extend test system to check score values. For now, verify operators load and don't crash.

### Acceptance Criteria

- [ ] `Operator` base class exists
- [ ] 5 operators implemented and registered
- [ ] `GameState.operators` stores active operators
- [ ] `ScoringEngine` calls operator hooks
- [ ] Score reflects operator bonuses
- [ ] Debug server can add/remove/list operators
- [ ] Existing tests still pass
- [ ] New operator tests pass

---

## Sprint 3: Puzzle Generation Updates

### Goal
Add negative number support and "slack" parameter for difficulty tuning.

### Dependencies
- Sprint 1 complete

### Scope

**In scope:**
- Negative numbers in puzzles
- Slack parameter (solution looseness)
- Explicit puzzle setup via debug server
- Updated validation for negatives

**Out of scope:**
- New cell types (locked, gold, etc.)
- Transformation operators

### Files to Modify

#### `scripts/core/puzzle_logic.gd`

Update `PuzzleConfig`:
```gdscript
class PuzzleConfig:
    var grid_size: Vector2i = Vector2i(3, 3)
    var cells_to_delete_ratio: float = 0.5
    var puzzle_seed: int = 0

    # NEW
    var allow_negatives: bool = false
    var negative_ratio: float = 0.2  # % of cells that CAN be negative
    var value_range: Vector2i = Vector2i(1, 9)
    var negative_range: Vector2i = Vector2i(-5, -1)
    var slack: float = 0.5  # 0.0 = tight, 1.0 = loose
```

Update `generate_puzzle()`:
```gdscript
static func generate_puzzle(config: PuzzleConfig) -> PuzzleState:
    # ... existing setup ...

    # Generate values with potential negatives
    for row in range(size.y):
        for col in range(size.x):
            var value: int
            if config.allow_negatives and randf() < config.negative_ratio:
                value = rng.randi_range(config.negative_range.x, config.negative_range.y)
            else:
                value = rng.randi_range(config.value_range.x, config.value_range.y)
            puzzle.set_cell_value(row, col, value)

    # ... rest of generation ...
```

#### `scripts/core/puzzle_state.gd`

Validation already uses `get_cell_state()` which works with any value, so negatives should "just work" for sums. But verify:

```gdscript
func get_current_row_sum(row: int) -> int:
    var sum = 0
    for col in range(grid_size.x):
        var cell = cells[row][col]
        if cell.state != CellState.DELETED:
            sum += cell.value  # Works with negatives
    return sum
```

#### `autoload/debug_server.gd`

Add `set_puzzle` action:
```gdscript
func _action_set_puzzle(params: Dictionary) -> Dictionary:
    ## Set explicit puzzle for testing
    ## params.grid: [[1, 2, -3], [4, 5, 6], ...]
    ## params.row_targets: [0, 15, ...]
    ## params.col_targets: [5, 7, 3]
    ## params.solution: [[true, false, true], ...] (optional)

    if not params.has("grid"):
        return {"error": "missing_grid", "message": "grid parameter required"}
    if not params.has("row_targets"):
        return {"error": "missing_row_targets", "message": "row_targets required"}
    if not params.has("col_targets"):
        return {"error": "missing_col_targets", "message": "col_targets required"}

    var grid = params.grid
    var rows = grid.size()
    var cols = grid[0].size() if rows > 0 else 0

    var puzzle = PuzzleState.new(Vector2i(cols, rows))
    puzzle.row_targets.assign(params.row_targets)
    puzzle.col_targets.assign(params.col_targets)

    for row in range(rows):
        for col in range(cols):
            puzzle.get_cell(row, col).value = grid[row][col]
            if params.has("solution"):
                puzzle.get_cell(row, col).is_solution = params.solution[row][col]

    GameState.puzzle = puzzle

    # Refresh UI
    var main_scene = _get_main_scene()
    if main_scene:
        var puzzle_grid = main_scene.get("puzzle_grid")
        if puzzle_grid and puzzle_grid.has_method("load_puzzle"):
            puzzle_grid.load_puzzle(puzzle)

    return {
        "success": true,
        "size": {"rows": rows, "cols": cols},
    }
```

### Test Cases

`tests/corpus/negative_numbers.json`:
```json
{
  "name": "negative_numbers",
  "description": "Puzzle with negative numbers sums correctly",
  "setup": {},
  "steps": [
    {
      "action": "set_puzzle",
      "params": {
        "grid": [[3, -2, 4], [1, 5, -1], [2, 3, 1]],
        "row_targets": [5, 5, 6],
        "col_targets": [6, 6, 4]
      }
    },
    {"action": "get_row_sum", "params": {"row": 0}},
    {"action": "delete_cell", "params": {"row": 0, "col": 2}},
    {"action": "get_row_sum", "params": {"row": 0}}
  ]
}
```

### Acceptance Criteria

- [ ] Negative numbers can appear in puzzles
- [ ] Sums calculate correctly with negatives
- [ ] `set_puzzle` debug action works
- [ ] Tests can use explicit grid setup instead of seeds
- [ ] Existing tests still pass

---

## Sprint 4: Run Flow

### Goal
Implement the run state machine: start run, progress through stages, handle win/loss, transitions.

### Dependencies
- Sprint 1 complete
- Sprint 2 complete (operators for starter loadout)

### Scope

**In scope:**
- Run state machine
- Stage progression (8 stages × 3 puzzles)
- Win/loss handling
- Basic HUD (lives, money, stage, score)
- Game over / victory screens
- Score targets per stage

**Out of scope:**
- Shop (Sprint 5)
- Boss puzzles
- Save/load

### Files to Create

#### `scripts/core/stage_config.gd`

```gdscript
class_name StageConfig
extends RefCounted

var stage: int
var puzzle_index: int
var grid_size: int
var score_target: int
var allow_negatives: bool
var slack: float
var money_reward: int

static func get_config(stage: int, puzzle_index: int) -> StageConfig:
    var config = StageConfig.new()
    config.stage = stage
    config.puzzle_index = puzzle_index

    # Grid size scales with stage
    if stage <= 2:
        config.grid_size = 3
    elif stage <= 4:
        config.grid_size = 4
    elif stage <= 6:
        config.grid_size = 5
    else:
        config.grid_size = 6

    # Score targets
    var base_targets = [300, 500, 800, 1200, 2000, 3500, 6000, 10000]
    config.score_target = base_targets[stage - 1]

    # Negatives from stage 4+
    config.allow_negatives = stage >= 4

    # Slack decreases over stages (tighter puzzles)
    config.slack = clampf(0.7 - (stage - 1) * 0.06, 0.2, 0.7)

    # Money reward
    config.money_reward = 3 + stage

    return config

func to_puzzle_config() -> PuzzleLogic.PuzzleConfig:
    var pc = PuzzleLogic.PuzzleConfig.new()
    pc.grid_size = Vector2i(grid_size, grid_size)
    pc.allow_negatives = allow_negatives
    pc.slack = slack
    pc.cells_to_delete_ratio = 0.5
    return pc
```

#### `scripts/core/run_manager.gd`

```gdscript
class_name RunManager
extends Node

enum State {
    IDLE,
    PUZZLE_ACTIVE,
    PUZZLE_RESULT,
    SHOP,
    GAME_OVER,
    VICTORY,
}

var current_state: State = State.IDLE

signal state_changed(new_state: State)
signal puzzle_ready()
signal show_result(won: bool, score: int, target: int)
signal show_shop()
signal show_game_over(total_score: int)
signal show_victory(total_score: int)

func start_run() -> void:
    GameState.reset()
    GameState.run = RunState.new()
    GameState.operators = [OperatorRegistry.create("counter")]  # Starter

    _start_next_puzzle()

func _start_next_puzzle() -> void:
    var config = StageConfig.get_config(
        GameState.run.stage,
        GameState.run.puzzle_index
    )
    var puzzle_config = config.to_puzzle_config()

    GameState.start_new_puzzle(puzzle_config)
    current_state = State.PUZZLE_ACTIVE
    state_changed.emit(current_state)
    puzzle_ready.emit()

func on_puzzle_complete(score: int) -> void:
    var config = StageConfig.get_config(
        GameState.run.stage,
        GameState.run.puzzle_index
    )

    var won = score >= config.score_target

    current_state = State.PUZZLE_RESULT
    state_changed.emit(current_state)
    show_result.emit(won, score, config.score_target)

    if won:
        GameState.run.add_score(score)
        GameState.run.add_money(config.money_reward)
    else:
        var game_over = GameState.run.lose_life()
        if game_over:
            _end_run(false)
            return

    # Progress
    GameState.run.advance_puzzle()

    # Check victory
    if GameState.run.stage > 8:
        _end_run(true)
        return

func continue_from_result() -> void:
    # Check if shop time (after 3 puzzles)
    if GameState.run.puzzle_index == 0 and GameState.run.stage > 1:
        current_state = State.SHOP
        state_changed.emit(current_state)
        show_shop.emit()
    else:
        _start_next_puzzle()

func continue_from_shop() -> void:
    _start_next_puzzle()

func _end_run(won: bool) -> void:
    if won:
        current_state = State.VICTORY
        show_victory.emit(GameState.run.total_score)
    else:
        current_state = State.GAME_OVER
        show_game_over.emit(GameState.run.total_score)
    state_changed.emit(current_state)
```

#### `scenes/ui/run_hud.gd` and `run_hud.tscn`

```gdscript
extends Control

@onready var stage_label: Label = %StageLabel
@onready var puzzle_label: Label = %PuzzleLabel
@onready var lives_label: Label = %LivesLabel
@onready var money_label: Label = %MoneyLabel
@onready var score_label: Label = %ScoreLabel
@onready var target_label: Label = %TargetLabel

func _ready() -> void:
    EventBus.state_changed.connect(_on_state_changed)
    refresh()

func _on_state_changed() -> void:
    refresh()

func refresh() -> void:
    if GameState.run == null:
        visible = false
        return

    visible = true
    var run = GameState.run

    stage_label.text = "Stage %d" % run.stage
    puzzle_label.text = "Puzzle %d/3" % (run.puzzle_index + 1)
    lives_label.text = "♥ %d" % run.lives
    money_label.text = "$%d" % run.money
    score_label.text = "Score: %d" % run.total_score

    var config = StageConfig.get_config(run.stage, run.puzzle_index)
    target_label.text = "Target: %d" % config.score_target
```

### Acceptance Criteria

- [ ] Can start a new run
- [ ] Puzzles progress through stages
- [ ] Winning adds score and money
- [ ] Losing deducts life
- [ ] 0 lives = game over
- [ ] Completing stage 8 = victory
- [ ] HUD shows current state
- [ ] Game over screen shows total score
- [ ] Victory screen shows total score

---

## Sprint 5: Shop

### Goal
Implement the between-stage shop where players buy operators.

### Dependencies
- Sprint 4 complete

### Scope

**In scope:**
- Shop state (items for sale)
- Buy operators
- Sell operators
- Reroll
- Shop UI

**Out of scope:**
- Functions/consumables (later)
- Operator packs
- Vouchers/upgrades

### Files to Create

#### `scripts/core/shop_state.gd`

```gdscript
class_name ShopState
extends RefCounted

var operator_slots: Array[Operator] = []
var reroll_cost: int = 2
var reroll_count: int = 0

func generate(stage: int) -> void:
    operator_slots.clear()

    # 3 operators for sale
    for i in range(3):
        var op = _random_operator(stage)
        operator_slots.append(op)

    reroll_count = 0
    reroll_cost = 2

func _random_operator(stage: int) -> Operator:
    var ids = OperatorRegistry.get_all_ids()
    var id = ids[randi() % ids.size()]
    return OperatorRegistry.create(id)

func buy_operator(index: int) -> Dictionary:
    if index < 0 or index >= operator_slots.size():
        return {"error": "invalid_index"}

    var op = operator_slots[index]
    if op == null:
        return {"error": "already_sold"}

    if GameState.run.money < op.price:
        return {"error": "not_enough_money"}

    if GameState.operators.size() >= 5:
        return {"error": "slots_full"}

    GameState.run.spend_money(op.price)
    GameState.operators.append(op)
    operator_slots[index] = null

    return {"success": true, "operator": op.serialize()}

func sell_operator(index: int) -> Dictionary:
    var op = GameState.remove_operator(index)
    if op == null:
        return {"error": "invalid_index"}

    var sell_price = op.price / 2
    GameState.run.add_money(sell_price)

    return {"success": true, "refund": sell_price}

func reroll() -> Dictionary:
    if GameState.run.money < reroll_cost:
        return {"error": "not_enough_money"}

    GameState.run.spend_money(reroll_cost)
    reroll_count += 1
    reroll_cost = 2 + reroll_count  # Increases each time

    generate(GameState.run.stage)

    return {"success": true, "new_cost": reroll_cost}
```

#### `scenes/shop/shop.tscn` and `shop.gd`

Basic UI:
- 3 operator cards (show name, description, price)
- Buy buttons
- Your operators (with sell buttons)
- Reroll button
- Continue button

### Acceptance Criteria

- [ ] Shop generates 3 operators
- [ ] Can buy operator (deducts money, adds to inventory)
- [ ] Can't buy if no money or slots full
- [ ] Can sell operator (refunds half price)
- [ ] Can reroll (costs increase each time)
- [ ] Continue advances to next stage
- [ ] Shop integrates with run flow

---

## Test Strategy

### Explicit Board Setup

All tests should use `set_puzzle` to create explicit boards, not seeds:

```json
{
  "setup": {},
  "steps": [
    {
      "action": "set_puzzle",
      "params": {
        "grid": [[1, 2, 3], [4, 5, 6], [7, 8, 9]],
        "row_targets": [6, 15, 24],
        "col_targets": [12, 15, 18]
      }
    },
    ...
  ]
}
```

### Test Categories

1. **Unit tests** (state classes): Serialization, calculations
2. **Integration tests** (debug server): Actions work correctly
3. **Flow tests**: Run progression, shop buying
4. **Operator tests**: Each operator scores correctly

---

## Appendix: Directory Structure

```
godot_app/
├── autoload/
│   ├── event_bus.gd
│   ├── game_state.gd (Sprint 1)
│   └── debug_server.gd
├── scripts/
│   ├── core/
│   │   ├── puzzle_state.gd
│   │   ├── puzzle_logic.gd
│   │   ├── scoring_engine.gd
│   │   ├── game_config.gd
│   │   ├── run_state.gd (Sprint 1)
│   │   ├── run_manager.gd (Sprint 4)
│   │   ├── stage_config.gd (Sprint 4)
│   │   └── shop_state.gd (Sprint 5)
│   └── operators/
│       ├── operator.gd (Sprint 2)
│       ├── operator_registry.gd (Sprint 2)
│       └── impl/
│           ├── op_counter.gd
│           ├── op_lucky_seven.gd
│           ├── op_prime_time.gd
│           ├── op_row_master.gd
│           └── op_corner_keeper.gd
├── scenes/
│   ├── main.gd
│   ├── main.tscn
│   ├── puzzle/
│   ├── shop/
│   │   ├── shop.gd (Sprint 5)
│   │   └── shop.tscn (Sprint 5)
│   └── ui/
│       ├── run_hud.gd (Sprint 4)
│       ├── run_hud.tscn (Sprint 4)
│       ├── game_over.tscn (Sprint 4)
│       ├── victory.tscn (Sprint 4)
│       └── result_popup.tscn (Sprint 4)
```
