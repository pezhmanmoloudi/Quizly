import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  change() {
    const file = this.inputTarget.files[0]
    if (!file) return
    this.inputTarget.closest("form").requestSubmit()
  }

  selectPreset({ params: { emoji, bg } }) {
    const canvas = document.createElement("canvas")
    canvas.width = 200
    canvas.height = 200
    const ctx = canvas.getContext("2d")

    ctx.fillStyle = bg
    ctx.fillRect(0, 0, 200, 200)

    ctx.font = "120px serif"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillText(emoji, 100, 108)

    canvas.toBlob(blob => {
      const file = new File([blob], "preset-avatar.png", { type: "image/png" })
      const dt = new DataTransfer()
      dt.items.add(file)
      this.inputTarget.files = dt.files
      this.inputTarget.closest("form").requestSubmit()
    }, "image/png")
  }
}
