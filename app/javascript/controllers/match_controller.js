import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["complete"]
  static values = { total: Number }

  connect() {
    this.selected = null
    this.matched = 0
  }

  select(event) {
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
      this.matched += 2

      if (this.matched >= this.totalValue * 2) {
        this.completeTarget.hidden = false
      }
    } else {
      const prev = this.selected
      prev.classList.remove("is-selected")
      prev.classList.add("is-wrong")
      tile.classList.add("is-wrong")
      this.selected = null

      setTimeout(() => {
        prev.classList.remove("is-wrong")
        tile.classList.remove("is-wrong")
      }, 700)
    }
  }
}
