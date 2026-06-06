import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["continueBtn", "exitLink"]

  connect() {
    this.element.focus()
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
}
