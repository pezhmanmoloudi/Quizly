import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answerInput", "submitBtn", "continueBtn", "exitLink", "timer", "streak"]

  #isSubmitting = false

  connect() {
    this.element.focus()
    this.streak = 0
    this.seconds = 0
    this.timerInterval = setInterval(() => this.#tickTimer(), 1000)
  }

  disconnect() {
    this.#isSubmitting = false
    clearInterval(this.timerInterval)
  }

  // Focus the continue button as soon as feedback is rendered; update streak from DOM
  continueBtnTargetConnected(target) {
    target.focus()
    const correct = this.element.querySelector(".learn-card__feedback--correct") !== null
    correct ? this.streak++ : this.streak = 0
    if (this.hasStreakTarget) this.streakTarget.textContent = this.streak
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

  #tickTimer() {
    this.seconds++
    if (!this.hasTimerTarget) return
    const m = String(Math.floor(this.seconds / 60)).padStart(2, "0")
    const s = String(this.seconds % 60).padStart(2, "0")
    this.timerTarget.textContent = `${m}:${s}`
  }
}
