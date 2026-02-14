# Top 10 Priorities

> Prioritized list of the most important things to do next
> Based on: Missing features × Player impact × Implementation effort
> Last updated: 2026-01-27

---

## Priority Ranking Criteria

- **Impact**: How much does this improve the player experience?
- **Blocking**: Does this unlock other features?
- **Effort**: How much work to implement?
- **Polish vs Features**: Prefer features that make the game "more game"

---

## 1. 🔊 Basic Sound Effects
**Impact: HIGH | Effort: LOW-MEDIUM**

The game is completely silent. This is the #1 most noticeable gap.

**Minimum viable:**
- Cell delete/restore click
- Row/column valid "ding"
- Puzzle complete fanfare
- Money +/- sounds
- Mistake/life loss sound

**Why first:** Trivially easy sounds (free assets) dramatically improve feel. No audio is jarring.

---

## 2. 📊 Operator Display During Gameplay
**Impact: HIGH | Effort: LOW**

Players have no visibility into their operators while solving puzzles. They're shown in shop, then invisible.

**Implement:**
- Small operator bar/tray at bottom or side of puzzle screen
- Show icons + names
- Ideally: highlight when operator triggers

**Why high priority:** Players forget what they bought. Core to the roguelike experience.

---

## 3. 🎭 More Operators (10 total)
**Impact: HIGH | Effort: MEDIUM**

Only 5 operators exist. Need variety for interesting shop decisions.

**Add 5 more operators:**
- **Zero Hero** (Rare): ×2 if any 0 is kept (needs negative numbers or 0s in generation)
- **Diagonal Master** (Uncommon): +100 if main diagonal is all kept
- **Minimalist** (Rare): +500 if you delete maximum possible cells
- **Speed Demon** (Uncommon): +50 × time_multiplier (rewards fast solves)
- **Double or Nothing** (Rare): ×2 score, but -1 life if you make a mistake

**Why needed:** 5 operators = limited replayability. Shop feels samey.

---

## 4. 🎯 Negative Numbers
**Impact: MEDIUM-HIGH | Effort: LOW**

Design doc emphasizes this. Config exists. Just needs enabling.

**Tasks:**
- Enable `allow_negatives` from stage 4+
- Adjust generation to include -1 to -5 values
- Test thoroughly (sum calculations already handle negatives)

**Why important:** Adds mental math depth, opens operator design space.

---

## 5. 🃏 First Consumable Function
**Impact: MEDIUM | Effort: MEDIUM**

Zero consumables exist. Need at least one to prove the system.

**Implement:**
- **Hint** ($3): Reveal one cell that's part of a valid solution
- Function base class
- Function registry
- Shop slot for functions
- UI for using consumables

**Why now:** Functions are core to Balatro design. Proves the consumable system.

---

## 6. ✨ Score Animation (Balatro-Style)
**Impact: MEDIUM-HIGH | Effort: MEDIUM**

Currently: "Score: 1847" appears instantly.
Desired: Base → +Kept → ×Lines → +Counter → ×Time = Final (with sounds)

**Implement:**
- `ScoreBreakdown` already has all the data
- Step-by-step reveal with delays
- Number countup animation
- Sound per step

**Why important:** This is the *moment of satisfaction*. Current implementation undersells wins.

---

## 7. 👁️ Mistake Feedback Enhancement
**Impact: MEDIUM | Effort: LOW**

When you make a mistake (delete critical cell / circle wrong cell), feedback is minimal.

**Improve:**
- Screen shake
- Flash the wrong cell red
- More dramatic life loss indicator
- Sound effect (buzzer/error)

**Why:** Mistakes should feel *bad*. Currently easy to miss.

---

## 8. 🏆 Boss Puzzle Modifiers
**Impact: MEDIUM | Effort: MEDIUM**

All puzzles play the same. Boss puzzles (puzzle 3 of each stage) should be special.

**Implement 2-3 boss modifiers:**
- **The Timer**: Strict 30-second time limit (fail = lose)
- **The Minimalist**: Must delete exactly N cells, no more, no less
- **The Primes**: Row targets are all prime numbers

**Why:** Variety, challenge progression, memorable moments.

---

## 9. 💾 Save/Load UI
**Impact: MEDIUM | Effort: LOW**

Serialization works. Players can't access it.

**Implement:**
- Auto-save on stage completion
- "Continue Run" button on title screen
- Load state on game launch

**Why:** Run-based games need this. Players will lose progress otherwise.

---

## 10. 🎨 Polish Pass: Visual Juice
**Impact: MEDIUM | Effort: MEDIUM**

General polish to make the game feel better.

**Include:**
- Cell hover effects
- Button feedback
- Transition animations between screens
- Timer bar color pulsing when low
- Life hearts animation on loss

**Why:** Cumulative effect of small polish makes game feel professional.

---

## Honorable Mentions (Do After Top 10)

| Priority | Feature | Why Not Top 10 |
|----------|---------|----------------|
| 11 | Difficulty tiers | Core loop needs to be fun first |
| 12 | Upgrades/Vouchers | Need functions first |
| 13 | Grid variations (decks) | Adds complexity without fixing core |
| 14 | Endless mode | Need base game polished |
| 15 | Meta-progression/unlocks | Post-MVP feature |
| 16 | Mobile touch polish | Desktop first |
| 17 | Transformation operators | Need more basics first |
| 18 | Options menu | Nice-to-have |

---

## Sprint Recommendation

**Sprint A (1-2 days): Audio + Visibility**
- [ ] Priority 1: Basic sound effects
- [ ] Priority 2: Operator display during gameplay

**Sprint B (2-3 days): Variety**
- [ ] Priority 3: 5 more operators
- [ ] Priority 4: Negative numbers

**Sprint C (2-3 days): Systems**
- [ ] Priority 5: First consumable
- [ ] Priority 6: Score animation

**Sprint D (1-2 days): Feel**
- [ ] Priority 7: Mistake feedback
- [ ] Priority 10: Visual polish pass

**Sprint E (1-2 days): Content**
- [ ] Priority 8: Boss modifiers
- [ ] Priority 9: Save/load UI

---

## The Goal

After these 10 priorities, the game should be:
- **Audible** (not silent)
- **Varied** (10 operators, consumables, boss modifiers)
- **Satisfying** (score animations, feedback)
- **Persistent** (save/load)

This gets you to a **publicly playable alpha**.
