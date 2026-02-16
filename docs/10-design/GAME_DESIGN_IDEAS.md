# Crossums Game Design

> Core design document for game mechanics and systems.
> Last updated: 2026-02-15

---

## Core Loop

1. **Solve puzzle** - Delete cells so each row/column sums to its target
2. **Beat the clock** - Timer runs out = game over
3. **Earn money** - Score converts to $ after each puzzle
4. **Buy operators** - Spend $ in shop to boost future earnings
5. **Progress** - Complete 3 puzzles per stage, 8 stages total

---

## Key Design Decisions

### Single-Solution Puzzles

Every puzzle has **exactly one valid solution**. The player's job is to *find* it, not *choose* it.

**Why:** Multi-solution puzzles made operators like "keep 7s for bonus" feel random rather than strategic. With single-solution, the puzzle is the challenge, and operators modify rewards.

### Timer as Fail Condition

Running out of time = game over. No "lives" system, no "critical cell mistakes."

**Why:**
- Transparent fail state (everyone understands timers)
- Undo is free - only cost is time
- Enables experimentation without fear

### Score → Money

Score earned from puzzles converts directly to money. No separate "score gates" for progression.

**Why:** Simplifies currencies. Money is the only resource you accumulate and spend.

---

## Currencies

| Currency | Source | Sink | Fail Condition |
|----------|--------|------|----------------|
| **Time** | Stage start | Solving puzzles | Run out → Game Over |
| **Money ($)** | Score conversion | Shop purchases | — |

That's it. Two currencies.

---

## Scoring System

### Base Formula

```
score = (kept_cells × base_points) × time_multiplier × operator_multipliers
```

### Components

| Component | Description |
|-----------|-------------|
| **Kept cells** | Cells remaining after solution (fixed by puzzle) |
| **Base points** | Points per kept cell (scales with grid size) |
| **Time multiplier** | Starts at 2.0×, decays to 1.0× over time |
| **Operator multipliers** | Bonuses from equipped operators |

### Score → Money Conversion

```
money_earned = floor(score / SCORE_TO_MONEY_DIVISOR)
```

Default divisor: 100 (so 500 points = $5)

### Exponential Scaling

Score can grow exponentially through:
- Operators that give ×mult (not just +bonus)
- Stacking multipliers across operators
- Time multiplier combining with operator multipliers

Early game: ~300 points = $3
Late game with good build: ~10,000+ points = $100+

---

## Operator Design Principles

### What Makes Good Operators (Single-Solution)

Operators should reward **how you play**, not **what the puzzle contains**:

| ✅ Good | ❌ Bad |
|---------|--------|
| Speed bonuses | "Keep 7s for bonus" (can't choose) |
| Precision bonuses (no restores) | "Keep corners" (can't choose) |
| Money multipliers | Cell value transformations |
| Time manipulation | Rule-breaking (invalid sums OK) |

### Operator Categories

1. **Scoring** - Flat bonuses, multipliers
2. **Economy** - Money bonuses, shop discounts
3. **Time** - Extensions, pauses, banking
4. **Utility** - Visual aids, auto-actions

---

## Progression

### Stage Structure

- 8 stages total
- 3 puzzles per stage (puzzle 3 = "boss")
- Shop after each stage
- Grid size increases: 3→3→4→4→5→5→6→6

### Difficulty Scaling

| Stage | Grid | Time Limit | Cell Values |
|-------|------|------------|-------------|
| 1 | 3×3 | 75s | 1-3 |
| 2 | 3×3 | 70s | 1-4 |
| 3 | 4×4 | 65s | 1-5 |
| 4 | 4×4 | 60s | 1-6 |
| 5 | 5×5 | 55s | 1-7 |
| 6 | 5×5 | 50s | 1-9 |
| 7 | 6×6 | 45s | -2 to 9 |
| 8 | 6×6 | 45s | -5 to 9 |

---

## Shop Economy

### What You Can Buy

| Item | Price Range | Effect |
|------|-------------|--------|
| Operators | $4-15 | Scoring/utility effects |
| Reroll | $2 | New shop inventory |
| Operator slots | $25-50 | Hold more operators |
| Operator upgrades | $10-40 | Level up existing operator |

### Expensive Late-Game Purchases

High scores need expensive sinks:
- 4th operator slot: $25
- 5th operator slot: $50
- Legendary operators: $30-50
- Operator level 2: $15, level 3: $30

---

## Open Questions

1. **Operator leveling** - Does upgrading operators add enough depth?
2. **Consumables** - Should there be one-time-use items?
3. **Meta-progression** - Unlocks across runs?

---

## References

- [OPERATORS.md](./OPERATORS.md) - Detailed operator designs
- [timer_as_fail_condition.md](./timer_as_fail_condition.md) - Timer design rationale
