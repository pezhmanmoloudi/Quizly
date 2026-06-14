import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template"]

  addCard() {
    const html = this.templateTarget.innerHTML
    this.cardsListTarget.insertAdjacentHTML("beforeend", html)
    this.cardsListTarget.lastElementChild?.querySelector("textarea")?.focus()
  }
}
