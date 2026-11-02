import { PuzzleState } from './puzzle'
import { randFloat, randInt, shuffle, type Rng } from './rng'
import { countSolutions } from './solver'

export interface GenerateOptions {
  size: number
  rng: Rng
  minValue?: number
  maxValue?: number
  /** Share of cells the solution deletes, drawn uniformly from this range. */
  minDeleteRatio?: number
  maxDeleteRatio?: number
}

const MAX_ATTEMPTS = 100
const TARGET_ATTEMPTS = 50

/** Uniform in [min, max] but never 0. */
export function randomNonzero(rng: Rng, min: number, max: number): number {
  if (min > 0 || max < 0) return randInt(rng, min, max)
  const v = randInt(rng, min, max - 1)
  return v >= 0 ? v + 1 : v
}

/**
 * A puzzle with exactly one solution, where no row or column starts already satisfied.
 * Falls back to a merely solvable puzzle if no unique one turns up.
 */
export function generateSingleSolution(o: GenerateOptions): PuzzleState {
  const { size, rng } = o
  const minValue = o.minValue ?? 1
  const maxValue = o.maxValue ?? 9
  const minDelete = o.minDeleteRatio ?? 0.4
  const maxDelete = o.maxDeleteRatio ?? 0.8
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const p = new PuzzleState(size)
    for (const row of p.cells) for (const c of row) c.value = randomNonzero(rng, minValue, maxValue)
    if (findUniqueTargets(p, rng, 1 - maxDelete, 1 - minDelete)) return p
  }
  return generateFallback(size, rng, minValue, maxValue)
}

function findUniqueTargets(p: PuzzleState, rng: Rng, minKeep: number, maxKeep: number): boolean {
  for (let attempt = 0; attempt < TARGET_ATTEMPTS; attempt++) {
    const keepRatio = randFloat(rng, minKeep, maxKeep)
    const keep = new Set<number>()
    const key = (r: number, c: number) => r * p.cols + c
    for (let r = 0; r < p.rows; r++) for (let c = 0; c < p.cols; c++) if (rng() < keepRatio) keep.add(key(r, c))
    for (let r = 0; r < p.rows; r++) {
      let has = false
      for (let c = 0; c < p.cols; c++) if (keep.has(key(r, c))) has = true
      if (!has) keep.add(key(r, randInt(rng, 0, p.cols - 1)))
    }
    for (let c = 0; c < p.cols; c++) {
      let has = false
      for (let r = 0; r < p.rows; r++) if (keep.has(key(r, c))) has = true
      if (!has) keep.add(key(randInt(rng, 0, p.rows - 1), c))
    }
    setTargetsFromKeep(p, keep)
    if (hasSatisfiedTargetAtStart(p)) continue
    if (countSolutions(p, 2) === 1) {
      p.seed = randInt(rng, 1, 0x7fffffff)
      p.solutionCellCount = keep.size
      return true
    }
  }
  return false
}

function setTargetsFromKeep(p: PuzzleState, keep: Set<number>): void {
  for (let r = 0; r < p.rows; r++) {
    let s = 0
    for (let c = 0; c < p.cols; c++) if (keep.has(r * p.cols + c)) s += p.cells[r][c].value
    p.rowTargets[r] = s
  }
  for (let c = 0; c < p.cols; c++) {
    let s = 0
    for (let r = 0; r < p.rows; r++) if (keep.has(r * p.cols + c)) s += p.cells[r][c].value
    p.colTargets[c] = s
  }
}

/** True if some row or column already sums to its target with every cell kept. */
export function hasSatisfiedTargetAtStart(p: PuzzleState): boolean {
  for (let r = 0; r < p.rows; r++) {
    let s = 0
    for (let c = 0; c < p.cols; c++) s += p.cells[r][c].value
    if (s === p.rowTargets[r]) return true
  }
  for (let c = 0; c < p.cols; c++) {
    let s = 0
    for (let r = 0; r < p.rows; r++) s += p.cells[r][c].value
    if (s === p.colTargets[c]) return true
  }
  return false
}

/**
 * A solvable puzzle with no uniqueness guarantee. About 40% of cells are decoys,
 * with at least one solution cell and one decoy in every row and column.
 */
export function generateFallback(size: number, rng: Rng, minValue: number, maxValue: number, deleteRatio = 0.4): PuzzleState {
  const p = new PuzzleState(size)
  const total = size * size
  const toDelete = Math.min(Math.max(Math.floor(total * deleteRatio), size), total - size)
  const key = (r: number, c: number) => r * size + c
  const solution = new Set<number>()
  const decoys = new Set<number>()

  for (let r = 0; r < size; r++) solution.add(key(r, randInt(rng, 0, size - 1)))
  for (let c = 0; c < size; c++) {
    let has = false
    for (let r = 0; r < size; r++) if (solution.has(key(r, c))) has = true
    if (!has) solution.add(key(randInt(rng, 0, size - 1), c))
  }
  for (let r = 0; r < size; r++) {
    const free: number[] = []
    for (let c = 0; c < size; c++) if (!solution.has(key(r, c))) free.push(c)
    if (free.length) decoys.add(key(r, free[randInt(rng, 0, free.length - 1)]))
  }
  for (let c = 0; c < size; c++) {
    let has = false
    for (let r = 0; r < size; r++) if (decoys.has(key(r, c))) has = true
    if (has) continue
    const free: number[] = []
    for (let r = 0; r < size; r++) if (!solution.has(key(r, c)) && !decoys.has(key(r, c))) free.push(r)
    if (free.length) decoys.add(key(free[randInt(rng, 0, free.length - 1)], c))
  }
  const remaining: number[] = []
  for (let i = 0; i < total; i++) if (!solution.has(i) && !decoys.has(i)) remaining.push(i)
  const order = shuffle(rng, remaining)
  const extra = toDelete - decoys.size
  order.forEach((i, idx) => (idx < extra ? decoys.add(i) : solution.add(i)))

  for (const row of p.cells) for (const c of row) c.value = randomNonzero(rng, minValue, maxValue)
  setTargetsFromKeep(p, solution)
  p.solutionCellCount = solution.size
  p.seed = randInt(rng, 1, 0x7fffffff)
  return p
}
