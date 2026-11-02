import { describe, expect, it } from 'vitest'
import { generateFallback, generateSingleSolution, hasSatisfiedTargetAtStart } from './generator'
import { mulberry32 } from './rng'
import { countSolutions } from './solver'

describe('generateSingleSolution', () => {
  it('is deterministic per seed', () => {
    const a = generateSingleSolution({ size: 4, rng: mulberry32(7) })
    const b = generateSingleSolution({ size: 4, rng: mulberry32(7) })
    expect(a.toJSON()).toEqual(b.toJSON())
    const c = generateSingleSolution({ size: 4, rng: mulberry32(8) })
    expect(c.toJSON()).not.toEqual(a.toJSON())
  })

  for (const size of [3, 4, 5, 6]) {
    it(`makes unique ${size}x${size} puzzles with no row or column solved at start`, () => {
      for (let seed = 1; seed <= 6; seed++) {
        const p = generateSingleSolution({ size, rng: mulberry32(seed) })
        expect(countSolutions(p, 3)).toBe(1)
        expect(hasSatisfiedTargetAtStart(p)).toBe(false)
        for (const row of p.cells) for (const c of row) expect(c.value).toBeGreaterThanOrEqual(1)
      }
    })
  }

  it('respects value ranges and never emits zero', () => {
    for (let seed = 1; seed <= 6; seed++) {
      const p = generateSingleSolution({ size: 5, rng: mulberry32(seed), minValue: -3, maxValue: 9 })
      expect(countSolutions(p, 3)).toBe(1)
      let negatives = 0
      for (const row of p.cells)
        for (const c of row) {
          expect(c.value).not.toBe(0)
          expect(c.value).toBeGreaterThanOrEqual(-3)
          expect(c.value).toBeLessThanOrEqual(9)
          if (c.value < 0) negatives++
        }
      expect(negatives).toBeGreaterThan(0)
    }
  })
})

describe('generateFallback', () => {
  it('is always solvable with at least one solution cell and one decoy per line', () => {
    for (let seed = 1; seed <= 10; seed++) {
      const p = generateFallback(4, mulberry32(seed), 1, 9)
      expect(countSolutions(p, 1)).toBe(1)
      for (let r = 0; r < 4; r++) expect(p.rowTargets[r]).toBeGreaterThan(0)
      expect(hasSatisfiedTargetAtStart(p)).toBe(false)
    }
  })
})
