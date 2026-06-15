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

  close() {
    this.dialogTarget.hidden = true
    document.body.classList.remove("modal-open")
    if (this._onKeydown) {
      document.removeEventListener("keydown", this._onKeydown)
      this._onKeydown = null
    }
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) this.close()
  }

  validateConfirmation() {
    const required = this.confirmInputTarget.dataset.requiredValue
    this.submitButtonTarget.disabled = this.confirmInputTarget.value !== required
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
