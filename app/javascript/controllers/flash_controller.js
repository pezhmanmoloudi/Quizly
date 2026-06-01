import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => this.dismiss(), 3000)
  }

  dismiss() {
    this.element.classList.add("flash--out")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
