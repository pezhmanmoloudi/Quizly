import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["front", "back", "status"]
  static values  = {
    flashcardId:  String,
    createUrl:    String,
    savingLabel:  String,
    savedLabel:   String,
    errorLabel:   String
  }

  schedule() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.save(), 700)
  }

  async save() {
    const front = this.frontTarget.value.trim()
    if (!front) return

    const isNew  = !this.flashcardIdValue
    const url    = isNew ? this.createUrlValue : `/flashcards/${this.flashcardIdValue}`
    const method = isNew ? "POST" : "PATCH"

    this.#setStatus("saving")
    try {
      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({
          flashcard: {
            front_content: front,
            back_content:  this.backTarget.value.trim()
          }
        })
      })

      if (response.ok) {
        const data = await response.json()
        if (isNew) {
          this.flashcardIdValue = String(data.id)
          this.element.id = `flashcard_${data.id}`
        }
        this.#setStatus("saved")
        setTimeout(() => this.#setStatus(""), 2000)
      } else {
        this.#setStatus("error")
      }
    } catch {
      this.#setStatus("error")
    }
  }

  async deleteCard() {
    if (!this.flashcardIdValue) {
      this.element.remove()
      return
    }
    this.element.remove()
    const response = await fetch(`/flashcards/${this.flashcardIdValue}`, {
      method: "DELETE",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
    if (response.ok) Turbo.renderStreamMessage(await response.text())
  }

  handleTab(event) {
    if (event.key !== "Tab" || event.shiftKey) return
    if (event.target !== this.backTarget) return
    const rows = document.querySelectorAll('[data-controller~="card-autosave"]')
    if (this.element !== rows[rows.length - 1]) return
    event.preventDefault()
    this.element.dispatchEvent(new CustomEvent("card-autosave:add-card", { bubbles: true }))
  }

  // ── Private ──────────────────────────────────────────────────────────────

  #setStatus(state) {
    if (!this.hasStatusTarget) return
    const labels = {
      saving: this.savingLabelValue,
      saved:  this.savedLabelValue,
      error:  this.errorLabelValue
    }
    this.statusTarget.textContent = labels[state] ?? ""
  }
}
