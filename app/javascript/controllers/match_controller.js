import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["complete", "timer", "pairsLeft", "streak",
                    "progressFill", "progressLabel", "matchedCounter"]
  static values  = { total: Number }

  connect() {
    this.selected      = null
    this.matched       = 0
    this.streak        = 0
    this.seconds       = 0
    this.isProcessing  = false
    this.timerInterval = setInterval(() => this.#tickTimer(), 1000)
    this.#updateStats()
  }

  disconnect() {
    clearInterval(this.timerInterval)
  }

  select(event) {
    if (this.isProcessing) return
    const tile = event.currentTarget
    if (tile.classList.contains("is-matched") || tile.classList.contains("is-wrong")) return

    if (!this.selected) {
      this.selected = tile
      tile.classList.add("is-selected")
      return
    }

    if (this.selected === tile) {
      tile.classList.remove("is-selected")
      this.selected = null
      return
    }

    const sameId   = tile.dataset.matchId   === this.selected.dataset.matchId
    const diffSide = tile.dataset.matchSide !== this.selected.dataset.matchSide

    if (sameId && diffSide) {
      this.selected.classList.remove("is-selected")
      this.selected.classList.add("is-matched")
      tile.classList.add("is-matched")
      this.selected = null
      this.matched += 1
      this.streak  += 1
      this.#updateStats()

      if (this.matched >= this.totalValue) {
        clearInterval(this.timerInterval)
        this.completeTarget.hidden = false
      }
    } else {
      const prev = this.selected
      prev.classList.remove("is-selected")
      prev.classList.add("is-wrong")
      tile.classList.add("is-wrong")
      this.selected     = null
      this.streak       = 0
      this.isProcessing = true
      this.#updateStats()

      setTimeout(() => {
        prev.classList.remove("is-wrong")
        tile.classList.remove("is-wrong")
        this.isProcessing = false
      }, 700)
    }
  }

  #tickTimer() {
    this.seconds += 1
    if (!this.hasTimerTarget) return
    const m = String(Math.floor(this.seconds / 60)).padStart(2, "0")
    const s = String(this.seconds % 60).padStart(2, "0")
    this.timerTarget.textContent = `${m}:${s}`
  }

  #updateStats() {
    const pairsLeft = this.totalValue - this.matched
    const pct = this.totalValue > 0
      ? Math.round((this.matched / this.totalValue) * 100) : 0

    if (this.hasPairsLeftTarget) this.pairsLeftTarget.textContent = pairsLeft
    if (this.hasStreakTarget)    this.streakTarget.textContent    = this.streak

    if (this.hasProgressFillTarget)
      this.progressFillTarget.style.width = `${pct}%`

    if (this.hasProgressLabelTarget) {
      const tmpl = this.progressLabelTarget.dataset.template || ""
      this.progressLabelTarget.textContent = tmpl.replace("__PCT__", pct)
    }

    if (this.hasMatchedCounterTarget) {
      const tmpl = this.matchedCounterTarget.dataset.template || ""
      this.matchedCounterTarget.textContent = tmpl.replace("__MATCHED__", this.matched)
    }
  }
}
