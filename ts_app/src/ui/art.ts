import { el } from './dom'

export type Pose = 'neutral' | 'triumph' | 'worried'

const ARMS: Record<Pose, string> = {
  neutral: 'M50 46 L32 64 M50 46 L66 62',
  triumph: 'M50 46 L28 24 M50 46 L72 24',
  worried: 'M50 46 L36 22 M50 46 L64 22',
}

/** Instruction-manual stick figure. Neutral holds a part; triumph raises arms; worried clutches head. */
export function figure(pose: Pose = 'neutral', size = 96): HTMLElement {
  const extra =
    pose === 'neutral'
      ? `<rect x="60" y="54" width="18" height="18" rx="3" fill="#d4a574" stroke="#2b2b2b" stroke-width="2"/>
         <text x="69" y="68" font-family="Arial Rounded MT Bold, Avenir Next, sans-serif" font-size="12" font-weight="700" text-anchor="middle" fill="#2b2b2b">7</text>`
      : pose === 'worried'
        ? `<text x="78" y="18" font-family="Avenir Next, sans-serif" font-size="18" font-weight="700" fill="#c44536">?</text>`
        : `<path d="M20 20 l3 -6 M80 20 l-3 -6 M14 32 l-6 -2 M86 32 l6 -2" stroke="#ffc61e" stroke-width="3" stroke-linecap="round"/>`
  const mouth = pose === 'worried' ? 'M45 27 q5 -3 10 0' : pose === 'triumph' ? 'M44 25 q6 6 12 0' : 'M45 26 h10'
  const wrap = el('span.figure')
  wrap.innerHTML = `<svg viewBox="0 0 100 106" width="${size}" height="${Math.round(size * 1.06)}" aria-hidden="true" fill="none" stroke="#2b2b2b" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="50" cy="20" r="12" fill="#f5f5f0"/>
    <path d="${mouth}" stroke-width="2"/>
    <path d="M50 32 V70"/>
    <path d="${ARMS[pose]}"/>
    <path d="M50 70 L36 100 M50 70 L64 100"/>
    ${extra}
  </svg>`
  return wrap
}

/** Numbered circle, as on manual steps. */
export function stepNo(n: number | string): HTMLElement {
  return el('span.step-no', {}, n)
}
