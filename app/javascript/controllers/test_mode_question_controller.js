import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "form"]

  select(event) {
    // Disable all options once one is picked to prevent double-submit
    this.optionTargets.forEach(btn => { btn.disabled = true })
  }
}
