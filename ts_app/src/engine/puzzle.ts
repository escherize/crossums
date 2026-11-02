export type CellState = 'active' | 'deleted' | 'circled'

export interface Cell {
  value: number
  state: CellState
}

export interface Pos {
  row: number
  col: number
}

/** One undo step: a player action, or the auto-action an operator took in response to one. */
export interface ActionBatch {
  type: 'delete' | 'circle'
  cells: Pos[]
  auto: boolean
  operatorId: string
}

export interface PuzzleJSON {
  rows: number
  cols: number
  cells: Cell[][]
  rowTargets: number[]
  colTargets: number[]
  actionHistory: ActionBatch[]
  seed: number
  solutionCellCount: number
  misstepCount: number
}

const samePos = (a: Pos, b: Pos) => a.row === b.row && a.col === b.col

/**
 * The grid, its targets, and what the player has done to it.
 * Kept cells (active or circled) count toward sums; deleted cells do not.
 */
export class PuzzleState {
  readonly rows: number
  readonly cols: number
  cells: Cell[][]
  rowTargets: number[]
  colTargets: number[]
  actionHistory: ActionBatch[] = []
  seed = 0
  solutionCellCount = 0
  /** Restores, uncircles and undos: times the player changed their mind. */
  misstepCount = 0
  private pendingBatch: ActionBatch | null = null

  constructor(rows: number, cols = rows) {
    this.rows = rows
    this.cols = cols
    this.cells = Array.from({ length: rows }, () => Array.from({ length: cols }, () => ({ value: 0, state: 'active' as CellState })))
    this.rowTargets = new Array(rows).fill(0)
    this.colTargets = new Array(cols).fill(0)
  }

  static fromValues(values: number[][], rowTargets: number[], colTargets: number[]): PuzzleState {
    const p = new PuzzleState(values.length, values[0].length)
    values.forEach((r, i) => r.forEach((v, j) => (p.cells[i][j].value = v)))
    p.rowTargets = rowTargets.slice()
    p.colTargets = colTargets.slice()
    return p
  }

  inBounds(row: number, col: number): boolean {
    return row >= 0 && row < this.rows && col >= 0 && col < this.cols
  }

  cell(row: number, col: number): Cell {
    return this.cells[row][col]
  }

  value(row: number, col: number): number {
    return this.cells[row][col].value
  }

  state(row: number, col: number): CellState {
    return this.cells[row][col].state
  }

  get totalCells(): number {
    return this.rows * this.cols
  }

  // ---- player actions ------------------------------------------------------

  deleteCell(row: number, col: number): boolean {
    const c = this.cells[row][col]
    if (c.state !== 'active') return false
    c.state = 'deleted'
    this.record('delete', { row, col })
    return true
  }

  restoreCell(row: number, col: number): boolean {
    const c = this.cells[row][col]
    if (c.state !== 'deleted') return false
    c.state = 'active'
    this.misstepCount++
    this.forget('delete', { row, col })
    return true
  }

  circleCell(row: number, col: number): boolean {
    const c = this.cells[row][col]
    if (c.state !== 'active') return false
    c.state = 'circled'
    this.record('circle', { row, col })
    return true
  }

  uncircleCell(row: number, col: number): boolean {
    const c = this.cells[row][col]
    if (c.state !== 'circled') return false
    c.state = 'active'
    this.misstepCount++
    this.forget('circle', { row, col })
    return true
  }

  /**
   * Revert the last player action together with every auto-action it triggered.
   * Counts as one misstep. Returns null when there is nothing to undo.
   */
  undoLastAction(): { batchesUndone: number; totalCells: number } | null {
    if (this.actionHistory.length === 0) return null
    let batchesUndone = 0
    let totalCells = 0
    while (this.actionHistory.length > 0) {
      const batch = this.actionHistory.pop()!
      batchesUndone++
      for (const p of batch.cells) {
        this.cells[p.row][p.col].state = 'active'
        totalCells++
      }
      if (!batch.auto) break
    }
    this.misstepCount++
    return { batchesUndone, totalCells }
  }

  /** Group the cell actions until endBatch() into one undo step. */
  beginBatch(type: ActionBatch['type'], auto: boolean, operatorId = ''): void {
    this.pendingBatch = { type, cells: [], auto, operatorId }
  }

  endBatch(): void {
    if (this.pendingBatch && this.pendingBatch.cells.length > 0) this.actionHistory.push(this.pendingBatch)
    this.pendingBatch = null
  }

  private record(type: ActionBatch['type'], pos: Pos): void {
    if (this.pendingBatch) {
      if (this.pendingBatch.type === type) this.pendingBatch.cells.push(pos)
    } else {
      this.actionHistory.push({ type, cells: [pos], auto: false, operatorId: '' })
    }
  }

  /** Remove a reverted cell from the newest batch that holds it. */
  private forget(type: ActionBatch['type'], pos: Pos): void {
    for (let i = this.actionHistory.length - 1; i >= 0; i--) {
      const batch = this.actionHistory[i]
      if (batch.type !== type) continue
      const idx = batch.cells.findIndex((p) => samePos(p, pos))
      if (idx < 0) continue
      batch.cells.splice(idx, 1)
      if (batch.cells.length === 0) this.actionHistory.splice(i, 1)
      return
    }
  }

  get canUndo(): boolean {
    return this.actionHistory.length > 0
  }

  get actionCount(): number {
    return this.actionHistory.length
  }

  // ---- sums ----------------------------------------------------------------

  rowSum(row: number): number {
    let s = 0
    for (const c of this.cells[row]) if (c.state !== 'deleted') s += c.value
    return s
  }

  colSum(col: number): number {
    let s = 0
    for (let r = 0; r < this.rows; r++) if (this.cells[r][col].state !== 'deleted') s += this.cells[r][col].value
    return s
  }

  circledRowSum(row: number): number {
    let s = 0
    for (const c of this.cells[row]) if (c.state === 'circled') s += c.value
    return s
  }

  circledColSum(col: number): number {
    let s = 0
    for (let r = 0; r < this.rows; r++) if (this.cells[r][col].state === 'circled') s += this.cells[r][col].value
    return s
  }

  isRowValid(row: number): boolean {
    return this.rowSum(row) === this.rowTargets[row]
  }

  isColValid(col: number): boolean {
    return this.colSum(col) === this.colTargets[col]
  }

  /** Every row and column of kept cells matches its target. */
  isSolved(): boolean {
    for (let r = 0; r < this.rows; r++) if (!this.isRowValid(r)) return false
    for (let c = 0; c < this.cols; c++) if (!this.isColValid(c)) return false
    return true
  }

  isRowSolvedByCircles(row: number): boolean {
    const s = this.circledRowSum(row)
    return s > 0 && s === this.rowTargets[row]
  }

  isColSolvedByCircles(col: number): boolean {
    const s = this.circledColSum(col)
    return s > 0 && s === this.colTargets[col]
  }

  /** The circled cells alone form a solution. Needs at least one circle. */
  isSolvedByCircles(): boolean {
    if (!this.cells.some((r) => r.some((c) => c.state === 'circled'))) return false
    for (let r = 0; r < this.rows; r++) if (this.circledRowSum(r) !== this.rowTargets[r]) return false
    for (let c = 0; c < this.cols; c++) if (this.circledColSum(c) !== this.colTargets[c]) return false
    return true
  }

  // ---- stats ---------------------------------------------------------------

  keptCount(): number {
    let n = 0
    for (const r of this.cells) for (const c of r) if (c.state !== 'deleted') n++
    return n
  }

  count(state: CellState): number {
    let n = 0
    for (const r of this.cells) for (const c of r) if (c.state === state) n++
    return n
  }

  positions(state: CellState): Pos[] {
    const out: Pos[] = []
    this.cells.forEach((r, row) => r.forEach((c, col) => c.state === state && out.push({ row, col })))
    return out
  }

  /** Put every cell back to active and forget the history. Values and targets stay. */
  reset(): void {
    for (const r of this.cells) for (const c of r) c.state = 'active'
    this.actionHistory = []
    this.pendingBatch = null
    this.misstepCount = 0
  }

  clone(): PuzzleState {
    return PuzzleState.fromJSON(this.toJSON())
  }

  toJSON(): PuzzleJSON {
    return {
      rows: this.rows,
      cols: this.cols,
      cells: this.cells.map((r) => r.map((c) => ({ ...c }))),
      rowTargets: this.rowTargets.slice(),
      colTargets: this.colTargets.slice(),
      actionHistory: this.actionHistory.map((b) => ({ ...b, cells: b.cells.map((p) => ({ ...p })) })),
      seed: this.seed,
      solutionCellCount: this.solutionCellCount,
      misstepCount: this.misstepCount,
    }
  }

  static fromJSON(j: PuzzleJSON): PuzzleState {
    const p = new PuzzleState(j.rows, j.cols)
    p.cells = j.cells.map((r) => r.map((c) => ({ ...c })))
    p.rowTargets = j.rowTargets.slice()
    p.colTargets = j.colTargets.slice()
    p.actionHistory = j.actionHistory.map((b) => ({ ...b, cells: b.cells.map((q) => ({ ...q })) }))
    p.seed = j.seed
    p.solutionCellCount = j.solutionCellCount
    p.misstepCount = j.misstepCount
    return p
  }
}
