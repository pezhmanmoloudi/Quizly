import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "visibilitySelect",  "visibilityDesc",
    "accessModeSelect",  "accessModeDesc",
    "passwordSection",
    "shareSection",
  ]

  connect() {
    this.#syncState()
  }

  onVisibilityChange()  { this.#syncState() }
  onAccessModeChange()  { this.#syncState() }

  // ── Private ───────────────────────────────────────────────────────────────

  #syncState() {
    const visibility = this.visibilitySelectTarget.value

    this.#updateDesc(this.visibilitySelectTarget, this.visibilityDescTarget)

    if (visibility === "private") {
      this.accessModeSelectTarget.value    = "open"
      this.accessModeSelectTarget.disabled = true
    } else {
      this.accessModeSelectTarget.disabled = false
    }

    this.#updateDesc(this.accessModeSelectTarget, this.accessModeDescTarget)

    if (this.hasShareSectionTarget) {
      this.shareSectionTarget.classList.toggle("access-section--hidden", visibility !== "unlisted")
    }

    this.#setPasswordVisible(
      visibility !== "private" &&
      this.accessModeSelectTarget.value === "password"
    )
  }

  #updateDesc(selectEl, descEl) {
    if (!descEl) return
    const key = "desc" + selectEl.value
      .split("_")
      .map(w => w[0].toUpperCase() + w.slice(1))
      .join("")
    descEl.textContent = selectEl.dataset[key] ?? ""
  }

  #setPasswordVisible(visible) {
    if (this.hasPasswordSectionTarget) {
      this.passwordSectionTarget.classList.toggle("access-section--hidden", !visible)
    }
  }
}
