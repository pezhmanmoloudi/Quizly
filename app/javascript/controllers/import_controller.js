import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "textarea", "colSepField", "rowSepField",
    "sepRadio", "colCustom", "rowCustom",
    "submitBtn", "previewRows", "emptyState", "previewCount"
  ]
  static values = {
    termLabel: String,
    definitionLabel: String,
    previewOne: String,
    previewOther: String
  }

  connect() {
    this.#syncColSep()
    this.#syncRowSep()
    this.updatePreview()
  }

  separatorChanged(event) {
    const el = event.target
    const group = el.dataset.sepGroup

    if (el.type === "radio") {
      if (group === "col") this.#syncColSep()
      else                 this.#syncRowSep()
    } else {
      // custom text input changed
      if (group === "col") this.colSepFieldTarget.value = el.value
      else                 this.rowSepFieldTarget.value = el.value
    }

    this.updatePreview()
  }

  updatePreview() {
    const text   = this.hasTextareaTarget ? this.textareaTarget.value : ""
    const colSep = this.colSepFieldTarget.value
    const rowSep = this.rowSepFieldTarget.value || "\n"

    const pairs = this.#parsePairs(text, colSep, rowSep)

    if (pairs.length === 0) {
      this.emptyStateTarget.hidden  = false
      this.previewRowsTarget.hidden = true
      this.previewCountTarget.textContent = ""
      if (this.hasSubmitBtnTarget) this.submitBtnTarget.disabled = true
    } else {
      this.emptyStateTarget.hidden  = true
      this.previewRowsTarget.hidden = false
      this.previewRowsTarget.innerHTML = this.#buildRowsHTML(pairs)
      this.previewCountTarget.textContent = this.#countLabel(pairs.length)
      if (this.hasSubmitBtnTarget) this.submitBtnTarget.disabled = false
    }
  }

  // ── Private ──────────────────────────────────────────────

  #syncColSep() {
    const checked = this.sepRadioTargets.find(r => r.dataset.sepGroup === "col" && r.checked)
    if (!checked) return

    const colCustom = this.hasColCustomTarget ? this.colCustomTarget : null

    if (checked.value === "tab") {
      this.colSepFieldTarget.value = "\t"
      if (colCustom) colCustom.hidden = true
    } else if (checked.value === "comma") {
      this.colSepFieldTarget.value = ","
      if (colCustom) colCustom.hidden = true
    } else {
      if (colCustom) {
        colCustom.hidden = false
        colCustom.focus()
        this.colSepFieldTarget.value = colCustom.value
      }
    }
  }

  #syncRowSep() {
    const checked = this.sepRadioTargets.find(r => r.dataset.sepGroup === "row" && r.checked)
    if (!checked) return

    const rowCustom = this.hasRowCustomTarget ? this.rowCustomTarget : null

    if (checked.value === "newline") {
      this.rowSepFieldTarget.value = "\n"
      if (rowCustom) rowCustom.hidden = true
    } else if (checked.value === "semicolon") {
      this.rowSepFieldTarget.value = ";"
      if (rowCustom) rowCustom.hidden = true
    } else {
      if (rowCustom) {
        rowCustom.hidden = false
        rowCustom.focus()
        this.rowSepFieldTarget.value = rowCustom.value
      }
    }
  }

  #parsePairs(text, colSep, rowSep) {
    if (!text.trim() || !colSep) return []

    const splitRow = (rowSep === "\n")
      ? text.split(/\r?\n/)
      : text.split(rowSep)

    return splitRow
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        const idx = line.indexOf(colSep)
        if (idx === -1) return null
        const term       = line.substring(0, idx).trim()
        const definition = line.substring(idx + colSep.length).trim()
        return (term && definition) ? { term, definition } : null
      })
      .filter(Boolean)
  }

  #buildRowsHTML(pairs) {
    return pairs.map((pair, i) => `
      <div class="import-preview-row">
        <span class="import-preview-row__num">${i + 1}</span>
        <div class="import-preview-box">
          <span class="import-preview-box__content">${this.#esc(pair.term)}</span>
          <span class="import-preview-box__label">${this.#esc(this.termLabelValue)}</span>
        </div>
        <div class="import-preview-box">
          <span class="import-preview-box__content">${this.#esc(pair.definition)}</span>
          <span class="import-preview-box__label">${this.#esc(this.definitionLabelValue)}</span>
        </div>
      </div>
    `).join("")
  }

  #countLabel(n) {
    if (n === 1) return this.previewOneValue
    return this.previewOtherValue.replace("%{count}", n)
  }

  #esc(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
