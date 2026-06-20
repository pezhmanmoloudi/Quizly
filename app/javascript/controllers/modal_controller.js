import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "confirmInput", "submitButton"]

  open() {
    this.dialogTarget.hidden = false
    document.body.classList.add("modal-open")
    this._onKeydown = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this._onKeydown)
    if (this.hasConfirmInputTarget) {
      this.confirmInputTarget.value = ""
      this.submitButtonTarget.disabled = true
      this.confirmInputTarget.focus()
    } else {
      requestAnimationFrame(() => {
        this.dialogTarget.querySelector(
          'input:not([type="hidden"]):not([disabled]), button:not([disabled]), [tabindex]:not([tabindex="-1"])'
        )?.focus()
      })
    }
  }

  // Called via turbo:frame-load on the global modal frame
  openFromFrame() {
    requestAnimationFrame(() => {
      if (this.hasDialogTarget) this.open()
    })
  }

  close() {
    document.body.classList.remove("modal-open")
    if (this._onKeydown) {
      document.removeEventListener("keydown", this._onKeydown)
      this._onKeydown = null
    }
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    const frame = this.element.querySelector("turbo-frame#modal")
    if (frame) frame.innerHTML = ""
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) this.close()
  }

  validateConfirmation() {
    const required = this.confirmInputTarget.dataset.requiredValue
    this.submitButtonTarget.disabled = this.confirmInputTarget.value !== required
  }

  enableIfNotBlank(event) {
    this.submitButtonTarget.disabled = !event.target.value.trim()
  }

  enableIfChanged(event) {
    const original = event.target.dataset.originalValue
    this.submitButtonTarget.disabled =
      !event.target.value.trim() || event.target.value === original
  }

  closeOnSuccess(event) {
    if (event.detail.success) this.close()
  }

  validateCheckboxes() {
    const checked = this.element.querySelectorAll('input[type="checkbox"]:checked').length
    this.submitButtonTarget.disabled = checked === 0
  }

  dialogTargetDisconnected() {
    document.body.classList.remove("modal-open")
    if (this._onKeydown) {
      document.removeEventListener("keydown", this._onKeydown)
      this._onKeydown = null
    }
  }

  disconnect() {
    if (this._onKeydown) document.removeEventListener("keydown", this._onKeydown)
    document.body.classList.remove("modal-open")
  }
}
