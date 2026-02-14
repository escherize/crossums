# Crosssums: Roguelike Design Document

> A number-deletion puzzle game with Balatro-inspired roguelike mechanics

---

## Executive Summary

**Crosssums** takes a universally familiar concept—making numbers sum to targets—and layers a roguelike progression system inspired by Balatro. Players delete numbers from a grid to make each row and column sum to its target, while collecting modifiers that transform the rules, create scoring opportunities, and enable absurd mathematical combinations.

---

## Table of Contents

1. [Core Concept](#1-core-concept)
2. [Why This Works (Balatro Principles Applied)](#2-why-this-works-balatro-principles-applied)
3. [Core Mechanics](#3-core-mechanics)
4. [The Modifier System](#4-the-modifier-system)
5. [Scoring System](#5-scoring-system)
6. [Run Structure](#6-run-structure)
7. [Shop and Economy](#7-shop-and-economy)
8. [Difficulty Scaling](#8-difficulty-scaling)
9. [Grid Variations (Decks)](#9-grid-variations-decks)
10. [Visual and Audio Design](#10-visual-and-audio-design)
11. [Meta-Progression](#11-meta-progression)
12. [Educational Strategy: The Stealth Learning Approach](#12-educational-strategy-the-stealth-learning-approach)
13. [Tech Stack and Distribution Strategy](#13-tech-stack-and-distribution-strategy)
14. [Similar Games for Balatro-Style Treatment](#14-similar-games-for-balatro-style-treatment)

---

## 1. Core Concept

### The Base Game

You're presented with a grid of numbers. Each row and column has a **target sum**. Your goal: **delete the extra numbers** so that each row and column sums exactly to its target.

```
Example 5x5 Grid:

     [12] [15] [8] [11] [9]   ← Column targets
      ↓    ↓   ↓    ↓   ↓
[18]  3    7   2    4   6    → Must sum to 18
[14]  5    1   4    3   2    → Must sum to 14
[11]  2    4   1    2   3    → Must sum to 11
[16]  1    2   1    1   7    → Must sum to 16
[10]  1    1   0    1   2    → Must sum to 10
      ↑
  Row targets
```

The twist: Each cell you **keep** contributes to both its row AND column sum. Deleting a number affects both dimensions simultaneously.

### The Roguelike Layer

Like Balatro, success requires modifiers that break the rules:
- **Operators** (like Jokers): Persistent effects that transform how numbers work
- **Functions** (like Consumables): One-time effects that modify the grid
- **Upgrades** (like Vouchers): Permanent run-wide improvements

---

## 2. Why This Works (Balatro Principles Applied)

### Universal Foundation
Everyone knows addition. No explanation needed for "make these numbers sum to this target." This is even more universal than poker hands.

### The Multiplication Principle
The scoring formula uses multiplication:
```
Score = Base Points × Precision Bonus × Operator Multipliers
```

### Synergy Over Raw Power
Individual Operators are useful; combinations are devastating. An Operator that doubles 7s synergizes with an Operator that converts even numbers to 7.

### Constrained Choices
- Limited Operator slots (start with 5)
- Limited "moves" (deletions) per puzzle
- Must satisfy ALL row/column constraints

### Visible Calculation
Players see exactly how their score is computed, with each Operator's contribution displayed.

### Power Fantasy Permission
Let scores reach millions. Scale puzzles to match player power rather than capping it.

---

## 3. Core Mechanics

### Grid Solving

**The Puzzle**:
- Grid sizes: 3×3 (easy) to 7×7 (hard)
- Each cell contains a number (0-9, expandable with modifiers)
- Row targets on left, column targets on top
- Goal: Delete numbers until all sums match targets

**Constraints**:
- Every kept number contributes to both row AND column
- Some puzzles have multiple solutions (any valid solution works)
- Some puzzles have unique solutions (harder, worth more)

**Actions**:
- **Delete**: Remove a number from the grid
- **Keep**: Confirm a number stays (optional but locks it)
- **Submit**: Finalize your solution

**Touch Screen Support**:
- Tap a cell to toggle between deleted/active states
- No right-click or long-press needed - single tap toggles
- Designed for mobile/tablet play from the start

### Move Economy

- **Moves**: Each deletion costs 1 move
- **Base moves per puzzle**: Equal to cells that must be deleted
- **Bonus moves**: From Operators, Upgrades, or Functions
- **Unused moves**: Convert to score bonus or money

### Validation

When you submit:
1. Check all row sums
2. Check all column sums
3. If ALL match targets → Success
4. If ANY fail → Failure (lose a life or retry)

---

## 4. The Modifier System

### Operators (Like Jokers)

Operators provide persistent effects throughout the run. You have limited slots (base: 5).

**Categories**:

#### Scoring Operators
| Operator | Effect |
|----------|--------|
| **Counter** | +10 points for each kept number |
| **Row Master** | ×1.5 score for each perfectly solved row |
| **Prime Time** | +50 points for each prime number kept |
| **Lucky Seven** | +77 points for each 7 in the solution |
| **Zero Hero** | ×2 score if any row sums using a 0 |

#### Transformation Operators
| Operator | Effect |
|----------|--------|
| **Flipper** | All 6s become 9s, all 9s become 6s |
| **Doubler** | One random number in each row counts double |
| **Negative Zone** | Allows keeping numbers as negative values |
| **Decimal Point** | Numbers can be split (8 becomes 0.8, 8.0, or .8) |
| **Wildcard** | One random cell becomes any number you need |

#### Economy Operators
| Operator | Effect |
|----------|--------|
| **Calculator** | +$2 for each unique digit in solution |
| **Banker** | Interest on held money after each puzzle |
| **Thrifty** | -1 cost for all shop items |

#### Rule-Breaking Operators
| Operator | Effect |
|----------|--------|
| **Overflow** | Rows can exceed target by up to 10% |
| **Underflow** | Rows can fall short of target by up to 10% |
| **Skip Row** | One row doesn't need to sum correctly |
| **Column Blind** | One column doesn't need to sum correctly |
| **Merger** | Adjacent same numbers can combine (3,3 → 6) |

#### Legendary Operators (Rare)
| Operator | Effect |
|----------|--------|
| **Mathematician** | All numbers count as their digit sum too (17→1+7=8) |
| **Quantum** | Each kept number is simultaneously all its factors |
| **Infinity** | One cell can be ANY value (solves one constraint automatically) |

### Operator Editions
- **Golden**: +$5 when puzzle completed
- **Holographic**: +25 points per puzzle
- **Prismatic**: ×1.2 score multiplier
- **Negative**: Doesn't take a slot

### Functions (Like Consumables)

One-time use items that modify the current puzzle or grid.

#### Grid Functions
| Function | Effect |
|----------|--------|
| **Shuffle** | Randomize positions of all numbers |
| **Rotate** | Rotate grid 90 degrees (swaps rows/columns) |
| **Mirror** | Flip grid horizontally or vertically |
| **Reveal** | Show which numbers are part of optimal solution |
| **Expand** | Add +1 to all numbers in a row/column |
| **Reduce** | Subtract 1 from all numbers in a row/column |

#### Target Functions
| Function | Effect |
|----------|--------|
| **Relax** | Increase one target by 5 |
| **Tighten** | Decrease one target by 5 (worth more points) |
| **Swap** | Exchange two row targets or two column targets |
| **Average** | Set one target to the average of all targets |

#### Special Functions
| Function | Effect |
|----------|--------|
| **Undo** | Reverse last 3 deletions |
| **Clone** | Duplicate a kept number into an empty cell |
| **Destroy** | Remove an Operator to gain $20 |
| **Transform** | Change one number to any other single digit |

### Upgrades (Like Vouchers)

Permanent improvements purchased between puzzles.

| Upgrade | Effect | Cost |
|---------|--------|------|
| **Extra Slot** | +1 Operator slot | $15 |
| **Thick Grid** | Puzzles have +1 row | $10 |
| **Wide Grid** | Puzzles have +1 column | $10 |
| **Safety Net** | +1 retry per puzzle | $12 |
| **Quick Math** | +2 starting moves | $8 |
| **Big Numbers** | Numbers can go up to 15 | $10 |
| **Shop Expansion** | +1 item slot in shop | $10 |
| **Function Belt** | +1 Function slot | $12 |

---

## 5. Scoring System

### Base Formula

```
Score = (Base Points + Kept Bonuses) × Row Multiplier × Operator Multipliers
```

### Base Points

| Puzzle Type | Base Points |
|-------------|-------------|
| 3×3 Grid | 100 |
| 4×4 Grid | 200 |
| 5×5 Grid | 350 |
| 6×6 Grid | 500 |
| 7×7 Grid | 700 |

### Bonuses

| Condition | Bonus |
|-----------|-------|
| Each kept number | +5 points |
| Unused move | +20 points |
| Unique solution found | ×1.5 |
| Perfect (no retries) | ×1.25 |
| Speed bonus (under par time) | ×1.1 - ×1.5 |

### Row/Column Multipliers

Each row/column that sums perfectly contributes to the multiplier:
- First row: ×1.0 (base)
- Each additional row: +0.2
- Full grid completion: Additional ×1.5

### Why Scores Can Explode

With the right Operators:
- Prime Time (+50 per prime) with a prime-heavy solution
- Row Master (×1.5 per row) with Upgrade for more rows
- Stacking multiplication Operators
- Converting numbers to high-value targets

**Target**: Scores should range from ~500 (early game) to millions (late game).

---

## 6. Run Structure

### The Ante System

A run consists of **8 Stages**, each with **3 Puzzles**:

```
Stage 1: [Puzzle 1] → [Puzzle 2] → [Boss Puzzle] → Shop
Stage 2: [Puzzle 1] → [Puzzle 2] → [Boss Puzzle] → Shop
...
Stage 8: [Puzzle 1] → [Puzzle 2] → [Final Boss Puzzle] → WIN
```

### Puzzle Difficulty Scaling

| Stage | Grid Size | Target Range | Score Required |
|-------|-----------|--------------|----------------|
| 1 | 3×3 | 5-15 | 300 |
| 2 | 3×3 | 8-20 | 600 |
| 3 | 4×4 | 10-25 | 1,200 |
| 4 | 4×4 | 12-30 | 2,500 |
| 5 | 5×5 | 15-35 | 5,000 |
| 6 | 5×5 | 18-40 | 10,000 |
| 7 | 6×6 | 20-45 | 25,000 |
| 8 | 6×6+ | 25-50 | 75,000 |

### Boss Puzzles

Boss Puzzles add special constraints:

| Boss | Effect |
|------|--------|
| **The Mask** | Some numbers are hidden until you delete adjacent cells |
| **The Mirror** | Solution must be symmetric |
| **The Timer** | Strict time limit |
| **The Minimalist** | Must use exactly N deletions, no more |
| **The Maximalist** | Must keep at least N numbers |
| **The Primes** | All row targets are prime |
| **The Evens** | No odd numbers can be kept |
| **The Sequence** | One row must form an arithmetic sequence |

### Lives System

- Start with 3 lives
- Lose 1 life for failed puzzle
- Gain lives through Operators or shop purchases
- 0 lives = run over

### Skipping

Like Balatro, players can skip Puzzle 1 or 2 (not Boss) for a **Tag** reward:
- Random Operator Tag
- Money Tag (+$10)
- Function Tag (free consumable)
- Upgrade Tag (discount on next upgrade)

Risk: Miss the shop visit and scoring opportunity.

---

## 7. Shop and Economy

### Shop Layout

After each Boss Puzzle:

```
┌─────────────────────────────────────────────┐
│  OPERATORS: [Op1 $6] [Op2 $8] [Op3 $12]    │
│  FUNCTIONS: [Fn1 $3] [Fn2 $4]               │
│  PACKS:     [Operator Pack $8] [Function Pack $5] │
│  UPGRADE:   [Current Upgrade $10]           │
│  REROLL:    [$2]                            │
└─────────────────────────────────────────────┘
```

### Money Sources

| Source | Amount |
|--------|--------|
| Puzzle completion | $3-8 based on size |
| Boss completion | $10 |
| Unused moves | $1 each |
| Score bonus (exceed target by 2x) | +$5 |
| Interest (per $5 held, max $5) | $1 |
| Selling Operators | Half purchase price |

### Operator Pricing

| Rarity | Base Price |
|--------|------------|
| Common | $5-7 |
| Uncommon | $8-12 |
| Rare | $15-20 |
| Legendary | Only from packs/special |

### Packs

| Pack | Cost | Contents |
|------|------|----------|
| Standard Operator Pack | $8 | Choose 1 of 3 Operators |
| Premium Operator Pack | $15 | Choose 1 of 5, guaranteed Uncommon+ |
| Function Pack | $5 | Choose 2 of 4 Functions |
| Mega Pack | $20 | 1 Operator + 2 Functions + $5 |

---

## 8. Difficulty Scaling

### Difficulty Tiers (Like Stakes)

| Tier | Name | Modifier |
|------|------|----------|
| 1 | **Casual** | Base game |
| 2 | **Standard** | Puzzle 1 gives no money |
| 3 | **Hard** | Score requirements +25% |
| 4 | **Expert** | Some Operators are "Locked" (can't be sold) |
| 5 | **Master** | -1 starting move per puzzle |
| 6 | **Insane** | Score requirements +50% |
| 7 | **Nightmare** | Some Operators "Decay" (weaken over time) |
| 8 | **Impossible** | Operators have upkeep costs |

### Endless Mode

After Stage 8, continue with:
- Increasing grid sizes (7×7, 8×8...)
- Exponentially scaling score requirements
- Harder Boss variations

---

## 9. Grid Variations (Decks)

Like Balatro's decks, different starting configurations change strategy:

| Grid Type | Effect | Strategy |
|-----------|--------|----------|
| **Standard** | Normal 3×3 starting grid | Balanced |
| **Compact** | Start at 4×4, -1 Operator slot | Tight optimization |
| **Expanded** | Start at 3×3, +2 columns | Column-focused |
| **Prime Grid** | All starting numbers are prime | Prime synergies |
| **Binary** | Only 0s and 1s | Quantity over quality |
| **High Roller** | Numbers range 5-15 | Big number strategies |
| **Negative** | Some numbers start negative | Subtraction play |
| **Sparse** | 50% fewer numbers (easier deletion) | Speed runs |
| **Dense** | 50% more numbers (harder deletion) | Scoring potential |
| **Symmetric** | Grid is always symmetric | Pattern recognition |
| **Random** | Grid size varies each puzzle | Adaptability |
| **Challenge** | All puzzles are Boss Puzzles | For experts |

---

## 10. Visual and Audio Design

### Visual Philosophy

**Clean and Readable**:
- Numbers are large and clear
- Deleted cells visually distinct (grayed, crossed out)
- Active constraints highlighted
- Running sums displayed in real-time

**Satisfying Feedback**:
- Numbers "pop" when deleted
- Rows/columns flash when sum is correct
- Score calculation animated step-by-step
- Operator effects visualized

**Aesthetic Direction**:
- Math notebook / graph paper theme
- Or: Calculator/spreadsheet retro aesthetic
- Or: Chalkboard classroom vibe
- Subtle animations, not distracting

### Audio Design

**Sound Effects**:
- Satisfying "click" when deleting numbers
- Rising tone as row sum approaches target
- "Ding" when row/column completes
- Cascade of sounds during score calculation
- Each Operator has signature sound

**Music**:
- Lo-fi, contemplative background
- Intensifies during Boss Puzzles
- Tempo increases with time pressure

---

## 11. Meta-Progression

### Unlockables

**Operators** (50+ total, ~20 unlocked via meta):
- Win with specific Grid Types
- Achieve certain score thresholds
- Complete specific challenges

**Grid Types** (12 total, 11 unlocked):
- Beat the game on each difficulty tier
- Complete achievement challenges

**Functions** (25+ total, ~10 unlocked):
- Use specific Operators in winning runs
- Complete numerical challenges (e.g., "Win with only prime numbers kept")

**Cosmetics**:
- Grid themes
- Number fonts
- Celebration animations

### Achievement Examples

| Achievement | Unlock |
|-------------|--------|
| "Prime Minister" - Win with only primes | Prime Time Operator |
| "Minimalist" - Win with <50 total deletions | Sparse Grid Type |
| "Perfect Run" - No retries in a run | Safety Net Upgrade |
| "Millionaire" - Score 1,000,000 in one puzzle | Legendary Operator access |

---

## 12. Educational Strategy: The Stealth Learning Approach

### The Critical Decision: Game First, Always

**Crosssums will NOT be marketed as an educational game.**

This is a deliberate strategic choice based on extensive analysis of what makes games like Balatro succeed versus what kills educational games.

### Why "Educational Game" Is a Death Sentence

The moment you label something "educational," you trigger immediate associations:

| What You Say | What People Hear |
|--------------|------------------|
| "Educational game" | "Boring but good for you" |
| "Math learning tool" | "Homework disguised as fun" |
| "Brain training" | "Something my mom would like" |
| "Curriculum-aligned" | "Designed by committee" |

**Balatro never marketed itself as "learn probability theory!"** It was a game that happened to involve math. The learning was incidental, invisible, and therefore powerful.

### The "Chocolate-Covered Broccoli" Problem

Educational game design has a name for the naive approach: wrap learning in "fun" mechanics, and kids will eat their vegetables.

It doesn't work because:

1. **Players aren't stupid.** They recognize when gameplay is subservient to learning objectives.
2. **The chocolate melts.** Fun mechanics that don't serve the core game feel hollow.
3. **Neither side is satisfied.** Educators want measurable outcomes. Gamers want depth. You disappoint both.
4. **Design by committee.** "We need to cover these standards" → constrained, compromised design.

### What Would Be Lost With Educational Positioning

- **The transgressive fantasy.** Balatro feels illicit—you're "breaking poker." Educational framing makes it virtuous, approved, *boring*.
- **The power fantasy.** Breaking mathematical rules is fun. Educational games need to *teach* rules, not celebrate violations.
- **Aesthetic freedom.** Gambling-adjacent aesthetics (which create satisfaction) become problematic for school contexts.
- **Audience trust.** Gamers smell insincerity. If the roguelike layer is a Trojan horse for math practice, players feel manipulated.

### The Success Pattern: Incidental Learning

Games that actually taught people things *never tried to*:

| Game | What It Taught | How |
|------|----------------|-----|
| **Minecraft** | Geometry, circuits, resources | By being a sandbox, not a classroom |
| **Kerbal Space Program** | Orbital mechanics, physics | By simulating reality, not testing it |
| **Civilization** | History, geography, systems | By making you live through it |
| **Balatro** | Probability, multiplication, optimization | By making big numbers satisfying |

**The pattern: Make a great game. Let learning happen as a side effect.**

### What Players Will Learn (Without Trying)

A well-designed Crosssums will build these skills invisibly:

#### Mental Math Fluency
- Rapid addition/subtraction
- Number sense ("what adds to 17?")
- Estimation and approximation
- Automatic recall of number bonds

#### Algebraic Thinking
- Working with variables (Wildcard Operator)
- Constraint satisfaction (rows AND columns)
- Substitution (transformation effects)
- Systems of equations (multiple simultaneous constraints)

#### Number Theory Intuition
- Prime number recognition (through synergies like Prime Time)
- Factors and multiples (through Operators)
- Odd/even properties
- Negative number manipulation

#### Executive Function
- Planning ahead
- Resource management
- Adapting strategies to changing conditions
- Risk assessment

#### Systems Thinking
- Interdependencies (changing one cell affects two sums)
- Optimization under constraints
- Trade-off evaluation
- Emergent complexity from simple rules

**None of this requires calling it "educational."**

### The Positioning Strategy

#### What We Say
- "Number puzzle roguelike"
- "What if Balatro and Sudoku had a baby"
- "Make numbers explode"
- "Break math to win"

#### What We Never Say
- "Educational"
- "Learning game"
- "Math practice"
- "Brain training"
- "Good for kids"

### The Long-Term Educational Play

#### Phase 1: Launch as Pure Game (Year 1)
- Target roguelike/puzzle game audience
- Build credibility in gaming community
- Let organic word-of-mouth develop
- Teachers who are gamers will discover it naturally

#### Phase 2: Quiet Educational Adoption (Year 1-2)
- Create free resources for educators (blog posts, not products)
- "How I Use Crosssums in My Classroom" guest posts
- Respond to (don't initiate) educational interest
- Share teacher testimonials on social media

#### Phase 3: Optional Classroom Tools (Year 2+, If Demand Exists)
- **Separate product**: "Crosssums Classroom Edition"
- Does NOT replace or dilute the main game
- Adds: progress tracking, assignment features, curriculum alignment
- Removes: gambling aesthetics, some compulsion mechanics
- Only pursue if organic demand materializes

### The Decisive Test

Ask: **Would Balatro have succeeded if it launched as "Poker Math Trainer: Learn Probability Through Play"?**

Obviously not. It would have been:
- Reviewed by education blogs, not gaming sites
- Downloaded by parents, not players
- Played once "to check it out," not obsessively
- Forgotten in a month

### The Paradox of Educational Games

> **The more you try to teach, the less people learn, because they stop playing.**

Minecraft has taught more kids about geometry than every "geometry game" combined—because kids *wanted* to play it.

### Ethical Considerations

Balatro's compulsion loops are powerful. We're using similar mechanics. Is this ethical?

**Our position:**
- No microtransactions or real-money gambling
- No predatory monetization
- The "cost" is time, not money
- Adults can make their own choices about time
- For younger players, parents can set limits

**What we won't do:**
- Target children explicitly
- Market to schools as engagement bait
- Use dark patterns to maximize playtime
- Ignore concerns about compulsion if they arise

### Summary: The Educational Positioning Matrix

| Approach | Fun | Learning | Commercial | Recommendation |
|----------|-----|----------|------------|----------------|
| Pure game, stealth learning | ★★★★★ | ★★★★ | ★★★★★ | **YES** |
| Post-launch classroom edition | ★★★★★ | ★★★★ | ★★★★ | Maybe later |
| "Brain training" positioning | ★★★ | ★★★ | ★★★ | No |
| Explicit educational | ★★ | ★★ | ★★ | **Never** |

### Design Mantras for This Section

1. "The best math teacher is a game that doesn't know it's teaching."
2. "Education is the side effect, not the goal."
3. "Players who love the game will learn. Players who know they're learning will quit."
4. "Balatro taught probability. It never said so."
5. "Make it undeniably fun. The learning takes care of itself."

---

## 13. Tech Stack and Distribution Strategy

### The Balatro Precedent

Balatro was built with:
- **Engine**: LÖVE (Love2D) - Lua-based 2D game framework
- **Language**: Lua
- **Development time**: ~2.5 years solo
- **Initial platforms**: Steam, PlayStation, Xbox, Nintendo Switch
- **Later**: macOS, iOS, Android

This stack enabled a solo developer to ship on all major platforms with relatively low overhead.

### Recommended Tech Stack for Crosssums

#### Option A: Web-First (Recommended for Speed-to-Market)

| Component | Technology | Why |
|-----------|------------|-----|
| **Engine** | None (vanilla) or Phaser.js | Lightweight, fast iteration |
| **Language** | TypeScript | Type safety, excellent tooling |
| **Rendering** | Canvas API or PixiJS | Simple 2D, great performance |
| **State Management** | Zustand or vanilla | Minimal overhead |
| **Build** | Vite | Fast dev server, easy builds |
| **Desktop Wrapper** | Electron or Tauri | Steam distribution |
| **Mobile Wrapper** | Capacitor or PWA | iOS/Android with same codebase |

**Pros:**
- Fastest iteration speed
- Single codebase for web, desktop, mobile
- Easy to prototype and test
- Lower barrier to entry
- Can launch browser demo immediately

**Cons:**
- Performance ceiling (fine for this game type)
- Electron bundles are large
- Some platform-specific quirks

#### Option B: LÖVE/Lua (The Balatro Stack)

| Component | Technology | Why |
|-----------|------------|-----|
| **Engine** | LÖVE (Love2D) | Proven for this exact genre |
| **Language** | Lua | Simple, fast scripting |
| **Console Ports** | Via publisher (like Playstack) | Handled externally |
| **Mobile** | love.js or native port | Possible but requires work |

**Pros:**
- Balatro proved it works
- Extremely lightweight
- Great for 2D card/puzzle games
- Easy to learn
- Excellent community

**Cons:**
- Mobile support requires extra work
- Console ports need publisher help
- Less modern tooling than TypeScript
- Smaller talent pool if you hire

#### Option C: Godot (Best All-Rounder)

| Component | Technology | Why |
|-----------|------------|-----|
| **Engine** | Godot 4.x | Open source, full-featured |
| **Language** | GDScript or C# | GDScript for speed, C# for complexity |
| **Export** | Built-in | Windows, Mac, Linux, Web, Mobile, Consoles |

**Pros:**
- Single engine for all platforms
- Built-in export to web (HTML5)
- Growing ecosystem
- No licensing fees
- 2D-first design

**Cons:**
- Console exports still require third-party tools
- Larger binary sizes than LÖVE
- Engine updates can break things

#### Option D: Unity (Overkill but Safe)

| Component | Technology | Why |
|-----------|------------|-----|
| **Engine** | Unity | Industry standard |
| **Language** | C# | Robust, well-supported |
| **Export** | Built-in | Everything |

**Pros:**
- Maximum platform support
- Huge ecosystem, assets, tutorials
- Easy to hire for
- Proven at scale

**Cons:**
- Overkill for a 2D puzzle game
- Licensing concerns (recent controversies)
- Slower iteration than web/LÖVE
- Heavier runtime

### Recommended Choice: Web-First with TypeScript

For a game like Crosssums, I recommend **Option A** for these reasons:

1. **Instant playtesting**: Share a link, anyone can play immediately
2. **Demo strategy**: Browser demo drives Steam wishlists (proven by many indie hits)
3. **Iteration speed**: Hot reload, instant feedback
4. **Single codebase**: Write once, deploy to web, Steam (Electron/Tauri), mobile (Capacitor)
5. **Modern tooling**: TypeScript catches bugs, VSCode integration is excellent
6. **Low risk**: If the game doesn't work, you haven't invested in engine learning

### Distribution Strategy

#### Phase 1: Validate (Months 1-3)

| Action | Platform | Goal |
|--------|----------|------|
| **Playable prototype** | itch.io (web) | Test core loop |
| **Discord community** | Discord | Build early audience |
| **Social content** | Twitter/TikTok | Generate interest |
| **Feedback collection** | Google Forms | Identify issues |

**Key milestone**: 1,000+ plays, positive feedback on core loop

#### Phase 2: Demo Launch (Months 4-6)

| Action | Platform | Goal |
|--------|----------|------|
| **Steam page** | Steam | Start wishlist collection |
| **Polished demo** | Steam Next Fest | Major visibility spike |
| **Press outreach** | Indie game press | Coverage and wishlists |
| **Content creators** | YouTube/Twitch | Organic discovery |

**Key milestone**: 10,000+ wishlists before launch

#### Phase 3: Launch (Month 7-9)

| Action | Platform | Priority |
|--------|----------|----------|
| **Steam release** | Steam | PRIMARY - 70%+ of revenue |
| **Web version** | itch.io / Newgrounds | Free demo, funnel to Steam |
| **GOG** | GOG | Secondary PC market |

**Pricing strategy**:
- $9.99-$14.99 (Balatro was $14.99)
- Launch discount 10-15%
- Regular sale participation

#### Phase 4: Platform Expansion (Months 10-18)

| Platform | Approach | Notes |
|----------|----------|-------|
| **Nintendo Switch** | Publisher or self-publish | Roguelikes do well here |
| **Mobile (iOS/Android)** | Premium ($4.99-6.99) | NOT free-to-play |
| **PlayStation/Xbox** | Publisher deal | Higher barrier, lower priority |
| **Netflix Games** | If approached | Guaranteed revenue, good exposure |

### Platform-Specific Notes

#### Steam (Critical)
- **Steam Next Fest**: Mandatory. Demos during Next Fest get massive visibility.
- **Tags**: "Roguelike Deckbuilder", "Card Game", "Puzzle", "Strategy"
- **Similar to**: Balatro, Slay the Spire, Luck Be a Landlord
- **Community**: Steam forums, update posts, community engagement

#### Mobile (Important)
- **Premium pricing**: Do NOT go free-to-play. It conflicts with roguelike design.
- **Apple Arcade**: Good option if they approach (guaranteed revenue, no IAP pressure)
- **Touch controls**: The game naturally works well (tap to delete numbers)

#### Nintendo Switch (High Priority)
- Roguelikes over-index on Switch (portable, pick-up-and-play)
- Balatro did extremely well on Switch
- Consider publisher for easier certification process

### Marketing Stack

| Purpose | Tool | Notes |
|---------|------|-------|
| **Community** | Discord | Core community hub |
| **Announcements** | Twitter/X | Game dev community lives here |
| **Video content** | TikTok/YouTube Shorts | Viral potential for score explosions |
| **Long-form** | YouTube | Trailers, devlogs |
| **Press** | Press kit (presskit.html) | Make journalists' jobs easy |
| **Email** | Buttondown/Mailchimp | Mailing list for launch day |
| **Steam** | Steamworks | Built-in visibility tools |

### The Demo Strategy (Critical)

Balatro's demo was crucial to its success. For Crosssums:

1. **Demo scope**: First 2-3 Stages, limited Operators/Grids
2. **Demo availability**: Permanent on Steam, web version on itch.io
3. **Demo-to-purchase hook**: Show locked content, tease synergies
4. **Steam Next Fest**: Time demo polish for Next Fest participation

### Budget Allocation (If $10K-50K Available)

| Category | % | Notes |
|----------|---|-------|
| **Development** | 40% | Your time or contractor time |
| **Art/Audio** | 25% | Polished visuals matter for this genre |
| **Marketing** | 20% | Launch ads, content creator outreach |
| **Platform fees** | 10% | Steam, Apple, etc. |
| **Contingency** | 5% | Unexpected costs |

### Success Metrics by Phase

| Phase | Metric | Target |
|-------|--------|--------|
| **Prototype** | Playtest retention | 50%+ play 3+ games |
| **Demo** | Steam wishlists | 10,000+ |
| **Launch week** | Sales | 5,000+ units |
| **Month 1** | Revenue | Recoup costs |
| **Year 1** | Total sales | 50,000+ units |

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **Market saturation** | Differentiate via number puzzles vs. cards |
| **Balatro fatigue** | Wait 12-18 months post-Balatro peak |
| **Platform rejection** | Avoid explicit gambling imagery |
| **Scope creep** | MVP first: 50 Operators, 5 Grids, 8 Stages |
| **Solo dev burnout** | Set hard deadlines, take breaks |

### Tech Stack Summary

```
RECOMMENDED STACK:
├── Language: TypeScript
├── Rendering: PixiJS or Canvas API
├── State: Zustand
├── Build: Vite
├── Desktop: Tauri (smaller) or Electron (easier)
├── Mobile: Capacitor
├── Web: Direct deployment
└── Source Control: Git + GitHub

ALTERNATIVE (Balatro-style):
├── Engine: LÖVE (Love2D)
├── Language: Lua
└── Ports: Handle per-platform
```

---

## 14. Similar Games for Balatro-Style Treatment

Beyond Crosssums, here are other simple games ripe for roguelike transformation:

### Tier 1: Perfect Candidates

| Game | Why It Works | Potential "Joker" System |
|------|--------------|-------------------------|
| **Minesweeper** | Universal familiarity, logical deduction | Operators that reveal cells, change mine behavior, score bonuses |
| **Sudoku** | Deep logic, constraint satisfaction | Number modifiers, region bonuses, rule-breakers |
| **Wordle/Word Games** | Letter manipulation, pattern matching | Letter modifiers, word bonuses, alphabet transformations |
| **2048** | Number merging, spatial reasoning | Merge bonuses, tile modifiers, board expansions |
| **Nonograms/Picross** | Pattern completion, grid solving | Row/column bonuses, color modifiers |

### Tier 2: Strong Candidates

| Game | Why It Works | Potential "Joker" System |
|------|--------------|-------------------------|
| **Yahtzee/Dice** | Probability, set collection | Dice modifiers, reroll bonuses, category multipliers |
| **Mahjong Solitaire** | Tile matching, spatial awareness | Match bonuses, tile transformations, layout modifiers |
| **Tetris** | Shape fitting, spatial reasoning | Block modifiers, line bonuses, hold mechanics |
| **Memory/Concentration** | Pattern memory, matching | Peek abilities, match multipliers, grid modifiers |
| **Connect 4/Tic-Tac-Toe** | Pattern completion | Win condition modifiers, board transformations |

### Tier 3: Experimental Candidates

| Game | Why It Works | Potential "Joker" System |
|------|--------------|-------------------------|
| **Snake** | Simple movement, growth | Speed modifiers, food bonuses, board effects |
| **Breakout/Arkanoid** | Physics, brick breaking | Ball modifiers, brick types, paddle upgrades |
| **Pipe Dream** | Connection puzzles | Pipe modifiers, flow bonuses, grid effects |
| **Lights Out** | Toggle puzzles | Light modifiers, pattern bonuses |

### Key Criteria for Selection

A game is a good candidate if it has:

1. **Universal Recognition**: Everyone knows how to play (or can learn in <1 minute)
2. **Clear Win State**: Obvious success/failure conditions
3. **Discrete Actions**: Countable moves that can be modified
4. **Numerical Output**: Some score or metric that can be multiplied
5. **Constraint Satisfaction**: Rules that can be bent/broken by modifiers
6. **Quick Sessions**: Individual puzzles take 1-5 minutes
7. **Skill Expression**: Better players consistently outperform beginners

### The Transformation Formula

To "Balatro-ify" any simple game:

1. **Identify the core loop** (in Crosssums: delete numbers to match sums)
2. **Create a scoring system** with chips×mult structure
3. **Design Operators** that modify rules, add bonuses, or transform elements
4. **Add consumables** for one-time grid manipulation
5. **Build progression** through stages with increasing requirements
6. **Include Boss variants** with special constraints
7. **Implement economy** for shop between stages
8. **Layer meta-progression** through unlockables
9. **Add "juice"** through visual/audio feedback on scoring

---

## Appendix: Quick Reference

### Core Loop
```
Puzzle → Score → Shop → (repeat) → Boss → Win/Lose
```

### Key Numbers
- 8 Stages, 3 Puzzles each = 24 puzzles per run
- 5 base Operator slots
- 3 starting lives
- ~$5-10 income per puzzle
- Target score scales from 300 to 75,000+

### Design Mantras
1. "Addition is universal"
2. "Deletion creates choice"
3. "Multiplication enables explosion"
4. "Constraints enable creativity"
5. "Every number should feel meaningful"

---

*Design Document v1.2 - January 2026*

*Updates:*
- *v1.1: Added Educational Strategy section*
- *v1.2: Added Tech Stack and Distribution Strategy section*
