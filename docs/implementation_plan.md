# Crosssums Implementation Plan - Godot 4.5

## Overview
Build a Balatro-inspired roguelike puzzle game where players delete numbers from a grid to make rows and columns sum to targets.

---

## Project Structure

```
godot_app/
├── autoload/                    # Singletons
│   ├── event_bus.gd            # Signal hub
│   ├── game_manager.gd         # Run state, game flow
│   └── audio_manager.gd        # SFX/music
│
├── scenes/
│   ├── main.tscn               # Entry point
│   ├── screens/                # Full screens
│   │   ├── title_screen.tscn
│   │   ├── puzzle_screen.tscn
│   │   ├── shop_screen.tscn
│   │   └── results_screen.tscn
│   ├── puzzle/                 # Puzzle components
│   │   ├── puzzle_grid.tscn
│   │   ├── grid_cell.tscn
│   │   └── target_display.tscn
│   ├── modifiers/              # Cards
│   │   ├── operator_card.tscn
│   │   └── operator_slot.tscn
│   └── ui/                     # Reusable UI
│       ├── hud.tscn
│       └── score_display.tscn
│
├── scripts/
│   ├── core/
│   │   ├── puzzle_state.gd     # Grid data structure
│   │   ├── puzzle_logic.gd     # Generation & validation
│   │   ├── scoring_engine.gd   # Score calculation
│   │   └── run_state.gd        # Run progression
│   └── modifiers/
│       ├── operator.gd         # Base operator class
│       └── modifier_registry.gd
│
├── resources/
│   └── operators/              # Operator definitions (.tres)
│
└── assets/
    ├── sprites/
    ├── audio/
    └── fonts/
```

---

## MVP Scope (Target: First Playable)

### Core Features
- [ ] Grid rendering (3x3 to 5x5)
- [ ] Cell deletion on click
- [ ] Real-time sum display
- [ ] Solution validation
- [ ] Basic scoring (base + kept bonuses + row multipliers)
- [ ] 5 starter operators
- [ ] 3 stages (9 puzzles total)
- [ ] Lives system (3 lives)
- [ ] Simple shop (buy operators)
- [ ] Title → Puzzle → Shop → Results flow

### MVP Operators
1. **Counter** (Common) - +10 pts per kept number
2. **Prime Time** (Uncommon) - +50 pts per prime kept
3. **Lucky Seven** (Common) - +77 pts per 7
4. **Zero Hero** (Uncommon) - x2 if any 0 kept
5. **Row Master** (Rare) - x1.5 per row

### Stage Configuration
| Stage | Grid | Score Required |
|-------|------|----------------|
| 1     | 3x3  | 300            |
| 2     | 4x4  | 800            |
| 3     | 5x5  | 2000           |

---

## Implementation Phases

### Phase 1: Core Puzzle (Foundation)
1. Create folder structure and autoloads
2. Implement `event_bus.gd` - signal hub
3. Implement `puzzle_state.gd` - grid data class
4. Create `grid_cell.tscn` - clickable number cell
5. Create `puzzle_grid.tscn` - dynamic NxN grid
6. Create `target_display.tscn` - row/column targets
7. Wire up cell deletion → sum recalculation
8. Color targets green/red based on current sum

**Key file: `scripts/core/puzzle_state.gd`**
```gdscript
class_name PuzzleState
var grid_size: Vector2i
var cells: Array[Array]  # 2D array of CellData
var row_targets: Array[int]
var col_targets: Array[int]
var deleted_cells: Array[Vector2i]
```

### Phase 2: Generation & Validation
1. Implement `puzzle_logic.gd`:
   - Generate valid solution first
   - Add extra deletable numbers
   - Calculate targets from solution
2. Add Submit button
3. Validate all rows/columns match targets
4. Show success/failure feedback

**Algorithm**: Generate solution row-by-row, tracking column sums. Last row solves column constraints.

### Phase 3: Scoring System
1. Implement `scoring_engine.gd`:
   - Base points by grid size (100/200/350)
   - +5 per kept number
   - Row multiplier: 1.0 + 0.2 per valid row/col
2. Create score breakdown display
3. Animate Balatro-style sequential reveal
4. Add score tick SFX

**Formula**: `Score = (Base + KeptBonus) × RowMult × OperatorMults`

### Phase 4: Operator System
1. Create `operator.gd` base Resource class
2. Create `modifier_registry.gd` singleton
3. Implement 5 MVP operators as resources
4. Create `operator_card.tscn` visual
5. Create `operator_slot.tscn` for HUD
6. Hook operators into scoring pipeline
7. Show operator effects in score breakdown

**Key pattern**: Operators process left-to-right like Balatro jokers.

### Phase 5: Run Structure
1. Implement `run_state.gd`:
   - Current stage/puzzle tracking
   - Money, lives, operators
   - Score requirements per stage
2. Implement `game_manager.gd` state machine
3. Create HUD (stage, lives, money, score target)
4. Implement stage progression
5. Create game over / run complete screens

### Phase 6: Shop System
1. Create `shop_screen.tscn` layout
2. Generate random operator offerings
3. Implement buy mechanics (deduct money)
4. Implement sell mechanics (drag to sell area)
5. Add reroll button ($2)
6. Continue button → next stage

### Phase 7: Polish
1. Cell deletion animations (pop, fade)
2. Score counting animations
3. Operator trigger effects (glow, shake)
4. Screen transitions
5. Sound effects throughout
6. Particles for big scores

---

## Key Architecture Decisions

### Event Bus Pattern
All game events flow through `event_bus.gd`:
```gdscript
signal cell_deleted(row, col, value)
signal puzzle_submitted()
signal score_calculated(breakdown)
signal operator_triggered(operator_id)
```

### Resource-Based Operators
Operators are Godot Resources for data-driven design:
```gdscript
class_name Operator extends Resource
@export var id: String
@export var display_name: String
@export var description: String
@export var rarity: Rarity
@export var base_price: int
func calculate_scoring_effect(ctx) -> Dictionary
```

### State Machine for Game Flow
```
TITLE → RUN_SETUP → PUZZLE_PLAYING → PUZZLE_RESULTS
                  ↗                 ↘
              SHOP ←←←←←←←←←←←←←←←←← (if not final stage)
                                     ↓
                              RUN_COMPLETE / GAME_OVER
```

---

## Critical Files to Create

| File | Purpose |
|------|---------|
| `autoload/event_bus.gd` | Signal hub - create first |
| `autoload/game_manager.gd` | Game state machine |
| `scripts/core/puzzle_state.gd` | Grid data structure |
| `scripts/core/puzzle_logic.gd` | Generation + validation |
| `scripts/core/scoring_engine.gd` | Score calculation |
| `scripts/core/run_state.gd` | Run progression data |
| `scripts/modifiers/operator.gd` | Operator base class |
| `scenes/puzzle/puzzle_grid.tscn` | Main gameplay scene |

---

## Post-MVP Roadmap

1. Functions (consumables)
2. Upgrades (vouchers)
3. Boss puzzles with special rules
4. Stages 4-8
5. More operators (25+)
6. Grid variations (decks)
7. Meta-progression/unlocks
8. Save/load system
