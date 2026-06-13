import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["visibilityGroup", "editGroup", "editPermissionRadio", "passwordSection", "passwordInput", "sharePanel", "shareLinkInput", "copyLabel", "shareWarning"]
  static values  = { currentVisibility: String }

  connect() {
    this.#syncState()
  }

  onVisibilityChange() {
    this.#syncState()
  }

  onEditPermissionChange() {
    this.#syncState()
  }

  copyShareLink(event) {
    const input = this.shareLinkInputTarget
    navigator.clipboard.writeText(input.value).then(() => {
      const label = this.copyLabelTarget
      const btn   = event.currentTarget
      const original = label.textContent
      label.textContent = btn.dataset.copiedLabel || original
      btn.disabled = true
      setTimeout(() => {
        label.textContent = original
        btn.disabled = false
      }, 2000)
    })
  }

  // ── Private ───────────────────────────────────────────────────────────────

  #syncState() {
    const visibility = this.#selectedVisibility()
    const wasUnlisted = this.currentVisibilityValue === "unlisted"

    if (visibility === "private" || visibility === "unlisted") {
      this.#forceOwnerOnly()
      this.#setEditGroupDisabled(true)
      this.#setPasswordVisible(false)
      this.#setSharePanelVisible(visibility === "unlisted")
    } else if (visibility === "password_protected") {
      this.#setEditGroupDisabled(false)
      this.#setPasswordVisible(true)
      this.#setSharePanelVisible(false)
    } else {
      // everyone
      this.#setEditGroupDisabled(false)
      this.#setPasswordVisible(this.#selectedEditPermission() === "password_users")
      this.#setSharePanelVisible(false)
    }

    this.#setShareWarningVisible(wasUnlisted && visibility !== "unlisted")
  }

  #selectedVisibility() {
    const checked = this.visibilityGroupTarget.querySelector("input[type='radio']:checked")
    return checked ? checked.value : null
  }

  #selectedEditPermission() {
    const checked = this.editGroupTarget.querySelector("input[type='radio']:checked")
    return checked ? checked.value : null
  }

  #forceOwnerOnly() {
    this.editPermissionRadioTargets.forEach(radio => {
      radio.checked = radio.value === "owner_only"
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

  #setSharePanelVisible(visible) {
    if (this.hasSharePanelTarget) {
      this.sharePanelTarget.style.display = visible ? "" : "none"
    }
  }

  #setShareWarningVisible(visible) {
    if (this.hasShareWarningTarget) {
      this.shareWarningTarget.style.display = visible ? "" : "none"
    }
  }
}
