import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.menuTarget.dataset.open = "false"
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  toggle() {
    this.menuTarget.dataset.open === "true" ? this.close() : this.open()
  }

  open() {
    this.menuTarget.dataset.open = "true"
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.menuTarget.dataset.open = "false"
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
