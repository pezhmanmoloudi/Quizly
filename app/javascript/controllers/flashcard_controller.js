import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["back", "showButton", "ratingForm"]

  reveal(event) {
    const card = event.currentTarget.closest(".flashcard-card")
    if (card) {
      card.querySelector(".flashcard-card__inner")?.classList.add("is-flipped")
      return
    }
    this.backTarget.hidden = false
    this.showButtonTarget.hidden = true
    this.ratingFormTargets.forEach(el => { el.style.display = "" })
  }

  reset() {
    this.backTarget.hidden = true
    this.showButtonTarget.hidden = false
    this.ratingFormTargets.forEach(el => { el.style.display = "none" })
  }
}
