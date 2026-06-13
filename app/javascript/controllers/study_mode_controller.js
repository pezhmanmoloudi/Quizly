import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["showButton", "againBtn", "hardBtn", "goodBtn", "easyBtn", "exitLink", "timer", "streak"]

  #isSubmitting = false

  connect() {
    this.element.focus()
    this.seconds = 0
    this.timerInterval = setInterval(() => this.#tickTimer(), 1000)
  }

  disconnect() {
    this.#isSubmitting = false
    clearInterval(this.timerInterval)
  }

  trackRating() {
    // streak is server-managed via session; page reloads after rating with updated value
  }

  handleKey(event) {
    if (this.#isFormElementFocused()) return
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case " ":
        event.preventDefault()
        this.#revealCard()
        break
      case "1":
        this.#submitRating("againBtn")
        break
      case "2":
        this.#submitRating("hardBtn")
        break
      case "3":
        this.#submitRating("goodBtn")
        break
      case "4":
        this.#submitRating("easyBtn")
        break
      case "Escape":
        if (this.hasExitLinkTarget) this.exitLinkTarget.click()
        break
    }
  }

  #revealCard() {
    if (!this.hasShowButtonTarget) return
    if (this.showButtonTarget.hidden) return  // already revealed
    this.showButtonTarget.click()
  }

  #submitRating(targetName) {
    // Card must be revealed (show button hidden) before rating is allowed
    if (this.hasShowButtonTarget && !this.showButtonTarget.hidden) return
    if (this.#isSubmitting) return

    const target = this[`has${this.#capitalise(targetName)}Target`]
      ? this[`${targetName}Target`]
      : null
    if (!target) return

    this.#isSubmitting = true
    this.#disableRatingButtons()
    target.click()
  }

  #disableRatingButtons() {
    for (const name of ["againBtn", "hardBtn", "goodBtn", "easyBtn"]) {
      const key = `has${this.#capitalise(name)}Target`
      if (this[key]) this[`${name}Target`].disabled = true
    }
  }

  #capitalise(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  #isFormElementFocused() {
    const tag = document.activeElement?.tagName
    return ["INPUT", "BUTTON", "TEXTAREA", "SELECT", "A"].includes(tag)
  }

  #tickTimer() {
    this.seconds++
    if (!this.hasTimerTarget) return
    const m = String(Math.floor(this.seconds / 60)).padStart(2, "0")
    const s = String(this.seconds % 60).padStart(2, "0")
    this.timerTarget.textContent = `${m}:${s}`
  }
}
