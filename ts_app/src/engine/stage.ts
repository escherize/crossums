/** Difficulty parameters for one puzzle of a run. */
export interface StageConfig {
  stage: number
  puzzleIndex: number
  gridSize: number
  scoreTarget: number
  minValue: number
  maxValue: number
}

/** Grid sizes per stage 1-9: ramp 3→6 with positives, then again 3→6 with negatives. */
const GRID_SIZES = [3, 3, 4, 5, 6, 3, 4, 5, 6]
const SCORE_TARGETS = [400, 600, 900, 1200, 1800, 2500, 3500, 5000, 7000]
const VALUE_RANGES: [number, number][] = [
  [1, 3],
  [1, 5],
  [1, 7],
  [1, 9],
  [1, 9],
  [-1, 9],
  [-2, 9],
  [-3, 9],
  [-3, 9],
]

export function stageConfig(stage: number, puzzleIndex: number): StageConfig {
  const i = Math.min(Math.max(stage - 1, 0), GRID_SIZES.length - 1)
  const [minValue, maxValue] = VALUE_RANGES[i]
  return { stage, puzzleIndex, gridSize: GRID_SIZES[i], scoreTarget: SCORE_TARGETS[i], minValue, maxValue }
}
