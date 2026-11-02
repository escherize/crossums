import { config } from '../engine/config'
import type { Game } from '../engine/game'
import type { Operator } from '../engine/operators'
import type { RatingBreakdown } from '../engine/scoring'
import { clear, clock, el, money } from './dom'

const RARITY = ['Common', 'Uncommon', 'Rare', 'Legendary']

function panel(title: string, ...children: (Node | string)[]): HTMLElement {
  return el('div.overlay', {}, el('div.panel', {}, el('h2', {}, title), ...children))
}

function paceStars(pace: number): string {
  if (pace <= 1) return '★★★★★'
  if (pace <= 2) return '★★★★'
  if (pace <= 3) return '★★★'
  if (pace <= 5) return '★★'
  return '★'
}

const f1 = (n: number) => n.toFixed(1)

export function resultOverlay(b: RatingBreakdown, onContinue: () => void): HTMLElement {
  const lines: HTMLElement[] = []
  const line = (text: string, cls = '') => lines.push(el(`div.line${cls ? '.' + cls : ''}`, {}, text))
  line(`Pace: ${b.pace.toFixed(2)} sec/cell  ${paceStars(b.pace)}`)
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

  const streakBroken = b.misstepCount >= config.streakMisstepThreshold
  const reward =
    streakBroken
      ? el('div.reward.bad', {}, 'Streak broken!')
      : b.streakMult > 1
        ? el('div.reward.streak', {}, `${money(b.baseMoney)} × ${f1(b.streakMult)} ${'🔥'.repeat(Math.min(b.streak, 5))}`)
        : null

  return panel(
    'Solved!',
    el(`div.grade.grade-${b.grade.toLowerCase()}`, {}, b.grade),
    el('div.breakdown', {}, ...lines),
    el(`div.big-money.grade-${b.grade.toLowerCase()}`, {}, `+${money(b.finalMoney)}`),
    reward ?? '',
    el('button.primary', { type: 'button', onclick: onContinue }, 'Continue'),
  )
}

export interface ShopHandlers {
  buy(i: number): void
  sell(i: number): void
  reroll(): void
  buyTime(): void
  done(): void
}

/** Shop between stages. Call update() after any game change while it is open. */
export class ShopOverlay {
  readonly el: HTMLElement
  private body: HTMLElement

  constructor(
    private game: Game,
    private h: ShopHandlers,
  ) {
    this.body = el('div.shop-body')
    this.el = panel(`Shop · Stage ${game.run?.stage ?? 1}`, this.body)
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
                'div.card',
                {},
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
        el('button.primary', { type: 'button', onclick: () => this.h.done() }, 'Next stage'),
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
    'Game Over',
    el('p.sub', {}, "Time's up!"),
    el('p', {}, `Final score: ${totalScore}`),
    el('p', {}, `Stages cleared: ${stagesCleared} / ${config.finalStage}`),
    el('div.row', {}, el('button.primary', { type: 'button', onclick: onRetry }, 'Try again'), el('button', { type: 'button', onclick: onTitle }, 'Title')),
  )
}

export function victoryOverlay(totalScore: number, onAgain: () => void, onTitle: () => void): HTMLElement {
  return panel(
    'Victory!',
    el('p.sub', {}, `All ${config.finalStage} stages cleared`),
    el('p', {}, `Final score: ${totalScore}`),
    el('div.row', {}, el('button.primary', { type: 'button', onclick: onAgain }, 'Play again'), el('button', { type: 'button', onclick: onTitle }, 'Title')),
  )
}

export function pauseOverlay(onResume: () => void, onQuit: () => void): HTMLElement {
  return panel(
    'Paused',
    el('p.sub', {}, 'The clock is stopped. The board is hidden so pausing is not thinking time.'),
    el('div.row', {}, el('button.primary', { type: 'button', onclick: onResume }, 'Resume'), el('button', { type: 'button', onclick: onQuit }, 'Quit to title')),
  )
}

export function howToPlayOverlay(onClose: () => void): HTMLElement {
  return panel(
    'How to play',
    el('p', {}, 'Delete cells so every row and column adds up to its target. All targets green wins.'),
    el('ul', {}, el('li', {}, el('b', {}, 'Tap'), ' a cell to delete it. Tap again to restore it.'), el('li', {}, el('b', {}, 'Hold'), ' (or right-click) to circle a cell you are sure stays. Circled cells alone can also win.'), el('li', {}, el('b', {}, 'Undo'), ' takes back your last move. Restores, uncircles and undos are missteps.')),
    el('p', {}, 'The clock is one shared pool for the whole run. Each puzzle adds time; when the pool is empty the run ends.'),
    el('p', {}, 'Faster solves with fewer missteps earn a higher rating. Rating cubed is money. Spend it in the shop on operators that change how you score.'),
    el('p', {}, `${config.finalStage} stages × ${config.puzzlesPerStage} puzzles. Grids grow from 3×3 to 6×6, then negatives arrive.`),
    el('button.primary', { type: 'button', onclick: onClose }, 'Got it'),
  )
}
