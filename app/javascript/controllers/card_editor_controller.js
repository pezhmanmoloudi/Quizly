import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsList", "template", "row", "saveButton"]
  static values  = {
    errorTerm:       String,
    errorDefinition: String
  }

  connect() { this.#updateUI() }

  // ── Form submission ──────────────────────────────────────────────────────

  handleSubmit(event) {
    if (!this.#validateRows()) event.preventDefault()
  }

  // ── Card management ──────────────────────────────────────────────────────

  addCard() {
    this.#appendNewRow()
    this.#updateUI()
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
    this.#updateUI()
  }

  // ── Field error clearing ─────────────────────────────────────────────────

  clearFieldError(event) {
    const panel = event.target.closest(".card-row__panel")
    if (!panel) return
    const err = panel.querySelector(".card-row__field-error")
    if (err) { err.textContent = ""; err.hidden = true }
  }

  // ── Image handling ───────────────────────────────────────────────────────

  triggerImageUpload(event) {
    const panel = event.currentTarget.closest(".card-row__image-panel")
    panel?.querySelector(".card-row__image-input")?.click()
  }

  previewImage(event) {
    const input = event.currentTarget
    const panel = input.closest(".card-row__image-panel")
    if (!panel || !input.files?.[0]) return

    const preview = panel.querySelector(".card-row__image-preview")
    const btn     = panel.querySelector(".card-row__image-btn")
    preview.src    = URL.createObjectURL(input.files[0])
    preview.hidden = false
    if (btn) btn.hidden = true
  }

  // ── Private ──────────────────────────────────────────────────────────────

  #visibleRows() {
    return this.rowTargets.filter(r => !r.hidden)
  }

  #updateUI() {
    const visible = this.#visibleRows()
    visible.forEach((row, i) => {
      const num = row.querySelector(".card-row__number")
      if (num) num.textContent = i + 1
      const btn = row.querySelector(".card-row__delete")
      if (btn) btn.hidden = false
    })
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = visible.length === 0
    }
  }

  #appendNewRow() {
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, Date.now())
    this.cardsListTarget.insertAdjacentHTML("beforeend", html)
  }

  #validateRows() {
    let firstInvalid = null

    this.#visibleRows().forEach(row => {
      const termArea = row.querySelector("textarea[name*='front_content']")
      const defArea  = row.querySelector("textarea[name*='back_content']")

      if (termArea && !termArea.value.trim()) {
        this.#showFieldError(termArea, this.errorTermValue)
        firstInvalid ||= termArea
      }
      if (defArea && !defArea.value.trim()) {
        this.#showFieldError(defArea, this.errorDefinitionValue)
        firstInvalid ||= defArea
      }
    })

    if (firstInvalid) {
      firstInvalid.scrollIntoView({ behavior: "smooth", block: "center" })
      firstInvalid.focus()
      return false
    }
    return true
  }

  #showFieldError(field, message) {
    const panel = field.closest(".card-row__panel")
    if (!panel) return
    const err = panel.querySelector(".card-row__field-error")
    if (!err) return
    err.textContent = message
    err.hidden = false
  }
}
