import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["current"]
  static values = { total: Number }

  connect() {
    this.index = 0
    this.slides = this.element.querySelectorAll(".flashcard-browse__slide")
  }

  next() {
    if (this.index < this.totalValue - 1) {
      this.#goTo(this.index + 1)
    }
    this.#resetFlip()
  }

  previous() {
    if (this.index > 0) {
      this.#goTo(this.index - 1)
    }
    this.#resetFlip()
  }

  #goTo(index) {
    this.slides[this.index].hidden = true
    this.index = index
    this.slides[this.index].hidden = false
    this.currentTarget.textContent = this.index + 1
  }

  #resetFlip() {
    const flashcardEl = this.element.querySelector("[data-controller='flashcard']")
    if (!flashcardEl) return
    const back = flashcardEl.querySelector("[data-flashcard-target='back']")
    const showBtn = flashcardEl.querySelector("[data-flashcard-target='showButton']")
    if (back) back.hidden = true
    if (showBtn) showBtn.hidden = false
  }
}
