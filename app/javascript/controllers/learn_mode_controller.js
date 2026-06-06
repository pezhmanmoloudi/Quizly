import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answerInput", "submitBtn", "exitLink"]

  #isSubmitting = false

  connect() {
    this.element.focus()
  }

  disconnect() {
    this.#isSubmitting = false
  }

  handleKey(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case "Enter":
        if (this.#activeTagAllowsEnter()) return
        event.preventDefault()
        this.#submitAnswer()
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
