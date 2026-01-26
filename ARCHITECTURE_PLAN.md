# Crosssums Architecture Plan

> Comprehensive plan for run structure, operators, and game systems

## Design Principles

1. **Centralized State**: All game state lives in one place (`GameState` autoload)
2. **View = f(State)**: Scenes render state, don't own it
3. **Testability**: All state queryable/settable via debug server
4. **Explicit over Magic**: Tests use explicit board setup, not seeds

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      GameState (Autoload)                   │
├─────────────────────────────────────────────────────────────┤
│  run: RunState                                              │
│  puzzle: PuzzleState (existing)                             │
│  operators: Array[Operator]                                 │
│  functions: Array[Function]  (consumables)                  │
│  config: GameConfig                                         │
├─────────────────────────────────────────────────────────────┤
│  serialize() -> Dictionary                                  │
│  deserialize(data: Dictionary)                              │
│  reset()                                                    │
└─────────────────────────────────────────────────────────────┘
          │
          │ signals
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    EventBus (existing)                      │
│  state_changed, run_started, stage_advanced, puzzle_won...  │
└─────────────────────────────────────────────────────────────┘
          │
          │ observed by
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Scene Tree (Views)                      │
│  MainScene, PuzzleGrid, ShopScreen, RunHUD, etc.            │
│  Read from GameState, emit actions via EventBus             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation

### 1.1 GameState Autoload

**File**: `autoload/game_state.gd`

```gdscript
extends Node

# Core state
var run: RunState = null
var puzzle: PuzzleState = null  # Move from main.gd
var operators: Array[Operator] = []
var functions: Array[GameFunction] = []

# Serialization
func serialize() -> Dictionary:
    return {
        "run": run.serialize() if run else null,
        "puzzle": puzzle.serialize() if puzzle else null,
        "operators": operators.map(func(o): return o.serialize()),
        "functions": functions.map(func(f): return f.serialize()),
    }

func deserialize(data: Dictionary) -> void:
    # Restore full state from dictionary
    pass
```

### 1.2 RunState Class

**File**: `scripts/core/run_state.gd`

```gdscript
class_name RunState
extends RefCounted

# Progression
var stage: int = 1
var puzzle_index: int = 0  # 0, 1, 2 (boss)
var is_boss: bool:
    get: return puzzle_index == 2

# Resources
var lives: int = 3
var money: int = 0
var score: int = 0

# Stage config
var score_target: int = 300

# Serialization
func serialize() -> Dictionary:
    return {
        "stage": stage,
        "puzzle_index": puzzle_index,
        "lives": lives,
        "money": money,
        "score": score,
        "score_target": score_target,
    }

static func deserialize(data: Dictionary) -> RunState:
    var run = RunState.new()
    run.stage = data.get("stage", 1)
    # ... etc
    return run
```

### 1.3 Stage Configuration

**File**: `scripts/core/stage_config.gd`

```gdscript
class_name StageConfig
extends RefCounted

var stage_number: int
var grid_size: int
var score_target: int
var allow_negatives: bool
var slack: float  # 0.0 = tight, 1.0 = very loose (many solutions)
var boss_modifier: String  # "", "timed", "minimalist", etc.

static func get_config(stage: int, puzzle_index: int) -> StageConfig:
    # Return appropriate config for stage/puzzle
    pass
```

**Stage Progression Table**:

| Stage | Grid | Target | Negatives | Slack | Notes |
|-------|------|--------|-----------|-------|-------|
| 1 | 3×3 | 300 | No | 0.7 | Tutorial-ish |
| 2 | 3×3 | 500 | No | 0.5 | Tighter |
| 3 | 4×4 | 800 | No | 0.6 | Bigger grid |
| 4 | 4×4 | 1200 | Yes | 0.5 | Negatives introduced |
| 5 | 5×5 | 2000 | Yes | 0.4 | |
| 6 | 5×5 | 3500 | Yes | 0.3 | |
| 7 | 6×6 | 6000 | Yes | 0.3 | |
| 8 | 6×6 | 10000 | Yes | 0.2 | Final |

---

## Phase 2: Operator System

### 2.1 Operator Base Class

**File**: `scripts/operators/operator.gd`

```gdscript
class_name Operator
extends RefCounted

var id: String
var display_name: String
var description: String
var rarity: int  # 0=common, 1=uncommon, 2=rare

# Hook methods (override in subclasses)
func on_cell_kept(row: int, col: int, value: int, puzzle: PuzzleState) -> Dictionary:
    # Return {"score_bonus": 0, "mult_bonus": 0.0}
    return {}

func on_row_solved(row: int, puzzle: PuzzleState) -> Dictionary:
    return {}

func on_col_solved(col: int, puzzle: PuzzleState) -> Dictionary:
    return {}

func on_puzzle_start(puzzle: PuzzleState) -> void:
    pass

func on_puzzle_end(puzzle: PuzzleState, score: int) -> Dictionary:
    # Return {"score_bonus": 0, "money_bonus": 0}
    return {}

func modify_cell_value(row: int, col: int, base_value: int, puzzle: PuzzleState) -> int:
    # For transformation operators (Flipper, Doubler)
    return base_value

func serialize() -> Dictionary:
    return {"id": id}

static func deserialize(data: Dictionary) -> Operator:
    return OperatorRegistry.create(data.id)
```

### 2.2 Operator Registry

**File**: `scripts/operators/operator_registry.gd`

```gdscript
class_name OperatorRegistry

const OPERATORS = {
    "counter": preload("res://scripts/operators/impl/counter.gd"),
    "lucky_seven": preload("res://scripts/operators/impl/lucky_seven.gd"),
    "prime_time": preload("res://scripts/operators/impl/prime_time.gd"),
    "row_master": preload("res://scripts/operators/impl/row_master.gd"),
    "corner_bonus": preload("res://scripts/operators/impl/corner_bonus.gd"),
}

static func create(id: String) -> Operator:
    if OPERATORS.has(id):
        return OPERATORS[id].new()
    return null

static func get_random(rarity: int = -1) -> Operator:
    # Return random operator, optionally filtered by rarity
    pass
```

### 2.3 Starter Operators (5 to prove system)

| ID | Name | Effect | Rarity |
|----|------|--------|--------|
| `counter` | Counter | +10 pts per kept cell | Common |
| `lucky_seven` | Lucky Seven | +77 pts per 7 kept | Common |
| `prime_time` | Prime Time | +30 pts per prime kept | Uncommon |
| `row_master` | Row Master | +50 pts per solved row | Common |
| `corner_bonus` | Corner Keeper | +100 if all corners kept | Uncommon |

### 2.4 Scoring Engine Update

**File**: `scripts/core/scoring_engine.gd` (update existing)

```gdscript
static func calculate_score(puzzle: PuzzleState, operators: Array[Operator], ...) -> ScoreBreakdown:
    var base = get_base_points(puzzle.grid_size)
    var bonuses = 0
    var mult = 1.0

    # Cell bonuses
    for row in range(puzzle.grid_size.y):
        for col in range(puzzle.grid_size.x):
            if puzzle.get_cell_state(row, col) != PuzzleState.CellState.DELETED:
                var value = puzzle.get_cell_value(row, col)
                for op in operators:
                    var result = op.on_cell_kept(row, col, value, puzzle)
                    bonuses += result.get("score_bonus", 0)
                    mult += result.get("mult_bonus", 0.0)

    # Row/col bonuses
    for row in range(puzzle.grid_size.y):
        if puzzle.is_row_valid(row):
            for op in operators:
                var result = op.on_row_solved(row, puzzle)
                bonuses += result.get("score_bonus", 0)

    # ... similar for columns

    return ScoreBreakdown.new(base, bonuses, mult)
```

---

## Phase 3: Puzzle Generation Updates

### 3.1 Negative Number Support

**File**: `scripts/core/puzzle_logic.gd` (update)

```gdscript
class PuzzleConfig:
    var allow_negatives: bool = false
    var negative_ratio: float = 0.2  # 20% of cells can be negative
    var value_range: Vector2i = Vector2i(1, 9)
    var negative_range: Vector2i = Vector2i(-5, -1)
```

### 3.2 Slack Parameter (Solution Looseness)

```gdscript
class PuzzleConfig:
    var slack: float = 0.5  # 0.0 = minimal cells, 1.0 = many extra valid cells

# In generation:
# slack affects how many "extra" valid cells exist beyond minimum solution
```

### 3.3 Explicit Board Setup (for tests)

**Debug server additions**:

```gdscript
func _action_set_puzzle(params: Dictionary) -> Dictionary:
    # Set entire puzzle explicitly
    # params.grid: [[1,2,3], [4,5,6], ...]
    # params.row_targets: [6, 15, ...]
    # params.col_targets: [12, 15, ...]
    # params.solution: [[true, false, true], ...] (optional)
    pass
```

---

## Phase 4: Run Flow

### 4.1 State Machine

```
[MENU]
   │ start_run
   ▼
[RUN_ACTIVE]
   │
   ├─► [PUZZLE_ACTIVE]
   │      │ win/lose
   │      ▼
   │   [PUZZLE_RESULT]
   │      │ continue
   │      ▼
   │   [SHOP] (after boss) ──► next stage
   │      │
   │      └─► [PUZZLE_ACTIVE] (next puzzle)
   │
   ├─► [GAME_OVER] (lives = 0)
   │
   └─► [RUN_WON] (stage 8 boss beaten)
```

### 4.2 Run Manager

**File**: `scripts/core/run_manager.gd`

```gdscript
class_name RunManager
extends RefCounted

signal puzzle_started
signal puzzle_ended(won: bool, score: int)
signal stage_advanced(stage: int)
signal shop_opened
signal run_ended(won: bool)

func start_run() -> void:
    GameState.run = RunState.new()
    GameState.operators = [OperatorRegistry.create("counter")]  # Starter
    _start_puzzle()

func _start_puzzle() -> void:
    var config = StageConfig.get_config(GameState.run.stage, GameState.run.puzzle_index)
    GameState.puzzle = PuzzleLogic.generate_puzzle(config)
    puzzle_started.emit()

func on_puzzle_submitted(score: int) -> void:
    if score >= GameState.run.score_target:
        _handle_win(score)
    else:
        _handle_loss()

func _handle_win(score: int) -> void:
    GameState.run.score += score
    GameState.run.money += _calculate_money(score)

    if GameState.run.is_boss:
        if GameState.run.stage >= 8:
            run_ended.emit(true)
        else:
            shop_opened.emit()
    else:
        GameState.run.puzzle_index += 1
        _start_puzzle()

func _handle_loss() -> void:
    GameState.run.lives -= 1
    if GameState.run.lives <= 0:
        run_ended.emit(false)
    else:
        # Retry same puzzle or move on?
        puzzle_ended.emit(false, 0)
```

---

## Phase 5: Shop

### 5.1 Shop State

```gdscript
class ShopState:
    var operator_slots: Array[Operator]  # 3 operators for sale
    var function_slots: Array[GameFunction]  # 2 functions for sale
    var reroll_cost: int = 2

    func generate(stage: int) -> void:
        # Populate slots based on stage (higher = better operators)
        pass

    func buy_operator(index: int) -> bool:
        var op = operator_slots[index]
        if GameState.run.money >= op.price:
            GameState.run.money -= op.price
            GameState.operators.append(op)
            operator_slots[index] = null
            return true
        return false
```

### 5.2 Shop UI (Later)

- Display 3 operators, 2 functions
- Show prices, descriptions
- Buy/sell buttons
- Reroll button
- "Continue" to next stage

---

## Phase 6: Debug Server Updates

Add to debug server:

| Action | Purpose |
|--------|---------|
| `get_run_state` | Query full run state |
| `set_run_state` | Set run state for tests |
| `set_puzzle` | Set explicit puzzle (grid + targets) |
| `add_operator` | Add operator to inventory |
| `remove_operator` | Remove operator |
| `trigger_shop` | Open shop state |
| `advance_stage` | Skip to next stage |

---

## Implementation Order

### Sprint 1: State Foundation
- [ ] Create `GameState` autoload
- [ ] Create `RunState` class
- [ ] Move puzzle state to `GameState`
- [ ] Add serialization methods
- [ ] Update debug server to use `GameState`
- [ ] Update tests to use explicit board setup

### Sprint 2: Operators
- [ ] Create `Operator` base class
- [ ] Create `OperatorRegistry`
- [ ] Implement 5 starter operators
- [ ] Update `ScoringEngine` to use operators
- [ ] Add operator debug server actions
- [ ] Write operator tests

### Sprint 3: Puzzle Generation
- [ ] Add negative number support
- [ ] Add slack parameter
- [ ] Add `set_puzzle` debug action
- [ ] Update tests

### Sprint 4: Run Flow
- [ ] Create `RunManager`
- [ ] Create `StageConfig`
- [ ] Implement state machine
- [ ] Add run HUD (lives, money, stage)
- [ ] Add win/lose screens

### Sprint 5: Shop
- [ ] Create `ShopState`
- [ ] Create shop UI scene
- [ ] Implement buy/sell/reroll
- [ ] Integrate with run flow

---

## File Structure (Final)

```
godot_app/
├── autoload/
│   ├── event_bus.gd (existing)
│   ├── game_state.gd (NEW)
│   └── debug_server.gd (existing, update)
├── scripts/
│   ├── core/
│   │   ├── puzzle_state.gd (existing)
│   │   ├── puzzle_logic.gd (existing, update)
│   │   ├── scoring_engine.gd (existing, update)
│   │   ├── run_state.gd (NEW)
│   │   ├── run_manager.gd (NEW)
│   │   ├── stage_config.gd (NEW)
│   │   └── game_config.gd (existing)
│   └── operators/
│       ├── operator.gd (NEW)
│       ├── operator_registry.gd (NEW)
│       └── impl/
│           ├── counter.gd (NEW)
│           ├── lucky_seven.gd (NEW)
│           ├── prime_time.gd (NEW)
│           ├── row_master.gd (NEW)
│           └── corner_bonus.gd (NEW)
├── scenes/
│   ├── main.gd (update to use GameState)
│   ├── main.tscn
│   ├── puzzle/ (existing)
│   ├── shop/
│   │   ├── shop.gd (NEW)
│   │   └── shop.tscn (NEW)
│   └── ui/
│       ├── run_hud.gd (NEW)
│       ├── run_hud.tscn (NEW)
│       ├── game_over.tscn (NEW)
│       └── run_won.tscn (NEW)
```

---

## Open Questions

1. **Retry on fail?** Lose life and retry same puzzle, or move on?
2. **Operator slots limit?** Start with 5, upgradeable?
3. **Function (consumable) design?** What are the first 3?
4. **Boss modifiers?** What's the first boss type?
5. **Save/load runs?** Or just single-session?

---

*Plan created: January 2026*
