import './style.css'
import { config, VERSION } from './engine/config'
import { Game, localSaveStorage, type Phase } from './engine/game'
import { createOperator } from './engine/operators'
import { findSolutions } from './engine/solver'
import { figure, stepNo } from './ui/art'
import { Board } from './ui/board'
import { celebrate, victoryShower } from './ui/confetti'
import { clear, clock, el, money } from './ui/dom'
import { ShopOverlay, gameOverOverlay, howToPlayOverlay, pauseOverlay, resultOverlay, victoryOverlay } from './ui/overlays'
import { sound } from './ui/sound'

const root = document.getElementById('app')!
const game = new Game({ storage: localSaveStorage() })

// ---- title -----------------------------------------------------------------

function showTitle(): void {
  clear(root)
  const overlayHost = el('div.overlay-host')
  const muteBtn = el('button.ghost', { type: 'button', 'aria-label': 'Toggle sound' }, sound.muted ? '🔇' : '🔊')
  muteBtn.onclick = () => {
    sound.setMuted(!sound.muted)
    muteBtn.textContent = sound.muted ? '🔇' : '🔊'
  }
  const begin = () => {
    sound.play('button')
    game.deleteSave()
    game.startRun()
    showGame()
  }
  const hasSave = game.hasSave()
  root.append(
    el(
      'div.screen.title',
      {},
      el(
        'div.cover.manual',
        {},
        figure('neutral', 110),
        el('h1', {}, 'Sum Assembly', el('br'), 'Required'),
        el('div.rule'),
        el('p.tagline', {}, `Flat-pack number puzzles · v${VERSION}`),
        el(
          'div.menu',
          {},
          hasSave ? el('button.primary', { type: 'button', onclick: () => game.load() && showGame() }, 'Resume assembly') : null,
          el('button.primary', { type: 'button', onclick: begin }, hasSave ? 'New assembly' : 'Begin assembly'),
          el(
            'button',
            {
              type: 'button',
              onclick: () => {
                sound.play('menu')
                overlayHost.replaceChildren(howToPlayOverlay(() => clear(overlayHost)))
              },
            },
            'Instructions',
          ),
        ),
        muteBtn,
      ),
      overlayHost,
    ),
  )
}

// ---- game ------------------------------------------------------------------

function showGame(): void {
  clear(root)
  const stepLabel = stepNo('')
  const partLabel = el('b')
  const scoreLabel = el('b')
  const moneyLabel = el('b')
  const timerLabel = el('span.timer-label')
  const timerFill = el('div.timer-fill')
  const ops = el('div.ops')
  const status = el('div.status')
  const overlayHost = el('div.overlay-host')
  const undoBtn = el<'button'>('button', { type: 'button' }, 'Undo')
  const pauseBtn = el<'button'>('button', { type: 'button' }, 'Pause')
  const circleBtn = el<'button'>('button.circle-mode', { type: 'button', 'aria-label': 'Hold to circle' }, '○')

  const timers = new Set<ReturnType<typeof setTimeout>>()
  const later = (fn: () => void, ms: number) => {
    const t = setTimeout(() => {
      timers.delete(t)
      fn()
    }, ms)
    timers.add(t)
  }
  const say = (text: string, bad = false) => {
    status.textContent = text
    status.classList.toggle('bad', bad)
  }

  let mistakeJustNow = false
  const board = new Board(game, {
    tap(r, c) {
      const before = game.puzzle?.state(r, c)
      mistakeJustNow = false
      game.tap(r, c)
      const after = game.puzzle?.state(r, c)
      if (before === after || mistakeJustNow) return
      sound.play(after === 'deleted' ? 'click' : 'restore')
      if (after === 'active') say('Changed your mind. That counts as a misstep.')
    },
    circle(r, c) {
      const before = game.puzzle?.state(r, c)
      mistakeJustNow = false
      game.circle(r, c)
      if (game.puzzle?.state(r, c) !== before && !mistakeJustNow) sound.play('ding', 0.4)
    },
  })

  undoBtn.onclick = () => {
    const r = game.undo()
    if (r) {
      sound.play('restore')
      say(r.batchesUndone === 1 ? `Undid ${r.totalCells} part(s)` : `Undid ${r.totalCells} part(s) across ${r.batchesUndone} actions`)
    }
  }
  pauseBtn.onclick = () => game.pause()

  // Hold-to-circle button. Pointer events are per finger, so a second finger can tap cells meanwhile.
  const circleOn = (e: PointerEvent) => {
    e.preventDefault()
    game.circleMode = true
    circleBtn.classList.add('active')
    circleBtn.textContent = '◉'
    board.update()
  }
  const circleOff = () => {
    if (!game.circleMode) return
    game.circleMode = false
    circleBtn.classList.remove('active')
    circleBtn.textContent = '○'
    board.update()
  }
  circleBtn.addEventListener('pointerdown', circleOn)
  circleBtn.addEventListener('pointerup', circleOff)
  circleBtn.addEventListener('pointercancel', circleOff)
  circleBtn.addEventListener('pointerleave', circleOff)
  circleBtn.addEventListener('contextmenu', (e) => e.preventDefault())

  root.append(
    el(
      'div.screen.game',
      {},
      el(
        'header.hud.manual',
        {},
        el(
          'div.hud-row',
          {},
          el('span.step', {}, stepLabel, 'Steg'),
          el('span.hud-stat', {}, partLabel),
          el('span.hud-spacer'),
          el('span.hud-stat.hud-money', {}, moneyLabel),
          el('span.hud-stat', {}, 'Poäng ', scoreLabel),
        ),
        el('div.timer', {}, el('div.timer-bar', {}, timerFill), timerLabel),
      ),
      ops,
      el('main.board-host', {}, board.el),
      status,
      el('footer.controls', {}, undoBtn, circleBtn, pauseBtn),
      overlayHost,
    ),
  )

  // Operator chips. Rebuilt when the owned set changes; each can flash with a floating label.
  const chips = new Map<string, HTMLElement>()
  let opsKey: string | null = null
  const renderOps = () => {
    const key = game.operators.map((o) => o.id).join(',')
    if (key === opsKey) return
    opsKey = key
    clear(ops)
    chips.clear()
    for (const op of game.operators) {
      const chip = el(`div.chip.rarity-${op.rarity}`, { title: op.description, onclick: () => say(`${op.name}: ${op.description}`) }, op.name)
      chips.set(op.id, chip)
      ops.appendChild(chip)
    }
  }
  const fireChip = (id: string, text: string) => {
    const chip = chips.get(id)
    if (!chip) return
    chip.classList.remove('fire')
    void chip.offsetWidth
    chip.classList.add('fire')
    const f = el('span.float', {}, text)
    chip.appendChild(f)
    later(() => f.remove(), 1000)
  }

  let shownPhase: Phase | null = null
  let shownPaused = false
  let shop: ShopOverlay | null = null
  let stopShower: (() => void) | null = null
  let pendingTriggers: { id: string; bonus: number }[] = []

  const refreshHud = () => {
    const run = game.run
    if (!run) return
    stepLabel.textContent = String(run.stage)
    partLabel.textContent = `${run.puzzleIndex + 1} / ${config.puzzlesPerStage}`
    moneyLabel.textContent = money(run.money)
    scoreLabel.textContent = run.totalScore.toLocaleString()
    undoBtn.disabled = !game.canAct || !game.puzzle?.canUndo
    pauseBtn.disabled = !game.canAct
  }

  const refreshTimer = () => {
    const remaining = game.timeRemaining()
    const progress = Math.min(remaining / 120, 1)
    timerFill.style.width = `${progress * 100}%`
    timerFill.classList.toggle('low', progress < 0.3)
    timerLabel.textContent = clock(remaining)
  }

  const toTitle = () => {
    game.returnToTitle()
    showTitle()
  }

  const syncOverlay = () => {
    const phase = game.phase
    if (phase === shownPhase && game.paused === shownPaused) return
    shownPhase = phase
    shownPaused = game.paused
    shop = null
    stopShower?.()
    stopShower = null
    clear(overlayHost)
    board.el.classList.toggle('hidden', game.paused)
    switch (phase) {
      case 'puzzle':
        if (game.paused) overlayHost.appendChild(pauseOverlay(() => game.resume(), toTitle))
        else say('Remove parts until every row and column adds up.')
        break
      case 'result': {
        // Show each scoring trigger on its chip before the result page appears.
        const triggers = pendingTriggers
        pendingTriggers = []
        const b = game.lastBreakdown!
        const gapMs = 380
        triggers.forEach((t, i) =>
          later(() => {
            sound.play('multiplier', 0.5)
            fireChip(t.id, `+${t.bonus}`)
          }, 150 + i * gapMs),
        )
        later(
          () => {
            sound.play('fanfare')
            celebrate(b.grade)
            overlayHost.appendChild(resultOverlay(b, () => game.continueFromResult()))
          },
          triggers.length ? 150 + triggers.length * gapMs + 250 : 350,
        )
        break
      }
      case 'shop':
        sound.play('menu')
        shop = new ShopOverlay(game, {
          buy: (i) => game.shopBuy(i) && sound.play('coinSpend'),
          sell: (i) => game.shopSell(i) && sound.play('coinGain'),
          reroll: () => game.shopReroll() && sound.play('coinSpend'),
          buyTime: () => game.shopBuyTime() && sound.play('coinSpend'),
          done: () => game.continueFromShop(),
        })
        overlayHost.appendChild(shop.el)
        break
      case 'gameOver':
        sound.play('timeout')
        overlayHost.appendChild(gameOverOverlay(game.run?.totalScore ?? 0, game.stagesCleared, () => game.startRun(), toTitle))
        break
      case 'victory':
        sound.play('fanfare')
        stopShower = victoryShower()
        overlayHost.appendChild(victoryOverlay(game.run?.totalScore ?? 0, () => game.startRun(), toTitle))
        break
      case 'idle':
        showTitle()
        break
    }
  }

  const onChange = () => {
    board.update()
    renderOps()
    refreshHud()
    syncOverlay()
    shop?.update()
  }
  const unsubs = [
    game.on('change', onChange),
    game.on('autoAction', (a) => {
      sound.play('multiplier', 0.5)
      fireChip(a.operatorId, `${a.type === 'delete' ? '−' : '○'}${a.cells.length}`)
      const name = game.operators.find((o) => o.id === a.operatorId)?.name ?? a.operatorId
      say(`${name} ${a.type === 'delete' ? 'removed' : 'circled'} ${a.cells.length} part(s)`)
      undoBtn.classList.remove('pulse')
      void undoBtn.offsetWidth
      undoBtn.classList.add('pulse')
    }),
    game.on('operatorTriggered', (t) => {
      if (t.bonus) pendingTriggers.push(t)
    }),
    game.on('mistake', (m) => {
      mistakeJustNow = true
      sound.play('mistake')
      board.flashWrong(m.row, m.col)
      board.shake()
      say(m.kind === 'delete' ? 'That part was needed. Undo to get it back.' : 'That part is not in the solution. Tap it to uncircle.', true)
    }),
    game.on('solved', (b) => {
      say(`Solved in ${b.timeUsed.toFixed(1)}s (${b.pace.toFixed(1)}s per part)`)
    }),
  ]

  const onKey = (e: KeyboardEvent) => {
    if (e.key === 'u' || e.key === 'z') undoBtn.click()
    else if (e.key === 'p') game.paused ? game.resume() : game.pause()
    else if (e.key === 'Escape' && game.paused) game.resume()
  }
  window.addEventListener('keydown', onKey)
  const onHide = () => document.hidden && game.pause()
  document.addEventListener('visibilitychange', onHide)

  let raf = 0
  const loop = () => {
    if (!root.contains(board.el)) {
      cancelAnimationFrame(raf)
      unsubs.forEach((u) => u())
      timers.forEach((t) => clearTimeout(t))
      window.removeEventListener('keydown', onKey)
      document.removeEventListener('visibilitychange', onHide)
      return
    }
    game.tick()
    refreshTimer()
    raf = requestAnimationFrame(loop)
  }
  onChange()
  refreshTimer()
  raf = requestAnimationFrame(loop)
}

/** Debug hook for tooling and tests: window.crossums.game, solve(), addOperator(id). */
Object.assign(window, {
  crossums: {
    game,
    addOperator(id: string): boolean {
      return game.addOperator(createOperator(id))
    },
    /** Delete every cell outside the solution of the live puzzle. */
    solve(): void {
      const p = game.puzzle
      if (!p) return
      const keep = new Set(findSolutions(p, 1)[0]?.map((q) => `${q.row},${q.col}`) ?? [])
      for (let r = 0; r < p.rows; r++) for (let c = 0; c < p.cols; c++) if (!keep.has(`${r},${c}`) && p.state(r, c) === 'active') game.tap(r, c)
    },
  },
})

showTitle()
