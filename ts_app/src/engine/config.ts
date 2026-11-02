/** Tunable game parameters. Everything a designer might change lives here. */
export const VERSION = '0.4.0'

export const config = {
  /** Seconds granted to the time pool when a puzzle starts, by stage. */
  timeLimitBase: 75,
  timeLimitStageReduction: 5,
  timeLimitFloor: 45,
  /** Extra seconds for the third (boss) puzzle of a stage. */
  timeLimitBossBonus: 15,
  timePoolCap: 180,
  timePurchaseAmount: 15,

  /** Interest: $1 per $5 held, at most $5, paid when a puzzle completes. */
  interestRate: 1,
  interestCap: 5,
  interestThreshold: 5,

  /** Pace rating: rating = (ratingBase - seconds per cell) + clean bonus + operator score / divisor. */
  ratingBase: 12,
  misstepPenalty: 0.5,
  maxCleanBonus: 2,
  operatorRatingDivisor: 50,
  /** money = round(rating^3 / moneyDivisor) * streak multiplier */
  moneyDivisor: 500,
  streakMultipliers: [1, 1, 1.5, 2, 3],
  /** A solve with this many missteps or more breaks the streak. */
  streakMisstepThreshold: 4,

  maxOperators: 5,
  puzzlesPerStage: 3,
  finalStage: 9,
}

export function timeLimit(stage: number, puzzleIndex: number): number {
  const reduction = (stage - 1) * config.timeLimitStageReduction
  const boss = puzzleIndex === 2 ? config.timeLimitBossBonus : 0
  return Math.max(config.timeLimitBase - reduction + boss, config.timeLimitFloor)
}

export function streakMultiplier(streak: number): number {
  const m = config.streakMultipliers
  return m[Math.min(streak, m.length - 1)]
}

export function cleanBonus(missteps: number): number {
  return Math.max(0, config.maxCleanBonus - missteps * config.misstepPenalty)
}

export type Grade = 'SS' | 'S' | 'A' | 'B' | 'C' | 'D'

const GRADE_THRESHOLDS: [Grade, number][] = [
  ['SS', 14],
  ['S', 12],
  ['A', 10],
  ['B', 8],
  ['C', 6],
]

export function gradeFromRating(rating: number): Grade {
  for (const [g, t] of GRADE_THRESHOLDS) if (rating >= t) return g
  return 'D'
}

/** Nth time purchase in a run costs $(N+1). */
export function timePurchasePrice(purchasesThisRun: number): number {
  return purchasesThisRun + 1
}

export function interestFor(money: number): number {
  if (money < config.interestThreshold) return 0
  return Math.min(Math.floor(money / config.interestThreshold) * config.interestRate, config.interestCap)
}
