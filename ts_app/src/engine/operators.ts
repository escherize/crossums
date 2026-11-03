import type { Pos, PuzzleState } from './puzzle'
import { shuffle, type Rng } from './rng'

export type Rarity = 0 | 1 | 2 | 3

/** Cells an operator wants changed in response to the player's last action. */
export interface AutoAction {
  type: 'delete' | 'circle'
  cells: Pos[]
  operatorId: string
}

/**
 * A Balatro-style joker. Scoring hooks return bonus points; `onPuzzleEnd` may also
 * return money. `autoAction` runs after every player action and on puzzle load.
 */
export interface Operator {
  id: string
  name: string
  description: string
  rarity: Rarity
  price: number
  onCellKept?(row: number, col: number, value: number, p: PuzzleState): number
  onRowComplete?(row: number, p: PuzzleState): number
  onColComplete?(col: number, p: PuzzleState): number
  onPuzzleEnd?(p: PuzzleState): { score?: number; money?: number }
  onPuzzleStart?(p: PuzzleState): void
  autoAction?(p: PuzzleState): AutoAction | null
}

const activeInRow = (p: PuzzleState, row: number): Pos[] => {
  const out: Pos[] = []
  for (let col = 0; col < p.cols; col++) if (p.state(row, col) === 'active') out.push({ row, col })
  return out
}

const activeInCol = (p: PuzzleState, col: number): Pos[] => {
  const out: Pos[] = []
  for (let row = 0; row < p.rows; row++) if (p.state(row, col) === 'active') out.push({ row, col })
  return out
}

/**
 * True if a kept (non-deleted) cell in the row is negative. The auto-actions below reason
 * from a line's visible sum, which only pins the line down when every kept value is positive:
 * with a negative present, a zero-sum pair can hide inside a line that already matches.
 */
const rowHasNegative = (p: PuzzleState, row: number): boolean => p.cells[row].some((c) => c.state !== 'deleted' && c.value < 0)

const colHasNegative = (p: PuzzleState, col: number): boolean => {
  for (let row = 0; row < p.rows; row++) {
    const c = p.cells[row][col]
    if (c.state !== 'deleted' && c.value < 0) return true
  }
  return false
}

/** Active cells of every row passing `rowTest` and column passing `colTest`, without duplicates. */
function collect(p: PuzzleState, rowTest: (r: number) => boolean, colTest: (c: number) => boolean): Pos[] {
  const seen = new Set<string>()
  const out: Pos[] = []
  const add = (pos: Pos) => {
    const k = `${pos.row},${pos.col}`
    if (!seen.has(k)) seen.add(k), out.push(pos)
  }
  for (let r = 0; r < p.rows; r++) if (rowTest(r)) activeInRow(p, r).forEach(add)
  for (let c = 0; c < p.cols; c++) if (colTest(c)) activeInCol(p, c).forEach(add)
  return out
}

const counter = (): Operator => ({
  id: 'counter',
  name: 'RÄKNA',
  description: '+10 points for each kept cell',
  rarity: 0,
  price: 5,
  onCellKept: () => 10,
})

const rowMaster = (): Operator => ({
  id: 'row_master',
  name: 'RAD',
  description: '+50 points for each completed row',
  rarity: 0,
  price: 5,
  onRowComplete: () => 50,
})

const columnMaster = (): Operator => ({
  id: 'column_master',
  name: 'KOLONN',
  description: '+50 points for each completed column',
  rarity: 0,
  price: 5,
  onColComplete: () => 50,
})

const circlicious = (): Operator => ({
  id: 'circlicious',
  name: 'RUNDLIG',
  description: '+$2 per circled, -$1 per deleted',
  rarity: 1,
  price: 6,
  onPuzzleEnd: (p) => ({ money: p.count('circled') * 2 - p.count('deleted') }),
})

const eliteDelete = (): Operator => ({
  id: 'elite_delete',
  name: 'PRECIS',
  description: '+$2 per deleted, -$1 per circled',
  rarity: 1,
  price: 6,
  onPuzzleEnd: (p) => ({ money: p.count('deleted') * 2 - p.count('circled') }),
})

const purist = (): Operator => ({
  id: 'purist',
  name: 'RENHET',
  description: '+300 points if no circles used',
  rarity: 1,
  price: 7,
  onPuzzleEnd: (p) => (p.count('circled') === 0 ? { score: 300 } : {}),
})

/**
 * Deletes the one cell left when exactly one row and one column are still wrong, and
 * removing it finishes the puzzle. With negatives the wrong lines can need other changes.
 */
const gimme = (): Operator => ({
  id: 'gimme',
  name: 'GRATIS',
  description: 'Auto-solves when 1 row and 1 column remain',
  rarity: 1,
  price: 6,
  autoAction: (p) => {
    const rows: number[] = []
    const cols: number[] = []
    for (let r = 0; r < p.rows; r++) if (!p.isRowValid(r)) rows.push(r)
    for (let c = 0; c < p.cols; c++) if (!p.isColValid(c)) cols.push(c)
    if (rows.length !== 1 || cols.length !== 1) return null
    const pos = { row: rows[0], col: cols[0] }
    if (p.state(pos.row, pos.col) !== 'active') return null
    const v = p.value(pos.row, pos.col)
    if (p.rowSum(pos.row) - v !== p.rowTargets[pos.row] || p.colSum(pos.col) - v !== p.colTargets[pos.col]) return null
    return { type: 'delete', cells: [pos], operatorId: 'gimme' }
  },
})

const sumSight = (): Operator => ({
  id: 'sum_sight',
  name: 'SUMMA',
  description: 'Circled cells show their sum on targets',
  rarity: 0,
  price: 4,
})

const safetyNet = (): Operator => ({
  id: 'safety_net',
  name: 'SKYDD',
  description: 'Cells in solved rows/cols glow green',
  rarity: 1,
  price: 5,
})

/** Circles the active cells of any all-positive row or column whose kept cells already hit the target. */
const clickClique = (): Operator => ({
  id: 'click_clique',
  name: 'KLICK',
  description: 'When active cells hit a target, auto-circle them',
  rarity: 2,
  price: 20,
  autoAction: (p) => {
    const cells = collect(
      p,
      (r) => p.isRowValid(r) && !rowHasNegative(p, r),
      (c) => p.isColValid(c) && !colHasNegative(p, c),
    )
    return cells.length ? { type: 'circle', cells, operatorId: 'click_clique' } : null
  },
})

/** Deletes the active cells of any all-positive row or column whose circled cells alone hit the target. */
const garbageCollector = (): Operator => ({
  id: 'garbage_collector',
  name: 'STÄDA',
  description: 'When circled cells hit a target, auto-delete the rest',
  rarity: 2,
  price: 20,
  autoAction: (p) => {
    const cells = collect(
      p,
      (r) => p.isRowSolvedByCircles(r) && !rowHasNegative(p, r),
      (c) => p.isColSolvedByCircles(c) && !colHasNegative(p, c),
    )
    return cells.length ? { type: 'delete', cells, operatorId: 'garbage_collector' } : null
  },
})

/**
 * Deletes cells larger than the target of an all-positive row or column they sit in.
 * A line holding a negative is left alone: 9 can be needed for a target of 6 next to a -3.
 */
const trimmer = (): Operator => ({
  id: 'trimmer',
  name: 'SÅG',
  description: 'Auto-deletes cells too big for their targets',
  rarity: 2,
  price: 20,
  autoAction: (p) => {
    const rowOk = Array.from({ length: p.rows }, (_, r) => !rowHasNegative(p, r))
    const colOk = Array.from({ length: p.cols }, (_, c) => !colHasNegative(p, c))
    const cells: Pos[] = []
    for (let row = 0; row < p.rows; row++)
      for (let col = 0; col < p.cols; col++) {
        if (p.state(row, col) !== 'active') continue
        const v = p.value(row, col)
        if ((rowOk[row] && v > p.rowTargets[row]) || (colOk[col] && v > p.colTargets[col])) cells.push({ row, col })
      }
    return cells.length ? { type: 'delete', cells, operatorId: 'trimmer' } : null
  },
})

export const OPERATORS: Record<string, () => Operator> = {
  counter,
  row_master: rowMaster,
  column_master: columnMaster,
  circlicious,
  elite_delete: eliteDelete,
  purist,
  gimme,
  sum_sight: sumSight,
  safety_net: safetyNet,
  click_clique: clickClique,
  garbage_collector: garbageCollector,
  trimmer,
}

export function createOperator(id: string): Operator {
  const make = OPERATORS[id]
  if (!make) throw new Error(`Unknown operator: ${id}`)
  return make()
}

export function allOperatorIds(): string[] {
  return Object.keys(OPERATORS)
}

/** `count` distinct operators not in `exclude`. Deterministic when an rng is given. */
export function randomOperators(count: number, exclude: string[] = [], rng: Rng | null = null): Operator[] {
  const available = allOperatorIds().filter((id) => !exclude.includes(id))
  const order = shuffle(rng ?? Math.random, available)
  return order.slice(0, count).map(createOperator)
}
