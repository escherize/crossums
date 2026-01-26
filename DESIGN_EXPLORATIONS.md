# Design Explorations

> Captured from design discussion, January 2026

## Core Insight: Easy Boards + Operators

The puzzle doesn't need to be hard to solve. Many solutions can be valid. **Operators make you want specific solutions.**

### The Pattern (from Balatro)
- Making *a* valid hand is easy
- Jokers make you *want* specific hands
- Skill = optimization, not just validity

### Applied to Crosssums
- Easy board: multiple valid solutions
- Operators reward specific solutions: keep 7s, keep corners, minimize cells, adjacency bonuses
- Question shifts from "can I solve?" to "what's the BEST solve?"

## Difficulty Tuning via Board Generation

| Phase | Board Difficulty | Operators | Challenge |
|-------|------------------|-----------|-----------|
| Early | Easy (many solutions) | Simple | Learn mechanics |
| Mid | Easy | Complex | Optimization |
| Late | Tighter | Stacked | Both skills |
| Boss | Constrained | Synergy-dependent | Mastery |

## Negative Numbers (Must Have)

```
Row target: 5
Cells: [3] [4] [-2] [6]

Keep 3 + 4 - 2 = 5 ✓
```

- Mental math gets interesting
- Negatives can "undo" overshoots
- Opens new operator designs
- Mid-game unlock in progression

## What Makes Puzzles Harder (Not Locked Cells)

| Easier | Harder |
|--------|--------|
| Locked cells (fewer choices) | More valid cells than needed |
| Wide target tolerance | Tight targets (fewer solutions) |
| Small grids | Large grids |
| All positive | Mixed positive/negative |

## Spatial Advantages (vs Balatro's 1D)

Crosssums has a 2D grid. Lean into it:
- Region effects (2x2, diagonal, corners)
- Adjacency bonuses
- Pattern bonuses (L-shape, T-shape, lines)
- Chain reactions

## Progression: Mastery-Based (Not Ante-Based)

Instead of "beat score or die":
- Prove skill → unlock new mechanics
- Less punishing, more "climbing"
- Zones introduce new concepts (negatives, operators, grid sizes)

## Skill Growth Axes

1. **Forced move recognition** - see what MUST go
2. **Number sense** - quick mental math
3. **Solution optimization** - find best among valid
4. **Operator vision** - see how operators change optimal play

## Memorable Moments

- Perfect solve (maximum cells kept)
- Clutch operator use
- Cascade solve (one deletion unlocks everything)
- Speed flex

## Naming

- "Operators" not "Jokers" (math terminology, fits theme)
- Consumables = "Functions"? (one-time use)

---

*To be continued with implementation planning*
