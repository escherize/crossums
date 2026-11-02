# Crossums (TypeScript)

Browser build of Crossums: delete numbers from a grid until every row and column sums to its target, then spend what you earn on operators. Static web app: Vite + TypeScript, no framework, no server. Installs to an iPad home screen as a full-screen app.

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
  operators.ts  the 12 operators and the shop draw
  stage.ts      grid size, value range and score target per stage
  run.ts        RunState: progression, money, time pool, streak, seeds
  config.ts     every tunable number
  game.ts       Game: phases, timer, auto-actions, shop, save/load. The UI only calls this.
src/ui/       DOM rendering and input
  board.ts      grid, targets, tap vs long-press vs right-click
  overlays.ts   result, shop, pause, game over, victory, how to play
  sound.ts      effects from public/sfx
src/main.ts   title and game screens, frame loop, keyboard
```

`window.crossums` exposes `game` and `solve()` for tooling and manual testing.

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
