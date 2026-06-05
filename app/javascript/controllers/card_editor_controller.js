import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template", "row"]
  static values  = { createUrl: String }

  connect() { this.#renumber() }

  addCard() {
    this.#appendNewRow()
    this.#renumber()
    this.cardsListTarget.lastElementChild?.querySelector("textarea")?.focus()
  }

  removeCard(event) {
    const row = event.target.closest("[data-card-editor-target='row']")
    if (!row) return
    const destroyField = row.querySelector(".destroy-field")
    if (destroyField) {
      destroyField.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.#renumber()
  }

  async handleDefinitionKeydown(event) {
    if (event.key !== "Tab" || event.shiftKey) return
    const row = event.target.closest("[data-card-editor-target='row']")
    if (!row) return

    const visibleRows = this.rowTargets.filter(r => !r.hidden)
    if (row !== visibleRows.at(-1)) return

    const term = row.querySelector("[name*='front_content']")
    if (!term?.value.trim() || !event.target.value.trim()) return

    event.preventDefault()
    await this.#saveRow(row, term.value.trim(), event.target.value.trim())
    this.#appendNewRow()
    this.#renumber()
    this.cardsListTarget.lastElementChild?.querySelector("textarea")?.focus()
  }

  async handleDefinitionBlur(event) {
    const row = event.target.closest("[data-card-editor-target='row']")
    if (!row || row.dataset.saved) return
    const term = row.querySelector("[name*='front_content']")
    if (!term?.value.trim() || !event.target.value.trim()) return
    await this.#saveRow(row, term.value.trim(), event.target.value.trim())
  }

  async #saveRow(row, frontContent, backContent) {
    if (row.dataset.saved) return
    try {
      const resp = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ flashcard: { front_content: frontContent, back_content: backContent } })
      })
      if (resp.ok) row.dataset.saved = "true"
    } catch { /* silent — card stays editable */ }
  }

  #appendNewRow() {
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, Date.now())
    this.cardsListTarget.insertAdjacentHTML("beforeend", html)
  }

  #renumber() {
    const visible = this.rowTargets.filter(r => !r.hidden)
    visible.forEach((row, i) => {
      const num = row.querySelector(".card-row__number")
      if (num) num.textContent = i + 1
    })
  }
}
