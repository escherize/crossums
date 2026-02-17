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

## Scoring System: Pace Rating

### Formula

```
pace = time_used / cell_count        // seconds per cell
pace_rating = 12 - pace              // faster = higher
clean_bonus = max(0, 2.0 - missteps × 0.5)  // 0 missteps = +2.0, 4+ = 0
operator_bonus = operator_score / 50
total_rating = pace_rating + clean_bonus + operator_bonus
money = round(rating³ / 100) × streak_mult
```

### Components

| Component | Formula | Range |
|-----------|---------|-------|
| **Pace Rating** | `12 - (time/cells)` | ~7-12 typically |
| **Clean Bonus** | `max(0, 2.0 - missteps × 0.5)` | 0-2 |
| **Operator Bonus** | `operator_score / 50` | varies |
| **Streak Mult** | `[1.0, 1.0, 1.5, 2.0, 3.0][streak]` | 1-3x |

### Missteps

A "misstep" is recorded when the player changes their mind:
- Delete a cell, then restore it
- Circle a cell, then uncircle it
- Use the undo button

**Streak breaks at 4+ missteps** - you lose the multiplier AND reset to 0.

### Letter Grades (from Rating)

| Rating | Grade |
|--------|-------|
| 14+ | SS |
| 12+ | S |
| 10+ | A |
| 8+ | B |
| 6+ | C |
| <6 | D |

### Money Examples

| Scenario | Pace | Clean | Ops | Rating | Money |
|----------|------|-------|-----|--------|-------|
| Slow 3x3 | 3s | +2.0 | 0 | 11.0 | $13 |
| Fast 3x3 | 1s | +2.0 | 0 | 13.0 | $22 |
| Fast 6x6 | 1s | +2.0 | +1 | 14.0 | $27 |
| Fast + streak | 1s | +2.0 | 0 | 13.0 | $44 (x2) |
| Messy solve | 2s | +0.5 | 0 | 10.5 | $11 |

See [score_screen_redesign.md](./score_screen_redesign.md) for full design rationale.

---

## Operator Design Principles

### What Makes Good Operators (Single-Solution)

Operators should reward **how you play**, not **what the puzzle contains**:

| Good Operator Design | Bad Operator Design |
|----------------------|---------------------|
| Speed bonuses | "Keep 7s for bonus" (can't choose) |
| Clean play bonuses (low missteps) | "Keep corners" (can't choose) |
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
