import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  toggle() {
    this.fieldTarget.type = this.fieldTarget.type === "password" ? "text" : "password"
  }
}
