import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "label"]
  static values  = { copied: String }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value).then(() => {
      const original = this.labelTarget.textContent
      const btn = this.element.querySelector("button")
      this.labelTarget.textContent = this.copiedValue || original
      if (btn) btn.disabled = true
      setTimeout(() => {
        this.labelTarget.textContent = original
        if (btn) btn.disabled = false
      }, 2000)
    })
  }
}
