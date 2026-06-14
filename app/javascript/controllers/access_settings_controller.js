import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["visibilityGroup", "editGroup", "editPermissionRadio", "passwordSection", "passwordInput"]

  connect() {
    this.#syncState()
  }

  onVisibilityChange() {
    this.#syncState()
  }

  onEditPermissionChange() {
    this.#syncState()
  }

  // ── Private ───────────────────────────────────────────────────────────────

  #syncState() {
    const visibility = this.#selectedVisibility()

    if (visibility === "private") {
      this.#forceOnlyMe()
      this.#setEditGroupDisabled(true)
      this.#setPasswordVisible(false)
    } else {
      this.#setEditGroupDisabled(false)
      this.#setPasswordVisible(this.#selectedEditPermission() === "people_with_password")
    }
  }

  #selectedVisibility() {
    const checked = this.visibilityGroupTarget.querySelector("input[type='radio']:checked")
    return checked ? checked.value : null
  }

  #selectedEditPermission() {
    const checked = this.editGroupTarget.querySelector("input[type='radio']:checked")
    return checked ? checked.value : null
  }

  #forceOnlyMe() {
    this.editPermissionRadioTargets.forEach(radio => {
      radio.checked = radio.value === "only_me"
    })
  }

  #setEditGroupDisabled(disabled) {
    this.editPermissionRadioTargets.forEach(radio => {
      radio.disabled = disabled
    })
    this.editGroupTarget.style.opacity = disabled ? "0.4" : ""
  }

  #setPasswordVisible(visible) {
    if (this.hasPasswordSectionTarget) {
      this.passwordSectionTarget.style.display = visible ? "" : "none"
    }
    if (this.hasPasswordInputTarget) {
      this.passwordInputTarget.required = visible
    }
  }
}
