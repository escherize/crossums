# Design Decision: Timer as Fail Condition

> **Decision:** Replace "critical cell" mistake system with timer-based failure.
> **Date:** 2026-02-15
> **Status:** Approved

---

## The Change

| Before | After |
|--------|-------|
| Delete critical cell → lose life | Delete any cell → OK |
| Timer affects score multiplier | Timer expiring = fail puzzle |
| "Mistake" = invisible rule violation | No "mistakes" - just solve or timeout |

---

## Why This is Better

### 1. Transparent Fail Condition

**Before:** Players couldn't see why a cell was "wrong" to delete. The critical cell concept requires solver-level reasoning that's invisible to players.

**After:** Everyone understands timers. Clock hits zero = you lose. No hidden rules.

### 2. Productive vs Paralyzing Anxiety

**Before:** "Is this cell safe to delete?" → Hesitation, fear of invisible traps.

**After:** "Can I solve this in time?" → Urgency, action-oriented play.

Timer pressure motivates action. Mistake fear causes paralysis.

### 3. Undo Becomes Strategic

**Before:** Restore a deleted cell, but life already lost. Undo is a desperate band-aid.

**After:** Restore freely—only cost is time. Undo becomes a strategic tool for experimentation.

### 4. Simpler Cognitive Load

**Before (5 things to track):**
1. Which cells are safe to delete?
2. Current sum vs target
3. Lives remaining
4. Time for score bonus
5. Is puzzle still solvable?

**After (3 things to track):**
1. Current sum vs target
2. Time remaining
3. Am I making progress?

### 5. Richer Operator Design Space

Time-as-resource opens operator categories impossible before:

- **Time Extension:** +seconds per puzzle
- **Time Manipulation:** Pause, slow, reset timer
- **Time Risk/Reward:** Trade time for money/score
- **Time Banking:** Carry unused time forward

---

## Implementation Overview

### Remove Critical Cell Checking

```gdscript
# BEFORE: in puzzle_grid._on_cell_clicked()
cell_data.state = PuzzleState.CellState.DELETED
var still_solvable := PuzzleLogic.has_any_solution(puzzle_state)
cell_data.state = PuzzleState.CellState.ACTIVE
if not still_solvable:
    EventBus.mistake_made.emit(row, col)  # DELETE THIS

# AFTER: Just delete the cell
if puzzle_state.delete_cell(row, col):
    cell.set_cell_state(PuzzleState.CellState.DELETED)
    # ... rest of logic
```

### Timer Expiration = Puzzle Failure

```gdscript
func _on_timer_expired():
    EventBus.puzzle_failed.emit("timeout")
    # Either: lose a life and continue
    # Or: puzzle gives 0 points, move on
```

### Score Calculation

```gdscript
# Time bonus replaces precision multiplier
var time_remaining: float = timer.time_left
var time_bonus: int = int(time_remaining * 10)  # 30s left = +300 points

final_score = base_score + kept_bonus + operator_bonus + time_bonus
```

### Timer Scaling by Stage

```gdscript
# Example: generous early, tighter late
func get_time_limit(stage: int, puzzle_index: int) -> float:
    var base := 75.0  # Stage 1 base
    var stage_reduction := (stage - 1) * 5.0  # -5s per stage
    var boss_bonus := 15.0 if puzzle_index == 2 else 0.0  # Boss gets more time
    return base - stage_reduction + boss_bonus
```

---

## New Operator Ideas (Time-Based)

### Time Extension

| ID | Name | Effect | Rarity | Price |
|----|------|--------|--------|-------|
| `time_lord` | Time Lord | +15 seconds per puzzle | Common | 5 |
| `hourglass` | Hourglass | +3 seconds per completed row/column | Uncommon | 6 |
| `time_bank` | Time Bank | Unused time carries to next puzzle (max +30s) | Rare | 9 |

### Time Manipulation

| ID | Name | Effect | Rarity | Price |
|----|------|--------|--------|-------|
| `second_wind` | Second Wind | When timer hits 10s, reset to 30s (once/puzzle) | Rare | 8 |
| `zen_master` | Zen Master | Timer pauses 3s when you complete a row | Uncommon | 7 |
| `freeze_frame` | Freeze Frame | One-time: pause timer for 10 seconds | Rare | 7 |

### Time Risk/Reward

| ID | Name | Effect | Rarity | Price |
|----|------|--------|--------|-------|
| `panic_button` | Panic Button | Tap to add 10s (costs $2 per use) | Common | 4 |
| `overtime` | Overtime | First timeout per stage = -$5 instead of -life | Rare | 10 |
| `rush_hour` | Rush Hour | Timer runs 1.5x speed, but +50% score | Rare | 8 |
| `deadline` | Deadline | -10 seconds per puzzle, but +$2 per solve | Uncommon | 6 |

---

## What This Affects

### Code Changes Needed

1. **puzzle_grid.gd:** Remove `PuzzleLogic.has_any_solution()` check on delete
2. **puzzle_grid.gd:** Remove `PuzzleLogic.has_solution_including_cell()` check on circle
3. **main.gd or puzzle scene:** Add timer expiration handler
4. **scoring_engine.gd:** Add time bonus, possibly remove precision multiplier
5. **EventBus:** Remove `mistake_made` signal (or repurpose)
6. **sound_manager.gd:** Remove mistake sound trigger (or repurpose for timeout)

### Tests Affected

- Tests that assert on `mistake_made` events
- Tests that check critical cell behavior
- Scoring tests need time bonus consideration

### Docs to Update

- CLAUDE.md if it mentions critical cells
- Any gameplay documentation

---

## Edge Cases

### What if player circles wrong cells?

**Before:** Circling a non-solution cell = mistake.

**After:** Circle whatever you want. If it helps you think, great. If not, it just costs time to uncircle.

Circling becomes pure player tool, not a testable action.

### What about "already solved" detection?

Keep auto-win on correct solution. Timer doesn't prevent winning—it just limits how long you have to find the solution.

### Accessibility

- Default timer should be generous (60-75 seconds)
- Setting: "Extended Time Mode" (+50%)
- Setting: "Zen Mode" (no timer, practice only, no score)
- Operators let players build time-generous loadouts

---

## Summary

The timer-as-fail-condition design:

1. **Removes invisible rules** - No more "why was that wrong?"
2. **Creates clear pressure** - Solve before time runs out
3. **Enables experimentation** - Undo freely, only cost is time
4. **Opens operator space** - Time manipulation is rich design territory
5. **Simplifies mental model** - 3 things to track instead of 5

This is a fundamental improvement to the game's accessibility and feel.
