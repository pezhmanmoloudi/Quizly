import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "tab", "dot"]
  static values  = { autoplay: { type: Number, default: 5000 } }

  connect() {
    this.activeIndex = 0
    this.#timer       = null
    this.#touchStartX = null
    this.#updatePositions()
    this.#startAutoplay()
    this.#bindTouch()
  }

  disconnect() {
    this.#stopAutoplay()
  }

  next() {
    this.#goTo((this.activeIndex + 1) % this.slideTargets.length)
  }

  prev() {
    const len = this.slideTargets.length
    this.#goTo((this.activeIndex - 1 + len) % len)
  }

  goTo(event) {
    this.#goTo(parseInt(event.currentTarget.dataset.index, 10))
  }

  pauseAutoPlay()  { this.#stopAutoplay() }
  resumeAutoPlay() { this.#startAutoplay() }

  // ── private ───────────────────────────────────────────────

  #timer
  #touchStartX

  #goTo(index) {
    this.activeIndex = index
    this.#updatePositions()
    this.#stopAutoplay()
    this.#startAutoplay()
  }

  #updatePositions() {
    const len = this.slideTargets.length
    this.slideTargets.forEach((slide, i) => {
      const offset = ((i - this.activeIndex) % len + len) % len
      slide.classList.remove("is-active", "is-prev", "is-next", "is-far-prev", "is-far-next")
      if      (offset === 0)       slide.classList.add("is-active")
      else if (offset === 1)       slide.classList.add("is-next")
      else if (offset === 2)       slide.classList.add("is-far-next")
      else if (offset === len - 1) slide.classList.add("is-prev")
      else if (offset === len - 2) slide.classList.add("is-far-prev")
    })

    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("mode-selector__tab--active", i === this.activeIndex)
    })

    if (this.hasDotTarget) {
      this.dotTargets.forEach((dot, i) => {
        dot.classList.toggle("is-active", i === this.activeIndex)
      })
    }
  }

  #startAutoplay() {
    if (this.autoplayValue <= 0) return
    this.#timer = setInterval(() => this.next(), this.autoplayValue)
  }

  #stopAutoplay() {
    clearInterval(this.#timer)
    this.#timer = null
  }

  #bindTouch() {
    this.element.addEventListener("touchstart", e => {
      this.#touchStartX = e.touches[0].clientX
    }, { passive: true })

    this.element.addEventListener("touchend", e => {
      if (this.#touchStartX === null) return
      const delta = e.changedTouches[0].clientX - this.#touchStartX
      if (Math.abs(delta) >= 50) delta < 0 ? this.next() : this.prev()
      this.#touchStartX = null
    }, { passive: true })
  }
}
