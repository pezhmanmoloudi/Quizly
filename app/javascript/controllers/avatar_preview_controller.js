import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image", "placeholder"]

  change() {
    const file = this.inputTarget.files[0]
    if (!file || !file.type.startsWith("image/")) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.imageTarget.src = e.target.result
      this.imageTarget.hidden = false
      if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
    }
    reader.readAsDataURL(file)

    // Auto-submit the avatar upload form immediately on file selection
    this.inputTarget.form.requestSubmit()
  }
}
