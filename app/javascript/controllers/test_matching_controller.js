import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["term", "definition", "answerInput", "submit"]
  static values  = { total: Number }

  #selectedTerm = null
  #pairs        = {}

  selectTerm(event) {
    const tile = event.currentTarget
    if (tile.dataset.matched === "true") {
      this.#unpair(tile)
      return
    }

    if (this.#selectedTerm) this.#selectedTerm.classList.remove("is-selected")
    this.#selectedTerm = tile
    tile.classList.add("is-selected")
  }

  selectDefinition(event) {
    if (!this.#selectedTerm) return
    const defTile = event.currentTarget
    if (defTile.dataset.matched === "true") return

    const termId  = this.#selectedTerm.dataset.id
    const defText = defTile.textContent.trim()

    this.#pairs[termId] = defText

    this.#selectedTerm.classList.remove("is-selected")
    this.#selectedTerm.classList.add("is-matched")
    this.#selectedTerm.dataset.matched = "true"
    this.#selectedTerm.dataset.pairedWith = defTile.dataset.id
    defTile.classList.add("is-matched")
    defTile.dataset.matched  = "true"
    defTile.dataset.pairedWith = termId

    this.#selectedTerm = null
    this.#updateSubmit()
  }

  #unpair(termTile) {
    const pairedDefId = termTile.dataset.pairedWith
    const defTile = this.definitionTargets.find(t => t.dataset.id === pairedDefId)

    delete this.#pairs[termTile.dataset.id]
    termTile.classList.remove("is-matched", "is-selected")
    delete termTile.dataset.matched
    delete termTile.dataset.pairedWith

    if (defTile) {
      defTile.classList.remove("is-matched")
      delete defTile.dataset.matched
      delete defTile.dataset.pairedWith
    }

    this.#selectedTerm = termTile
    termTile.classList.add("is-selected")
    this.#updateSubmit()
  }

  #updateSubmit() {
    const allPaired = Object.keys(this.#pairs).length === this.totalValue
    this.answerInputTarget.value = allPaired ? JSON.stringify(this.#pairs) : ""
    this.submitTarget.disabled = !allPaired
  }
}
