# Crosssums

A Balatro-inspired roguelike number puzzle game built in Godot 4.5.

## Concept

Delete numbers from a grid so each row and column sums to its target. Keep more numbers for higher scores. Collect operators (like Balatro's Jokers) to modify scoring.

## Status

**Phase 1-3 Complete** - Core puzzle mechanics working
- Grid rendering (3x3 to 6x6)
- Touch-friendly tap-to-toggle
- Puzzle generation with guaranteed solutions
- Scoring system with optimization incentives
- Auto-win detection

**Next Up** - Run structure (stages, lives, score targets), then operators

## Quick Start

1. Open `godot_app/` in Godot 4.5.1+
2. Run (F5)
3. Click numbers to delete them
4. Make all targets turn green

## Documentation

- `godot_app/DEVELOPMENT.md` - Architecture, code guide, data flow
- `crosssums-design-doc.md` - Full game design document
- `worklog.md` - Daily development log

## Tech Stack

- Godot 4.5.1
- GDScript
- Target: Mobile/tablet (touch-first design)
