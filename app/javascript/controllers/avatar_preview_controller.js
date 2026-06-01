import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image", "placeholder", "submit"]

  change() {
    const file = this.inputTarget.files[0]
    if (!file) return

    // Show a local preview so the user can see what they picked
    const reader = new FileReader()
    reader.onload = (e) => {
      this.imageTarget.src = e.target.result
      this.imageTarget.hidden = false
      if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
    }
    reader.readAsDataURL(file)

    // Reveal the Upload button (server handles all format/size validation)
    if (this.hasSubmitTarget) this.submitTarget.hidden = false
  }
}
