# ts_app

Vite + TypeScript, no framework. See README.md for layout and the differences from the Godot build.

- `src/engine/` never touches the DOM. Everything in it is deterministic given an `Rng` and a clock, and tested in `*.test.ts` next to the source. Put new rules there, not in `src/ui/`.
- `Game` is the only thing the UI talks to. New player actions go on `Game`; the UI calls them and re-renders on the `change` event.
- Tunable numbers live in `src/engine/config.ts`. Stage tables live in `src/engine/stage.ts`.
- `npm test` and `npm run build` (which typechecks) must pass before committing.
- Bump `SEED_VERSION` in `src/engine/run.ts` when generation changes.
