import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["continueBtn", "exitLink", "timer"]

  connect() {
    this.element.focus()
    this.seconds = 0
    this.timerInterval = setInterval(() => this.#tickTimer(), 1000)
  }

  disconnect() {
    clearInterval(this.timerInterval)
  }

  // Auto-focus the continue button the moment feedback is rendered
  continueBtnTargetConnected(target) {
    target.focus()
  }

  handleKey(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case "Escape":
        if (this.hasExitLinkTarget) this.exitLinkTarget.click()
        break
      case "Enter":
        if (this.hasContinueBtnTarget) {
          event.preventDefault()
          this.continueBtnTarget.click()
        }
        break
      case " ":
        if (this.hasContinueBtnTarget) {
          event.preventDefault()
          this.continueBtnTarget.click()
        }
        break
      case "1":
      case "2":
      case "3":
      case "4":
        this.#selectOptionByIndex(parseInt(event.key, 10) - 1)
        break
    }
  }

  #selectOptionByIndex(index) {
    const options = this.element.querySelectorAll(".test-option:not([disabled])")
    if (options[index]) options[index].click()
  }

  #tickTimer() {
    this.seconds++
    if (!this.hasTimerTarget) return
    const m = String(Math.floor(this.seconds / 60)).padStart(2, "0")
    const s = String(this.seconds % 60).padStart(2, "0")
    this.timerTarget.textContent = `${m}:${s}`
  }
}
