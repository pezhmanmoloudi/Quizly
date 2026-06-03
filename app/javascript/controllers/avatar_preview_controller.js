import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  change() {
    const file = this.inputTarget.files[0]
    if (!file) return
    this.inputTarget.closest("form").requestSubmit()
  }
}
