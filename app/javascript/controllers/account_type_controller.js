import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    if (!this.hasMenuTarget) return
    this.menuTarget.dataset.open = this.menuTarget.dataset.open === "true" ? "false" : "true"
  }

  close() {
    if (this.hasMenuTarget) this.menuTarget.dataset.open = "false"
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
