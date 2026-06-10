import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 3000 } }

  connect() {
    this._timer = setTimeout(() => this.dismiss(), this.timeoutValue)
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  dismiss() {
    this.element.classList.add("flash--out")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
