import { describe, expect, it } from 'vitest'
import { Game, memoryStorage } from './game'
import { createOperator } from './operators'
import { mulberry32 } from './rng'
import { findSolutions, solvableWithCircles } from './solver'

/**
 * Play each negative-value stage with every auto-acting operator: delete decoys in a
 * random order, circle about half the solution cells. The operator must never leave the
 * board unfinishable, on load or after any move.
 */
describe('auto-actions on boards with negative values', () => {
  for (const id of ['gimme', 'click_clique', 'garbage_collector', 'trimmer']) {
    it(`${id} never breaks a puzzle`, () => {
      for (let stage = 6; stage <= 9; stage++) {
        for (let seed = 1; seed <= 40; seed++) {
          const game = new Game({ clock: () => 0, storage: memoryStorage() })
          game.startRun(seed)
          game.addOperator(createOperator(id))
          game.run!.stage = stage
          game.run!.puzzleIndex = 0
          game['startNextPuzzle']()
          const p = game.puzzle!
          const where = `${id} stage ${stage} seed ${seed}`
          expect(solvableWithCircles(p), `${where}: unfinishable on load`).toBe(true)

          const keep = new Set(findSolutions(p, 1)[0].map((q) => `${q.row},${q.col}`))
          const rng = mulberry32(seed)
          const moves: { row: number; col: number; keep: boolean }[] = []
          for (let row = 0; row < p.rows; row++)
            for (let col = 0; col < p.cols; col++) moves.push({ row, col, keep: keep.has(`${row},${col}`) })
          moves.sort(() => rng() - 0.5)
          for (const m of moves) {
            if (game.phase !== 'puzzle' || game.puzzleSolved) break
            if (p.state(m.row, m.col) !== 'active') continue
            if (m.keep) {
              if (rng() < 0.5) game.circle(m.row, m.col)
            } else game.tap(m.row, m.col)
            if (game.phase === 'puzzle' && !game.puzzleSolved) expect(game.solvable, `${where}: unfinishable after move`).toBe(true)
          }
          expect(game.phase, `${where}: did not finish`).toBe('result')
        }
      }
    })
  }
})
