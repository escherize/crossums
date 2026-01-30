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
| `lucky_seven` | Lucky Seven | +77 points for each 7 kept | Common | 6 | cell_kept |
| `prime_time` | Prime Time | +30 points per prime kept | Uncommon | 8 | cell_kept |
| `row_master` | Row Master | +50 points per completed row | Common | 5 | row_complete |
| `corner_keeper` | Corner Keeper | +200 points if all 4 corners kept | Uncommon | 7 | puzzle_end |

---

## Planned Operators

### Scoring Operators

| ID | Name | Effect | Rarity | Hook |
|----|------|--------|--------|------|
| `column_master` | Column Master | +50 points per completed column | Common | col_complete |
| `zero_hero` | Zero Hero | ×2 score if any row sums using a 0 | Uncommon | puzzle_end |
| `even_steven` | Even Steven | +20 points per even number kept | Common | cell_kept |
| `odd_job` | Odd Job | +20 points per odd number kept | Common | cell_kept |
| `big_ten` | Big Ten | +100 points for each 10+ kept | Uncommon | cell_kept |
| `sequence` | Sequence | +150 points for 3+ consecutive numbers kept | Rare | puzzle_end |
| `pair_bonus` | Pair Bonus | +50 points for each pair of same numbers | Uncommon | puzzle_end |

### Transformation Operators

These change how numbers work in the puzzle.

| ID | Name | Effect | Rarity | Hook |
|----|------|--------|--------|------|
| `flipper` | Flipper | All 6s become 9s, all 9s become 6s | Uncommon | puzzle_start |
| `doubler` | Doubler | One random cell per row counts double | Rare | cell_kept |
| `negative_zone` | Negative Zone | Cells can be kept as negative values | Rare | cell_kept |
| `decimal_point` | Decimal Point | Numbers can be split (18 → 1.8) | Legendary | cell_kept |
| `wildcard` | Wildcard | One random cell becomes any number needed | Legendary | puzzle_start |

### Economy Operators

| ID | Name | Effect | Rarity | Hook |
|----|------|--------|--------|------|
| `calculator` | Calculator | +$2 for each unique digit in solution | Uncommon | puzzle_end |
| `banker` | Banker | +10% interest on money after each puzzle | Rare | puzzle_end |
| `thrifty` | Thrifty | -1 cost for all shop items | Uncommon | passive |
| `gold_finder` | Gold Finder | +$1 for each row with no mistakes | Common | puzzle_end |

### Rule-Breaking Operators

These bend the puzzle rules.

| ID | Name | Effect | Rarity | Hook |
|----|------|--------|--------|------|
| `overflow` | Overflow | Rows can exceed target by up to 10% | Rare | validation |
| `underflow` | Underflow | Rows can fall short by up to 10% | Rare | validation |
| `skip_row` | Skip Row | One row doesn't need to sum correctly | Rare | validation |
| `column_blind` | Column Blind | One column doesn't need to sum correctly | Rare | validation |
| `merger` | Merger | Adjacent same numbers can combine (3,3 → 6) | Legendary | cell_kept |

### Legendary Operators

Powerful, run-defining effects.

| ID | Name | Effect | Rarity | Hook |
|----|------|--------|--------|------|
| `mathematician` | Mathematician | Numbers also count as their digit sum (17 → 8) | Legendary | cell_kept |
| `quantum` | Quantum | Each kept number is simultaneously all its factors | Legendary | cell_kept |
| `infinity` | Infinity | One cell can be ANY value | Legendary | puzzle_start |
| `perfectionist` | Perfectionist | ×3 score if no restores used | Legendary | puzzle_end |

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
