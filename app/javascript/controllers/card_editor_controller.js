import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template", "row"]

  connect() {
    this.#renumber()
  }

  addCard() {
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, Date.now())
    this.cardsListTarget.insertAdjacentHTML("beforeend", html)
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

  #renumber() {
    const visible = this.rowTargets.filter(r => !r.hidden)
    visible.forEach((row, i) => {
      const num = row.querySelector(".card-row__number")
      if (num) num.textContent = i + 1
    })
  }
}
