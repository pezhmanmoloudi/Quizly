import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template", "row"]
  static values  = { createUrl: String }

  connect() { this.#renumber() }

  addCard() {
    this.#appendNewRow()
    this.#renumber()
    this.cardsListTarget.lastElementChild?.querySelector("textarea")?.focus()
  }

  removeCard(event) {
    const row = event.target.closest("[data-card-editor-target='row']")
    if (!row) return
    const destroyField = row.querySelector(".destroy-field")
    if (destroyField) {
      destroyField.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.#renumber()
  }

  async saveCard(event) {
    const btn      = event.currentTarget
    const row      = btn.closest("[data-card-editor-target='row']")
    if (!row) return

    const termArea = row.querySelector("[name*='front_content']")
    const defArea  = row.querySelector("[name*='back_content']")

    if (!termArea?.value.trim()) {
      this.#showFieldError(termArea, "Please enter a term.")
      termArea.focus()
      return
    }

    if (!defArea?.value.trim()) {
      this.#showFieldError(defArea, "Please enter a definition.")
      defArea.focus()
      return
    }

    btn.disabled = true
    const ok = await this.#postCard(termArea.value.trim(), defArea.value.trim())
    btn.disabled = false

    if (ok) {
      termArea.value = ""
      defArea.value  = ""
      termArea.focus()
      this.#showToast("Flashcard saved!")
    }
  }

  async #postCard(frontContent, backContent) {
    try {
      const resp = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ flashcard: { front_content: frontContent, back_content: backContent } })
      })
      return resp.ok
    } catch { return false }
  }

  #showFieldError(textarea, message) {
    const el = textarea.closest(".card-row__panel")?.querySelector(".card-row__field-error")
    if (!el) return
    el.textContent = message
    el.hidden = false
    setTimeout(() => { el.hidden = true }, 2500)
  }

  #showToast(message) {
    const container = document.getElementById("flash-messages")
    if (!container) return
    const div = document.createElement("div")
    div.className = "flash flash--notice"
    div.dataset.controller = "flash"
    div.textContent = message
    container.appendChild(div)
  }

  #appendNewRow() {
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, Date.now())
    this.cardsListTarget.insertAdjacentHTML("beforeend", html)
  }

  #renumber() {
    const visible = this.rowTargets.filter(r => !r.hidden)
    visible.forEach((row, i) => {
      const num = row.querySelector(".card-row__number")
      if (num) num.textContent = i + 1
    })
  }
}
