import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["back", "showButton", "ratingForm"]

  reveal() {
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
