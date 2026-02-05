# Multi-Solution Puzzle Generation

## Problem Statement

The current puzzle generator creates puzzles with exactly **one solution**. This limits player agency - there's no meaningful choice in HOW to solve, only whether you find THE answer.

**Goal**: Generate puzzles with multiple valid solutions so players can make strategic choices (e.g., "keep corners for my Corner Keeper operator" vs "keep this row for Row Master").

---

## Key Insight

**Value diversity controls solution count.**

- All same values (e.g., all 1s) → maximum solutions (purely combinatorial)
- All different values → tends toward single solution
- Controlled repetition OR coincidental sums → controlled solution count

However, **low diversity removes the math challenge**. If all cells are 1s, players don't need to calculate sums - they just pick patterns. The arithmetic IS the game.

---

## Approach A: Coincidental Sums (Recommended)

### Concept

Keep full value diversity (1-9), but find target configurations where **different number combinations happen to sum to the same target**.

```
Row: [1] [7] [3] [5]   Target: 8

Solutions:
  - Keep {1, 7} → 1+7 = 8 ✓
  - Keep {3, 5} → 3+5 = 8 ✓

Player must recognize BOTH pairs sum to 8.
Math preserved. Choice introduced.
```

### Why This Works

The puzzle remains a math challenge - players must calculate whether subsets hit targets. But multiple subsets can "coincidentally" work, creating strategic options.

### Algorithm

```
1. Generate grid with diverse values (1-9, normal distribution)

2. For each possible target configuration:
   a. Calculate row/column sums for a candidate "keep set"
   b. Use those sums as targets
   c. Count all valid solutions (different keep sets that also satisfy targets)
   d. If solution_count in desired range [2, 5], accept

3. Key: Don't reduce diversity. Instead, search for targets where
   multiple diverse subsets happen to produce the same sums.

4. Optimization: Prioritize grids where values have "sum partners"
   - If row has [1,7,3,5], note that 1+7=8 and 3+5=8
   - Target 8 for this row enables choice
```

### Pros
- Preserves full arithmetic challenge
- Choices feel earned ("I noticed both pairs sum to 8!")
- Works with existing value ranges
- Operators remain strategic (choose solution that triggers bonuses)

### Cons
- Harder to generate (coincidences are statistically rare)
- May require more generation attempts
- Solution count less predictable

### Implementation Notes

```gdscript
# Pseudo-code for coincidental sum detection
func find_sum_partners(row_values: Array) -> Dictionary:
    # Returns {sum: [[indices that produce it], ...]}
    var sum_groups = {}
    for subset in all_subsets(row_values):
        var s = subset.sum()
        if not sum_groups.has(s):
            sum_groups[s] = []
        sum_groups[s].append(subset.indices)

    # Filter to sums with multiple ways to achieve
    return sum_groups.filter(func(s, groups): return groups.size() > 1)
```

---

## Approach B: Flexible Region (Hybrid)

### Concept

Generate a normal single-solution puzzle, then embed a small "exchange pattern" region where either choice works.

```
Normal puzzle:
[5] [3] [4] [2]     ← Requires specific solution
[2] [6] [1] [8]     ← Requires specific solution
[4] [4] [7] [3]     ← This 2x2 has exchange pattern
[4] [4] [5] [1]     ← Either diagonal works

The 2x2 in bottom-left:
[4] [4]   Diagonal A: 4+4 = 8
[4] [4]   Diagonal B: 4+4 = 8

Player can choose which diagonal to keep.
```

### Exchange Pattern Definition

A 2x2 subgrid where both diagonals sum to the same value:

```
[a] [b]
[c] [d]

If a + d = b + c, player can keep either diagonal.
```

### Algorithm

```
1. Generate normal single-solution puzzle using existing algorithm

2. Scan for potential exchange pattern locations (2x2 subgrids)

3. For each candidate location:
   a. Check if modifying values could create equal diagonal sums
   b. Verify the rest of the puzzle still has valid solution
   c. Adjust row/column targets to accommodate both diagonals

4. Alternative: Intentionally place exchange pattern during generation
   - Pick a 2x2 region
   - Set values so diagonals are equal (e.g., all same value)
   - Build rest of puzzle around it
```

### Pros
- Guaranteed single choice point
- Most of puzzle retains full math challenge
- Predictable solution count (exactly 2^k for k exchange patterns)
- Easier to generate than pure coincidental sums

### Cons
- Choice point is localized, may feel artificial
- Low-diversity region (the exchange pattern) stands out visually
- Less emergent - choice is "designed in" rather than discovered

### Implementation Notes

```gdscript
# Creating an exchange pattern
func create_exchange_pattern(state: PuzzleState, row: int, col: int) -> bool:
    # Make 2x2 at (row,col) have equal diagonals
    var a = state.get_cell(row, col).value
    var d = state.get_cell(row+1, col+1).value
    var sum = a + d

    # Find b,c where b+c = sum and both in valid range
    for b in range(1, min(sum, 10)):
        var c = sum - b
        if c >= 1 and c <= 9:
            state.get_cell(row, col+1).value = b
            state.get_cell(row+1, col).value = c
            return true
    return false
```

---

## Comparison

| Aspect | Approach A (Coincidental) | Approach B (Flexible Region) |
|--------|---------------------------|------------------------------|
| Math challenge | Fully preserved | Mostly preserved |
| Choice feeling | Emergent, discovered | Designed, localized |
| Generation difficulty | Higher | Lower |
| Solution count control | Less predictable | Precise (2^k) |
| Visual appearance | Normal grid | May have obvious repeated values |
| Operator synergy | Natural | Works but feels "set up" |

---

## Recommendation

**Start with Approach A** (coincidental sums) as the primary method:
- Preserves the core puzzle experience
- Choices feel rewarding when discovered
- Aligns with Balatro-style "find the combo" gameplay

**Use Approach B as fallback** when Approach A fails to find multi-solution puzzles within attempt limits.

---

## Future Considerations

### Operator Integration

Solution count could be a configurable parameter affected by operators:

```gdscript
var base_solutions = 3
var operator_bonus = GameState.get_operator_solution_modifier()  # e.g., +2
var target = base_solutions + operator_bonus

var puzzle = PuzzleGenerator.generate(grid_size, target, rng)
```

Example operators:
- **"Chaos Theory"**: +2 target solutions (more choices)
- **"Perfectionist"**: -2 target solutions (fewer choices, higher precision bonus)

### Difficulty Scaling

Earlier stages could have more solutions (forgiving), later stages fewer (demanding):

```gdscript
var stage_solution_targets = {
    1: 4,  # Early: lots of valid paths
    2: 4,
    3: 3,
    4: 3,
    5: 2,  # Late: fewer options, more precise
    6: 2,
    7: 2,
    8: 1,  # Final: single solution, pure challenge
}
```

### Showing Solution Count to Player

Consider UI feedback:
- "Multiple solutions exist" indicator
- Post-solve: "You found 1 of 3 possible solutions"
- Achievement: "Found the optimal solution" (highest score among alternatives)

---

## Current Implementation Status

The `PuzzleGenerator` class in `scripts/core/puzzle_generator.gd` currently implements a diversity-based approach that sacrifices math challenge for solution count control.

**Next step**: Refactor to prioritize Approach A (coincidental sums with full diversity), falling back to Approach B (exchange patterns) or current diversity method only when needed.
