# MVP Definition

> The absolute minimum needed to ship something playable and fun
> Think: What would you put on itch.io as a "playable demo"?
> Last updated: 2026-01-27

---

## The Indie Game Dev Reality Check

**You are closer to MVP than you think.**

Current state:
- Core puzzle loop works ✅
- Scoring works ✅
- 8-stage progression works ✅
- Shop works ✅
- Win/lose conditions work ✅
- 5 operators exist ✅

What's missing is **polish and variety**, not **mechanics**.

---

## MVP Scope: "The 1.0 Demo"

### What MUST Ship

| Category | Requirement | Status |
|----------|-------------|--------|
| **Core Loop** | Delete cells to match sums | ✅ Done |
| **Puzzle Gen** | Guaranteed solvable, not trivial | ✅ Done |
| **Scoring** | Base + kept + multipliers | ✅ Done |
| **Operators** | 10 operators minimum | 🚧 Have 5, need 5 more |
| **Shop** | Buy/sell/reroll | ✅ Done |
| **Progression** | 8 stages, increasing difficulty | ✅ Done |
| **Timer** | Run out of time = game over | ✅ Done |
| **Sound** | Basic SFX (clicks, wins, money) | ❌ Missing |
| **Feedback** | Know why you won/lost | 🚧 Needs score animation |
| **Save/Load** | Don't lose progress | ❌ UI missing |

### What Can Ship Later (Post-MVP)

| Category | Feature | Why Cut |
|----------|---------|---------|
| Consumables/Functions | Hint, Shuffle, etc. | Operators sufficient for variety |
| Boss Puzzles | Special constraints | Regular puzzles work |
| Negative Numbers | Extended math | Complicates onboarding |
| Difficulty Tiers | Stakes system | One difficulty is fine for demo |
| Grid Variations | Deck types | Standard grid works |
| Transformation Operators | Flipper, Doubler | Scoring operators first |
| Meta-Progression | Unlocks, achievements | Demo doesn't need |
| Music | Background tracks | SFX more critical |
| Options Menu | Settings | Hardcoded is fine |
| Endless Mode | Post-stage-8 | Victory is fine endpoint |

---

## The MVP Experience

### First 30 Seconds
1. Player sees title screen
2. Clicks "Start Run"
3. 3×3 puzzle appears with clear targets
4. Player taps cells, sees sums change
5. **Auto-wins** when solution found (no submit button confusion)

### First 5 Minutes
1. Complete 2-3 puzzles
2. See score convert to money
3. Feel time pressure, understand stakes
4. Complete Stage 1, enter shop
5. See operators, buy one
6. Notice gameplay changes with operator

### First 15 Minutes
1. Progress through stages 1-3
2. Grid grows from 3×3 to 4×4
3. Score targets increase
4. Build operator collection
5. Either reach stage 4+ or lose

### Win State
- Complete stage 8 → Victory screen with total score
- Satisfying "you beat the demo" moment

### Lose State
- Run out of time → Game Over with stages cleared
- Clear "try again" call to action

---

## The Critical Missing Pieces

### 1. Sound (Estimated: 4-8 hours)
- Download free SFX (Freesound, Kenney)
- Cell click: "tick"
- Row valid: "ding"
- Mistake: "buzzer"
- Money: "coin"
- Win: "fanfare"

**This is the single highest-impact task for MVP feel.**

### 2. 5 More Operators (Estimated: 2-4 hours)
```
6. Zero Hero: ×2 if any zero kept
7. Diagonal Bonus: +100 if main diagonal kept
8. Speed Demon: +50 per 0.1 time_mult above 1.0
9. Row Streak: +100 for each consecutive valid row
10. Big Spender: +money_spent × 10 points
```

Just need variety. Don't need to be perfectly balanced.

### 3. Save/Load UI (Estimated: 2-3 hours)
- Serialization works
- Add "Continue Run" button to title
- Auto-save after each stage
- Load on game start if save exists

### 4. Score Animation (Estimated: 4-6 hours)
- Show breakdown step by step
- Number countup tweens
- Sound per step
- Makes wins feel *earned*

---

## What NOT to Do Before MVP

1. **Don't add negative numbers** - Complicates first impression
2. **Don't add consumables** - Operators are enough
3. **Don't add boss modifiers** - Regular puzzles work
4. **Don't add difficulty tiers** - One difficulty for demo
5. **Don't perfect balance** - Playable > perfect
6. **Don't add music** - SFX more critical
7. **Don't build options menu** - Waste of time for demo

---

## MVP Timeline Estimate

Assuming focused work sessions:

| Task | Estimate |
|------|----------|
| Basic SFX integration | 4-8 hours |
| 5 more operators | 2-4 hours |
| Save/Load UI | 2-3 hours |
| Score animation | 4-6 hours |
| Operator display in play | 2-3 hours |
| Testing & polish | 4-8 hours |
| **Total** | **18-32 hours** |

That's **1-2 focused weekends** or **1 week of evenings**.

---

## The MVP Launch Strategy

### Where to Launch
1. **itch.io** - Primary. Free, indie-friendly, web builds work.
2. **Reddit** - r/puzzlegames, r/roguelites, r/indiegames
3. **Twitter/X** - #indiedev, #gamedev, gameplay GIFs
4. **Discord** - Roguelike/puzzle game servers

### What to Call It
- "Crosssums Demo" or "Crosssums Alpha"
- "A number puzzle roguelike in the spirit of Balatro"
- Web playable, no download required

### What to Ask For
- "Looking for feedback on the core loop"
- "Is this fun? Is this confusing?"
- "What operators would you want to see?"

---

## Post-MVP Roadmap (If Reception is Good)

### Phase 2: Depth
- Negative numbers
- Consumables/Functions
- 10 more operators (20 total)
- Boss puzzle modifiers

### Phase 3: Polish
- Music
- Particle effects
- Improved animations
- Mobile-optimized touch

### Phase 4: Replayability
- Difficulty tiers
- Grid variations
- Meta-progression
- Achievements

### Phase 5: Distribution
- Steam page & wishlists
- Steam Next Fest demo
- Mobile ports (Capacitor)
- Console consideration

---

## The Hard Truth

The game is **85% mechanically complete**.

The remaining 15% is:
- **Sound** (makes it feel like a game)
- **Variety** (makes it replayable)
- **Persistence** (respects player time)
- **Feedback** (teaches through play)

None of this is hard. It just needs to be done.

---

## Decision: Ship Criteria

**MVP is ready to ship when:**

1. [ ] Sound effects exist (even basic)
2. [ ] 10 operators available
3. [ ] Save/Load works from UI
4. [ ] Score shows breakdown
5. [ ] Operators visible during play
6. [ ] Playtesters complete 3+ runs without confusion
7. [ ] Web build works on itch.io

**That's it. Ship the thing.**

---

## Final Note: Ship > Perfect

> "A game that ships at 80% quality teaches you more than a game at 95% quality that never ships."

Crosssums has a **proven core loop**. The puzzle is fun. The roguelike layer works. You're building iteration on a solid foundation.

Get it in front of players. Learn what they actually want. Iterate.

**The first version is never the final version. Ship it.**
