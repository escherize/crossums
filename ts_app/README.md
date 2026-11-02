# Sum Assembly Required (TypeScript)

Browser build of Crossums, shipping as *Sum Assembly Required*: remove numbered parts from a grid until every row and column sums to its target, then spend what you earn on operators. Static web app: Vite + TypeScript, no framework, no server. Installs to an iPad home screen as a full-screen app. Live at https://escherize.com/crossums/.

The look follows `../docs/20-product/theme_sum_assembly_required.md`: a flat-pack instruction manual. Cardboard background, laminate panels with thin rules, birch tiles, Swedish blue and yellow accents, stick-figure art, STEG and POÄNG labels, and Swedish operator names (ids are unchanged, so saves survive the rename).

The Godot 4 original lives in `../godot_app/`. This port keeps its rules, numbers and operators; see "Differences" for the few places it does not.

## Run

```bash
npm install
npm run dev      # http://localhost:5173
npm test         # vitest
npm run build    # typecheck + bundle to dist/
```

`dist/` is plain HTML/JS/CSS. Any static host serves it.

## Layout

```
src/engine/   pure game logic, no DOM, fully unit-tested
  puzzle.ts     PuzzleState: cells, targets, delete/restore/circle, batched undo, missteps
  solver.ts     subset search; countSolutions / findSolutions, correct with negative values
  generator.ts  single-solution puzzles (no line satisfied at start), fallback generator
  scoring.ts    pace rating → grade → money; operator hooks
  operators.ts  the 12 operators (Swedish names, English effects) and the shop draw
  stage.ts      grid size, value range and score target per stage
  run.ts        RunState: progression, money, time pool, streak, seeds
  config.ts     every tunable number
  game.ts       Game: phases, timer, auto-actions, mistakes, shop, save/load. The UI only calls this.
src/ui/       DOM rendering and input
  board.ts      grid, targets, tap vs long-press vs right-click
  overlays.ts   result (animated breakdown), shop, pause, game over, victory, instructions
  art.ts        stick figure and step-number circle
  confetti.ts   bursts on solve, shower on victory
  sound.ts      effects from public/sfx
src/main.ts   title and game screens, frame loop, keyboard
```

`window.crossums` exposes `game`, `solve()` and `addOperator(id)` for tooling and manual testing.

## Feedback while playing

- Owned operators sit under the HUD as chips. A chip flashes with a floating label when its operator auto-acts, and again for each scoring bonus before the result page opens.
- A mistake (removing a part every solution needs, or circling one no solution keeps) shakes the board, flashes the part red, plays the error sound, and says so in the status line. The engine emits it as the `mistake` event; it fires once per break, not for every move made while the puzzle is already unfinishable.
- The result page reveals its lines one by one and counts the money up with ticks. Reduced-motion settings skip the animation.

## Input

- Tap: delete an active cell, restore a deleted one, uncircle a circled one.
- Hold 400 ms, or right-click: circle. On touch screens the ○ button can be held with one finger while another taps cells.
- `u`/`z` undo, `p` pause, Escape resume. The app pauses itself when the tab is hidden.

## Differences from the Godot build

- Operator money (Circlicious, Elite Delete) is paid. The Godot rating path computed it and dropped it.
- The solver enumerates fully when a line holds a negative value. Godot pruned on "sum exceeds target", which miscounts solutions once negatives appear in stage 6.
- Saves happen at every puzzle and shop transition, before the next puzzle's time is granted, so quitting mid-puzzle resumes at that puzzle's start with the same pool. Godot saved only on entering the shop.
- Puzzle seeds use mulberry32, so a run seed does not reproduce the Godot puzzles for that seed. `SEED_VERSION` is 2.
- Final money never goes below zero.
