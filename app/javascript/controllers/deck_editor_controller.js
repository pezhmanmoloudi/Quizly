import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template"]

  connect() {
    this.element.addEventListener("card-autosave:add-card", () => this.addCard())
  }

  addCard() {
    const clone = this.templateTarget.content.cloneNode(true)
    const row = clone.querySelector("[id^='card-row']")
    if (row) row.id = `card-row-new-${Date.now()}`
    this.cardsListTarget.appendChild(clone)
    this.cardsListTarget.lastElementChild?.querySelector("textarea")?.focus()
  }
}
