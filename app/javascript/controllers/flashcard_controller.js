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
    if (this.hasRatingFormTarget) {
      this.ratingFormTarget.style.display = ""
    }
  }

  reset() {
    this.backTarget.hidden = true
    this.showButtonTarget.hidden = false
    if (this.hasRatingFormTarget) {
      this.ratingFormTarget.style.display = "none"
    }
  }
}
