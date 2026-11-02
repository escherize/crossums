# Color Audit for Sum Assembly Required Theme

## Status: Complete

This audit documents all hardcoded color values in the codebase and maps them to the new "Sum Assembly Required" theme palette.

---

## Theme Color Mapping

| Purpose | Current Color | New Color Name | New Hex |
|---------|--------------|----------------|---------|
| Background | Dark blue-gray | Cardboard | #C4A882 |
| Primary surface | Dark blue | Birch Wood | #D4A574 |
| Secondary surface | Various grays | White Laminate | #F5F5F0 |
| Primary accent | Cyan | Swedish Blue | #004F9F |
| Secondary accent | Yellow/Gold | Swedish Yellow | #FFC61E |
| Text | White | Charcoal | #333333 |
| Valid target | Green (0.2, 0.6, 0.3) | Success Green | #4A7C4E |
| Invalid target | Red (0.7, 0.25, 0.25) | Warning Red | #C44536 |
| Deleted cell | Dark gray | Dotted Gray | #999999 |

---

## Files with Hardcoded Colors

### 1. `scenes/main.tscn` - Main Game Screen
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 11 | `Color(0.2, 0.22, 0.28, 1)` | Main background StyleBox | #C4A882 (Cardboard) |
| 18 | `Color(0.4, 0.8, 0.9, 1)` | Timer fill StyleBox | #004F9F (Swedish Blue) |
| 40 | `Color(0.12, 0.14, 0.18, 1)` | Game area background | #D4A574 (Birch Wood) |
| 76 | `Color(0.9, 0.85, 0.6, 1)` | Stage label font color | #333333 (Charcoal) |
| 83 | `Color(0.7, 0.75, 0.8, 1)` | Puzzle label font color | #333333 (Charcoal) |
| 90 | `Color(0.4, 0.8, 0.4, 1)` | Money label font color | #4A7C4E (Success Green) |
| 97 | `Color(0.8, 0.8, 0.9, 1)` | Score label font color | #333333 (Charcoal) |
| 104 | `Color(0.5, 0.8, 0.9, 1)` | Timer label font color | #333333 (Charcoal) |

### 2. `scenes/main.gd` - Main Game Logic
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 74 | `Color(0.4, 0.8, 0.9, 1.0)` | Timer fill cyan | #004F9F (Swedish Blue) |
| 144 | `Color(0.4, 0.8, 0.9, 1.0)` | Timer fill reset | #004F9F (Swedish Blue) |
| 161 | `Color(0.4, 0.8, 0.9, 1.0)` | Timer cyan | #004F9F (Swedish Blue) |
| 162 | `Color(0.9, 0.3, 0.3, 1.0)` | Timer warning red | #C44536 (Warning Red) |
| 255 | `Color(1.5, 1.5, 0.5)` | Undo button flash | #FFC61E (Swedish Yellow) |

### 3. `scenes/puzzle/grid_cell.gd` - Grid Cell Colors
| Line | Constant | Current Value | Purpose | New Value |
|------|----------|--------------|---------|-----------|
| 17 | `COLOR_ACTIVE` | `Color(0.2, 0.25, 0.35)` | Active cell background | #F5F5F0 (White Laminate) |
| 18 | `COLOR_ACTIVE_HOVER` | `Color(0.3, 0.35, 0.45)` | Hover state | Lighter #F5F5F0 |
| 19 | `COLOR_DELETED` | `Color(0.15, 0.15, 0.15)` | Deleted cell | #999999 (Gray) |
| 20 | `COLOR_CIRCLED` | `Color(0.15, 0.32, 0.42)` | Circled background | Swedish Blue tinted |
| 21 | `COLOR_CIRCLED_BORDER` | `Color(0.4, 0.9, 1.0)` | Circled border | #004F9F (Swedish Blue) |
| 22 | `COLOR_PROTECTED_TINT` | `Color(0.6, 1.0, 0.6)` | Safety net tint | Keep or #4A7C4E |
| 24 | `TEXT_COLOR_ACTIVE` | `Color(0.95, 0.95, 0.95)` | Active text | #333333 (Charcoal) |
| 25 | `TEXT_COLOR_DELETED` | `Color(0.4, 0.4, 0.4)` | Deleted text | #999999 (Gray) |
| 26 | `TEXT_COLOR_CIRCLED` | `Color(0.85, 1.0, 1.0)` | Circled text | #004F9F (Swedish Blue) |

### 4. `scenes/puzzle/target_display.gd` - Target Indicators
| Line | Constant | Current Value | Purpose | New Value |
|------|----------|--------------|---------|-----------|
| 15 | `COLOR_WRONG` | `Color(0.7, 0.25, 0.25)` | Invalid target | #C44536 (Warning Red) |
| 16 | `COLOR_EXACT` | `Color(0.2, 0.6, 0.3)` | Valid target | #4A7C4E (Success Green) |
| 17 | `TEXT_COLOR` | `Color(0.95, 0.95, 0.95)` | Target text | #F5F5F0 (White Laminate) |
| 21 | `CIRC_TEXT_COLOR` | `Color(0.6, 0.9, 0.95)` | Circled sum text | #004F9F (Swedish Blue) |

### 5. `scenes/title/title_screen.tscn` - Title Screen
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 52 | `Color(1, 1, 1, 1)` | Title font color | #333333 (Charcoal) |
| 53 | `Color(0, 0, 0, 1)` | Title outline color | Keep or remove |
| (background) | Default | Background | #C4A882 (Cardboard) |

### 6. `scenes/title/how_to_play.tscn` - How To Play Overlay
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 21 | `Color(0, 0, 0, 0.85)` | Overlay dimming | Keep semi-transparent dark |

### 7. `scenes/ui/result_popup.gd` - Result/Score Popup
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 16-21 | Grade colors | Letter grade colors | Keep (distinctive grades) |
| 80 | `Color(0.4, 0.9, 0.4)` | Win color | #4A7C4E (Success Green) |
| 83 | `Color(0.9, 0.4, 0.4)` | Lose color | #C44536 (Warning Red) |
| 234+ | Various breakdown colors | Score breakdown | Adjust to theme |

### 8. `scenes/ui/result_popup.tscn` - Result Popup Scene
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 21 | `Color(0, 0, 0, 0.8)` | Overlay dimming | Keep semi-transparent dark |
| 84 | `Color(0.6, 0.65, 0.7, 1)` | Label font | #333333 (Charcoal) |
| 92 | `Color(0.4, 0.8, 0.4, 1)` | Score font | #4A7C4E (Success Green) |

### 9. `scenes/ui/shop_placeholder.tscn` & `.gd` - Shop Screen
| Line (tscn) | Current Value | Purpose | New Value |
|-------------|--------------|---------|-----------|
| 21 | `Color(0, 0, 0, 0.9)` | Shop overlay | Keep semi-transparent dark |
| 63 | `Color(0.4, 0.8, 0.4, 1)` | Money label | #4A7C4E (Success Green) |
| 69 | `Color(0.8, 0.85, 0.9, 1)` | Title label | #333333 (Charcoal) |
| 93 | `Color(0.7, 0.85, 0.9, 1)` | Info label | #333333 (Charcoal) |
| 110 | `Color(0.8, 0.85, 0.9, 1)` | Roster label | #333333 (Charcoal) |

| Line (gd) | Current Value | Purpose | New Value |
|-----------|--------------|---------|-----------|
| 93 | `Color(0.5, 0.5, 0.5)` | Empty slot text | #999999 (Gray) |
| 106 | `Color(0.7, 0.75, 0.8)` | Description text | #333333 (Charcoal) |
| 121 | `Color(0.2, 0.6, 0.3)` | Buy button bg | #004F9F (Swedish Blue) |
| 133 | `Color(0.25, 0.7, 0.35)` | Buy button hover | Lighter blue |
| 137 | `Color(0.15, 0.5, 0.25)` | Buy button pressed | Darker blue |
| 141 | `Color(0.3, 0.3, 0.3)` | Buy button disabled | #999999 (Gray) |

### 10. `scenes/ui/operator_card.gd` & `.tscn` - Operator Cards
| Line (gd) | Current Value | Purpose | New Value |
|-----------|--------------|---------|-----------|
| 6 | `Color(0.5, 0.6, 0.7)` | Common rarity | Keep (rarity system) |
| 7 | `Color(0.3, 0.7, 0.4)` | Uncommon rarity | Keep |
| 8 | `Color(0.3, 0.6, 0.9)` | Rare rarity | Keep |
| 9 | `Color(0.9, 0.7, 0.2)` | Legendary rarity | #FFC61E (Swedish Yellow) |

| Line (tscn) | Current Value | Purpose | New Value |
|-------------|--------------|---------|-----------|
| 17 | `Color(0.5, 0.6, 0.7, 1)` | Card background | Use rarity color |
| 34 | `Color(0.6, 0.65, 0.7, 1)` | Description text | #333333 (Charcoal) |

### 11. `scenes/ui/operator_display.gd` & `.tscn` - Operator Display
| Line (gd) | Current Value | Purpose | New Value |
|-----------|--------------|---------|-----------|
| 48 | `Color(0.4, 0.45, 0.5)` | Empty slot text | #999999 (Gray) |

| Line (tscn) | Current Value | Purpose | New Value |
|-------------|--------------|---------|-----------|
| 14 | `Color(0.7, 0.75, 0.8, 1)` | Heading font | #333333 (Charcoal) |

### 12. `scenes/ui/circle_mode_button.gd` - Circle Mode Button
| Line | Constant | Current Value | Purpose | New Value |
|------|----------|--------------|---------|-----------|
| 13 | `COLOR_INACTIVE` | `Color(0.3, 0.35, 0.4)` | Inactive state | #D4A574 (Birch Wood) |
| 14 | `COLOR_ACTIVE` | `Color(0.3, 0.7, 0.9)` | Active state | #004F9F (Swedish Blue) |
| 104 | Text color | `Color(0.7, 0.75, 0.8)` | Inactive text | #333333 (Charcoal) |

### 13. `scenes/ui/victory.tscn` - Victory Screen
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 22 | `Color(0.05, 0.15, 0.1, 0.95)` | Victory overlay | Keep dark green tint |
| 42 | `Color(0.4, 0.9, 0.5, 1)` | Victory text | #4A7C4E (Success Green) |
| 49 | `Color(0.6, 0.8, 0.7, 1)` | Subtitle text | #333333 (Charcoal) |

### 14. `scenes/ui/game_over.tscn` - Game Over Screen
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 22 | `Color(0.15, 0.05, 0.05, 0.95)` | Game over overlay | Keep dark red tint |
| 42 | `Color(0.9, 0.3, 0.3, 1)` | Game over text | #C44536 (Warning Red) |
| 61 | `Color(0.6, 0.65, 0.7, 1)` | Stats text | #333333 (Charcoal) |

### 15. `scenes/ui/pause_overlay.tscn` - Pause Overlay
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 4 | `Color(0.1, 0.12, 0.15, 0.95)` | Pause bg | Keep dark overlay |
| 25 | `Color(0.05, 0.05, 0.08, 0.9)` | Panel bg | Keep dark |

### 16. `export_presets.cfg` - Export Settings
| Line | Current Value | Purpose | New Value |
|------|--------------|---------|-----------|
| 43 | `Color(0, 0, 0, 1)` | PWA background | #C4A882 (Cardboard) |
| 308 | `Color(0, 0, 0, 1)` | iOS storyboard bg | #C4A882 (Cardboard) |

---

## Summary

**Total files to modify:** 16 files (9 `.tscn`, 6 `.gd`, 1 `.cfg`)

**High Priority (core gameplay):**
1. `grid_cell.gd` - Cell colors
2. `target_display.gd` - Target indicators
3. `main.tscn` - Main game background

**Medium Priority (UI consistency):**
4. `main.gd` - Timer colors
5. `title_screen.tscn` - Title screen
6. `result_popup.gd/.tscn` - Score screens
7. `shop_placeholder.gd/.tscn` - Shop

**Lower Priority (polish):**
8. `operator_card.gd/.tscn`
9. `operator_display.gd/.tscn`
10. `circle_mode_button.gd`
11. `victory.tscn` / `game_over.tscn`
12. `pause_overlay.tscn`
13. `export_presets.cfg`

---

## Next Steps

1. **Task 2.2:** Add centralized color palette to `game_config.gd`
2. **Task 2.3:** Apply background/surface colors to main scenes
3. **Task 2.4:** Apply cell and target colors
