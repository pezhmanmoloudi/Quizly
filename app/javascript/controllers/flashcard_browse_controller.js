import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["current", "progressFill"]
  static values = { total: Number }

  connect() {
    this.index = 0
    this.slides = this.element.querySelectorAll(".flashcard-browse__slide")
  }

  next() {
    this.#resetFlip()
    if (this.index < this.totalValue - 1) {
      this.#goTo(this.index + 1)
    }
  }

  previous() {
    this.#resetFlip()
    if (this.index > 0) {
      this.#goTo(this.index - 1)
    }
  }

  #goTo(index) {
    this.slides[this.index].hidden = true
    this.index = index
    this.slides[this.index].hidden = false
    this.currentTarget.textContent = this.index + 1
    if (this.hasProgressFillTarget) {
      const pct = Math.round((this.index + 1) / this.totalValue * 100)
      this.progressFillTarget.style.width = `${pct}%`
    }
  }

  #resetFlip() {
    const slide = this.slides[this.index]
    if (!slide) return
    const cardInner = slide.querySelector(".flashcard-card__inner")
    if (cardInner) {
      cardInner.classList.remove("is-flipped")
      return
    }
    const flashcardEl = this.element.querySelector("[data-controller='flashcard']")
    if (!flashcardEl) return
    const back = flashcardEl.querySelector("[data-flashcard-target='back']")
    const showBtn = flashcardEl.querySelector("[data-flashcard-target='showButton']")
    if (back) back.hidden = true
    if (showBtn) showBtn.hidden = false
  }
}
