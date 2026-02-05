# Legacy Puzzle Generation Strategies

This document preserves puzzle generation strategies that were explored but not used in the final implementation. They're kept for reference in case we want to revisit them.

## Current Approach (as of Feb 2026)

The puzzle generator now uses two simple strategies:

1. **Single-solution** (for boss boards): Random values, find targets giving exactly 1 solution
2. **Multi-solution** (normal puzzles): Create 2x2 exchange patterns, then shuffle the board

This is simpler and more predictable than the previous approaches.

---

## Legacy Strategy 1: Coincidental Sums

### Concept
Fill the grid with diverse values (1-9), then search for target configurations where different number combinations happen to sum to the same target.

**Example**: Row `[1, 7, 3, 5]` with target 8:
- Both `{1,7}` and `{3,5}` sum to 8
- Player must recognize both pairs - math challenge preserved!

### Algorithm
```gdscript
1. Fill grid with random values 1-9
2. For each row, find all "sum partners" - different subsets that sum to same value
3. Pick targets with high "partner scores" (more ways to achieve them)
4. Verify solution count is in desired range
5. Repeat up to 100 times
```

### Why We Moved Away
- **Statistically rare**: With truly diverse values, coincidences are uncommon
- **Low success rate**: Often fell back to other strategies anyway
- **Unpredictable**: Hard to control solution count
- **Slow**: Required many attempts to find valid configurations

### Code Reference
```gdscript
static func _strategy_coincidental_sums(grid_size, min_solutions, max_solutions, rng):
    for _attempt in range(100):
        # Fill grid with diverse values (1-9)
        for row in range(grid_size.y):
            for col in range(grid_size.x):
                state.get_cell(row, col).value = rng.randi_range(1, 9)

        # Try to find good targets using sum partners
        result = _find_coincidental_targets(state, min_solutions, max_solutions, rng)
        if result != null:
            return result
    return null

static func _find_sum_partners(cells: Array) -> Dictionary:
    # Returns {sum: [[indices that produce it], ...]}
    # Generate all 2^n subsets, group by sum
    var sum_groups = {}
    for mask in range(1, 1 << n):
        var subset_sum = sum of cells where bit is set
        sum_groups[subset_sum].append(indices)
    return sum_groups
```

---

## Legacy Strategy 2: Controlled Value Diversity

### Concept
Control solution count by controlling how many unique values appear in the grid.
- **Low diversity** (all same values): Many solutions (any subset of same size works)
- **High diversity** (all different values): Few solutions

### Algorithm
```gdscript
1. Map target solution count to diversity level (logarithmic)
2. Fill grid with values at that diversity level:
   - diversity < 0.2: mostly same value
   - diversity 0.2-0.5: 2-3 distinct values
   - diversity 0.5-0.7: 3-5 distinct values
   - diversity > 0.7: full range 1-9
3. Find targets that give solutions in range
```

### Why We Moved Away
- **Sacrifices math challenge**: Low diversity grids (all 3s, all 1s) are trivial
- **Visually boring**: Uniform rows are obvious even after shuffling
- **Feels like cheating**: Players notice the repeated values

### Code Reference
```gdscript
static func _fill_with_diversity(state, diversity, rng):
    if diversity < 0.2:
        # Very low: mostly same value
        var base = rng.randi_range(1, 3)
        for cell in grid:
            cell.value = base if rng.randf() > diversity*2 else rng.randi_range(1,4)
    elif diversity < 0.5:
        # Medium-low: 2-3 values
        var values = [rng.randi_range(1,3), rng.randi_range(2,5)]
        for cell in grid:
            cell.value = values[rng.randi() % values.size()]
    # ... etc
```

---

## Legacy Strategy 3: Exchange Patterns (Old Implementation)

### Concept
Create 2x2 regions where both diagonals sum to the same value:
```
[a][b]   where a+d = b+c
[c][d]   Player can keep {a,d} OR {b,c}
```

Each independent 2x2 pattern doubles the solution count (2^k solutions for k patterns).

### Algorithm
```gdscript
1. Fill grid with base values (1-5)
2. Calculate needed patterns: k = log2(target_solutions)
3. For each pattern position:
   - Read existing a, d values
   - Set b, c such that b+c = a+d
   - Mark cells as used (no overlapping patterns)
4. Find targets
```

### Why We Moved Away (from this implementation)
- **Not actually removed**: We still use exchange patterns!
- **This old version** had issues:
  - Used fixed base values 1-5 (low diversity)
  - Didn't shuffle to disperse patterns
  - Complex overlap detection

The new implementation:
- Uses random 1-9 values first
- Creates patterns by modifying only b and c
- Shuffles entire board to disperse patterns

---

## Legacy Strategy 4: Random Sampling

### Concept
Simplest approach: random values, random keep-sets, check if solution count is acceptable.

### Algorithm
```gdscript
1. Fill grid with random values 1-9
2. Sample random keep-sets (30-70% of cells)
3. Calculate targets from keep-set
4. Count solutions
5. Accept if in range, else retry
```

### Why We Moved Away
- **Unpredictable**: Solution count varies wildly
- **No control**: Can't reliably get specific solution counts
- **Still used for single-solution**: The new `generate_single_solution` is essentially this with `target = 1`

---

## Lessons Learned

1. **Simpler is better**: The exchange pattern + shuffle approach is straightforward and works
2. **Visual matters**: Players notice repeated values, even after shuffling
3. **Control > variety**: Predictable solution counts are more important than diverse algorithms
4. **Math challenge vs choice**: There's a fundamental tradeoff - we chose exchange patterns as a good middle ground
