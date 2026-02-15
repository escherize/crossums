# Operator Ideas: Board-Reading Super Powers

> Philosophy: Operators can help users understand the board and make better decisions. These should feel like super powers—you see more, understand more, decide faster.

## The Super Power Fantasy

Great power-ups make players feel smarter, not just stronger. These operators:
- Reveal hidden information
- Highlight important patterns
- Preview consequences
- Calculate automatically
- Warn of dangers
- Enhance memory

---

## 25 Board-Reading Operator Ideas

### Category A: Sum Visualization

#### 1. Sum Sight
**Effect:** Circled cells show their sum in the corner of each target cell
**Rarity:** Common | **Price:** 5

**Super power feel:** You gain "X-ray vision" for your progress. The sum updates live as you circle cells—no mental math required.

**Better choices:** Lets you verify your theory before committing. Circle 3 cells, see sum is 2 off, know you need to adjust.

---

### Category C: Pattern Recognition

#### 11. Pair Spotter
**Effect:** Highlight pairs of cells that sum to a row/column's deficit
**Rarity:** Uncommon | **Price:** 6

**Super power feel:** Combinations reveal themselves. "These two cells together equal exactly what I need!"

**Better choices:** Spot non-obvious combinations. Speed up solving.

---

#### 13. Row-Column Intersection
### Category D: Consequence Preview

#### 16. Delete Preview
**Effect:** Hovering shows what row/col sums would become after deletion
**Rarity:** Common | **Price:** 5

**Super power feel:** See the future before acting. "If I delete this, the row becomes..."

**Better choices:** Never be surprised by a deletion. Check before committing.

---

#### 17. Chain Reaction
**Effect:** Show cells that become "forced" deletions after hovering cell is deleted
**Rarity:** Rare | **Price:** 9

**Super power feel:** See dominoes before they fall. "Deleting this means I must delete these too."

**Better choices:** Understand cascading consequences. Avoid accidental chain failures.

---

### Category E: Information Overlays

#### 22. Deletion Tracker
**Effect:** Show "X of Y cells deleted"
**Rarity:** Common | **Price:** 3

**Super power feel:** Know exactly where you stand. Progress bar for puzzle solving.

**Better choices:** Gauge difficulty. "3 cells left to decide, 2 rows incomplete—almost there!"

---

#### 25. Constraint Tightness
**Effect:** Highlight rows/columns with only one valid configuration remaining
**Rarity:** Rare | **Price:** 8

**Super power feel:** Know which lines are "solved" even before you delete. These are deterministic.

**Better choices:** Tackle forced rows first. They give you information for free.

---

## Implementation Notes

### Visual Design Principles
- **Color consistency** - Red=danger, green=safe, gold=perfect, blue=info
- **Non-blocking** - Overlays shouldn't hide cell values

### Technical Considerations
- Hover effects need debouncing to avoid flicker

### Balance Concerns
- Consider limiting uses per puzzle for strongest operators
- Or make them expensive enough to be rare finds
