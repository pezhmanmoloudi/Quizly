import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template"]

  connect() {
    this._addCardHandler = () => this.addCard()
    this.element.addEventListener("card-autosave:add-card", this._addCardHandler)
  }

  disconnect() {
    this.element.removeEventListener("card-autosave:add-card", this._addCardHandler)
  }

  addCard() {
    const clone = this.templateTarget.content.cloneNode(true)
    const row = clone.querySelector("[id^='card-row']")
    if (row) row.id = `card-row-new-${Date.now()}`
    this.cardsListTarget.appendChild(clone)
    this.cardsListTarget.lastElementChild?.querySelector("textarea")?.focus()
  }
}
