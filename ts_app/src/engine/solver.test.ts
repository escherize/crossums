import { describe, expect, it } from 'vitest'
import { PuzzleState } from './puzzle'
import { countSolutions, findSolutions, subsetsWithSum } from './solver'

describe('subsetsWithSum', () => {
  it('finds positive subsets', () => {
    const cells = [1, 2, 5].map((value, col) => ({ col, value }))
    expect(subsetsWithSum(cells, 7)).toEqual([[1, 2]])
    expect(subsetsWithSum(cells, 3)).toEqual([[0, 1]])
    expect(subsetsWithSum(cells, 4)).toEqual([])
  })

  it('handles negatives, where a running sum can overshoot and come back', () => {
    const cells = [3, -2, 1].map((value, col) => ({ col, value }))
    expect(subsetsWithSum(cells, 2)).toEqual([[0, 1, 2]])
    expect(subsetsWithSum(cells, 1)).toEqual([[0, 1], [2]])
  })
})

describe('countSolutions / findSolutions', () => {
  const p = PuzzleState.fromValues(
    [
      [1, 2, 5],
      [4, 2, 3],
      [5, 6, 6],
    ],
    [7, 5, 5],
    [5, 4, 8],
  )

  it('the reference board has exactly one solution', () => {
    expect(countSolutions(p)).toBe(1)
    expect(findSolutions(p)).toEqual([
      [
        { row: 0, col: 1 },
        { row: 0, col: 2 },
        { row: 1, col: 1 },
        { row: 1, col: 2 },
        { row: 2, col: 0 },
      ],
    ])
  })

  it('respects deleted cells and reports dead ends', () => {
    const q = p.clone()
    q.deleteCell(0, 1)
    expect(countSolutions(q)).toBe(0)
  })

  it('counts multiple solutions and stops at max', () => {
    const m = PuzzleState.fromValues(
      [
        [1, 1],
        [1, 1],
      ],
      [1, 1],
      [1, 1],
    )
    expect(countSolutions(m)).toBe(2)
    expect(countSolutions(m, 1)).toBe(1)
  })

  it('solves boards with negative values', () => {
    const n = PuzzleState.fromValues(
      [
        [3, -2, 1],
        [2, 2, -1],
        [-1, 4, 2],
      ],
      [2, 1, 6],
      [5, 2, 2],
    )
    expect(countSolutions(n)).toBeGreaterThan(0)
    expect(findSolutions(n, 1)[0]).toContainEqual({ row: 0, col: 1 })
  })
})
