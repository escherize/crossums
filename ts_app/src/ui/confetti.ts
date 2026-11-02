import confetti from 'canvas-confetti'
import type { Grade } from '../engine/config'

const SCALE: Record<Grade, number> = { D: 0.3, C: 0.5, B: 0.8, A: 1, S: 1.4, SS: 2 }
const COLORS = ['#f1c27a', '#d99a1e', '#137a2d', '#1f6d80', '#f3e9d6']

/** One burst from the bottom of the screen, bigger for better grades. */
export function celebrate(grade: Grade): void {
  const scale = SCALE[grade]
  void confetti({
    particleCount: Math.round(90 * scale),
    spread: 70 + 20 * scale,
    startVelocity: 45,
    origin: { y: 0.75 },
    colors: COLORS,
    disableForReducedMotion: true,
  })
  if (scale >= 1.4)
    setTimeout(() => {
      void confetti({ particleCount: 60, angle: 60, spread: 60, origin: { x: 0, y: 0.7 }, colors: COLORS, disableForReducedMotion: true })
      void confetti({ particleCount: 60, angle: 120, spread: 60, origin: { x: 1, y: 0.7 }, colors: COLORS, disableForReducedMotion: true })
    }, 250)
}

/** Side cannons for a few seconds. Returns a function that stops them early. */
export function victoryShower(durationMs = 4000): () => void {
  const end = Date.now() + durationMs
  let stopped = false
  const frame = () => {
    if (stopped) return
    void confetti({ particleCount: 5, angle: 60, spread: 55, origin: { x: 0, y: 0.7 }, colors: COLORS, disableForReducedMotion: true })
    void confetti({ particleCount: 5, angle: 120, spread: 55, origin: { x: 1, y: 0.7 }, colors: COLORS, disableForReducedMotion: true })
    if (Date.now() < end) requestAnimationFrame(frame)
  }
  frame()
  return () => {
    stopped = true
    confetti.reset()
  }
}
