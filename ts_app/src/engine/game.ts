import { config, interestFor, timeLimit, timePurchasePrice } from './config'
import { generateSingleSolution } from './generator'
import { createOperator, randomOperators, type AutoAction, type Operator } from './operators'
import { PuzzleState } from './puzzle'
import { seededRng } from './rng'
import { RunState, type RunJSON } from './run'
import { calculateRating, type RatingBreakdown } from './scoring'
import { solvableWithCircles } from './solver'
import { stageConfig, type StageConfig } from './stage'

export type Phase = 'idle' | 'puzzle' | 'result' | 'shop' | 'gameOver' | 'victory'

export interface GameEvents {
  /** Anything the UI shows may have changed. */
  change: undefined
  /** An operator just changed cells on the player's behalf. */
  autoAction: AutoAction
  operatorTriggered: { id: string; bonus: number }
  /** The player's last delete or circle made the puzzle unfinishable. */
  mistake: Mistake
  solved: RatingBreakdown
  timeUp: undefined
}

export interface Mistake {
  row: number
  col: number
  /** 'delete': the cell was needed. 'circle': no solution keeps it. */
  kind: 'delete' | 'circle'
}

type Listener<K extends keyof GameEvents> = (payload: GameEvents[K]) => void

/** Where a run is saved. One slot. */
export interface SaveStorage {
  get(): string | null
  set(value: string): void
  remove(): void
}

export function memoryStorage(): SaveStorage {
  let v: string | null = null
  return { get: () => v, set: (x) => (v = x), remove: () => (v = null) }
}

export function localSaveStorage(key = 'crossums_save'): SaveStorage {
  const safe = <T>(f: () => T, fallback: T): T => {
    try {
      return f()
    } catch {
      return fallback
    }
  }
  return {
    get: () => safe(() => localStorage.getItem(key), null),
    set: (v) => safe(() => localStorage.setItem(key, v), undefined),
    remove: () => safe(() => localStorage.removeItem(key), undefined),
  }
}

export interface GameOptions {
  /** Milliseconds clock. Injected so tests control time. */
  clock?: () => number
  storage?: SaveStorage
}

export interface ShopState {
  slots: (Operator | null)[]
  rerollCost: number
  rerollCount: number
}

const SAVE_VERSION = 2
const SHOP_SLOTS = 3
const REROLL_BASE_COST = 2

interface SaveJSON {
  version: number
  phase: 'puzzle' | 'shop'
  run: RunJSON
  operators: string[]
}

/**
 * The whole game apart from rendering: run progression, the live puzzle, the time pool,
 * operators and their auto-actions, scoring, the shop, and saving.
 *
 * Flow: startRun → puzzle → result → (shop after each stage) → puzzle … → victory | gameOver.
 * The UI calls tap/circle/undo for input and tick() every frame for the timer.
 */
export class Game {
  phase: Phase = 'idle'
  run: RunState | null = null
  puzzle: PuzzleState | null = null
  operators: Operator[] = []
  stage: StageConfig | null = null
  lastBreakdown: RatingBreakdown | null = null
  /** False once a player action has made the puzzle unfinishable, until it is fixed. */
  solvable = true
  shop: ShopState = { slots: [], rerollCost: REROLL_BASE_COST, rerollCount: 0 }
  /** While true, taps circle instead of delete (the held "shift" button on touch). */
  circleMode = false
  paused = false
  puzzleSolved = false
  stagesCleared = 0

  private readonly clock: () => number
  private readonly storage: SaveStorage
  private puzzleStartMs = 0
  private pauseOffsetMs = 0
  private pauseStartMs = 0
  private timeAtPuzzleStart = 0
  private executingAuto = false
  private listeners: { [K in keyof GameEvents]?: Listener<K>[] } = {}

  constructor(o: GameOptions = {}) {
    this.clock = o.clock ?? (() => performance.now())
    this.storage = o.storage ?? memoryStorage()
  }

  // ---- events --------------------------------------------------------------

  on<K extends keyof GameEvents>(event: K, fn: Listener<K>): () => void {
    const list = (this.listeners[event] ??= []) as Listener<K>[]
    list.push(fn)
    return () => {
      const i = list.indexOf(fn)
      if (i >= 0) list.splice(i, 1)
    }
  }

  private emit<K extends keyof GameEvents>(event: K, payload: GameEvents[K]): void {
    const list = this.listeners[event] as Listener<K>[] | undefined
    list?.slice().forEach((fn) => fn(payload))
  }

  private changed(): void {
    this.emit('change', undefined)
  }

  // ---- run control ---------------------------------------------------------

  startRun(runSeed = 0): void {
    this.reset()
    this.run = new RunState()
    this.run.runSeed = runSeed
    this.startNextPuzzle()
  }

  returnToTitle(): void {
    this.reset()
    this.changed()
  }

  private reset(): void {
    this.phase = 'idle'
    this.run = null
    this.puzzle = null
    this.operators = []
    this.stage = null
    this.lastBreakdown = null
    this.shop = { slots: [], rerollCost: REROLL_BASE_COST, rerollCount: 0 }
    this.circleMode = false
    this.paused = false
    this.puzzleSolved = false
    this.stagesCleared = 0
  }

  private startNextPuzzle(): void {
    const run = this.run!
    this.stage = stageConfig(run.stage, run.puzzleIndex)
    const { rng, seed } = seededRng(run.puzzleSeed())
    const puzzle = generateSingleSolution({
      size: this.stage.gridSize,
      rng,
      minValue: this.stage.minValue,
      maxValue: this.stage.maxValue,
    })
    puzzle.seed = seed
    this.loadPuzzle(puzzle)
  }

  /**
   * Make `puzzle` the live puzzle: grant its time to the pool, start the clock, and let
   * operators react to the fresh board. Exposed so tests and tools can set up exact boards.
   */
  loadPuzzle(puzzle: PuzzleState): void {
    const run = this.run
    if (!run) throw new Error('loadPuzzle needs an active run')
    this.stage ??= stageConfig(run.stage, run.puzzleIndex)
    this.puzzle = puzzle
    this.solvable = true
    this.lastBreakdown = null
    this.puzzleSolved = false
    this.paused = false
    this.pauseOffsetMs = 0
    run.timePool = Math.min(run.timePool + timeLimit(run.stage, run.puzzleIndex), config.timePoolCap)
    this.timeAtPuzzleStart = run.timePool
    this.puzzleStartMs = this.clock()
    this.phase = 'puzzle'
    for (const op of this.operators) op.onPuzzleStart?.(puzzle)
    this.changed()
    this.checkAutoActions()
  }

  // ---- timing --------------------------------------------------------------

  /** Seconds spent on the current puzzle, excluding pauses. */
  elapsed(): number {
    if (!this.puzzle) return 0
    const pausedNow = this.paused ? this.clock() - this.pauseStartMs : 0
    return (this.clock() - this.puzzleStartMs - this.pauseOffsetMs - pausedNow) / 1000
  }

  /** Seconds left in the pool. */
  timeRemaining(): number {
    if (!this.run) return 0
    if (this.phase !== 'puzzle' || this.puzzleSolved) return Math.max(this.run.timePool, 0)
    return Math.max(this.timeAtPuzzleStart - this.elapsed(), 0)
  }

  /** Advance the timer. Call once per frame; ends the run when the pool hits zero. */
  tick(): void {
    if (this.phase !== 'puzzle' || this.puzzleSolved || this.paused || !this.run) return
    this.run.timePool = this.timeRemaining()
    if (this.run.timePool <= 0) {
      this.puzzleSolved = true
      this.emit('timeUp', undefined)
      this.endRun(false)
    }
  }

  pause(): void {
    if (this.phase !== 'puzzle' || this.puzzleSolved || this.paused) return
    this.paused = true
    this.pauseStartMs = this.clock()
    this.changed()
  }

  resume(): void {
    if (!this.paused) return
    this.pauseOffsetMs += this.clock() - this.pauseStartMs
    this.paused = false
    this.changed()
  }

  // ---- puzzle input --------------------------------------------------------

  get canAct(): boolean {
    return this.phase === 'puzzle' && !this.puzzleSolved && !this.paused && this.puzzle !== null
  }

  /** Tap: delete an active cell, restore a deleted one, uncircle a circled one. */
  tap(row: number, col: number): void {
    if (!this.canAct) return
    if (this.circleMode) return this.circle(row, col)
    const p = this.puzzle!
    const s = p.state(row, col)
    const did = s === 'active' ? p.deleteCell(row, col) : s === 'deleted' ? p.restoreCell(row, col) : p.uncircleCell(row, col)
    if (did) this.afterAction(s === 'active' ? { row, col, kind: 'delete' } : undefined)
  }

  /** Long press or right-click: toggle the circle mark on a kept cell. */
  circle(row: number, col: number): void {
    if (!this.canAct) return
    const p = this.puzzle!
    const s = p.state(row, col)
    const did = s === 'active' ? p.circleCell(row, col) : s === 'circled' ? p.uncircleCell(row, col) : false
    if (did) this.afterAction(s === 'active' ? { row, col, kind: 'circle' } : undefined)
  }

  undo(): { batchesUndone: number; totalCells: number } | null {
    if (!this.canAct) return null
    const r = this.puzzle!.undoLastAction()
    if (r) {
      this.solvable = solvableWithCircles(this.puzzle!)
      this.changed()
    }
    return r
  }

  /** `candidate` is the delete or circle that may have broken the puzzle. */
  private afterAction(candidate?: Mistake): void {
    const p = this.puzzle!
    if (p.isSolved() || p.isSolvedByCircles()) this.solvable = true
    else {
      const was = this.solvable
      this.solvable = solvableWithCircles(p)
      if (was && !this.solvable && candidate) this.emit('mistake', candidate)
    }
    this.changed()
    if (!this.checkAutoWin()) this.checkAutoActions()
  }

  private checkAutoWin(): boolean {
    if (this.puzzleSolved || !this.puzzle) return false
    if (this.puzzle.isSolved() || this.puzzle.isSolvedByCircles()) {
      this.completePuzzle()
      return true
    }
    return false
  }

  /** Run the first operator auto-action that applies. One per player action, no chaining. */
  private checkAutoActions(): void {
    if (this.puzzleSolved || !this.puzzle || this.executingAuto) return
    for (const op of this.operators) {
      const action = op.autoAction?.(this.puzzle)
      if (action) {
        this.executeAutoAction(action)
        return
      }
    }
  }

  /**
   * Operators only ever help: an auto-action that would leave a finishable puzzle
   * unfinishable is dropped. The operators guard against this themselves; this is the net.
   */
  private autoActionIsSafe(a: AutoAction): boolean {
    if (!this.solvable) return true
    const trial = this.puzzle!.clone()
    for (const pos of a.cells) a.type === 'delete' ? trial.deleteCell(pos.row, pos.col) : trial.circleCell(pos.row, pos.col)
    return trial.isSolved() || trial.isSolvedByCircles() || solvableWithCircles(trial)
  }

  private executeAutoAction(a: AutoAction): void {
    if (!this.autoActionIsSafe(a)) return
    const p = this.puzzle!
    this.executingAuto = true
    this.emit('operatorTriggered', { id: a.operatorId, bonus: 0 })
    p.beginBatch(a.type, true, a.operatorId)
    for (const pos of a.cells) {
      if (this.puzzleSolved) break
      const did = a.type === 'delete' ? p.deleteCell(pos.row, pos.col) : p.circleCell(pos.row, pos.col)
      if (did) this.checkAutoWin()
    }
    p.endBatch()
    this.executingAuto = false
    this.emit('autoAction', a)
    this.changed()
  }

  private completePuzzle(): void {
    const run = this.run!
    const puzzle = this.puzzle!
    this.puzzleSolved = true
    const timeUsed = this.elapsed()
    run.timePool = Math.max(this.timeAtPuzzleStart - timeUsed, 0)

    const breakdown = calculateRating(puzzle, timeUsed, this.operators, run.streak, (id, bonus) =>
      this.emit('operatorTriggered', { id, bonus }),
    )
    if (breakdown.misstepCount < config.streakMisstepThreshold) run.streak++
    else run.streak = 0
    run.lastGrade = breakdown.grade

    const interest = interestFor(run.money)
    run.money += breakdown.finalMoney + interest
    run.interestEarnedThisStage += interest

    const displayScore = Math.floor(breakdown.totalRating * 100)
    run.stageScore += displayScore
    run.totalScore += displayScore

    const wasBoss = run.isBossPuzzle
    run.advancePuzzle()
    this.lastBreakdown = breakdown
    this.emit('solved', breakdown)

    if (run.stage > config.finalStage) {
      this.stagesCleared = config.finalStage
      this.endRun(true)
      return
    }
    if (wasBoss) {
      run.stageScore = 0
      run.interestEarnedThisStage = 0
      this.stagesCleared = run.stage - 1
    }
    this.phase = 'result'
    this.changed()
  }

  continueFromResult(): void {
    if (this.phase !== 'result' || !this.run) return
    if (this.run.puzzleIndex === 0 && this.run.stage > 1) {
      this.save('shop')
      this.openShop()
    } else {
      this.save('puzzle')
      this.startNextPuzzle()
    }
  }

  continueFromShop(): void {
    if (this.phase !== 'shop') return
    this.save('puzzle')
    this.startNextPuzzle()
  }

  private endRun(won: boolean): void {
    this.deleteSave()
    this.phase = won ? 'victory' : 'gameOver'
    this.changed()
  }

  // ---- operators -----------------------------------------------------------

  hasOperator(id: string): boolean {
    return this.operators.some((o) => o.id === id)
  }

  addOperator(op: Operator): boolean {
    if (this.operators.length >= config.maxOperators) return false
    this.operators.push(op)
    this.changed()
    return true
  }

  removeOperator(index: number): Operator | null {
    if (index < 0 || index >= this.operators.length) return null
    const [op] = this.operators.splice(index, 1)
    this.changed()
    return op
  }

  // ---- shop ----------------------------------------------------------------

  private openShop(): void {
    this.shop = { slots: [], rerollCost: REROLL_BASE_COST, rerollCount: 0 }
    this.fillShop()
    this.phase = 'shop'
    this.changed()
  }

  private fillShop(): void {
    const owned = this.operators.map((o) => o.id)
    const rng = this.run?.shopRng(this.shop.rerollCount) ?? null
    this.shop.slots = randomOperators(SHOP_SLOTS, owned, rng)
  }

  get canReroll(): boolean {
    return this.phase === 'shop' && !!this.run && this.run.money >= this.shop.rerollCost
  }

  shopReroll(): boolean {
    if (!this.canReroll) return false
    this.run!.spend(this.shop.rerollCost)
    this.shop.rerollCount++
    this.shop.rerollCost = REROLL_BASE_COST + this.shop.rerollCount
    this.fillShop()
    this.changed()
    return true
  }

  canBuy(index: number): boolean {
    const op = this.shop.slots[index]
    return this.phase === 'shop' && !!op && !!this.run && this.run.money >= op.price && this.operators.length < config.maxOperators
  }

  shopBuy(index: number): boolean {
    if (!this.canBuy(index)) return false
    const op = this.shop.slots[index]!
    this.run!.spend(op.price)
    this.operators.push(op)
    this.shop.slots[index] = null
    this.changed()
    return true
  }

  /** Sell an owned operator for half price. */
  shopSell(index: number): boolean {
    if (this.phase !== 'shop' || !this.run) return false
    const op = this.removeOperator(index)
    if (!op) return false
    this.run.money += Math.floor(op.price / 2)
    this.changed()
    return true
  }

  get timePrice(): number {
    return timePurchasePrice(this.run?.timePurchases ?? 0)
  }

  get canBuyTime(): boolean {
    return this.phase === 'shop' && !!this.run && this.run.money >= this.timePrice && this.run.timePool < config.timePoolCap
  }

  shopBuyTime(): boolean {
    if (!this.canBuyTime) return false
    const run = this.run!
    run.spend(this.timePrice)
    run.timePool = Math.min(run.timePool + config.timePurchaseAmount, config.timePoolCap)
    run.timePurchases++
    this.changed()
    return true
  }

  // ---- save / load ---------------------------------------------------------

  /**
   * Snapshot the run at a transition, before the next puzzle's time is granted.
   * `phase` says what to start on load.
   */
  private save(phase: SaveJSON['phase']): void {
    if (!this.run) return
    const data: SaveJSON = { version: SAVE_VERSION, phase, run: this.run.toJSON(), operators: this.operators.map((o) => o.id) }
    this.storage.set(JSON.stringify(data))
  }

  hasSave(): boolean {
    return this.storage.get() !== null
  }

  deleteSave(): void {
    this.storage.remove()
  }

  /** Resume a saved run. Returns false (and clears the slot) if there is none or it is unreadable. */
  load(): boolean {
    const raw = this.storage.get()
    if (!raw) return false
    let data: SaveJSON
    try {
      data = JSON.parse(raw)
    } catch {
      this.deleteSave()
      return false
    }
    if (data.version !== SAVE_VERSION || !data.run) {
      this.deleteSave()
      return false
    }
    this.reset()
    this.run = RunState.fromJSON(data.run)
    this.operators = data.operators.flatMap((id) => (id in OPERATOR_IDS ? [createOperator(id)] : []))
    if (data.phase === 'shop') this.openShop()
    else this.startNextPuzzle()
    return true
  }
}

const OPERATOR_IDS: Record<string, true> = Object.fromEntries(
  ['counter', 'row_master', 'column_master', 'circlicious', 'elite_delete', 'purist', 'gimme', 'sum_sight', 'safety_net', 'click_clique', 'garbage_collector', 'trimmer'].map((id) => [id, true]),
)
