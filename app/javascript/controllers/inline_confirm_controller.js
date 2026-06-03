import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actions", "confirm", "deleteForm"]

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
