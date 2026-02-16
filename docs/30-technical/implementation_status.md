# Implementation Status

> Cross-reference of design docs vs actual code implementation
> Last updated: 2026-02-15

---

## Legend
- ✅ Implemented - Feature is complete and working
- 🚧 Partially Implemented - Core exists but missing pieces
- ❌ Not Yet Implemented - Documented but no code
- 📋 Planned - Mentioned in docs, on roadmap

---

## Core Puzzle Mechanics

| Feature | Status | Notes |
|---------|--------|-------|
| Grid rendering (3x3 to 6x6) | ✅ | Working with `puzzle_grid.gd` |
| Cell deletion on tap/click | ✅ | Toggle delete/restore working |
| Cell circling (mark as keeper) | ✅ | Added for circle-based win condition |
| Real-time sum display | ✅ | Row/column targets update live |
| Target color feedback (red/green) | ✅ | 2-state: match vs no-match |
| Auto-win detection | ✅ | Both deletion-based and circle-based |
| Undo functionality | ✅ | Undo button + history tracking |
| Solution validation | ✅ | `PuzzleLogic.validate()` |
| Single-solution puzzles | ✅ | Each puzzle has exactly one valid solution |
| Negative numbers | ❌ | `allow_negatives` flag exists but not enabled |
| Locked cells (boss constraint) | ❌ | `CellState.LOCKED` enum exists, not used |

## Puzzle Generation

| Feature | Status | Notes |
|---------|--------|-------|
| Guaranteed solvable puzzles | ✅ | Algorithm ensures at least one solution |
| At least 1 solution cell per row/col | ✅ | No zero targets |
| At least 1 decoy cell per row/col | ✅ | Puzzle never pre-solved |
| Backtracking solver | ✅ | `has_any_solution()` with memoization |
| Slack parameter (difficulty) | 🚧 | Config exists, affects delete ratio |
| Negative number generation | ❌ | Config present, generation skipped |
| Seed-based reproducibility | ✅ | `puzzle_seed` works |

## Scoring System

| Feature | Status | Notes |
|---------|--------|-------|
| Base points by grid size | ✅ | `dim² × 10` (90/160/250/360 for 3x3-6x6) |
| Kept cell bonus | ✅ | +25 per kept cell |
| Time multiplier (decaying) | ✅ | 2.0x → 1.0x over puzzle duration |
| Operator scoring hooks | ✅ | `on_cell_kept`, `on_row_complete`, etc. |
| Score breakdown display | ✅ | Summary shown on win |
| Animated score calculation | ❌ | No step-by-step Balatro-style reveal |
| Streak multiplier | ❌ | Config exists, not wired up |

## Operator System (Jokers)

| Feature | Status | Notes |
|---------|--------|-------|
| Operator base class | ✅ | `Operator.gd` with hooks |
| Operator registry | ✅ | `OperatorRegistry.gd` with 9 operators |
| Counter (+10 per kept) | ✅ | Working |
| Row Master (+50 per row) | ✅ | Working |
| Column Master (+50 per col) | ✅ | Working |
| Circlicious (+$2 circled/-$1 deleted) | ✅ | Working |
| Elite Delete (+$2 deleted/-$1 circled) | ✅ | Working |
| Purist (+300 if no circles) | ✅ | Working |
| Gimme (auto-solve last cell) | ✅ | Working |
| Sum Sight (show running sums) | ✅ | Working |
| Safety Net (solved rows/cols glow) | ✅ | Working |
| Transformation operators (Flipper, Doubler) | ❌ | Not implemented |
| Economy operators (Calculator, Banker) | ❌ | Not implemented |
| Rule-breaking operators (Overflow, Skip Row) | ❌ | Not implemented |
| Legendary operators | ❌ | Not implemented |
| Operator editions (Golden, Holo, etc.) | ❌ | Not implemented |
| Operator slots limit (max 5) | ✅ | `MAX_OPERATORS = 5` |
| Operator selling | ✅ | Half price refund |
| Operator trigger animation/feedback | 🚧 | Event emitted, no visual effect |

## Functions (Consumables)

| Feature | Status | Notes |
|---------|--------|-------|
| Function base class | ❌ | Not implemented |
| Function registry | ❌ | Not implemented |
| Grid functions (Shuffle, Rotate, Mirror) | ❌ | Not implemented |
| Target functions (Relax, Tighten) | ❌ | Not implemented |
| Hint function (reveal solution) | ❌ | Not implemented |
| Any consumable | ❌ | Zero consumables exist |

## Run Structure

| Feature | Status | Notes |
|---------|--------|-------|
| 8 stages | ✅ | `StageConfig` with 8 stages |
| 3 puzzles per stage | ✅ | `puzzle_index` 0-2 |
| Grid size progression | ✅ | 3x3 → 6x6 |
| Lives system | ❌ | Removed; timer timeout is only fail condition |
| Money system | ✅ | Score converts to money, spend in shop |
| Stage gate | ❌ | Removed; no score requirements to advance |
| Boss puzzles (special constraints) | ❌ | No special boss rules |
| Puzzle skipping for tags | ❌ | Not implemented |
| Run state serialization | ✅ | Save/load capable |

## Shop System

| Feature | Status | Notes |
|---------|--------|-------|
| Shop screen | ✅ | `shop_placeholder.gd` functional |
| 3 operators for sale | ✅ | Random selection |
| Buy operators | ✅ | Deducts money, adds to inventory |
| Sell operators | ✅ | Returns half price |
| Reroll (escalating cost) | ✅ | $2, $3, $4... |
| Functions for sale | ❌ | No functions exist |
| Packs (choose 1 of N) | ❌ | Not implemented |
| Upgrades/Vouchers | ❌ | Not implemented |

## Difficulty Tiers

| Feature | Status | Notes |
|---------|--------|-------|
| Base difficulty (Casual) | ✅ | Current implementation |
| Difficulty modifiers | ❌ | None of the 8 tiers |
| Endless mode | ❌ | Not implemented |

## Grid Variations (Decks)

| Feature | Status | Notes |
|---------|--------|-------|
| Standard grid | ✅ | Default |
| Alternative grid types | ❌ | None of the 12 deck types |

## Visual/Audio

| Feature | Status | Notes |
|---------|--------|-------|
| Cell deletion animation | ✅ | Scale animation |
| Target color changes | ✅ | Red/green transitions |
| Score display | ✅ | Final score with summary |
| Timer bar | ✅ | Visual decay indicator |
| Operator card display | 🚧 | In shop only, not in play |
| Sound effects | ✅ | SoundManager + audio files (gitignored) |
| Music | ❌ | No audio implemented |
| Particle effects | ❌ | Not implemented |
| Screen transitions | 🚧 | Basic scene changes only |

## Meta-Progression

| Feature | Status | Notes |
|---------|--------|-------|
| Persistent unlocks | ❌ | Not implemented |
| Achievement system | ❌ | Not implemented |
| Operator unlocking | ❌ | All operators available |
| Grid type unlocking | ❌ | N/A (no grid types) |
| Cosmetics | ❌ | Not implemented |

## UI Screens

| Feature | Status | Notes |
|---------|--------|-------|
| Title screen | ✅ | Start, How to Play, Options (grayed) |
| Main puzzle screen | ✅ | Full HUD with all indicators |
| How to Play overlay | ✅ | Basic tutorial text |
| Result popup | ✅ | Win/lose, score, reward |
| Shop screen | ✅ | Buy/sell/reroll |
| Game over screen | ✅ | Score + return to title |
| Victory screen | ✅ | Score + return to title |
| Options menu | ❌ | Button exists, not functional |

## Testing & Debugging

| Feature | Status | Notes |
|---------|--------|-------|
| Debug server | ✅ | HTTP API for game control |
| JSON test corpus | ✅ | 28 tests in `tests/corpus/` |
| Test runner | ✅ | TypeScript + Godot headless |
| GDLint integration | ✅ | Runs before tests |
| Explicit puzzle setup | ✅ | `set_puzzle` action |
| Operator manipulation | ✅ | `add_operator`, `remove_operator` |
| State serialization | ✅ | `get_full_state`, `set_full_state` |

---

## Summary by Phase

### Phase 1-3: Core Puzzle ✅
Everything needed for basic puzzle solving is complete.

### Phase 4: Operators ✅
9 operators implemented. No transformation/economy/rule-breaking operators yet.

### Phase 5: Shop ✅
Basic shop is functional. No consumables/packs/upgrades.

### Sprint 3: Negative Numbers ❌
Infrastructure exists but feature not enabled.

### Sprint 4: Run Flow ✅
8 stages with progression. Lives and score gates removed; timer timeout is fail condition.

---

## Technical Debt & Known Issues

1. **Audio files gitignored** - SoundManager works, assets excluded from repo
2. **No save/load UI** - Code exists but no player-facing feature
3. **Operator UI during play** - No indicator of owned operators in puzzle screen
4. **No score animation** - Instant score reveal, not Balatro-style cascade
5. **Options menu stub** - Button does nothing
6. **Animations need polish** - Minimal juice currently
