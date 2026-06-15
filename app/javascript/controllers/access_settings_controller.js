import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "visibilitySelect", "visibilityDesc",
    "editSelect",       "editDesc",
    "passwordSection",  "passwordInput",
    "shareSection",
  ]

  connect() {
    this.#syncState()
  }

  onVisibilityChange()     { this.#syncState() }
  onEditPermissionChange() { this.#syncState() }

  // ── Private ───────────────────────────────────────────────────────────────

  #syncState() {
    const visibility = this.visibilitySelectTarget.value

    this.#updateDesc(this.visibilitySelectTarget, this.visibilityDescTarget)

    if (visibility === "private") {
      this.editSelectTarget.value    = "only_me"
      this.editSelectTarget.disabled = true
    } else {
      this.editSelectTarget.disabled = false
    }

    this.#updateDesc(this.editSelectTarget, this.editDescTarget)

    if (this.hasShareSectionTarget) {
      this.shareSectionTarget.classList.toggle("access-section--hidden", visibility !== "unlisted")
    }

    this.#setPasswordVisible(
      visibility !== "private" &&
      this.editSelectTarget.value === "people_with_password"
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
    if (this.hasPasswordInputTarget) {
      this.passwordInputTarget.required = visible
      this.passwordInputTarget.disabled = !visible
    }
  }
}
