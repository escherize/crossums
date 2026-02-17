# Score Screen Redesign (2026-02-16)

> **Status:** Implemented

## Problem (Solved)
The previous score screen was confusing:
1. Grade ignored time, but final score included it - cognitive dissonance
2. "Perfect: 190" didn't explain what it meant
3. Money formula mixed score (with time) and grade (without time)
4. S/SS grades required operators but this wasn't communicated
5. No animation/juice - numbers just appeared

## Design Goals
Based on game design review:
- **Grade now includes time** - fast perfect = S, slow perfect = B
- Make money formula super-linear: `(base + bonus) × mult`
- Restructure screen to show clear breakdown
- S/SS achievable through pure skill (speed), operators help but don't gate

---

## Implementation Summary

### Changes Made

#### 1. Grade Includes Time (scoring_engine.gd)
```gdscript
# Grade now includes time multiplier
var grade_score: int = int((breakdown.subtotal + breakdown.operator_bonus) * breakdown.time_multiplier)
breakdown.grade = calculate_grade(grade_score, breakdown.par_score)
```

#### 2. Adjusted Thresholds (game_config.gd)
```gdscript
static var GRADE_THRESHOLDS := {
    "D": 0.0,    # Any completion
    "C": 0.5,    # 50% of par
    "B": 0.75,   # 75% of par
    "A": 0.9,    # 90% of par (normal speed perfect)
    "S": 1.1,    # 110% of par (fast perfect)
    "SS": 1.4    # 140% of par (very fast or operators)
}
```

#### 3. Super-Linear Money Formula (run_manager.gd)
```gdscript
# (base + bonus) × mult instead of base × mult + bonus
var score_money: int = int((base_money + grade_bonus) * grade_mult)
```

#### 4. Rebalanced Bonuses (game_config.gd)
```gdscript
# Lower since super-linear formula multiplies them
static var GRADE_MONEY_BONUS := {
    "D": 0, "C": 0, "B": 1, "A": 1, "S": 2, "SS": 4
}
```

#### 5. Simplified Result Display (result_popup.gd)
- Removed "Perfect: X" line (grade IS the comparison now)
- Money shows super-linear formula: `($1 + $2) × 2.5 = +$7`

---

## Expected Outcomes

| Solve | Time Mult | Subtotal | Grade Score | % of Par | Grade |
|-------|-----------|----------|-------------|----------|-------|
| Slow perfect | 0.8× | 190 | 152 | 80% | B |
| Normal perfect | 1.0× | 190 | 190 | 100% | A |
| Fast perfect | 1.25× | 190 | 237 | 125% | S |
| Fast + ops | 1.5× | 240 | 360 | 190% | SS |

---

## Design Rationale (from Game Design Review)

**Why include time in grade?**
> "Speed IS a puzzle skill - pattern recognition, decision confidence. A player who solves perfectly in 15 seconds has more mastery than one who takes 90 seconds."

**Why S/SS no longer require operators?**
> "Operators should enhance, not gate. A player with no operators who plays flawlessly fast should achieve S. This makes grade = skill, not item collection."

**Why super-linear money?**
> "If the difference between B and A is always ~$0.50, grades feel decorative. Super-linear creates meaningful decisions: 'Do I play safe for B or risk timeout going for A?'"

**Grade now means:**
- D/C = Incomplete or poor solution
- B = Solved but slowly
- A = Good solve at reasonable speed
- S = Excellent speed or operators helping
- SS = Both fast AND operator bonuses
