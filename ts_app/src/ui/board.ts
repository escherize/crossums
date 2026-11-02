import type { Game } from '../engine/game'
import type { PuzzleState } from '../engine/puzzle'
import { el, clear } from './dom'

export interface BoardHandlers {
  tap(row: number, col: number): void
  circle(row: number, col: number): void
}

const LONG_PRESS_MS = 400
const MIN_CELL = 44
const MAX_CELL = 180
const GAP = 8
/** Board padding plus border, per axis. */
const FRAME = 27

/**
 * Renders the targets and cells for the live puzzle and turns pointer input into
 * tap / circle calls. Tap = pointer down and up within the long-press window;
 * holding, or right-click, circles instead.
 */
export class Board {
  readonly el: HTMLElement
  private puzzle: PuzzleState | null = null
  private cells: HTMLElement[][] = []
  private rowTargets: HTMLElement[] = []
  private colTargets: HTMLElement[] = []
  private observer: ResizeObserver | null = null

  constructor(
    private game: Game,
    private handlers: BoardHandlers,
  ) {
    this.el = el('div.board')
    this.el.addEventListener('contextmenu', (e) => e.preventDefault())
  }

  /** Rebuild the DOM when the puzzle object changes; otherwise refresh classes. */
  update(): void {
    const host = this.el.parentElement
    if (host && !this.observer) {
      this.observer = new ResizeObserver(() => this.fit())
      this.observer.observe(host)
    }
    const p = this.game.puzzle
    if (p !== this.puzzle) {
      this.puzzle = p
      this.build()
    }
    this.refresh()
  }

  /**
   * Size cells to fill the host. The grid is (cols+1) x (rows+1) units including
   * the targets. Horizontally, when there is room for one more unit, the board gets
   * an offset margin so the number cells, not the whole grid, are centred.
   */
  private fit(): void {
    const p = this.puzzle
    const host = this.el.parentElement
    if (!p || !host) return
    // The host grows with the board, so measure the room the rest of the screen
    // leaves in the viewport instead of the host's own height.
    const screen = host.parentElement ?? host
    const other = screen.getBoundingClientRect().height - host.getBoundingClientRect().height
    const w = host.clientWidth - FRAME
    const h = Math.max(0, window.innerHeight - other - FRAME)
    const unit = (px: number, units: number) => Math.floor((px - GAP * (units - 1)) / units)
    const clamp = (n: number) => Math.max(MIN_CELL, Math.min(MAX_CELL, n))
    const tall = unit(h, p.rows + 1)
    const plain = Math.min(unit(w, p.cols + 1), tall)
    const offset = Math.min(unit(w, p.cols + 2), tall)
    // Centre the cells only when the extra unit still fits and costs less than a
    // quarter of the cell size.
    const useOffset = offset >= MIN_CELL && offset >= plain * 0.75
    this.el.classList.toggle('offset-x', useOffset)
    this.el.style.setProperty('--cell', `${clamp(useOffset ? offset : plain)}px`)
  }

  /** Red flash on one cell, for a mistake. */
  flashWrong(row: number, col: number): void {
    const node = this.cells[row]?.[col]
    if (!node) return
    node.classList.remove('wrong')
    void node.offsetWidth
    node.classList.add('wrong')
  }

  /** Shake the whole board once. */
  shake(): void {
    const host = this.el.parentElement
    if (!host) return
    host.classList.remove('shake')
    void host.offsetWidth
    host.classList.add('shake')
  }

  private build(): void {
    clear(this.el)
    this.cells = []
    this.rowTargets = []
    this.colTargets = []
    const p = this.puzzle
    if (!p) return
    this.el.style.setProperty('--cols', String(p.cols))
    this.el.style.setProperty('--rows', String(p.rows))
    this.fit()

    this.el.appendChild(el('div.corner'))
    for (let c = 0; c < p.cols; c++) {
      const t = this.target(p.colTargets[c])
      this.colTargets.push(t)
      this.el.appendChild(t)
    }
    for (let r = 0; r < p.rows; r++) {
      const t = this.target(p.rowTargets[r])
      this.rowTargets.push(t)
      this.el.appendChild(t)
      const rowEls: HTMLElement[] = []
      for (let c = 0; c < p.cols; c++) {
        const cell = this.cell(r, c, p.value(r, c))
        rowEls.push(cell)
        this.el.appendChild(cell)
      }
      this.cells.push(rowEls)
    }
  }

  private target(value: number): HTMLElement {
    return el('div.target', {}, el('span.target-value', {}, value), el('span.target-circled'))
  }

  private cell(row: number, col: number, value: number): HTMLElement {
    const node = el<'button'>('button.cell', { type: 'button', 'aria-label': `cell ${row + 1},${col + 1} value ${value}` }, el('span.value', {}, value))
    let pointerId: number | null = null
    let timer: ReturnType<typeof setTimeout> | null = null
    let longPressed = false
    const release = () => {
      if (timer) clearTimeout(timer)
      timer = null
      pointerId = null
      node.classList.remove('pressing')
    }
    node.addEventListener('pointerdown', (e) => {
      if (e.button === 2 || pointerId !== null) return
      e.preventDefault()
      pointerId = e.pointerId
      longPressed = false
      node.classList.add('pressing')
      timer = setTimeout(() => {
        longPressed = true
        node.classList.remove('pressing')
        this.handlers.circle(row, col)
      }, LONG_PRESS_MS)
    })
    node.addEventListener('pointerup', (e) => {
      if (e.pointerId !== pointerId) return
      const wasLong = longPressed
      release()
      if (!wasLong) this.handlers.tap(row, col)
    })
    node.addEventListener('pointercancel', (e) => e.pointerId === pointerId && release())
    node.addEventListener('pointerleave', (e) => e.pointerId === pointerId && release())
    node.addEventListener('contextmenu', (e) => {
      e.preventDefault()
      release()
      this.handlers.circle(row, col)
    })
    return node
  }

  private refresh(): void {
    const p = this.puzzle
    if (!p) return
    const sumSight = this.game.hasOperator('sum_sight')
    const safetyNet = this.game.hasOperator('safety_net')
    const solvedRows: boolean[] = []
    const solvedCols: boolean[] = []
    for (let r = 0; r < p.rows; r++) {
      solvedRows.push(p.isRowValid(r))
      this.paintTarget(this.rowTargets[r], p.isRowValid(r), p.isRowSolvedByCircles(r), sumSight ? p.circledRowSum(r) : 0)
    }
    for (let c = 0; c < p.cols; c++) {
      solvedCols.push(p.isColValid(c))
      this.paintTarget(this.colTargets[c], p.isColValid(c), p.isColSolvedByCircles(c), sumSight ? p.circledColSum(c) : 0)
    }
    for (let r = 0; r < p.rows; r++)
      for (let c = 0; c < p.cols; c++) {
        const node = this.cells[r][c]
        const state = p.state(r, c)
        const prev = node.dataset.state
        node.dataset.state = state
        if (prev && prev !== state) {
          node.classList.remove('pop')
          void node.offsetWidth
          node.classList.add('pop')
        }
        node.classList.toggle('protected', safetyNet && (solvedRows[r] || solvedCols[c]))
        node.classList.toggle('circle-hint', this.game.circleMode && state === 'active')
      }
  }

  private paintTarget(node: HTMLElement, exact: boolean, byCircles: boolean, circledSum: number): void {
    node.classList.toggle('exact', exact)
    node.classList.toggle('by-circles', byCircles)
    const circ = node.querySelector('.target-circled') as HTMLElement
    circ.textContent = circledSum ? String(circledSum) : ''
  }
}
