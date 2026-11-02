import { config } from '../engine/config'
import type { Game } from '../engine/game'
import type { Operator } from '../engine/operators'
import type { RatingBreakdown } from '../engine/scoring'
import { figure, stepNo } from './art'
import { clear, clock, el, money } from './dom'
import { sound } from './sound'

const RARITY = ['Common', 'Uncommon', 'Rare', 'Legendary']

function panel(title: string, ...children: (Node | string)[]): HTMLElement {
  return el('div.overlay', {}, el('div.panel.manual', {}, el('h2', {}, title), ...children))
}

function paceStars(pace: number): string {
  if (pace <= 1) return '★★★★★'
  if (pace <= 2) return '★★★★'
  if (pace <= 3) return '★★★'
  if (pace <= 5) return '★★'
  return '★'
}

const f1 = (n: number) => n.toFixed(1)

const reducedMotion = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false

/** Count `node` from 0 to `to` over `ms`, ticking as it goes. */
function countUp(node: HTMLElement, to: number, ms: number, delay: number): void {
  const show = (v: number) => (node.textContent = `+${money(v)}`)
  if (reducedMotion() || to === 0) {
    show(to)
    return
  }
  show(0)
  setTimeout(() => {
    const start = performance.now()
    let shown = 0
    let lastTick = 0
    const step = (t: number) => {
      const k = Math.min(1, (t - start) / ms)
      const v = Math.round(to * (1 - (1 - k) ** 2))
      if (v !== shown) {
        shown = v
        show(v)
        if (t - lastTick > 55) {
          lastTick = t
          sound.play('tick', 0.25)
        }
      }
      if (k < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }, delay)
}

export function resultOverlay(b: RatingBreakdown, onContinue: () => void): HTMLElement {
  const lines: HTMLElement[] = []
  const line = (text: string, cls = '') => lines.push(el(`div.line.reveal${cls ? '.' + cls : ''}`, {}, text))
  line(`Pace: ${b.pace.toFixed(2)} sec/part  ${paceStars(b.pace)}`)
  line(`Rating: ${f1(b.paceRating)}`)
  if (b.misstepCount > 0) line(`${b.misstepCount} misstep${b.misstepCount > 1 ? 's' : ''}`, 'bad')
  if (b.cleanBonus > 0) line(`Clean bonus: + ${f1(b.cleanBonus)}`, 'good')
  for (const d of b.operatorDetails) {
    if (d.bonus) line(`${d.name}: + ${f1(d.bonus / config.operatorRatingDivisor)}`, 'op')
    if (d.money) line(`${d.name}: ${d.money > 0 ? '+' : ''}${money(d.money)}`, 'op')
  }
  const parts = [f1(b.paceRating)]
  if (b.cleanBonus > 0) parts.push(f1(b.cleanBonus))
  if (b.operatorRatingBonus > 0) parts.push(f1(b.operatorRatingBonus))
  line(`${parts.join(' + ')} = ${f1(b.totalRating)}`, 'formula')
  line(`round(${f1(b.totalRating)}³ / ${config.moneyDivisor}) = ${money(b.baseMoney)}`, 'formula')

  const stepMs = 110
  lines.forEach((l, i) => (l.style.animationDelay = `${200 + i * stepMs}ms`))
  const moneyAt = 200 + lines.length * stepMs + 100

  const streakBroken = b.misstepCount >= config.streakMisstepThreshold
  const reward = streakBroken
    ? el('div.reward.bad.reveal', {}, 'Streak broken!')
    : b.streakMult > 1
      ? el('div.reward.streak.reveal', {}, `${money(b.baseMoney)} × ${f1(b.streakMult)} ${'🔥'.repeat(Math.min(b.streak, 5))}`)
      : null
  if (reward) reward.style.animationDelay = `${moneyAt + 650}ms`

  const big = el(`div.big-money.reveal.grade-${b.grade.toLowerCase()}`)
  big.style.animationDelay = `${moneyAt}ms`
  countUp(big, b.finalMoney, 650, moneyAt)

  const btn = el('button.primary.reveal', { type: 'button', onclick: onContinue }, 'Continue')
  btn.style.animationDelay = `${moneyAt + 500}ms`

  return panel(
    'Slutförd ✓',
    el(`div.grade.grade-${b.grade.toLowerCase()}`, {}, b.grade),
    el('div.breakdown', {}, ...lines),
    big,
    reward ?? '',
    btn,
  )
}

export interface ShopHandlers {
  buy(i: number): void
  sell(i: number): void
  reroll(): void
  buyTime(): void
  done(): void
}

/** Shop between steps. Call update() after any game change while it is open. */
export class ShopOverlay {
  readonly el: HTMLElement
  private body: HTMLElement

  constructor(
    private game: Game,
    private h: ShopHandlers,
  ) {
    this.body = el('div.shop-body')
    this.el = panel(`Shop · Steg ${game.run?.stage ?? 1}`, this.body)
    this.update()
  }

  update(): void {
    const g = this.game
    const run = g.run!
    clear(this.body)
    this.body.append(
      el('div.shop-stats', {}, el('span.money', {}, money(run.money)), el('span', {}, `Time bank ${clock(run.timePool)}`)),
      el('h3', {}, 'For sale'),
      el('div.cards', {}, ...g.shop.slots.map((op, i) => this.card(op, i))),
      el('h3', {}, `Your operators (${g.operators.length}/${config.maxOperators})`),
      el(
        'div.cards.owned',
        {},
        ...(g.operators.length
          ? g.operators.map((op, i) =>
              el(
                `div.card.rarity-${op.rarity}`,
                {},
                el('div.card-rarity', {}, RARITY[op.rarity]),
                el('div.card-name', {}, op.name),
                el('div.card-desc', {}, op.description),
                el('button', { type: 'button', onclick: () => this.h.sell(i) }, `Sell ${money(Math.floor(op.price / 2))}`),
              ),
            )
          : [el('div.empty', {}, 'None yet')]),
      ),
      el(
        'div.shop-actions',
        {},
        el('button', { type: 'button', disabled: !g.canReroll, onclick: () => this.h.reroll() }, `Reroll (${money(g.shop.rerollCost)})`),
        el('button', { type: 'button', disabled: !g.canBuyTime, onclick: () => this.h.buyTime() }, `+${config.timePurchaseAmount}s time (${money(g.timePrice)})`),
        el('button.primary', { type: 'button', onclick: () => this.h.done() }, 'Next step'),
      ),
    )
  }

  private card(op: Operator | null, i: number): HTMLElement {
    if (!op) return el('div.card.sold', {}, el('div.card-name', {}, 'Sold'))
    return el(
      `div.card.rarity-${op.rarity}`,
      {},
      el('div.card-rarity', {}, RARITY[op.rarity]),
      el('div.card-name', {}, op.name),
      el('div.card-desc', {}, op.description),
      el('button.primary', { type: 'button', disabled: !this.game.canBuy(i), onclick: () => this.h.buy(i) }, `Buy ${money(op.price)}`),
    )
  }
}

export function gameOverOverlay(totalScore: number, stagesCleared: number, onRetry: () => void, onTitle: () => void): HTMLElement {
  return panel(
    'Out of time',
    figure('worried', 80),
    el('p.sub', {}, 'The clock ran out mid-assembly.'),
    el('p', {}, `Poäng: ${totalScore}`),
    el('p', {}, `Steps completed: ${stagesCleared} / ${config.finalStage}`),
    el('div.row', {}, el('button.primary', { type: 'button', onclick: onRetry }, 'Try again'), el('button', { type: 'button', onclick: onTitle }, 'Title')),
  )
}

export function victoryOverlay(totalScore: number, onAgain: () => void, onTitle: () => void): HTMLElement {
  return panel(
    'Klar!',
    figure('triumph', 80),
    el('p.sub', {}, `All ${config.finalStage} steps completed. It somehow works.`),
    el('p', {}, `Poäng: ${totalScore}`),
    el('div.row', {}, el('button.primary', { type: 'button', onclick: onAgain }, 'Build again'), el('button', { type: 'button', onclick: onTitle }, 'Title')),
  )
}

export function pauseOverlay(onResume: () => void, onQuit: () => void): HTMLElement {
  return panel(
    'Paus',
    el('p.sub', {}, 'The clock is stopped. The board is hidden so pausing is not thinking time.'),
    el('div.row', {}, el('button.primary', { type: 'button', onclick: onResume }, 'Resume'), el('button', { type: 'button', onclick: onQuit }, 'Quit to title')),
  )
}

export function howToPlayOverlay(onClose: () => void): HTMLElement {
  const step = (n: number, title: string, body: string) => el('li', {}, stepNo(n), el('div', {}, el('b', {}, title), body))
  return panel(
    'Instructions',
    el(
      'ol.steps',
      {},
      step(1, 'Remove parts', 'Tap a part to remove it. Every row and column must add up to the target on its paper strip. All strips green finishes the step.'),
      step(2, 'Hold to circle', 'Hold a part, or right-click it, to circle one you are sure stays. Circled parts alone can also finish a step. On touch screens, hold ○ and tap.'),
      step(3, 'Changing your mind costs', 'Putting a part back, uncircling, or undo is a misstep. Missteps lower your rating and break your streak.'),
      step(4, 'One clock for the whole build', 'Each puzzle adds time to a shared pool. When the pool is empty the assembly stops.'),
      step(5, 'Rating → money → operators', 'Faster, cleaner solves earn a higher rating. Rating cubed is money. Spend it between steps on operators that change how you score.'),
    ),
    el('p.sub', {}, `${config.finalStage} steps × ${config.puzzlesPerStage} puzzles. Grids grow from 3×3 to 6×6, then negative parts arrive.`),
    el('button.primary', { type: 'button', onclick: onClose }, 'Got it'),
  )
}
