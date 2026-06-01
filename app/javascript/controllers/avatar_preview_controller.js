import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "actions", "confirm", "deleteForm"]

  change() {
    const file = this.inputTarget.files[0]
    if (!file) return
    this.inputTarget.closest("form").requestSubmit()
  }

  confirmRemove() {
    this.actionsTarget.hidden = true
    this.confirmTarget.hidden = false
  }

  cancelRemove() {
    this.confirmTarget.hidden = true
    this.actionsTarget.hidden = false
  }

  doRemove() {
    this.deleteFormTarget.requestSubmit()
  }
}
