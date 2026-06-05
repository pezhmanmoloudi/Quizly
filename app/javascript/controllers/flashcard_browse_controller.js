import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["current", "progressFill"]
  static values = { total: Number }

  connect() {
    this.index = 0
    this.slides = this.element.querySelectorAll(".flashcard-browse__slide")
    this.element.focus()
  }

  disconnect() {
    this.slides = null
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

  handleKey(event) {
    if (this.#isFormElementFocused()) return
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case " ":
        event.preventDefault()
        this.#toggleFlip()
        break
      case "ArrowLeft":
        event.preventDefault()
        this.previous()
        break
      case "ArrowRight":
        event.preventDefault()
        this.next()
        break
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

  #toggleFlip() {
    const slide = this.slides[this.index]
    if (!slide) return
    const cardInner = slide.querySelector(".flashcard-card__inner")
    if (cardInner) {
      cardInner.classList.toggle("is-flipped")
      return
    }
    // Fallback for non-3D card variant
    const back    = this.element.querySelector("[data-flashcard-target='back']")
    const showBtn = this.element.querySelector("[data-flashcard-target='showButton']")
    if (back && showBtn) {
      const isRevealed = !back.hidden
      back.hidden    = isRevealed
      showBtn.hidden = !isRevealed
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
    const back    = flashcardEl.querySelector("[data-flashcard-target='back']")
    const showBtn = flashcardEl.querySelector("[data-flashcard-target='showButton']")
    if (back)    back.hidden    = true
    if (showBtn) showBtn.hidden = false
  }

  #isFormElementFocused() {
    const tag = document.activeElement?.tagName
    return ["INPUT", "BUTTON", "TEXTAREA", "SELECT", "A"].includes(tag)
  }
}
