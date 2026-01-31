# Master Todo List

> Consolidated from: user_todos.md, next_steps.md, priorities.md, mvp.md, implementation_status.md, GAME_DESIGN_IDEAS.md, crosssums-design-doc.md, OPERATORS.md, GTM_STRATEGY.md, visual_identity.md
> Last updated: 2026-01-30

---

## MVP Ship Criteria

**The game is ready to ship when:**
- [ ] Sound effects exist (even basic)
- [ ] 10+ operators available
- [ ] Save/Load works from UI
- [ ] Score shows breakdown animation
- [ ] Operators visible during puzzle play
- [ ] Web build works on itch.io

---

## Priority 1: MVP Blockers

### 1.1 Sound Effects
**Status:** ❌ Not started
**Impact:** HIGH | **Effort:** LOW-MEDIUM

The game is completely silent. This is the most noticeable gap.

**Acceptance Criteria:**
- [ ] Cell delete/restore produces a click sound
- [ ] Row/column turning green produces a "ding" sound
- [ ] Puzzle complete triggers a fanfare
- [ ] Money gain/loss has coin sounds
- [ ] Mistake/life loss plays error sound
- [ ] Sounds don't overlap or cause audio issues
- [ ] Volume is balanced (no sound is jarring)

**Assets needed:** 5-6 basic SFX (Freesound, Kenney, etc.)

---

### 1.2 Operator Display During Gameplay
**Status:** ✅ Done
**Notes:** Operators are already shown during gameplay.

---

### 1.3 Save/Load UI
**Status:** 🚧 Code exists, no UI
**Impact:** MEDIUM | **Effort:** LOW

Run state can be serialized, but players can't access it.

**Acceptance Criteria:**
- [ ] Auto-save triggers after each stage completion
- [ ] "Continue Run" button appears on title screen when save exists
- [ ] Loading a save restores full run state (stage, score, lives, operators, money)
- [ ] Starting a new run clears/overwrites the save
- [ ] Graceful handling of corrupted saves

---

### 1.4 Score Animation (Balatro-Style)
**Status:** ✅ Done
**Impact:** MEDIUM-HIGH | **Effort:** MEDIUM

Implemented step-by-step score breakdown reveal.

**Acceptance Criteria:**
- [x] Base points appear first
- [x] +Kept cell bonus counts up
- [x] ×Line multiplier applies with visual effect
- [x] +Operator bonuses show one by one
- [x] ×Time multiplier applies
- [x] Final score reveals with emphasis
- [ ] Each step has sound effect (needs sound system first)
- [x] Total animation takes ~3 seconds (configurable)
- [x] Skip button available (shows "Skip", becomes "Continue" after animation)

---

### 1.5 More Operators (10 minimum)
**Status:** 🚧 Have 12, need variety
**Impact:** HIGH | **Effort:** MEDIUM

Recent commit added operators. Need to verify count and variety.

**Acceptance Criteria:**
- [ ] At least 10 distinct operators in registry
- [ ] Mix of rarities (Common, Uncommon, Rare)
- [ ] Mix of trigger types (cell_kept, row_complete, puzzle_end)
- [ ] All operators have tests
- [ ] Shop shows variety in typical run

**Current operators (12):**
1. Counter, 2. Lucky Seven, 3. Prime Time, 4. Row Master, 5. Corner Keeper, 6. Column Master, 7. Zero Hero, 8. Circlicious, 9. Elite Delete, 10. Flipper, 11. Purist, 12. Square Peg

---

## Priority 2: Polish & Feel

### 2.1 Mistake Feedback Enhancement
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** LOW

Mistakes (delete critical cell / circle wrong cell) need stronger feedback.

**Acceptance Criteria:**
- [ ] Screen shake on mistake
- [ ] Wrong cell flashes red
- [ ] Life loss has dramatic visual indicator
- [ ] Error/buzzer sound effect plays
- [ ] Circling a non-critical cell shows red throbbing animation (same as deleting critical)

---

### 2.2 Visual Polish Pass
**Status:** 🚧 Basic
**Impact:** MEDIUM | **Effort:** MEDIUM

General polish to make game feel professional.

**Acceptance Criteria:**
- [ ] Cell hover effects on desktop
- [ ] Button press feedback (scale/color change)
- [ ] Screen transition animations
- [ ] Timer bar pulses/changes color when low
- [ ] Life hearts animate on loss
- [ ] Cells "pop" when deleted (scale animation improved)

---

### 2.3 Circle Misstep Feedback
**Status:** ✅ Done (visual only)
**Impact:** LOW | **Effort:** LOW

From user_todos: circling a non-critical cell should feel like a mistake.

**Acceptance Criteria:**
- [x] Circling non-critical cell triggers red throbbing animation
- [x] Same visual treatment as deleting a critical cell
- [ ] Sound effect matches mistake sound (needs sound system first)

---

## Priority 3: Content & Variety

### 3.1 Negative Numbers
**Status:** ❌ Config exists, not enabled
**Impact:** MEDIUM-HIGH | **Effort:** LOW

Design doc emphasizes this. Infrastructure exists.

**Acceptance Criteria:**
- [ ] `allow_negatives` enabled from stage 4+
- [ ] Puzzle generation includes values -1 to -5
- [ ] Negative numbers display clearly (red text or minus sign)
- [ ] Sum calculations handle negatives correctly (already should)
- [ ] At least one operator synergizes with negatives
- [ ] Tests cover negative number puzzles

---

### 3.2 First Consumable Function
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** MEDIUM

Zero consumables exist. Need at least one to prove the system.

**Acceptance Criteria:**
- [ ] Function base class created
- [ ] Function registry implemented
- [ ] "Hint" function implemented: reveals one cell that's part of valid solution
- [ ] Hint costs $3
- [ ] Shop has function slot(s)
- [ ] UI for using consumables during puzzle
- [ ] Functions are one-time use (consumed on use)
- [ ] Tests cover function purchase and use

---

### 3.3 Boss Puzzle Modifiers
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** MEDIUM

All puzzles play the same. Boss puzzles (puzzle 3 of each stage) should be special.

**Acceptance Criteria:**
- [ ] 2-3 boss modifiers implemented
- [ ] **The Timer**: 30-second hard limit, fail = lose life
- [ ] **The Minimalist**: Must delete exactly N cells
- [ ] **The Primes**: Row targets are all prime numbers
- [ ] Boss modifier displayed clearly before puzzle starts
- [ ] Boss puzzles worth more points/money
- [ ] Tests cover each boss type

---

### 3.4 More Operators (20+ total)
**Status:** 🚧 Have 12
**Impact:** HIGH | **Effort:** MEDIUM

For full replayability, need more variety.

**Planned operators from OPERATORS.md:**

**Scoring:**
- [ ] Even Steven: +20 per even number kept
- [ ] Odd Job: +20 per odd number kept
- [ ] Big Ten: +100 for each 10+ kept
- [ ] Sequence: +150 for 3+ consecutive numbers kept
- [ ] Pair Bonus: +50 for each pair of same numbers

**Economy:**
- [ ] Calculator: +$2 for each unique digit
- [ ] Banker: +10% interest on money
- [ ] Thrifty: -1 cost for shop items
- [ ] Gold Finder: +$1 for each row with no mistakes

**Rule-Breaking:**
- [ ] Overflow: Rows can exceed target by 10%
- [ ] Underflow: Rows can fall short by 10%
- [ ] Skip Row: One row doesn't need to sum
- [ ] Column Blind: One column doesn't need to sum

**Transformation:**
- [ ] Doubler: One random cell per row counts double
- [ ] Negative Zone: Cells can be kept as negative
- [ ] Wildcard: One cell becomes any number needed

**Legendary:**
- [ ] Mathematician: Numbers also count as digit sum
- [ ] Perfectionist: ×3 score if no restores used

---

## Priority 4: Systems

### 4.1 Operator Trigger Visual Feedback
**Status:** 🚧 Event emitted, no visual
**Impact:** MEDIUM | **Effort:** MEDIUM

Players should see when operators activate.

**Acceptance Criteria:**
- [ ] Operator card glows/pulses when it triggers
- [ ] Floating text shows bonus granted
- [ ] Sound effect per trigger
- [ ] Multiple triggers in sequence are visible

---

### 4.2 Difficulty Tiers (Stakes)
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** MEDIUM

Post-MVP but important for replayability.

**Acceptance Criteria:**
- [ ] 3+ difficulty tiers implemented
- [ ] **Casual**: Base game (current)
- [ ] **Standard**: Puzzle 1 gives no money
- [ ] **Hard**: Score requirements +25%
- [ ] Difficulty selection on title screen
- [ ] Each tier has visual indicator
- [ ] Separate high scores per tier

---

### 4.3 Endless Mode
**Status:** ❌ Not started
**Impact:** LOW | **Effort:** LOW

After stage 8, continue playing.

**Acceptance Criteria:**
- [ ] Option to continue after stage 8 victory
- [ ] Grid sizes continue scaling (7×7, 8×8)
- [ ] Score requirements scale exponentially
- [ ] "Endless" indicated in UI
- [ ] High score tracking for endless

---

## Priority 5: Distribution

### 5.1 Web Build (itch.io)
**Status:** ⚠️ Unknown
**Impact:** HIGH | **Effort:** LOW

Critical for demo and visibility.

**Acceptance Criteria:**
- [ ] HTML5 export works
- [ ] Game loads on itch.io
- [ ] Touch and mouse input both work
- [ ] Performance acceptable (60fps target)
- [ ] No console errors blocking gameplay
- [ ] Save/load works in browser (localStorage)

---

### 5.2 iOS Export
**Status:** 🚧 Documented, not completed
**Impact:** MEDIUM | **Effort:** MEDIUM

Per ipad_export.md, setup is documented.

**Acceptance Criteria:**
- [ ] xcode-select points to Xcode.app
- [ ] iOS export preset configured with Team ID
- [ ] Export to Xcode project succeeds
- [ ] Build runs on real iPad
- [ ] Touch controls work properly
- [ ] Performance acceptable
- [ ] App icons created (all required sizes)

---

### 5.3 App Store Submission
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** HIGH

Per app_store_submission.md.

**Acceptance Criteria:**
- [ ] Apple Developer Program enrolled ($99/year)
- [ ] Bundle ID registered
- [ ] Distribution certificate created
- [ ] App Store provisioning profile created
- [ ] App created in App Store Connect
- [ ] App icon 1024×1024 created
- [ ] Screenshots for iPhone and iPad sizes
- [ ] Description, keywords, URLs filled
- [ ] Privacy declarations completed
- [ ] Age rating questionnaire completed
- [ ] Archive built and uploaded
- [ ] Submitted for review
- [ ] Approved and released

---

### 5.4 Steam Page
**Status:** ❌ Not started
**Impact:** HIGH | **Effort:** MEDIUM

Per GTM strategy, Steam is 70%+ of revenue.

**Acceptance Criteria:**
- [ ] Steamworks account created
- [ ] Store page created with:
  - [ ] Capsule art (multiple sizes)
  - [ ] Screenshots (5+)
  - [ ] Trailer
  - [ ] Description
  - [ ] Tags (Roguelike, Puzzle, Strategy, Indie)
- [ ] Demo build uploaded
- [ ] Steam Next Fest application submitted
- [ ] Wishlist tracking enabled

---

## Priority 6: Marketing

### 6.1 Trailer
**Status:** ❌ Not started
**Impact:** HIGH | **Effort:** MEDIUM

**Acceptance Criteria:**
- [ ] 60-90 second announce trailer
- [ ] Shows core loop (delete cells, match sums)
- [ ] Shows operator system
- [ ] Shows score explosion moment
- [ ] "Balatro meets Sudoku" hook
- [ ] Call to action (wishlist/play)
- [ ] Music and sound

---

### 6.2 Press Kit
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** LOW

**Acceptance Criteria:**
- [ ] presskit.html or equivalent
- [ ] Game description (short and long)
- [ ] Key features list
- [ ] Screenshots (high-res, no UI optional versions)
- [ ] Logo assets
- [ ] Developer info
- [ ] Contact email
- [ ] Social links

---

### 6.3 Social Media Presence
**Status:** ❌ Not started
**Impact:** MEDIUM | **Effort:** LOW (ongoing)

**Acceptance Criteria:**
- [ ] Twitter/X account created
- [ ] Discord server set up
- [ ] First devlog posted
- [ ] Consistent posting schedule defined

---

## Backlog: Ideas (Don't Implement Until Asked)

These are from user_todos.md and design docs. Tracked but not prioritized.

### Operator Ideas
- [ ] AutoAim: Auto-click intersection when 1 red row + 1 red col
- [ ] CoinFlip: 50% chance misstep doesn't cost heart
- [ ] Xray: Show sum of circled cells in target corner

### Cell Type Ideas
- [ ] Gold cells: +$ if kept in solution
- [ ] Locked cells: Cannot be deleted
- [ ] Wild cells: Count as any number

### Function Ideas
- [ ] Auto-Circle random critical cell
- [ ] Auto-Delete random non-critical cell
- [ ] Add a life
- [ ] +1/-1 wiggle room for target

### System Ideas
- [ ] Operator leveling (XP system)
- [ ] Operator editions (Golden, Holographic, Prismatic)
- [ ] Grid variations (Decks)
- [ ] Meta-progression (unlocks)
- [ ] Achievements

### Balance Observations
- [ ] "Decisions don't matter because I can easily buy all known operators"
- [ ] Need to tune economy to create meaningful shop choices

---

## Technical Debt

### Code Quality
- [ ] Options menu button does nothing (stub)
- [ ] Some animations need polish
- [ ] run_manager.gd.uid deleted (git status shows this)

### Test Coverage
- [ ] Visual regression tests may need baseline updates
- [ ] Animation handling in tests (reduce motion mode?)

---

## Document Cleanup

These docs have overlapping content and should be consolidated:

| Keep | Archive/Delete | Reason |
|------|----------------|--------|
| MASTER_TODO.md | user_todos.md | Consolidated here |
| MASTER_TODO.md | next_steps.md | Consolidated here |
| MASTER_TODO.md | priorities.md | Consolidated here |
| MASTER_TODO.md | mvp.md | Consolidated here |
| implementation_status.md | - | Keep for reference |
| crosssums-design-doc.md | - | Keep as source of truth |
| OPERATORS.md | - | Keep, actively maintained |
| GTM_STRATEGY.md | - | Keep for launch |
| visual_identity.md | - | Keep for design direction |

---

## Summary: What To Work On

### This Week (MVP Push)
1. **Sound effects** - Biggest bang for buck
2. **Operator display during play** - Quick win
3. **Save/Load UI** - Code exists, just needs UI

### Next Week
4. **Score animation** - The satisfaction moment
5. **Mistake feedback** - Polish

### Before Public Demo
6. **Web build working** - itch.io deployment
7. **Trailer** - Marketing asset

---

*This document is the single source of truth for what to work on. Other planning docs should be considered archived.*
