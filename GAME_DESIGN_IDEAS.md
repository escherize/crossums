# Crosssums Game Design Ideas

> Living document for game design brainstorming and iteration

---

## The Core Problem: What Choices Affect Score?

Currently, the player's only meaningful choice is **finding a solution that keeps more cells**. That's thin.

### Current Player Agency

| Choice | Impact |
|--------|--------|
| Which cells to delete | Core mechanic |
| Which solution to pick (when multiple exist) | More kept cells = more points |

That's it. We need more axes of optimization.

---

## The "Second Axis" Problem

**Balatro has Chips × Mult** - two things you're always optimizing. The tension between them creates interesting decisions.

**Crosssums currently has one axis**: kept cells bonus.

### Potential Second Axes

| Axis | How It Works | Tension Created |
|------|--------------|-----------------|
| **Time** | Decaying multiplier rewards speed | Speed vs. optimization |
| **Precision** | Mistakes/restores reduce bonus | Commitment vs. exploration |
| **Money** | Gold cells give $ if kept | Optimal solution vs. profitable solution |
| **Streak** | Consecutive wins build multiplier | Risk-taking vs. playing safe |

---

## Idea: Time Bonus Multiplier

Instead of a hard timer (frustrating), use a **decaying bonus multiplier**:

```
Time Multiplier: starts at 2.0x, decays to 1.0x over [X] seconds
```

### Design Parameters to Tune

- Starting multiplier (1.5x? 2.0x?)
- Floor (1.0x or lower?)
- Decay curve (linear? exponential?)
- Time window (30 sec? 60 sec? scales with grid size?)

### Pros
- Fast solves rewarded, slow solves still possible
- Adds tension without frustration
- Creates speed vs. optimization tradeoff

### Cons
- May conflict with "relaxing puzzle" feel
- Could punish new players
- Needs careful tuning per grid size

### Variant: Energy Pool
- Energy depletes over time across ALL puzzles in a stage
- Run out = lose a life
- Creates meta-tension: "can I afford to think on this one?"

---

## Idea: Precision Rating

Track player mistakes and reward clean solves.

### What Counts as a "Mistake"?

| Action | Penalty? |
|--------|----------|
| Delete a cell | No (core mechanic) |
| Restore a deleted cell | Yes - you changed your mind |
| Delete a cell that's in ALL valid solutions | Big yes - you broke it |

### Precision Multiplier

```
Perfect solve (no restores): 1.5x
1-2 restores: 1.25x
3+ restores: 1.0x
Broke the puzzle (had to restore critical cell): 0.75x
```

### Variant: Limited Restores
- Give player 3 "undo tokens" per puzzle
- Using them costs score but saves the solve
- Creates commitment tension

---

## Idea: Gold Cells

Some cells are marked as "gold" - if kept in your solution, you earn bonus money.

### Design

- Random cells (maybe 1-3 per puzzle) are gold
- If a gold cell is part of your solution: +$1-3
- If you delete a gold cell: nothing (no penalty)

### Why This Works

Creates a **third optimization target**:
1. Find a valid solution
2. Keep as many cells as possible (score)
3. Keep gold cells if possible (money)

Sometimes the optimal-score solution doesn't include the gold cell. Choice!

### Variants

- **Silver cells**: +bonus score instead of money
- **Cursed cells**: penalty if kept (avoid them)
- **Wild cells**: count as any number (easier but worth less)

---

## Idea: Combo/Streak System

Consecutive successful puzzles build a multiplier.

### Simple Version

```
Puzzle 1: 1.0x
Puzzle 2: 1.1x
Puzzle 3: 1.2x
...
Fail a puzzle: reset to 1.0x
```

### Stakes Version

- Streak multiplier is visible
- Player can "cash out" streak for bonus $ between puzzles
- Or risk it for higher multiplier
- Fail = lose the streak

---

## Idea: Cell Types (Beyond Gold)

| Cell Type | Visual | Effect |
|-----------|--------|--------|
| **Normal** | Plain | Standard behavior |
| **Gold** | Gold border | +$ if kept |
| **Locked** | Padlock icon | Cannot be deleted |
| **Fragile** | Cracked | If deleted, breaks adjacent cell too |
| **Wild** | ? symbol | Counts as any number (0-9) |
| **Negative** | Red text | Subtracts from sum instead of adding |
| **Multiplier** | ×2 badge | Doubles its value in sums |

These could be:
- Random in puzzles
- Introduced by Operators
- Part of specific stage themes

---

## Balatro Systems → Crosssums Mapping

| Balatro | Crosssums Equivalent | Status |
|---------|---------------------|--------|
| Chips | Base points by grid | Done |
| Mult | Line multiplier | Done |
| Jokers | Operators | Planned (Phase 4) |
| Planet cards | Level up... what? | **Open question** |
| Tarot cards | Consumables (hints, etc.) | Planned |
| Vouchers | Run-wide upgrades | Planned |
| Money | Shop currency | Planned |
| Hands/Discards | ??? | **Open question** |

### Open Question: What's Our "Planet Cards"?

In Balatro, Planet cards level up specific hand types permanently for the run.

What could level up in Crosssums?
- Specific number values (level up 7s to be worth more?)
- Grid sizes (level up 4x4 to give more base points?)
- Row/column bonuses?
- Operator effectiveness?

---

## Currencies and Resources

### Confirmed
- **Score**: Beat the target to pass
- **Money ($)**: Buy operators in shop

### Candidates to Add
- **Precision rating**: Affects... something?
- **Streak counter**: Multiplier or shop discount?
- **Energy/Time**: Shared resource across stage?
- **XP**: Level up operators?

### Operator Leveling (Speculative)

What if operators gained XP and leveled up?

```
Counter Lv.1: +10 pts per kept number
Counter Lv.2: +15 pts per kept number
Counter Lv.3: +20 pts per kept number
```

- Creates attachment to specific operators
- Adds another optimization dimension
- Risk: complexity creep

---

## Consumables (One-Time Use Items)

| Consumable | Effect | Cost |
|------------|--------|------|
| **Hint** | Reveals one solution cell | $3 |
| **Reroll** | Generate new puzzle (same difficulty) | $2 |
| **Freeze** | Pause time multiplier for 10 sec | $2 |
| **Restore+** | Restore a cell without precision penalty | $1 |
| **Double Down** | 2x kept bonus, but lose life if fail | Free |
| **Magnify** | One cell counts double in sums | $3 |
| **Swap** | Exchange two cells' positions | $2 |

---

## Priority Ranking

What to implement first (low effort, high impact):

### Tier 1: Do Soon
1. **Time bonus multiplier** - Adds tension, easy to implement
2. **Gold cells** - Third optimization axis, visual interest
3. **Basic precision tracking** - Foundation for later systems

### Tier 2: Do After Core Loop Feels Good
4. Streak system
5. Consumables (start with Hint)
6. Operator leveling

### Tier 3: Explore Later
7. Complex cell types (wild, negative, etc.)
8. Planet card equivalent
9. Energy pool system

---

## Open Questions

1. **How punishing should time pressure be?** Decaying bonus vs. actual failure?

2. **Should precision affect score or money?** Or something else?

3. **What's the Crossums equivalent of "leveling up hand types"?**

4. **How do we make multiple solutions feel intentional?** Right now it's accidental - should we lean into it or ensure unique solutions?

5. **Is there a "discard" equivalent?** Balatro has hands AND discards. We only have deletion.

6. **What breaks the game in a fun way?** Balatro lets you score millions. What's our absurd ceiling?

---

## Decisions Made

| Decision | Date | Rationale |
|----------|------|-----------|
| Kept cells bonus (+25 per cell) | 2026-01-23 | Rewards optimization |
| 2-state target colors (red/green) | 2026-01-23 | Simpler than 3-state |
| No hard timer | TBD | Puzzle games shouldn't stress |

---

## References

- See `crosssums-design-doc.md` for full design spec
- See `balatro-report.md` for Balatro analysis
- See `implementation_plan.md` for technical roadmap

---

*Last updated: 2026-01-24*
