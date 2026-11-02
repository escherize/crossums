# Sum Assembly Required: Theme Direction

An alternative visual identity inspired by flat-pack furniture assembly instructions.

---

## Core Concept

The entire game looks and feels like an IKEA instruction manual that came to life. Clean Scandinavian minimalism meets the universal experience of furniture assembly.

**Why it works:** Furniture assembly is already a puzzle. You're just making the puzzle explicit while keeping the satisfying tactile resolution of "it somehow works."

---

## Visual Identity

### Color Palette

| Role | Color | Hex | Notes |
|------|-------|-----|-------|
| Primary Surface | Birch Wood | `#D4A574` | Warm, natural |
| Secondary Surface | White Laminate | `#F5F5F0` | Clean, minimal |
| Background | Cardboard | `#C4A882` | Kraft paper texture |
| Accent Primary | Swedish Blue | `#004F9F` | Similar to but distinct from IKEA blue |
| Accent Secondary | Swedish Yellow | `#FFC61E` | Used sparingly |
| Text | Charcoal | `#333333` | Instruction manual ink |
| Deleted Cell | Dotted Outline | `#999999` | "Part not included" |
| Valid Target | Success Green | `#4A7C4E` | Muted, natural |
| Invalid Target | Warning Red | `#C44536` | Warm, not alarming |

### Typography

- **Primary Font:** Clean sans-serif (Futura, Verdana-style)
- **Numbers:** Technical drawing style—rounded, highly legible
- **Swedish Text:** Slightly imperfect, as if printed on kraft paper

### The Grid

The puzzle grid is a **wooden pegboard** viewed from above:

```
┌─────────────────────────────────┐
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐  = 12 │
│  │ 3 │ │ · │ │ 5 │ │ 4 │       │
│  └───┘ └───┘ └───┘ └───┘       │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐  = 10 │
│  │ · │ │ 2 │ │ 1 │ │ 7 │       │
│  └───┘ └───┘ └───┘ └───┘       │
│                                 │
│   =8   =7    =6    =11         │
└─────────────────────────────────┘
```

- Numbers are wooden dowels/pegs in holes, or printed on small wooden tiles
- Row/column targets appear on paper strips taped to edges (like measurement guides)
- Deleted cells show empty holes or dotted "part not included" outlines

### Puzzle Frame

Each puzzle is presented as an assembly step:

```
╭────────────────────────────────╮
│  STEG 14 av 47                 │
│  ─────────────────             │
│                                │
│  [PUZZLE GRID]                 │
│                                │
│  POÄNG: 1,247                  │
╰────────────────────────────────╯
```

### UI Elements

| Element | Treatment |
|---------|-----------|
| Panels | Cardboard texture with slightly rounded corners |
| Buttons (primary) | Wooden with chrome screw corners |
| Buttons (secondary) | Paper/cardboard, slightly dog-eared |
| Dividers | Small wooden dowels |
| Bullet points | Chrome hex screws |
| Corners | Chrome hinges and fixtures |
| Borders | Thin black lines (instruction manual style) |

### Decorative Elements

- Allen wrenches scattered around UI borders
- Small wooden dowels as decorative elements
- Numbered circles for navigation (like step numbers)
- Occasional stick figure reactions

---

## Naming & Terminology

### Core Terms

| Current | Swedish | Pronunciation | Meaning |
|---------|---------|---------------|---------|
| Points | **POÄNG** | "poh-ENG" | Points (also an IKEA chair!) |
| Score | **POÄNG** | | |
| Multiplier | **BONUS** | | Keep it simple |
| Stage/Level | **STEG** | "steg" | Step |
| Run | **BYGGE** | "BIG-eh" | Build/construction |
| Complete | **SLUTFÖRD** | | Completed |

### Operator Names

Operators are renamed with Swedish-inspired names. All are invented (not real IKEA products) for legal safety.

| Current | Swedish Name | Meaning | Effect Description |
|---------|--------------|---------|-------------------|
| Circlicious | **RUNDLIG** | "rounded" | Bonus for circled numbers |
| Zero Hero | **TOMRUM** | "empty space" | Bonus for zeros remaining |
| Column Master | **KOLONN** | "column" | Column-based scoring |
| Elite Delete | **PRECIS** | "precise" | Bonus for exact solutions |
| Flipper | **VÄND** | "turn/flip" | Flip number values |
| Purist | **RENHET** | "purity" | Bonus for clean solutions |
| Square Peg | **FYRKANT** | "square" | Grid-based bonuses |

### Additional Operator Ideas

| Name | Meaning | Potential Effect |
|------|---------|-----------------|
| **DUBBEL** | double | 2x multiplier |
| **MANUALEN** | the manual | Reveals hint for one row |
| **KAFFERAST** | coffee break | Extra time/moves |
| **TRÄHAMMARE** | wooden mallet | Force-delete capability |
| **SKIFTNYCKEL** | adjustable wrench | Modify a number by ±1 |
| **EXTRA DELAR** | extra parts | Start with bonus deletions |
| **HJÄLP** | help | Hint system |
| **SAKNAS** | missing | Challenge: random cells start deleted |
| **PRIMTAL** | prime number | Bonus for primes |
| **UDDA** | odd | Bonus for odd numbers |
| **JÄMN** | even | Bonus for even numbers |
| **KEDJA** | chain | Chain reaction bonuses |

---

## Sound Design

### Interaction Sounds

| Action | Sound |
|--------|-------|
| Hover/Select | Light wooden "tok" (tapping a dowel) |
| Delete number | Satisfying peg "pop" with slight suction release |
| Restore number | Solid "thock" of peg seating into hole |
| Row/column solved | Hex key sequence: "chk-chk-chk-CLICK" |
| Invalid move | Wobble of unleveled furniture |
| Stage complete | Satisfying mechanical resolution |

### Ambient Audio

- Light, repetitive, slightly muzak-influenced background
- Occasional "ding-dong" like a store PA system
- Distant warehouse ambience (subtle)

### Music Moods

| State | Feel |
|-------|------|
| Normal play | Pleasant, focused, store-like calm |
| Time pressure | Uptempo but composed ("store closing soon") |
| Victory | Satisfied accomplishment, soft resolution |

---

## The Tutorial: Assembly Instructions

The tutorial is presented as a wordless instruction manual, using the iconic stick-figure style.

### Tutorial Flow

```
┌─────────────────────────────────────────┐
│  STEG 1                                 │
│  ───────                                │
│                                         │
│  [Stick figure looking at grid]         │
│                                         │
│  [Arrow pointing to a number]           │
│                                         │
│  [Finger tap icon]                      │
│                                         │
│           ↓                             │
│                                         │
│  [Number disappears with "pop" visual]  │
│                                         │
│  [Stick figure nodding]                 │
│                                         │
└─────────────────────────────────────────┘
```

### Tutorial Steps

**STEG 1: Deletion**
- Pictogram: Finger tapping a number
- Result: Number lifts out
- Stick figure: Satisfied nod

**STEG 2: Target Sums**
- Pictogram: Arrow from remaining numbers to target
- Visual: Numbers + numbers = target (with check mark)
- Stick figure: "Aha!" moment

**STEG 3: Row Complete**
- Pictogram: Completed row glows
- Visual: Hex key turning, click animation
- Stick figure: Thumbs up

**STEG 4: Keep More = Score More**
- Pictogram: Two grids side by side
- Left: Many numbers remaining, big POÄNG
- Right: Few numbers remaining, small POÄNG
- Stick figure: Pointing to left grid approvingly

**STEG 5: The Goal**
- Pictogram: All rows and columns showing checkmarks
- Visual: Celebration, parts flying
- Stick figure: Arms raised in triumph

### Tutorial UI

- Minimal text (Swedish labels only, no explanations)
- Heavy reliance on pictograms and arrows
- "Next" button is just an arrow →
- Can tap anywhere to advance
- Skip option shown as small "HOPPA ÖVER" in corner

### Stick Figure Expressions

The tutorial stick figure has simple emotional states:

| State | Expression |
|-------|------------|
| Neutral | Standard pose |
| Confused | Question mark, scratching head |
| Success | Nodding, thumbs up |
| Triumph | Arms raised |
| Mistake | Hands on head, worried |

---

## Results Screen

```
╭──────────────────────────────────────╮
│                                      │
│  STEG 14 ✓ SLUTFÖRD                  │
│  ──────────────────                  │
│                                      │
│  [Pictogram of assembled shelf]      │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  POÄNG:         1,247         │  │
│  │  DELAR KVAR:    12 av 16      │  │
│  │  BONUS:         x1.5          │  │
│  └────────────────────────────────┘  │
│                                      │
│  [Stick figure admiring shelf]       │
│                                      │
│  ┌──────────────────────────────┐    │
│  │      → NÄSTA STEG            │    │
│  └──────────────────────────────┘    │
│                                      │
╰──────────────────────────────────────╯
```

---

## Animation Principles

### Core Philosophy

Everything should feel **tactile and physical**:

1. **Numbers don't disappear** — they're removed like lifting a peg
2. **Score increases** — counter clicking up, mechanical
3. **Transitions** — page turns, unfolding instructions
4. **Hover states** — subtle lift/shadow as if you're about to pick it up

### Specific Animations

| Event | Animation |
|-------|-----------|
| Cell hover | Slight lift, shadow appears beneath |
| Cell delete | Peg lifts up and out, hole revealed |
| Cell restore | Peg drops in, satisfying seat |
| Row complete | Brief pulse, hex-key rotation icon |
| Stage complete | Grid "folds" away like closing instructions |
| Stage start | Grid "unfolds" from paper |

---

## Legal Safety

### Do

- Create fictional Swedish store name: SMÖRGAS, TRÄVIK, MÖBELMAN
- Invent Swedish-ish operator names (not real products)
- Use similar but distinct blue (#004F9F, not #0051BA)
- Make stick figures your own style
- Market as "furniture assembly puzzle" not "IKEA parody"

### Don't

- Never use the word "IKEA" anywhere
- Don't copy exact product names (KALLAX, BILLY, MALM)
- Don't use the exact IKEA logo or wordmark
- Don't use exact IKEA stick figure style

### Positioning

The game comments on the universal experience of furniture assembly. This is parody/commentary and transformative use. Nobody will confuse this number puzzle with actual furniture.

---

## Implementation Phases

### Phase 1: Quick Wins (Low effort, high impact)

- [ ] Color palette shift to birch/white/cardboard
- [ ] Rename points to POÄNG throughout
- [ ] Rename operators with Swedish names
- [ ] Add "STEG X" framing to puzzles
- [ ] Update fonts to clean sans-serif

### Phase 2: Visual Polish

- [ ] Redesign grid cells as wooden pegs/tiles
- [ ] Add cardboard/wood textures to UI panels
- [ ] Create stick figure character for tutorial
- [ ] Implement paper-style transitions
- [ ] Design operator cards with pictograms

### Phase 3: Sound Design

- [ ] Wooden/mechanical interaction sounds
- [ ] Ambient background audio
- [ ] Satisfying click sequences
- [ ] Victory/completion sounds

### Phase 4: Full Theming

- [ ] Complete tutorial redesign (wordless)
- [ ] Operator pictogram system
- [ ] Results screen with stick figure
- [ ] Polish pass for coherence

---

## Open Questions

1. **Narrative frame?** — Options include:
   - Abstract (just puzzles, no story)
   - Apartment move-in (assemble furniture to progress)
   - Warehouse worker (balance inventory)
   - Keep it minimal?

2. **Store name?** — Need a fictional Swedish furniture store name
   - SMÖRGAS (sandwich — funny)
   - TRÄVIK (wood bay)
   - MÖBELMAN (furniture man)
   - BYGGHUS (build house)

3. **Stick figure style?** — How much personality?
   - Minimal (classic instruction manual)
   - Expressive (more cartoon-like)
   - Somewhere in between

---

## Comparison to Current Theme

| Aspect | Cyber-Neon (Current) | Sum Assembly Required |
|--------|---------------------|----------------------|
| Palette | Dark, neon, high contrast | Warm, natural, muted |
| Feel | Tech, futuristic | Cozy, tactile, familiar |
| Metaphor | Hacking, glitching | Building, assembling |
| Target Audience | Tech-savvy, Balatro fans | Broader, puzzle fans |
| Differentiation | Similar to Balatro | Unique in market |
| Humor | Minimal | Built-in (assembly frustration) |

---

## References

- IKEA instruction manuals (composition, pictograms)
- Unpacking (game) — tactile, satisfying object placement
- Monument Valley — clean, minimal puzzle aesthetic
- Human Resource Machine — instruction/programming visual style
