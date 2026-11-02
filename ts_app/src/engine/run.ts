import { config } from './config'
import { mulberry32, type Rng } from './rng'

/** Bump when puzzle generation changes, so old run seeds stop promising old puzzles. */
export const SEED_VERSION = 2

export interface RunJSON {
  stage: number
  puzzleIndex: number
  runSeed: number
  money: number
  totalScore: number
  stageScore: number
  timePool: number
  timePurchases: number
  lastGrade: string
  interestEarnedThisStage: number
  streak: number
}

/** Progress through one run. Serializable. */
export class RunState {
  stage = 1
  puzzleIndex = 0
  /** 0 means random puzzles; anything else gives a deterministic sequence. */
  runSeed = 0
  money = 0
  totalScore = 0
  stageScore = 0
  /** Seconds left. Shared across the whole run; never resets between puzzles. */
  timePool = 0
  timePurchases = 0
  lastGrade = ''
  interestEarnedThisStage = 0
  streak = 0

  get puzzlesCompleted(): number {
    return (this.stage - 1) * config.puzzlesPerStage + this.puzzleIndex
  }

  get isFinalStage(): boolean {
    return this.stage >= config.finalStage
  }

  get isBossPuzzle(): boolean {
    return this.puzzleIndex === config.puzzlesPerStage - 1
  }

  advancePuzzle(): void {
    this.puzzleIndex++
    if (this.puzzleIndex >= config.puzzlesPerStage) {
      this.puzzleIndex = 0
      this.stage++
    }
  }

  spend(amount: number): boolean {
    if (this.money < amount) return false
    this.money -= amount
    return true
  }

  /** Seed for the current puzzle, or 0 (random) for an unseeded run. */
  puzzleSeed(): number {
    if (this.runSeed === 0) return 0
    return ((this.runSeed * SEED_VERSION * 31337 + this.stage * 997 + this.puzzleIndex * 13) >>> 0) || 1
  }

  /** Separate RNG stream for the shop so shop draws never shift puzzle seeds. Null when unseeded. */
  shopRng(rerollCount: number): Rng | null {
    if (this.runSeed === 0) return null
    return mulberry32((this.runSeed * SEED_VERSION * 7919 + this.stage * 1009 + rerollCount * 17 + 999999) >>> 0)
  }

  toJSON(): RunJSON {
    return {
      stage: this.stage,
      puzzleIndex: this.puzzleIndex,
      runSeed: this.runSeed,
      money: this.money,
      totalScore: this.totalScore,
      stageScore: this.stageScore,
      timePool: this.timePool,
      timePurchases: this.timePurchases,
      lastGrade: this.lastGrade,
      interestEarnedThisStage: this.interestEarnedThisStage,
      streak: this.streak,
    }
  }

  static fromJSON(j: Partial<RunJSON>): RunState {
    const r = new RunState()
    Object.assign(r, j)
    return r
  }
}
