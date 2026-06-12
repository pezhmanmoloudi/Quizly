import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle() {
    this.menuTarget.dataset.open === "true" ? this.close() : this.open()
  }

  open() {
    this.menuTarget.dataset.open = "true"
    this.buttonTarget.setAttribute("aria-expanded", "true")
    const firstFocusable = this.menuTarget.querySelector("button, a, [tabindex]:not([tabindex='-1'])")
    ;(firstFocusable ?? this.menuTarget).focus()
  }

  close() {
    this.menuTarget.dataset.open = "false"
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.focus()
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.dataset.open = "false"
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }
}
