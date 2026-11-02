/** Seedable PRNG (mulberry32). Seeds are 32-bit; 0 means "pick a random seed". */
export type Rng = () => number

export function mulberry32(seed: number): Rng {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export function randomSeed(): number {
  return (Math.floor(Math.random() * 0xfffffffe) + 1) >>> 0
}

/** RNG for a seed; a seed of 0 draws a fresh random seed. Returns the seed actually used. */
export function seededRng(seed: number): { rng: Rng; seed: number } {
  const s = seed === 0 ? randomSeed() : seed >>> 0
  return { rng: mulberry32(s), seed: s }
}

/** Integer in [lo, hi] inclusive. */
export function randInt(rng: Rng, lo: number, hi: number): number {
  return lo + Math.floor(rng() * (hi - lo + 1))
}

export function randFloat(rng: Rng, lo: number, hi: number): number {
  return lo + rng() * (hi - lo)
}

export function shuffle<T>(rng: Rng, arr: T[]): T[] {
  const a = arr.slice()
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1))
    ;[a[i], a[j]] = [a[j], a[i]]
  }
  return a
}
