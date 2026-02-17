# Pace Rating System (2026-02-16)

> **Status:** Implemented

## Overview

Replaced the grade-based scoring system with a **Pace Rating** system that is:
- **Super-linear** - fast solves earn exponentially more
- **Easy to understand** - seconds per cell is intuitive
- **Fair across grid sizes** - 1s/cell means the same on 3x3 or 6x6

## Formula

```
pace = time_used / cell_count
rating = (12 - pace) + clean_bonus + operator_bonus
money = round(rating³ / 100) × streak_mult
```

### Components

| Component | Formula | Range |
|-----------|---------|-------|
| Pace Rating | `12 - (time/cells)` | ~7-12 typically |
| Clean Bonus | `max(0, 2.0 - missteps × 0.5)` | 0-2 |
| Operator Bonus | `operator_score / 50` | varies |
| Streak Mult | `[1.0, 1.0, 1.5, 2.0, 3.0][streak]` | 1-3x |

### Missteps

A "misstep" is recorded when the player changes their mind:
- Delete a cell, then restore it
- Circle a cell, then uncircle it
- Use the undo button

Clean solves (0 missteps) earn +2.0 rating bonus.

### Streak & Missteps

Streak rewards **consistent clean play**:
- **0-3 missteps**: Streak continues and you get the streak multiplier
- **4+ missteps**: Streak broken - you lose the multiplier AND reset to 0 (`STREAK_MISSTEP_THRESHOLD = 4`)

This means sloppy play is punished twice:
1. No clean bonus (4+ missteps means clean_bonus = 0)
2. No streak multiplier (even if you had built one up)

### Money Examples

| Scenario | Pace | Clean | Ops | Rating | Money |
|----------|------|-------|-----|--------|-------|
| Slow 3x3 | 3s | +2.0 | 0 | 11.0 | $13 |
| Fast 3x3 | 1s | +2.0 | 0 | 13.0 | $22 |
| Fast 6x6 | 1s | +2.0 | +1 | 14.0 | $27 |
| Fast + streak | 1s | +2.0 | 0 | 13.0 | $44 (×2) |
| Messy solve | 2s | +0.5 | 0 | 10.5 | $11 |

### Letter Grades (from Rating)

| Rating | Grade |
|--------|-------|
| 14+ | SS |
| 12+ | S |
| 10+ | A |
| 8+ | B |
| 6+ | C |
| <6 | D |

## Display Format

The result popup shows the full arithmetic breakdown:

```
┌─────────────────────────────┐
│         PASS!               │
│           S                 │
│                             │
│  PACE: 0.70 sec/cell        │
│  Rating: 11.3               │
│  ───────────                │
│  Zero missteps!             │
│  Clean bonus: + 2           │
│  ───────────                │
│  Operator bonus: 0          │
│  ───────────                │
│  Total Rating:              │
│  11.3 + 2 = 13.3            │
│  ───────────                │
│  round(13.3^3 / 100) = $24  │
│                             │
│         +$24                │
│       [Continue]            │
└─────────────────────────────┘
```

With streak multiplier, it shows: `$24 x 1.5 = +$36`

## Files Modified

1. **`puzzle_state.gd`** - Added `misstep_count` tracking
2. **`game_config.gd`** - Pace rating constants, streak multipliers
3. **`run_state.gd`** - Added `streak` tracking
4. **`scoring_engine.gd`** - New `RatingBreakdown` class and `calculate_rating()`
5. **`run_manager.gd`** - New `on_puzzle_complete_rating()` method
6. **`main.gd`** - Updated to use new rating system
7. **`result_popup.gd`** - New `show_result_rating()` display

## Design Rationale

**Why pace (time per cell)?**
> Scales naturally with grid size. A 1s/cell solve means the same skill level whether it's a 3x3 (9s total) or 6x6 (36s total).

**Why cubed?**
> Super-linear rewards for speed. Going from 2s/cell to 1s/cell more than doubles your money. This creates meaningful decisions about when to play safe vs push for speed.

**Why track missteps?**
> Rewards confident, decisive play. A player who knows the solution immediately should earn more than one who backtracks multiple times.

**Why streak multiplier?**
> Rewards consistency across puzzles. Maintains tension even on "easy" puzzles since breaking a streak hurts.
