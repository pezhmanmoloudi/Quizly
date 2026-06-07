import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "editBtn"]

  edit() {
    this.displayTarget.hidden = true
    this.editBtnTarget.hidden = true
    this.formTarget.hidden = false
  }

  cancel() {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
    this.editBtnTarget.hidden = false
  }
}
