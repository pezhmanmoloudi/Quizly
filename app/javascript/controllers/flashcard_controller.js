import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["back", "showButton", "ratingForm"]

  reveal() {
    this.backTarget.hidden = false
    this.showButtonTarget.hidden = true
    this.ratingFormTarget.style.display = ""
  }
}
