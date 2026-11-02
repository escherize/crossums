import './style.css'
import { config } from './engine/config'
import { VERSION } from './engine/config'
import { Game, localSaveStorage, type Phase } from './engine/game'
import { Board } from './ui/board'
import { clear, clock, el, money } from './ui/dom'
import { ShopOverlay, gameOverOverlay, howToPlayOverlay, pauseOverlay, resultOverlay, victoryOverlay } from './ui/overlays'
import { sound } from './ui/sound'
import { celebrate, victoryShower } from './ui/confetti'
import { findSolutions } from './engine/solver'

const root = document.getElementById('app')!
const game = new Game({ storage: localSaveStorage() })

// ---- title -----------------------------------------------------------------

function showTitle(): void {
  clear(root)
  const overlayHost = el('div.overlay-host')
  const muteBtn = el('button.ghost', { type: 'button' }, sound.muted ? '🔇' : '🔊')
  muteBtn.onclick = () => {
    sound.setMuted(!sound.muted)
    muteBtn.textContent = sound.muted ? '🔇' : '🔊'
  }
  root.append(
    el(
      'div.screen.title',
      {},
      el('h1', {}, 'Crossums'),
      el('p.tagline', {}, `A number puzzle roguelike · v${VERSION}`),
      el(
        'div.menu',
        {},
        game.hasSave()
          ? el('button.primary', { type: 'button', onclick: () => game.load() && showGame() }, 'Continue run')
          : null,
        el(
          'button.primary',
          { type: 'button', onclick: () => {
            sound.play('button')
            game.deleteSave()
            game.startRun()
            showGame()
          } },
          'Start run',
        ),
        el('button', { type: 'button', onclick: () => {
          sound.play('menu')
          overlayHost.replaceChildren(howToPlayOverlay(() => clear(overlayHost)))
        } }, 'How to play'),
      ),
      el('div.title-footer', {}, muteBtn),
      overlayHost,
    ),
  )
}

// ---- game ------------------------------------------------------------------

function showGame(): void {
  clear(root)
  const stageLabel = el('span.hud-stage')
  const puzzleLabel = el('span.hud-puzzle')
  const moneyLabel = el('span.hud-money')
  const scoreLabel = el('span.hud-score')
  const timerLabel = el('span.timer-label')
  const timerFill = el('div.timer-fill')
  const status = el('div.status')
  const overlayHost = el('div.overlay-host')
  const undoBtn = el<'button'>('button', { type: 'button' }, 'Undo')
  const pauseBtn = el<'button'>('button', { type: 'button' }, 'Pause')
  const circleBtn = el<'button'>('button.circle-mode', { type: 'button', 'aria-label': 'Hold to circle' }, '○')

  const board = new Board(game, {
    tap(r, c) {
      const before = game.puzzle?.state(r, c)
      game.tap(r, c)
      const after = game.puzzle?.state(r, c)
      if (before === after) return
      sound.play(after === 'deleted' ? 'click' : 'restore')
      if (after === 'active') status.textContent = 'Changed your mind. That counts as a misstep.'
    },
    circle(r, c) {
      const before = game.puzzle?.state(r, c)
      game.circle(r, c)
      if (game.puzzle?.state(r, c) !== before) sound.play('ding', 0.4)
    },
  })

  undoBtn.onclick = () => {
    const r = game.undo()
    if (r) {
      sound.play('restore')
      status.textContent = r.batchesUndone === 1 ? `Undid ${r.totalCells} cell(s)` : `Undid ${r.totalCells} cell(s) across ${r.batchesUndone} actions`
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
        'header.hud',
        {},
        el('div.hud-row', {}, stageLabel, puzzleLabel, moneyLabel, scoreLabel),
        el('div.timer', {}, el('div.timer-bar', {}, timerFill), timerLabel),
      ),
      el('main.board-host', {}, board.el),
      status,
      el('footer.controls', {}, undoBtn, circleBtn, pauseBtn),
      overlayHost,
    ),
  )

  let shownPhase: Phase | null = null
  let shownPaused = false
  let shop: ShopOverlay | null = null
  let stopShower: (() => void) | null = null

  const refreshHud = () => {
    const run = game.run
    if (!run) return
    stageLabel.textContent = `Stage ${run.stage}`
    puzzleLabel.textContent = `Puzzle ${run.puzzleIndex + 1}/${config.puzzlesPerStage}`
    moneyLabel.textContent = money(run.money)
    scoreLabel.textContent = `Score ${run.totalScore}`
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
    /** Debug hook for tooling and tests: window.crossums.game, window.crossums.solve(). */
Object.assign(window, {
  crossums: {
    game,
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
        else status.textContent = 'Delete cells to match the row and column targets.'
        break
      case 'result':
        sound.play('fanfare')
        celebrate(game.lastBreakdown!.grade)
        overlayHost.appendChild(resultOverlay(game.lastBreakdown!, () => game.continueFromResult()))
        break
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
        /** Debug hook for tooling and tests: window.crossums.game, window.crossums.solve(). */
Object.assign(window, {
  crossums: {
    game,
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
    }
  }

  const onChange = () => {
    board.update()
    refreshHud()
    syncOverlay()
    shop?.update()
  }
  const unsubs = [
    game.on('change', onChange),
    game.on('autoAction', (a) => {
      sound.play('multiplier', 0.5)
      status.textContent = `${a.operatorId.replace('_', ' ')} ${a.type === 'delete' ? 'deleted' : 'circled'} ${a.cells.length} cell(s)`
      undoBtn.classList.remove('pulse')
      void undoBtn.offsetWidth
      undoBtn.classList.add('pulse')
    }),
    game.on('solved', (b) => {
      status.textContent = `Solved in ${b.timeUsed.toFixed(1)}s (${b.pace.toFixed(1)}s/cell)`
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

/** Debug hook for tooling and tests: window.crossums.game, window.crossums.solve(). */
Object.assign(window, {
  crossums: {
    game,
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
