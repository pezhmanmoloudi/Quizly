import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["term", "definition", "row"]
  static values  = { updateUrl: String }

  connect() {
    this.originalTerm = this.termTarget.value
    this.originalDef  = this.definitionTarget.value
  }

  async handleBlur() {
    const term = this.termTarget.value.trim()
    const def  = this.definitionTarget.value.trim()
    if (!term || !def) return
    if (term === this.originalTerm.trim() && def === this.originalDef.trim()) return
    await this.#save(term, def)
  }

  async #save(frontContent, backContent) {
    try {
      const resp = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ flashcard: { front_content: frontContent, back_content: backContent } })
      })
      if (resp.ok) {
        this.originalTerm = frontContent
        this.originalDef  = backContent
        if (this.hasRowTarget) this.rowTarget.dataset.saved = "true"
      }
    } catch { /* silent */ }
  }
}
