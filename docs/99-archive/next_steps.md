# Look here for what to work on next.

## Potential Next Steps

### Polish the shop
- Add visual feedback for buy/sell (animations, sounds)
- Show operator rarity with colors
- Add tooltips for operators

### Add more operators
- Currently have 5 operators - could use more variety
- Consider transformation operators (Flipper, Doubler, etc.)

### Functions (consumables)
- One-time use items from the design doc
- Need: Function base class, registry, UI in shop

### Game balance
- Playtest new slack progression and stage gates
- Tune score targets (currently ~3x old values)
- Consider boss puzzle score weight (2x?)
- Consider grid sizes per puzzle (not just stage)

### Audio
- Add sound effects for interactions
- Background music

### Save/Load
- Persist run state between sessions


## Completed

- Circle-only win condition (circled cells matching targets wins)
- Board layout sizing (increased from 55% to 70%)
- Shop implementation (buy/sell/reroll operators)
- Circling an invalid move is a misstep
- Add linter
- Slack progression (tight→loose within each stage)
- Stage-level score gates (accumulate across 3 puzzles)
