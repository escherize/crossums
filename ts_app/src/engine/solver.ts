import type { Pos, PuzzleState } from './puzzle'

interface RowCell {
  col: number
  value: number
}

/**
 * Column indices of every subset of `cells` whose values add to `target`.
 * With only positive values the search prunes once the running sum passes the target;
 * with negatives present it enumerates every subset, since a sum can come back down.
 */
export function subsetsWithSum(cells: RowCell[], target: number): number[][] {
  const out: number[][] = []
  const allPositive = cells.every((c) => c.value > 0)
  const pick: number[] = []
  const rec = (i: number, sum: number): void => {
    if (allPositive) {
      if (sum === target) {
        out.push(pick.slice())
        return
      }
      if (i >= cells.length || sum > target) return
    } else if (i >= cells.length) {
      if (sum === target) out.push(pick.slice())
      return
    }
    pick.push(cells[i].col)
    rec(i + 1, sum + cells[i].value)
    pick.pop()
    rec(i + 1, sum)
  }
  rec(0, 0)
  return out
}

interface Plan {
  subsets: number[][][]
  allPositive: boolean
}

/** Per-row candidate subsets over the non-deleted cells, or null if some row has none. */
function plan(p: PuzzleState): Plan | null {
  const subsets: number[][][] = []
  let allPositive = true
  for (let r = 0; r < p.rows; r++) {
    const cells: RowCell[] = []
    for (let c = 0; c < p.cols; c++) {
      const cell = p.cells[r][c]
      if (cell.state === 'deleted') continue
      cells.push({ col: c, value: cell.value })
      if (cell.value <= 0) allPositive = false
    }
    const s = subsetsWithSum(cells, p.rowTargets[r])
    if (s.length === 0) return null
    subsets.push(s)
  }
  return { subsets, allPositive }
}

/**
 * Walk every combination of row subsets, calling `onSolution` with the kept positions
 * each time the column targets match too. Stops once it returns true.
 */
function search(p: PuzzleState, onSolution: (kept: Pos[]) => boolean): void {
  const pl = plan(p)
  if (!pl) return
  const colSums = new Array<number>(p.cols).fill(0)
  const chosen: number[][] = []
  let done = false
  const rec = (row: number): void => {
    if (done) return
    if (row >= p.rows) {
      for (let c = 0; c < p.cols; c++) if (colSums[c] !== p.colTargets[c]) return
      const kept: Pos[] = []
      chosen.forEach((cols, r) => cols.forEach((col) => kept.push({ row: r, col })))
      if (onSolution(kept)) done = true
      return
    }
    for (const subset of pl.subsets[row]) {
      for (const c of subset) colSums[c] += p.cells[row][c].value
      let ok = true
      if (pl.allPositive) for (let c = 0; c < p.cols; c++) if (colSums[c] > p.colTargets[c]) (ok = false), (c = p.cols)
      if (ok) {
        chosen.push(subset)
        rec(row + 1)
        chosen.pop()
      }
      for (const c of subset) colSums[c] -= p.cells[row][c].value
      if (done) return
    }
  }
  rec(0)
}

/** Number of ways to finish from the current state, counting up to `max`. */
export function countSolutions(p: PuzzleState, max = 50): number {
  let n = 0
  search(p, () => ++n >= max)
  return n
}

/** Up to `max` solutions, each as the positions to keep. */
export function findSolutions(p: PuzzleState, max = 10): Pos[][] {
  const out: Pos[][] = []
  search(p, (kept) => out.push(kept) >= max)
  return out
}

export function hasAnySolution(p: PuzzleState): boolean {
  return countSolutions(p, 1) > 0
}
