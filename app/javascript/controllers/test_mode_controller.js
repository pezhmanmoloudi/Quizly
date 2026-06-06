import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["exitLink"]

  connect() {
    this.element.focus()
  }

  handleKey(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case "Escape":
        if (this.hasExitLinkTarget) this.exitLinkTarget.click()
        break
      case " ":
        this.#triggerContinue(event)
        break
      case "1":
      case "2":
      case "3":
      case "4":
        this.#selectOptionByIndex(parseInt(event.key, 10) - 1)
        break
    }
  }

  #triggerContinue(event) {
    const btn = this.element.querySelector(".test-question__continue")
    if (!btn) return
    event.preventDefault()
    btn.click()
  }

  #selectOptionByIndex(index) {
    const options = this.element.querySelectorAll(".test-option:not([disabled])")
    if (options[index]) options[index].click()
  }
}
