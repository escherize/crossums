# PRD: Sum Assembly Required — Polish Pass

> Target: Release-ready web build
> Status: In Progress
> Last updated: 2025-02-25

---

## Executive Summary

Polish "Sum Assembly Required" — a flat-pack furniture-themed roguelike number puzzle — to release-ready state. Core mechanics complete. This PRD covers: fix mobile input, apply visual theme, create marketing assets.

---

## Current State

| System | Status |
|--------|--------|
| Core gameplay loop | ✅ Complete |
| Operators | ✅ Complete |
| Save/Load | ✅ Complete |
| Sound effects | ✅ Complete |
| Score animation | ✅ Complete |
| Web export | ⚠️ Mobile click bug |
| Visual theme | ❌ Not applied |
| Marketing assets | ❌ Not created |

---

## Implementation Plan

Each task is designed for ~30 minutes of focused work in a fresh context window.

---

### Phase 1: Critical Bug Fix

#### 1.1 Export web build and document mobile bug behavior
**Context:** The game works on desktop but mobile touch doesn't register clicks on cells.

**Steps:**
1. Read `godot_app/export_presets.cfg` to understand current HTML5 export settings
2. Run: `cd godot_app && /Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "HTML5" ../public/crossums/index.html`
3. Start local server: `cd public/crossums && python3 -m http.server 8080`
4. Test on desktop browser (Chrome) — verify clicking cells works
5. Test on mobile browser (iOS Safari or Android Chrome via ngrok/local network)
6. Document exact failure behavior in `tasks/mobile_bug_notes.md`:
   - Does tap register at all?
   - Does hover work?
   - Do other UI buttons (title screen, shop) work?
   - Check browser console for errors

**Done when:** `tasks/mobile_bug_notes.md` exists with clear reproduction steps and observed behavior.

---

#### 1.2 Investigate mobile touch event handling in Godot
**Context:** Need to understand how Godot handles touch vs mouse events for web export.

**Steps:**
1. Read `godot_app/scenes/puzzle/grid_cell.gd` — find the `_gui_input` or `_input` handler
2. Read `godot_app/scenes/puzzle/puzzle_grid.gd` — check if input is intercepted here
3. Search for `InputEventScreenTouch` or `InputEventMouseButton` in the codebase
4. Read `godot_app/project.godot` — check `input_devices/pointing/emulate_touch_from_mouse` and `emulate_mouse_from_touch` settings
5. Search Godot docs/forums for "HTML5 touch not working" — common solutions include:
   - Setting `emulate_mouse_from_touch = true`
   - Using `InputEventScreenTouch` instead of `InputEventMouseButton`
   - Checking `mouse_filter` settings on parent Controls
6. Document findings in `tasks/mobile_bug_notes.md`

**Done when:** Root cause identified and documented, proposed fix written.

---

#### 1.3 Fix mobile touch input
**Context:** Apply the fix identified in 1.2.

**Steps:**
1. Read `tasks/mobile_bug_notes.md` for the proposed fix
2. If project.godot setting: Edit `godot_app/project.godot` to add:
   ```
   [input_devices]
   pointing/emulate_mouse_from_touch=true
   ```
3. If code change needed: Edit `godot_app/scenes/puzzle/grid_cell.gd` to handle touch events
4. Re-export web build
5. Test on mobile — verify cell taps now register
6. Test tap-to-delete AND hold-to-circle both work
7. Update `tasks/mobile_bug_notes.md` with fix applied

**Done when:** Mobile touch works for both delete and circle actions; tested on real device.

---

#### 1.4 Verify complete web build works end-to-end
**Context:** Full regression test before theme changes.

**Steps:**
1. Export fresh web build
2. Test on desktop browser:
   - Start new run
   - Complete 3 puzzles
   - Buy an operator in shop
   - Use operator ability
   - Save game (pause menu)
   - Refresh page
   - Load game (title screen)
   - Verify state restored correctly
3. Test on mobile browser:
   - Same flow as above
   - Verify touch responsiveness throughout
   - Check performance (should feel smooth)
4. Check browser console for errors/warnings
5. Document any issues found

**Done when:** Full run completable on both desktop and mobile without errors.

---

### Phase 2: Visual Theme — Color & Text

#### 2.1 Audit current color definitions
**Context:** Before changing colors, find where they're defined.

**Steps:**
1. Search codebase for hex color codes: `Grep "Color(" or "#[0-9A-Fa-f]{6}"`
2. Read `godot_app/scripts/core/game_config.gd` — check for color constants
3. List all `.tscn` files that have hardcoded colors: `Grep "modulate" or "self_modulate" or "bg_color"`
4. Create `tasks/color_audit.md` listing:
   - Each file with hardcoded colors
   - Current color value
   - What it's used for (cell, background, text, etc.)
   - New color from theme (see mapping below)

**Color mapping (from theme doc):**
| Current Use | New Color | Hex |
|-------------|-----------|-----|
| Background | Cardboard | #C4A882 |
| Primary surface | Birch Wood | #D4A574 |
| Secondary surface | White Laminate | #F5F5F0 |
| Primary accent | Swedish Blue | #004F9F |
| Secondary accent | Swedish Yellow | #FFC61E |
| Text | Charcoal | #333333 |
| Valid target | Success Green | #4A7C4E |
| Invalid target | Warning Red | #C44536 |
| Deleted cell | Dotted gray | #999999 |

**Done when:** `tasks/color_audit.md` exists with complete inventory of color locations and mappings.

---

#### 2.2 Create centralized color palette in game_config.gd
**Context:** Centralize colors for easy theming.

**Steps:**
1. Read `godot_app/scripts/core/game_config.gd`
2. Add a `Colors` class or dictionary with all theme colors:
   ```gdscript
   class_name GameConfig

   # Sum Assembly Required Theme
   const COLORS = {
       "background": Color("#C4A882"),      # Cardboard
       "surface_primary": Color("#D4A574"), # Birch Wood
       "surface_secondary": Color("#F5F5F0"), # White Laminate
       "accent_primary": Color("#004F9F"),  # Swedish Blue
       "accent_secondary": Color("#FFC61E"), # Swedish Yellow
       "text": Color("#333333"),             # Charcoal
       "target_valid": Color("#4A7C4E"),    # Success Green
       "target_invalid": Color("#C44536"),  # Warning Red
       "cell_deleted": Color("#999999"),    # Gray
   }
   ```
3. Run lint: `~/Library/Python/3.9/bin/gdlint godot_app/scripts/core/game_config.gd`

**Done when:** `game_config.gd` has centralized color palette; lint passes.

---

#### 2.3 Apply background and surface colors to main scenes
**Context:** Update major UI backgrounds to use new palette.

**Steps:**
1. Read `tasks/color_audit.md` for list of files
2. For each main scene (`main.tscn`, `title_screen.tscn`, `puzzle_grid.tscn`, `shop.tscn`):
   - Open the `.tscn` file
   - Find background ColorRect or Panel nodes
   - Update color to use `GameConfig.COLORS["background"]` or hardcode hex if simpler
3. Update any Panel StyleBoxFlat backgrounds to Birch Wood (#D4A574)
4. Run game to verify visually
5. Update visual test baselines if needed: `bun tests/update-baselines.ts`

**Done when:** Main screens use cardboard/birch color scheme; game runs without errors.

---

#### 2.4 Apply cell and target colors
**Context:** Update puzzle grid cells and target indicators.

**Steps:**
1. Read `godot_app/scenes/puzzle/grid_cell.gd` — find where cell colors are set
2. Read `godot_app/scenes/puzzle/target_display.gd` — find valid/invalid color logic
3. Update deleted cell appearance to gray (#999999) with dotted outline if possible
4. Update valid target indicator to Success Green (#4A7C4E)
5. Update invalid target indicator to Warning Red (#C44536)
6. Update normal cell text to Charcoal (#333333)
7. Test with a puzzle — verify colors apply correctly
8. Run: `bun tests/run-tests.ts --visual-only` — update baselines if needed

**Done when:** Cell and target colors match theme; visual tests pass or baselines updated.

---

#### 2.5 Rename "Points" to "POÄNG" throughout UI
**Context:** Core terminology change for Swedish theme.

**Steps:**
1. Search for "Points" or "points" in all `.gd` and `.tscn` files
2. Search for "Score" or "score" in UI-facing strings (not variable names)
3. Replace UI-facing strings:
   - "Points" → "POÄNG"
   - "Score" → "POÄNG"
4. Key files to check:
   - `godot_app/scenes/ui/result_popup.gd` / `.tscn`
   - `godot_app/scenes/main.gd` / `.tscn`
   - `godot_app/scenes/ui/hud.gd` / `.tscn` (if exists)
5. Test the game — verify POÄNG appears on score displays
6. Run lint: `bun tests/run-tests.ts --lint-only`

**Done when:** All player-facing "Points"/"Score" text replaced with "POÄNG"; lint passes.

---

#### 2.6 Rename "Stage" to "STEG" and add stage framing
**Context:** Display puzzles as assembly steps.

**Steps:**
1. Search for "Stage" or "level" in UI strings
2. Replace:
   - "Stage X" → "STEG X"
   - "Stage X of Y" → "STEG X av Y"
3. Update result screen:
   - "Stage Complete" → "STEG X ✓ SLUTFÖRD"
4. Key files:
   - `godot_app/scenes/main.gd` — stage counter display
   - `godot_app/scenes/ui/result_popup.gd` — completion message
5. Verify the puzzle screen shows "STEG X av Y" format
6. Test completing a puzzle to see "SLUTFÖRD" message

**Done when:** Stage terminology updated; visible in game.

---

#### 2.7 Rename operators to Swedish names
**Context:** All operators get Swedish-inspired names.

**Steps:**
1. Read `godot_app/scripts/operators/operator_registry.gd` — find where names are defined
2. Update operator display names:
   | Current | Swedish |
   |---------|---------|
   | Circlicious | RUNDLIG |
   | Zero Hero | TOMRUM |
   | Column Master | KOLONN |
   | Elite Delete | PRECIS |
   | Flipper | VÄND |
   | Purist | RENHET |
   | Square Peg | FYRKANT |
   | Click Clique | KLICK |
   | Garbage Collector | RENSA |
   | Trimmer | TRIMMA |
3. Check each `godot_app/scripts/operators/impl/op_*.gd` for hardcoded names
4. Test shop screen — verify Swedish names appear
5. Run lint: `bun tests/run-tests.ts --lint-only`

**Done when:** All operators display Swedish names in shop and UI.

---

#### 2.8 Update fonts to clean sans-serif
**Context:** Switch from current font to Futura-style clean sans-serif.

**Steps:**
1. Find current font references: `Grep "\.ttf" or "\.otf" or "font"`
2. Either:
   - Download a free Futura-alternative (Jost, Poppins) to `godot_app/assets/fonts/`
   - Or use Godot's default sans-serif by removing custom font overrides
3. Update font references in theme or individual scenes
4. Ensure numbers are highly legible (test with puzzle grid)
5. Test at different viewport sizes

**Done when:** Game uses clean sans-serif font; numbers clearly readable.

---

### Phase 3: Marketing Assets

#### 3.1 Capture title screen screenshot
**Context:** First of 5 required screenshots.

**Steps:**
1. Run game: `bun game-cli.ts` or launch Godot
2. Navigate to title screen
3. Ensure theme colors are applied
4. Take screenshot at 1920x1080 or 1280x720
5. Save to `marketing/screenshots/01_title_screen.png`
6. Create `marketing/` directory if needed

**Done when:** Clean title screen screenshot saved.

---

#### 3.2 Capture puzzle mid-solve screenshot
**Context:** Show core gameplay.

**Steps:**
1. Start a run with seed for reproducibility
2. Play until you have an interesting board state:
   - Some cells deleted
   - Some rows/columns completed (green)
   - Some targets still red
3. Take screenshot
4. Save to `marketing/screenshots/02_puzzle_midsolve.png`

**Done when:** Gameplay screenshot showing active puzzle saved.

---

#### 3.3 Capture puzzle complete screenshot
**Context:** Show the satisfying completion state.

**Steps:**
1. Complete a puzzle (use small grid for quick completion)
2. Capture the moment with POÄNG displayed and "SLUTFÖRD" message
3. Save to `marketing/screenshots/03_puzzle_complete.png`

**Done when:** Completion screenshot with score visible saved.

---

#### 3.4 Capture shop/operator selection screenshot
**Context:** Show the roguelike meta-progression.

**Steps:**
1. Progress to shop screen
2. Ensure multiple operators visible
3. Show Swedish operator names (RUNDLIG, TOMRUM, etc.)
4. Take screenshot
5. Save to `marketing/screenshots/04_shop.png`

**Done when:** Shop screen screenshot saved.

---

#### 3.5 Capture game over/results screenshot
**Context:** Show end-of-run summary.

**Steps:**
1. Complete or fail a run to reach results screen
2. Take screenshot showing total POÄNG and stats
3. Save to `marketing/screenshots/05_results.png`

**Done when:** Results screen screenshot saved.

---

#### 3.6 Create cover image (630x500)
**Context:** Primary visual for itch.io listing.

**Steps:**
1. Create image at minimum 630x500 pixels
2. Include:
   - Game title "Sum Assembly Required"
   - Puzzle grid visual (stylized or screenshot-based)
   - Birch wood / cardboard color scheme
3. Ensure readable at thumbnail size (315x250)
4. Save to `marketing/cover_630x500.png`
5. Options:
   - Composite from screenshot + text overlay
   - Use Figma/Canva/GIMP
   - Keep simple and clean

**Done when:** Cover image created and readable at small size.

---

#### 3.7 Create animated GIF of solve sequence (optional)
**Context:** Eye-catching for itch.io page.

**Steps:**
1. Screen record a 5-10 second solve sequence
2. Show: cell deletions, row completing, score popups
3. Convert to GIF (ffmpeg or online tool)
4. Keep file size under 5MB
5. Save to `marketing/gameplay.gif`

**Done when:** Animated GIF showing core gameplay loop.

---

#### 3.8 Write itch.io description text
**Context:** Marketing copy for the page.

**Steps:**
1. Create `marketing/itch_description.md`
2. Write sections:
   - **Tagline:** "A flat-pack number puzzle roguelike. Delete the extras. Hit the targets."
   - **About:** 2-3 sentences explaining the core loop
   - **Features:** 5-7 bullet points
   - **How to Play:** Brief (3 bullets max)
   - **Credits:** Developer name, tools used
3. Keep it concise — players skim

**Template:**
```markdown
# Sum Assembly Required

A flat-pack number puzzle roguelike. Delete the extras. Hit the targets.

## About
[2-3 sentences]

## Features
- Roguelike progression with operators
- Multiple grid sizes (3x3 to 6x6)
- Strategic deletion puzzles
- Swedish furniture store aesthetic
- Save/load support

## How to Play
- Tap numbers to delete them
- Make each row and column sum to its target
- Keep more numbers for higher POÄNG

## Credits
- [Your name]
- Built with Godot 4.5
```

**Done when:** `marketing/itch_description.md` written with all sections.

---

## Acceptance Criteria

**The game is release-ready when:**
1. ✅ Web build loads and plays on mobile browsers (iOS Safari, Android Chrome)
2. ✅ Web build loads and plays on desktop browsers (Chrome, Firefox, Safari)
3. ✅ Full run can be completed without crashes
4. ✅ Save/load works in browser
5. ✅ Visual theme applied (birch colors, POÄNG, Swedish operator names)
6. ✅ Marketing assets created (cover image, 5+ screenshots, description)

---

## Out of Scope (Post-Polish)

- itch.io page setup and publishing
- iOS App Store submission
- Steam page
- Trailer video
- Press kit
- Additional operators
- Negative numbers feature
- Boss puzzle modifiers
- Difficulty tiers
- Endless mode

---

## Risk Register

| Risk | Mitigation |
|------|------------|
| Mobile click bug is deep in Godot web export | Check Godot forums/issues; may need workaround or Godot version update |
| Theme changes break existing visual tests | Update baselines after theme is applied |
| Performance issues on mobile | Profile, reduce effects if needed |

---

## Reference Documents

- `docs/20-product/theme_sum_assembly_required.md` — full theme spec
- `CLAUDE.md` — repo conventions

---

*This PRD is the source of truth for polish. Check off tasks as completed.*
