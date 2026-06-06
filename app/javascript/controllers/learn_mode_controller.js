import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answerInput", "submitBtn", "continueBtn", "exitLink"]

  #isSubmitting = false

  connect() {
    this.element.focus()
  }

  disconnect() {
    this.#isSubmitting = false
  }

  // Focus the continue button as soon as feedback is rendered
  continueBtnTargetConnected(target) {
    target.focus()
  }

  // Reset submission gate when a fresh answer input appears (new card loaded)
  answerInputTargetConnected() {
    this.#isSubmitting = false
  }

  handleKey(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case "Enter":
        if (this.#activeTagAllowsEnter()) return
        event.preventDefault()
        if (this.hasContinueBtnTarget) {
          this.continueBtnTarget.click()
        } else {
          this.#submitAnswer()
        }
        break
      case " ":
        if (this.hasContinueBtnTarget) {
          event.preventDefault()
          this.continueBtnTarget.click()
        }
        break
      case "Escape":
        if (this.hasExitLinkTarget) this.exitLinkTarget.click()
        break
    }
  }

  #submitAnswer() {
    if (this.#isSubmitting) return
    const input = this.hasAnswerInputTarget ? this.answerInputTarget : null
    if (!input || !input.value.trim()) return

    this.#isSubmitting = true
    if (this.hasSubmitBtnTarget) this.submitBtnTarget.disabled = true

    const form = input.closest("form")
    if (form) form.requestSubmit()
  }

  #activeTagAllowsEnter() {
    const tag = document.activeElement?.tagName
    return ["TEXTAREA", "SELECT"].includes(tag)
  }
}
