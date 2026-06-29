import { Controller } from "@hotwired/stimulus"
import KeyboardManager from "keyboard_manager"

export default class extends Controller {
  static targets = ["continueBtn", "exitLink", "timer"]

  connect() {
    this.element.focus()
    this.seconds = 0
    this.timerInterval = setInterval(() => this.#tickTimer(), 1000)
    // "submitted" == feedback shown == the continue button is present in the DOM.
    KeyboardManager.register(this, "test", () => ({ submitted: this.hasContinueBtnTarget }))
  }

  disconnect() {
    clearInterval(this.timerInterval)
    KeyboardManager.unregister(this)
  }

  // Auto-focus the continue button the moment feedback is rendered
  continueBtnTargetConnected(target) {
    target.focus()
  }

  // ── Keyboard actions (routed by KeyboardManager) ───────────
  selectOption(index) { this.#selectOptionByIndex(index) }
  continue()          { if (this.hasContinueBtnTarget) this.continueBtnTarget.click() }
  onEscape()          { if (this.hasExitLinkTarget) this.exitLinkTarget.click() }

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
