/** Short effects keyed by game moment. Files live in public/sfx. */
const FILES = {
  click: 'click',
  restore: 'restore',
  ding: 'ding',
  fanfare: 'fanfare',
  mistake: 'mistake',
  timeout: 'life_lost',
  coinGain: 'coin_gain',
  coinSpend: 'coin_spend',
  multiplier: 'multiplier',
  button: 'button',
  menu: 'menu_open',
  tick: 'score_tick',
} as const

export type SoundName = keyof typeof FILES

const MUTE_KEY = 'crossums_muted'

class Sound {
  private cache = new Map<SoundName, HTMLAudioElement>()
  muted = false

  constructor() {
    try {
      this.muted = localStorage.getItem(MUTE_KEY) === '1'
    } catch {
      /* storage unavailable */
    }
  }

  setMuted(m: boolean): void {
    this.muted = m
    try {
      localStorage.setItem(MUTE_KEY, m ? '1' : '0')
    } catch {
      /* storage unavailable */
    }
  }

  play(name: SoundName, volume = 0.6): void {
    if (this.muted) return
    let a = this.cache.get(name)
    if (!a) {
      a = new Audio(`${import.meta.env.BASE_URL}sfx/${FILES[name]}.wav`)
      a.preload = 'auto'
      this.cache.set(name, a)
    }
    const clip = a.paused ? a : (a.cloneNode() as HTMLAudioElement)
    clip.volume = volume
    clip.currentTime = 0
    void clip.play().catch(() => undefined)
  }
}

export const sound = new Sound()
