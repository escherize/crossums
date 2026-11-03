import { describe, expect, it } from 'vitest'
import { Game, memoryStorage } from './game'
import { createOperator, type Operator } from './operators'
import { PuzzleState } from './puzzle'
import { findSolutions } from './solver'

function harness() {
  let now = 0
  const storage = memoryStorage()
  const game = new Game({ clock: () => now, storage })
  return { game, storage, advance: (ms: number) => (now += ms), newGame: () => new Game({ clock: () => now, storage }) }
}

/** Delete every cell outside the unique solution. The last delete completes the puzzle. */
function solve(game: Game): void {
  const p = game.puzzle!
  const keep = new Set(findSolutions(p, 1)[0].map((q) => `${q.row},${q.col}`))
  for (let r = 0; r < p.rows; r++)
    for (let c = 0; c < p.cols; c++) if (!keep.has(`${r},${c}`) && p.state(r, c) === 'active') game.tap(r, c)
}

describe('Game run flow', () => {
  it('walks puzzle → result → next puzzle → shop after a stage', () => {
    const { game, advance } = harness()
    game.startRun(42)
    expect(game.phase).toBe('puzzle')
    expect(game.run!.stage).toBe(1)
    expect(game.stage!.gridSize).toBe(3)
    expect(game.timeRemaining()).toBe(75)

    advance(9000)
    solve(game)
    expect(game.phase).toBe('result')
    const b = game.lastBreakdown!
    expect(b.pace).toBe(1)
    expect(b.totalRating).toBe(13)
    expect(b.grade).toBe('S')
    expect(game.run!.money).toBe(b.finalMoney)
    expect(game.run!.streak).toBe(1)
    expect(game.run!.puzzleIndex).toBe(1)
    expect(game.timeRemaining()).toBe(66)

    game.continueFromResult()
    expect(game.phase).toBe('puzzle')
    expect(game.run!.puzzleIndex).toBe(1)
    expect(game.timeRemaining()).toBe(66 + 75)

    solve(game)
    game.continueFromResult()
    expect(game.run!.puzzleIndex).toBe(2)
    solve(game)
    game.continueFromResult()
    expect(game.phase).toBe('shop')
    expect(game.run!.stage).toBe(2)
    expect(game.shop.slots).toHaveLength(3)
    expect(game.run!.streak).toBe(3)

    game.continueFromShop()
    expect(game.phase).toBe('puzzle')
    expect(game.run!.stage).toBe(2)
  })

  it('the same seed replays the same puzzles', () => {
    const a = harness().game
    const b = harness().game
    a.startRun(99)
    b.startRun(99)
    expect(a.puzzle!.toJSON()).toEqual(b.puzzle!.toJSON())
    solve(a)
    solve(b)
    a.continueFromResult()
    b.continueFromResult()
    expect(a.puzzle!.toJSON()).toEqual(b.puzzle!.toJSON())
  })

  it('reaches victory after nine stages', () => {
    const { game, advance } = harness()
    game.startRun(7)
    let guard = 0
    while (game.phase !== 'victory' && guard++ < 100) {
      if (game.phase === 'puzzle') {
        advance(1000)
        solve(game)
      } else if (game.phase === 'result') game.continueFromResult()
      else if (game.phase === 'shop') game.continueFromShop()
      else throw new Error(`unexpected phase ${game.phase}`)
    }
    expect(game.phase).toBe('victory')
    expect(game.stagesCleared).toBe(9)
    expect(game.hasSave()).toBe(false)
  })

  it('runs out of time', () => {
    const { game, advance } = harness()
    game.startRun(1)
    advance(74_000)
    game.tick()
    expect(game.phase).toBe('puzzle')
    advance(2_000)
    game.tick()
    expect(game.phase).toBe('gameOver')
    expect(game.canAct).toBe(false)
  })

  it('pausing stops the clock and blocks input', () => {
    const { game, advance } = harness()
    game.startRun(1)
    advance(5_000)
    game.pause()
    expect(game.canAct).toBe(false)
    advance(50_000)
    game.tick()
    expect(game.phase).toBe('puzzle')
    game.resume()
    advance(1_000)
    game.tick()
    expect(game.timeRemaining()).toBeCloseTo(69)
    expect(game.elapsed()).toBeCloseTo(6)
  })

  it('saves at the shop and resumes there with operators intact', () => {
    const h = harness()
    const { game } = h
    game.startRun(5)
    for (let i = 0; i < 3; i++) {
      solve(game)
      game.continueFromResult()
    }
    expect(game.phase).toBe('shop')
    game.run!.money = 50
    const first = game.shop.slots[0]!
    expect(game.shopBuy(0)).toBe(true)
    expect(game.operators[0].id).toBe(first.id)
    game.continueFromShop()

    const g2 = h.newGame()
    expect(g2.hasSave()).toBe(true)
    expect(g2.load()).toBe(true)
    expect(g2.phase).toBe('puzzle')
    expect(g2.run!.stage).toBe(2)
    expect(g2.run!.puzzleIndex).toBe(0)
    expect(g2.operators.map((o) => o.id)).toEqual([first.id])
    expect(g2.puzzle!.toJSON()).toEqual(game.puzzle!.toJSON())
  })

  it('shop: reroll escalates, buying respects money and slots, selling refunds half, time is capped', () => {
    const { game } = harness()
    game.startRun(3)
    for (let i = 0; i < 3; i++) {
      solve(game)
      game.continueFromResult()
    }
    game.run!.money = 3
    expect(game.canBuy(0)).toBe(game.shop.slots[0]!.price <= 3)
    game.run!.money = 100
    expect(game.shopReroll()).toBe(true)
    expect(game.run!.money).toBe(98)
    expect(game.shop.rerollCost).toBe(3)
    const op = game.shop.slots[1]!
    expect(game.shopBuy(1)).toBe(true)
    expect(game.shop.slots[1]).toBeNull()
    expect(game.run!.money).toBe(98 - op.price)
    expect(game.shopSell(0)).toBe(true)
    expect(game.operators).toHaveLength(0)
    expect(game.run!.money).toBe(98 - op.price + Math.floor(op.price / 2))

    game.run!.timePool = 100
    const pool = game.run!.timePool
    expect(game.timePrice).toBe(1)
    expect(game.shopBuyTime()).toBe(true)
    expect(game.run!.timePool).toBe(Math.min(pool + 15, 180))
    expect(game.timePrice).toBe(2)
    for (let i = 0; i < 20; i++) game.shopBuyTime()
    expect(game.run!.timePool).toBeLessThanOrEqual(180)
  })
})

describe('operator auto-actions', () => {
  const start = (values: number[][], rows: number[], cols: number[], ops: string[]) => {
    const { game } = harness()
    game.startRun(1)
    for (const id of ops) game.addOperator(createOperator(id))
    game.loadPuzzle(PuzzleState.fromValues(values, rows, cols))
    return game
  }

  it('Gimme deletes the last cell when one row and one column remain', () => {
    const g = start(
      [
        [1, 1, 9],
        [1, 1, 9],
        [9, 9, 9],
      ],
      [2, 2, 0],
      [2, 2, 0],
      ['gimme'],
    )
    g.tap(0, 2)
    g.tap(1, 2)
    g.tap(2, 0)
    expect(g.phase).toBe('puzzle')
    g.tap(2, 1)
    expect(g.puzzle!.state(2, 2)).toBe('deleted')
    expect(g.phase).toBe('result')
  })

  it('Click Clique circles a completed line and undo reverts it with the trigger', () => {
    const g = start(
      [
        [2, 3, 9],
        [4, 5, 3],
        [8, 2, 4],
      ],
      [5, 20, 20],
      [20, 20, 20],
      ['click_clique'],
    )
    g.tap(1, 0)
    expect(g.puzzle!.actionCount).toBe(1)
    g.tap(0, 2)
    const p = g.puzzle!
    expect(p.state(0, 0)).toBe('circled')
    expect(p.state(0, 1)).toBe('circled')
    expect(p.actionHistory.at(-1)).toMatchObject({ auto: true, operatorId: 'click_clique', type: 'circle' })
    expect(g.undo()).toEqual({ batchesUndone: 2, totalCells: 3 })
    expect(p.state(0, 0)).toBe('active')
    expect(p.state(0, 2)).toBe('active')
    expect(p.state(1, 0)).toBe('deleted')
    g.undo()
    expect(p.state(1, 0)).toBe('active')
  })

  it('Garbage Collector deletes the rest of a line solved by circles', () => {
    const g = start(
      [
        [1, 5, 5],
        [5, 1, 5],
        [5, 5, 1],
      ],
      [1, 1, 1],
      [1, 1, 1],
      ['garbage_collector'],
    )
    g.circle(0, 0)
    const p = g.puzzle!
    expect(p.state(0, 1)).toBe('deleted')
    expect(p.state(0, 2)).toBe('deleted')
    expect(p.state(1, 0)).toBe('deleted')
    expect(p.state(2, 0)).toBe('deleted')
    expect(p.state(1, 1)).toBe('active')
    g.circle(1, 1)
    expect(g.phase).toBe('result')
  })

  it('Trimmer deletes oversized cells as soon as the puzzle loads', () => {
    const g = start(
      [
        [1, 2, 5],
        [3, 2, 1],
        [1, 7, 3],
      ],
      [3, 6, 4],
      [5, 4, 4],
      ['trimmer'],
    )
    const p = g.puzzle!
    expect(p.state(0, 2)).toBe('deleted')
    expect(p.state(2, 1)).toBe('deleted')
    expect(p.state(0, 0)).toBe('active')
    expect(p.state(1, 1)).toBe('active')
    expect(p.actionHistory).toHaveLength(1)
    expect(p.actionHistory[0].auto).toBe(true)
  })

  it('Gimme stays quiet when deleting the corner cell would not finish the puzzle', () => {
    // Row 0 and column 0 are the only wrong lines, but the fix is removing the 2 / -2 / 2
    // triangle, not the 5 at their crossing. The 5 is part of the solution.
    const g = start(
      [
        [5, 2, 1],
        [2, -2, 1],
        [1, 1, 1],
      ],
      [6, 1, 3],
      [6, 1, 3],
      ['gimme'],
    )
    expect(g.puzzle!.state(0, 0)).toBe('active')
    expect(g.solvable).toBe(true)
    expect(createOperator('gimme').autoAction!(g.puzzle!)).toBeNull()
  })

  it('Click Clique and Garbage Collector leave lines holding a negative alone', () => {
    // Row 0 already sums to its target, yet the 3 and -3 both have to go.
    const p = PuzzleState.fromValues(
      [
        [3, -3, 2],
        [1, 4, 1],
        [1, 1, 2],
      ],
      [2, 5, 2],
      [2, 5, 2],
    )
    expect(createOperator('click_clique').autoAction!(p)).toBeNull()
    p.circleCell(0, 2)
    expect(p.isRowSolvedByCircles(0)).toBe(true)
    // Column 2 is all positive and also solved by that circle, so only its cells go; row 0 keeps its 3 and -3.
    expect(createOperator('garbage_collector').autoAction!(p)).toMatchObject({ type: 'delete', cells: [{ row: 1, col: 2 }, { row: 2, col: 2 }] })
    // Row 1 is all positive, so it still gets circled once it matches.
    p.reset()
    p.deleteCell(1, 2)
    expect(createOperator('click_clique').autoAction!(p)).toMatchObject({ type: 'circle', cells: [{ row: 1, col: 0 }, { row: 1, col: 1 }] })
  })

  it('Trimmer only trims against all-positive lines', () => {
    // 9 > 6 but it is needed, because -3 sits in the same row.
    const p = PuzzleState.fromValues(
      [
        [9, -3, 2],
        [1, 1, 1],
        [1, 7, 1],
      ],
      [6, 2, 2],
      [10, -2, 2],
    )
    expect(createOperator('trimmer').autoAction!(p)).toMatchObject({ type: 'delete', cells: [{ row: 2, col: 1 }] })
  })

  it('an auto-action that would make the puzzle unfinishable is dropped', () => {
    const { game } = harness()
    game.startRun(1)
    const breaker: Operator = {
      id: 'breaker',
      name: 'X',
      description: '',
      rarity: 0,
      price: 0,
      autoAction: (p) => (p.state(0, 0) === 'active' ? { type: 'delete', cells: [{ row: 0, col: 0 }], operatorId: 'breaker' } : null),
    }
    game.addOperator(breaker)
    const fired: string[] = []
    game.on('autoAction', (a) => fired.push(a.operatorId))
    game.loadPuzzle(PuzzleState.fromValues([[1, 2], [3, 4]], [1, 3], [1, 2]))
    expect(game.puzzle!.state(0, 0)).toBe('active')
    expect(fired).toEqual([])
    // Once (0,0) is a decoy the same action goes through.
    game.loadPuzzle(PuzzleState.fromValues([[1, 2], [3, 4]], [2, 7], [3, 6]))
    expect(game.puzzle!.state(0, 0)).toBe('deleted')
    expect(fired).toEqual(['breaker'])
  })

  it('circle mode turns taps into circles; operator limit is five', () => {
    const g = start([[1, 2], [3, 4]], [1, 3], [1, 2], [])
    g.circleMode = true
    g.tap(0, 0)
    expect(g.puzzle!.state(0, 0)).toBe('circled')
    g.circleMode = false
    for (const id of ['counter', 'row_master', 'column_master', 'purist', 'gimme']) g.addOperator(createOperator(id))
    expect(g.operators).toHaveLength(5)
    expect(g.addOperator(createOperator('sum_sight'))).toBe(false)
  })
})

describe('mistakes', () => {
  function firstOutside(game: Game): { row: number; col: number } {
    const p = game.puzzle!
    const keep = new Set(findSolutions(p, 1)[0].map((q) => `${q.row},${q.col}`))
    for (let r = 0; r < p.rows; r++) for (let c = 0; c < p.cols; c++) if (!keep.has(`${r},${c}`)) return { row: r, col: c }
    throw new Error('no decoy cell')
  }
  function firstInside(game: Game): { row: number; col: number } {
    const [q] = findSolutions(game.puzzle!, 1)[0]
    return { row: q.row, col: q.col }
  }

  it('deleting a solution cell emits mistake once and undo clears it', () => {
    const { game } = harness()
    game.startRun(42)
    const seen: string[] = []
    game.on('mistake', (m) => seen.push(`${m.kind}@${m.row},${m.col}`))
    const needed = firstInside(game)
    const decoy = firstOutside(game)
    game.tap(needed.row, needed.col)
    expect(seen).toEqual([`delete@${needed.row},${needed.col}`])
    expect(game.solvable).toBe(false)
    // Further damage while already unsolvable is not a new mistake.
    game.tap(decoy.row, decoy.col)
    expect(seen).toHaveLength(1)
    game.undo()
    game.undo()
    expect(game.solvable).toBe(true)
  })

  it('circling a decoy emits a circle mistake; circling a solution cell does not', () => {
    const { game } = harness()
    game.startRun(42)
    const seen: string[] = []
    game.on('mistake', (m) => seen.push(m.kind))
    const needed = firstInside(game)
    game.circle(needed.row, needed.col)
    expect(seen).toEqual([])
    const decoy = firstOutside(game)
    game.circle(decoy.row, decoy.col)
    expect(seen).toEqual(['circle'])
    game.circle(decoy.row, decoy.col) // uncircle repairs it
    expect(game.solvable).toBe(true)
  })

  it('deleting a decoy is never a mistake', () => {
    const { game } = harness()
    game.startRun(7)
    let n = 0
    game.on('mistake', () => n++)
    solve(game)
    expect(n).toBe(0)
    expect(game.phase).toBe('result')
  })
})
