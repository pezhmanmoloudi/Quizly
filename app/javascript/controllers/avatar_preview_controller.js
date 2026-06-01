import { Controller } from "@hotwired/stimulus"

const MIN_PX = 100
const MAX_PX = 4000
const MAX_MB = 5

export default class extends Controller {
  static targets = ["input", "image", "placeholder", "error"]

  change() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.clearError()

    const img = new Image()
    const url = URL.createObjectURL(file)

    img.onload = () => {
      URL.revokeObjectURL(url)
      const { naturalWidth: w, naturalHeight: h } = img

      if (w < MIN_PX || h < MIN_PX) {
        this.showError(`Photo must be at least ${MIN_PX}×${MIN_PX} pixels (yours is ${w}×${h}).`)
        this.inputTarget.value = ""
        return
      }
      if (w > MAX_PX || h > MAX_PX) {
        this.showError(`Photo must be no larger than ${MAX_PX}×${MAX_PX} pixels (yours is ${w}×${h}).`)
        this.inputTarget.value = ""
        return
      }
      if (file.size > MAX_MB * 1024 * 1024) {
        this.showError(`Photo must be smaller than ${MAX_MB}MB.`)
        this.inputTarget.value = ""
        return
      }

      // Show preview then submit
      this.imageTarget.src = img.src
      this.imageTarget.hidden = false
      if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
      this.inputTarget.form.requestSubmit()
    }

    img.onerror = () => {
      URL.revokeObjectURL(url)
      this.showError("Could not read the image file.")
      this.inputTarget.value = ""
    }

    img.src = url
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.hidden = false
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.hidden = true
    }
  }
}
