import { describe, expect, it } from 'vitest'
import { config, gradeFromRating, interestFor, timeLimit } from './config'
import { createOperator } from './operators'
import { PuzzleState } from './puzzle'
import { calculateRating } from './scoring'

const solved3x3 = () => {
  const p = PuzzleState.fromValues(
    [
      [1, 2, 5],
      [4, 2, 3],
      [5, 6, 6],
    ],
    [7, 5, 5],
    [5, 4, 8],
  )
  p.deleteCell(0, 0)
  p.deleteCell(1, 0)
  p.deleteCell(2, 1)
  p.deleteCell(2, 2)
  return p
}

describe('calculateRating', () => {
  it('pace plus clean bonus, cubed into money', () => {
    const b = calculateRating(solved3x3(), 27, [], 0)
    expect(b.pace).toBe(3)
    expect(b.paceRating).toBe(9)
    expect(b.cleanBonus).toBe(2)
    expect(b.totalRating).toBe(11)
    expect(b.grade).toBe('A')
    expect(b.baseMoney).toBe(Math.round(1331 / config.moneyDivisor))
    expect(b.streakMult).toBe(1)
    expect(b.finalMoney).toBe(b.baseMoney)
  })

  it('missteps erode the clean bonus and four of them break the streak', () => {
    const p = solved3x3()
    p.misstepCount = 2
    expect(calculateRating(p, 9, [], 3).cleanBonus).toBe(1)
    expect(calculateRating(p, 9, [], 3).streakMult).toBe(2)
    p.misstepCount = 4
    expect(calculateRating(p, 9, [], 3).cleanBonus).toBe(0)
    expect(calculateRating(p, 9, [], 3).streakMult).toBe(1)
  })

  it('operators add rating points and money', () => {
    const b = calculateRating(solved3x3(), 9, [createOperator('counter'), createOperator('row_master'), createOperator('purist')], 0)
    // 5 kept × 10 + 3 rows × 50 + 300 purist
    expect(b.operatorScoreTotal).toBe(500)
    expect(b.operatorRatingBonus).toBe(10)
    expect(b.operatorDetails.map((d) => d.bonus)).toEqual([50, 150, 300])
    expect(b.grade).toBe('SS')
  })

  it('money operators count circled and deleted cells', () => {
    const p = solved3x3()
    p.circleCell(0, 1)
    p.circleCell(1, 1)
    const circ = calculateRating(p, 9, [createOperator('circlicious')], 0)
    expect(circ.operatorMoney).toBe(2 * 2 - 4)
    const elite = calculateRating(p, 9, [createOperator('elite_delete')], 0)
    expect(elite.operatorMoney).toBe(4 * 2 - 2)
    expect(elite.finalMoney).toBe(elite.baseMoney + 6)
  })

  it('never pays negative money', () => {
    const p = solved3x3()
    const b = calculateRating(p, 1000, [createOperator('circlicious')], 0)
    expect(b.baseMoney).toBe(0)
    expect(b.finalMoney).toBe(0)
  })
})

describe('config helpers', () => {
  it('grades', () => {
    expect(gradeFromRating(14)).toBe('SS')
    expect(gradeFromRating(11.9)).toBe('A')
    expect(gradeFromRating(5)).toBe('D')
  })
  it('time limits shrink per stage with a boss bonus and a floor', () => {
    expect(timeLimit(1, 0)).toBe(75)
    expect(timeLimit(1, 2)).toBe(90)
    expect(timeLimit(9, 0)).toBe(45)
  })
  it('interest is $1 per $5, capped at $5', () => {
    expect(interestFor(4)).toBe(0)
    expect(interestFor(12)).toBe(2)
    expect(interestFor(100)).toBe(5)
  })
})
