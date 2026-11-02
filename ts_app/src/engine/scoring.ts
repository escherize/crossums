import { cleanBonus, config, gradeFromRating, streakMultiplier, type Grade } from './config'
import type { Operator } from './operators'
import type { PuzzleState } from './puzzle'

export interface OperatorDetail {
  operatorId: string
  name: string
  /** Points this operator added. */
  bonus: number
  /** Dollars this operator added (may be negative). */
  money: number
}

/**
 * Everything the result screen shows. Rating is in "rating points";
 * money comes from the cubed rating, then the streak multiplier, then operator money.
 */
export interface RatingBreakdown {
  timeUsed: number
  cellCount: number
  /** Seconds per cell. */
  pace: number
  paceRating: number
  misstepCount: number
  cleanBonus: number
  operatorScoreTotal: number
  operatorRatingBonus: number
  operatorMoney: number
  operatorDetails: OperatorDetail[]
  totalRating: number
  grade: Grade
  baseMoney: number
  streak: number
  streakMult: number
  finalMoney: number
}

export function calculateRating(
  puzzle: PuzzleState,
  timeUsed: number,
  operators: Operator[],
  streak: number,
  onTrigger?: (operatorId: string, bonus: number) => void,
): RatingBreakdown {
  const cellCount = puzzle.totalCells
  const pace = cellCount > 0 ? timeUsed / cellCount : 0
  const paceRating = config.ratingBase - pace
  const misstepCount = puzzle.misstepCount
  const clean = cleanBonus(misstepCount)

  let operatorScoreTotal = 0
  let operatorMoney = 0
  const operatorDetails: OperatorDetail[] = []
  for (const op of operators) {
    let bonus = 0
    let money = 0
    if (op.onCellKept)
      for (let r = 0; r < puzzle.rows; r++)
        for (let c = 0; c < puzzle.cols; c++) {
          const cell = puzzle.cell(r, c)
          if (cell.state !== 'deleted') bonus += op.onCellKept(r, c, cell.value, puzzle)
        }
    if (op.onRowComplete) for (let r = 0; r < puzzle.rows; r++) if (puzzle.isRowValid(r)) bonus += op.onRowComplete(r, puzzle)
    if (op.onColComplete) for (let c = 0; c < puzzle.cols; c++) if (puzzle.isColValid(c)) bonus += op.onColComplete(c, puzzle)
    if (op.onPuzzleEnd) {
      const end = op.onPuzzleEnd(puzzle)
      bonus += end.score ?? 0
      money += end.money ?? 0
    }
    if (bonus !== 0 || money !== 0) {
      operatorDetails.push({ operatorId: op.id, name: op.name, bonus, money })
      onTrigger?.(op.id, bonus)
    }
    operatorScoreTotal += bonus
    operatorMoney += money
  }

  const operatorRatingBonus = operatorScoreTotal / config.operatorRatingDivisor
  const totalRating = paceRating + clean + operatorRatingBonus
  const grade = gradeFromRating(totalRating)
  const baseMoney = Math.round(Math.pow(Math.max(0, totalRating), 3) / config.moneyDivisor)
  const streakMult = misstepCount >= config.streakMisstepThreshold ? 1 : streakMultiplier(streak)
  const finalMoney = Math.max(0, Math.round(baseMoney * streakMult) + operatorMoney)

  return {
    timeUsed,
    cellCount,
    pace,
    paceRating,
    misstepCount,
    cleanBonus: clean,
    operatorScoreTotal,
    operatorRatingBonus,
    operatorMoney,
    operatorDetails,
    totalRating,
    grade,
    baseMoney,
    streak,
    streakMult,
    finalMoney,
  }
}
