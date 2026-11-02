# Master Todo List

> Last updated: 2026-03-14

---

## MVP Ship Criteria

**All MVP blockers are DONE:**
- [x] Sound effects exist
- [x] 10+ operators available (12: Counter, Row Master, Column Master, Circlicious, Elite Delete, Purist, Gimme, Sum Sight, Safety Net, Click Clique, Garbage Collector, Trimmer)
- [x] Save/Load works from UI
- [x] Score shows breakdown animation
- [x] Operators visible during puzzle play
- [x] Web build works on itch.io
- [x] 9-stage difficulty curve with negatives
- [x] Mistake feedback (screen shake, red flash, error sound)
- [x] Circle misstep feedback
- [x] Mobile touch input working

---

## Priority 1: Visual Reskin (CURRENT)

### 1.1 Asset Integration
**Status:** 🚧 Starting
**Impact:** HIGH | **Effort:** MEDIUM

The game currently uses **zero custom visual assets** — all UI is procedural StyleBoxFlat/ColorRect. We have assets ready to integrate. See asset inventory below.

**Asset Categories Needed:**

#### Backgrounds & Surfaces
- [ ] Title screen background (replace `main_background.png`)
- [ ] Game screen background (currently a flat ColorRect)
- [ ] Panel/card background texture (for overlays, shop, result popup)
- [ ] Shop background

#### Grid & Cells
- [ ] Cell texture — ACTIVE state (currently flat dark blue `StyleBoxFlat`)
- [ ] Cell texture — DELETED state (currently flat dark gray)
- [ ] Cell texture — CIRCLED state (currently teal + cyan border)
- [ ] Cell texture — PROTECTED state (Safety Net green tint)
- [ ] Target cell texture — WRONG (currently flat red)
- [ ] Target cell texture — SOLVED (currently flat green)

#### UI Elements
- [ ] Button texture/style (all buttons are default Godot theme)
- [ ] Operator card background (currently plain `PanelContainer`)
- [ ] Rarity strip / border treatments (Common, Uncommon, Rare, Legendary)
- [ ] Timer bar fill texture (currently flat cyan→red gradient)
- [ ] Timer bar background
- [ ] Life/heart icons (if applicable)
- [ ] Money/coin icon

#### Typography
- [ ] Primary font (title, headers)
- [ ] Body font (labels, descriptions)
- [ ] Number font (cell values, scores — needs to be very legible)
- [ ] Monospace font (timer display)

#### Overlays & Screens
- [ ] Pause overlay style
- [ ] Result popup panel
- [ ] Game Over screen treatment
- [ ] Victory screen treatment
- [ ] Grade badge visuals (D, C, B, A, S, SS)

#### Color Palette
- [ ] Define new color palette to replace hardcoded colors throughout:
  - Cell states (active/deleted/circled/protected)
  - Target states (wrong/solved)
  - UI accents (money green, timer cyan→red, stage gold)
  - Rarity colors (common gray, uncommon green, rare blue, legendary gold)
  - Grade colors (D gray, C white, B green, A blue, S gold, SS pink)
  - Score breakdown colors (base white, kept blue, operator purple, speed cyan)

---

## Priority 2: Polish & Feel

### 2.1 Mistake Feedback Enhancement
**Status:** ✅ Done
**Impact:** MEDIUM | **Effort:** LOW

Mistakes (delete critical cell / circle wrong cell) have screen shake + red flash + error sound.

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
**Status:** ✅ Done
**Notes:** Visual + sound effect both working.

---

## Priority 3: Content & Variety

### 3.1 Negative Numbers
**Status:** ✅ Done
**Notes:** Enabled in stages 6-9 per the 9-stage difficulty curve. Includes -1, -2, -3 ranges.

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

### Now: Visual Reskin
The game is feature-complete for MVP. All gameplay, operators, save/load, web build, and difficulty curve are working. Next step is integrating visual assets to replace the procedural StyleBoxFlat look.

### After Reskin
1. **Operator trigger visual feedback** - Glow/pulse when operators fire
2. **More operators (20+ total)** - Content variety for replayability
3. **Consumable functions** - First consumable to prove the system
4. **Boss puzzle modifiers** - Make puzzle 3 of each stage special
5. **Trailer** - Marketing asset for itch.io / Steam

### Known Issues
- Garbage Collector / Click Clique can softlock after misstep (may just be their tradeoff — consider raising their cost)
- Options menu button is a stub

---

*This document is the single source of truth for what to work on. Other planning docs should be considered archived.*

