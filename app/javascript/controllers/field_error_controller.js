import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "message"]

  connect() {
    if (this.messageTarget.textContent.trim()) {
      this.inputTarget.setAttribute("aria-invalid", "true")
    }
  }

  validate() {
    const input = this.inputTarget
    if (!input.validity.valid) {
      this.show(input.validationMessage)
      input.setAttribute("aria-invalid", "true")
    } else {
      this.clear()
    }
  }

  clear() {
    if (this.messageTarget.dataset.serverError) return
    this.messageTarget.hidden = true
    this.inputTarget.removeAttribute("aria-invalid")
  }

  show(msg) {
    this.messageTarget.textContent = msg
    this.messageTarget.hidden = false
  }
}
