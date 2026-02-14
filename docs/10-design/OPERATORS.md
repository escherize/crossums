# Operators

Operators are Balatro-inspired scoring modifiers that trigger on specific in-game events. Players can hold up to 5 operators at a time.

## Hook System

Each operator can implement these hooks:

| Hook | Trigger | Returns |
|------|---------|---------|
| `on_cell_kept(row, col, value, puzzle)` | Each kept cell during scoring | `score_bonus`, `mult_bonus` |
| `on_row_complete(row, puzzle)` | Each row that matches target | `score_bonus`, `mult_bonus` |
| `on_col_complete(col, puzzle)` | Each column that matches target | `score_bonus`, `mult_bonus` |
| `on_puzzle_end(puzzle)` | Once after all scoring | `score_bonus`, `mult_bonus`, `money_bonus` |
| `on_puzzle_start(puzzle)` | When puzzle loads | Setup effects |

## Implemented Operators

| ID | Name | Effect | Rarity | Price | Hook |
|----|------|--------|--------|-------|------|
| `counter` | Counter | +10 points per kept cell | Common | 5 | cell_kept |
| `row_master` | Row Master | +50 points per completed row | Common | 5 | row_complete |
| `column_master` | Column Master | +50 points per completed column | Common | 5 | col_complete |
| `circlicious` | Circlicious | +$2 per circled, -$1 per deleted | Uncommon | 6 | puzzle_end |
| `elite_delete` | Elite Delete | +$2 per deleted, -$1 per circled | Uncommon | 6 | puzzle_end |
| `purist` | Purist | +300 points if no circles used | Uncommon | 7 | puzzle_end |
| `gimme` | Gimme | Auto-solves when 1 row & 1 col remain | Uncommon | 6 | auto_action |

---

## Planned Operators

> **Note:** Many originally planned operators were removed because they conflict with single-solution puzzle design. Operators that reward "keeping specific cells" (like Corner Keeper, Lucky Seven) don't work when there's only one valid solution.

### Viable Candidates

| ID | Name | Effect | Rarity | Hook | Notes |
|----|------|--------|--------|------|-------|
| `banker` | Banker | +10% interest on money after each puzzle | Rare | puzzle_end | Passive economy |
| `thrifty` | Thrifty | -1 cost for all shop items | Uncommon | passive | Passive economy |
| `gold_finder` | Gold Finder | +$1 for each row with no mistakes | Common | puzzle_end | Rewards precision |
| `perfectionist` | Perfectionist | ×3 score if no restores used | Legendary | puzzle_end | Rewards precision |
| `speed_demon` | Speed Demon | +100 points if solved under 10 seconds | Rare | puzzle_end | Rewards speed |
| `combo_king` | Combo King | +25 points per cell deleted in a row without undo | Uncommon | cell_deleted | Rewards flow |

### Rejected (Conflict with Single-Solution)

These were removed because they reward keeping specific cell values/patterns, but single-solution puzzles don't give players that choice:

- Lucky Seven, Prime Time, Corner Keeper, Even Steven, Odd Job, Big Ten, Sequence, Pair Bonus, Calculator
- Transformation operators (Flipper, Doubler, etc.) - change valid solutions
- Rule-breaking operators (Overflow, Skip Row, etc.) - change valid solutions

---

## Operator Editions (Future)

Special variants that modify any operator:

| Edition | Effect |
|---------|--------|
| Golden | +$5 when puzzle completed |
| Holographic | +25 points per puzzle |
| Prismatic | ×1.2 score multiplier |
| Negative | Doesn't take an operator slot |

---

## Design Notes

### Rarity Distribution
- **Common (0)**: Simple, always-useful bonuses
- **Uncommon (1)**: Conditional bonuses requiring some strategy
- **Rare (2)**: Powerful effects that shape playstyle
- **Legendary (3)**: Run-defining, game-changing effects

### Spatial Opportunities
The 2D grid enables unique operator designs:
- Region effects (2×2 areas, diagonals, corners)
- Adjacency bonuses (kept cells next to each other)
- Pattern recognition (L-shapes, T-shapes, lines)

### Implementation Priority
1. Simple scoring (Column Master, Zero Hero, Even Steven)
2. Transformation (Flipper, Doubler)
3. Economy (Calculator, Banker)
4. Rule-breaking (Overflow/Underflow)
5. Legendary (as progression rewards)
