import { describe, expect, it } from 'vitest'
import { PuzzleState } from './puzzle'

const board = () =>
  PuzzleState.fromValues(
    [
      [1, 2, 5],
      [4, 2, 3],
      [5, 6, 6],
    ],
    [7, 5, 5],
    [5, 4, 8],
  )

describe('PuzzleState', () => {
  it('sums kept cells and detects the solution', () => {
    const p = board()
    expect(p.rowSum(0)).toBe(8)
    expect(p.isSolved()).toBe(false)
    p.deleteCell(0, 0)
    p.deleteCell(1, 0)
    p.deleteCell(2, 1)
    p.deleteCell(2, 2)
    expect(p.isSolved()).toBe(true)
    expect(p.keptCount()).toBe(5)
  })

  it('only active cells can be deleted or circled; restore and uncircle are missteps', () => {
    const p = board()
    expect(p.deleteCell(0, 0)).toBe(true)
    expect(p.deleteCell(0, 0)).toBe(false)
    expect(p.circleCell(0, 0)).toBe(false)
    expect(p.restoreCell(0, 0)).toBe(true)
    expect(p.circleCell(0, 0)).toBe(true)
    expect(p.deleteCell(0, 0)).toBe(false)
    expect(p.uncircleCell(0, 0)).toBe(true)
    expect(p.misstepCount).toBe(2)
    expect(p.actionHistory).toEqual([])
  })

  it('undo reverts one manual action at a time', () => {
    const p = board()
    p.circleCell(0, 0)
    p.circleCell(1, 1)
    expect(p.undoLastAction()).toEqual({ batchesUndone: 1, totalCells: 1 })
    expect(p.state(1, 1)).toBe('active')
    expect(p.state(0, 0)).toBe('circled')
    p.undoLastAction()
    expect(p.state(0, 0)).toBe('active')
    expect(p.undoLastAction()).toBeNull()
    expect(p.misstepCount).toBe(2)
  })

  it('undo groups a manual action with the auto-actions it triggered', () => {
    const p = board()
    p.deleteCell(1, 0)
    p.deleteCell(0, 2)
    p.beginBatch('circle', true, 'click_clique')
    p.circleCell(0, 0)
    p.circleCell(0, 1)
    p.endBatch()
    expect(p.actionCount).toBe(3)
    expect(p.undoLastAction()).toEqual({ batchesUndone: 2, totalCells: 3 })
    expect(p.state(0, 0)).toBe('active')
    expect(p.state(0, 1)).toBe('active')
    expect(p.state(0, 2)).toBe('active')
    expect(p.state(1, 0)).toBe('deleted')
    p.undoLastAction()
    expect(p.state(1, 0)).toBe('active')
  })

  it('an empty batch leaves no history', () => {
    const p = board()
    p.beginBatch('delete', true, 'x')
    p.endBatch()
    expect(p.canUndo).toBe(false)
  })

  it('restoring removes the cell from its batch and drops empty batches', () => {
    const p = board()
    p.deleteCell(0, 0)
    p.deleteCell(0, 1)
    p.restoreCell(0, 0)
    expect(p.actionHistory).toEqual([{ type: 'delete', cells: [{ row: 0, col: 1 }], auto: false, operatorId: '' }])
  })

  it('circled cells alone can solve', () => {
    const p = board()
    expect(p.isSolvedByCircles()).toBe(false)
    p.circleCell(0, 1)
    p.circleCell(0, 2)
    p.circleCell(1, 1)
    p.circleCell(1, 2)
    expect(p.isRowSolvedByCircles(0)).toBe(true)
    expect(p.isSolvedByCircles()).toBe(false)
    p.circleCell(2, 0)
    expect(p.isSolvedByCircles()).toBe(true)
    expect(p.isSolved()).toBe(false)
  })

  it('round-trips through JSON', () => {
    const p = board()
    p.deleteCell(0, 0)
    p.circleCell(1, 1)
    p.misstepCount = 3
    const q = PuzzleState.fromJSON(JSON.parse(JSON.stringify(p.toJSON())))
    expect(q.toJSON()).toEqual(p.toJSON())
    expect(q.state(0, 0)).toBe('deleted')
  })
})
