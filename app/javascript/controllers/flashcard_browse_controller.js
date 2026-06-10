import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "currentDisplay", "totalDisplay", "progressFill", "progressTrack",
    "optionsPanel", "optionsOverlay",
    "playBtn", "playIcon", "pauseIcon",
    "shortcutsPanel", "shortcutsToggleBtn"
  ]
  static values = { total: Number }

  connect() {
    this.index = 0
    this.slides = Array.from(this.element.querySelectorAll(".flashcard-browse__slide"))
    this.playTimer = null
    this.element.focus()
  }

  disconnect() {
    if (this.playTimer) clearInterval(this.playTimer)
    this.slides = null
  }

  next() {
    this.#resetFlip()
    if (this.index < this.slides.length - 1) this.#goTo(this.index + 1)
  }

  previous() {
    this.#resetFlip()
    if (this.index > 0) this.#goTo(this.index - 1)
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
      case "s":
      case "S":
        event.preventDefault()
        this.#starCurrent()
        break
    }
  }

  // ── Options panel ──────────────────────────────────────────

  openOptions() {
    this.optionsPanelTarget.classList.add("is-open")
    this.optionsPanelTarget.setAttribute("aria-hidden", "false")
    this.optionsOverlayTarget.hidden = false
  }

  closeOptions() {
    this.optionsPanelTarget.classList.remove("is-open")
    this.optionsPanelTarget.setAttribute("aria-hidden", "true")
    this.optionsOverlayTarget.hidden = true
  }

  // ── Study options ──────────────────────────────────────────

  toggleTrackProgress(event) {
    if (this.hasProgressTrackTarget) {
      this.progressTrackTarget.hidden = !event.target.checked
    }
  }

  toggleStarredOnly(event) {
    this.#resetFlip()
    const all = Array.from(this.element.querySelectorAll(".flashcard-browse__slide"))
    this.slides = event.target.checked
      ? all.filter(s => s.dataset.starred === "true")
      : all
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = this.slides.length
    }
    this.#showOnly(0)
  }

  toggleBothSides(event) {
    this.element.querySelectorAll(".flashcard-card").forEach(card => {
      card.classList.toggle("fb--both-sides", event.target.checked)
    })
  }

  toggleShortcuts() {
    const panel = this.shortcutsPanelTarget
    const btn   = this.shortcutsToggleBtnTarget
    panel.hidden = !panel.hidden
    btn.textContent = panel.hidden
      ? (btn.dataset.showLabel || "Show")
      : (btn.dataset.hideLabel || "Hide")
  }

  // ── Audio ──────────────────────────────────────────────────

  speak() {
    if (!window.speechSynthesis) return
    const slide = this.slides[this.index]
    if (!slide) return
    const text = slide.querySelector(".flashcard-card__face--front")?.textContent?.trim()
    if (!text) return
    window.speechSynthesis.cancel()
    window.speechSynthesis.speak(new SpeechSynthesisUtterance(text))
  }

  // ── Auto-play ──────────────────────────────────────────────

  togglePlay() {
    if (this.playTimer) {
      this.#stopPlay()
    } else {
      this.#startPlay()
    }
  }

  // ── Shuffle ────────────────────────────────────────────────

  shuffle() {
    const arr = Array.from(this.slides)
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[arr[i], arr[j]] = [arr[j], arr[i]]
    }
    this.slides = arr
    this.#resetFlip()
    this.#showOnly(0)
  }

  // ── Private ────────────────────────────────────────────────

  #goTo(index) {
    this.slides[this.index].hidden = true
    this.index = index
    this.slides[this.index].hidden = false
    this.#updateCounter()
  }

  #showOnly(index) {
    this.slides.forEach((s, i) => { s.hidden = i !== index })
    this.index = index
    this.#updateCounter()
  }

  #updateCounter() {
    if (this.hasCurrentDisplayTarget) {
      this.currentDisplayTarget.textContent = this.index + 1
    }
    if (this.hasProgressFillTarget && this.slides.length) {
      const pct = Math.round((this.index + 1) / this.slides.length * 100)
      this.progressFillTarget.style.width = `${pct}%`
    }
  }

  #toggleFlip() {
    const slide = this.slides[this.index]
    if (!slide) return
    const inner = slide.querySelector(".flashcard-card__inner")
    if (inner) {
      inner.classList.toggle("is-flipped")
      return
    }
    const back    = this.element.querySelector("[data-flashcard-target='back']")
    const showBtn = this.element.querySelector("[data-flashcard-target='showButton']")
    if (back && showBtn) {
      const revealed = !back.hidden
      back.hidden    = revealed
      showBtn.hidden = !revealed
    }
  }

  #resetFlip() {
    const slide = this.slides[this.index]
    if (!slide) return
    const inner = slide.querySelector(".flashcard-card__inner")
    if (inner) {
      inner.classList.remove("is-flipped")
      return
    }
    const back    = this.element.querySelector("[data-flashcard-target='back']")
    const showBtn = this.element.querySelector("[data-flashcard-target='showButton']")
    if (back)    back.hidden    = true
    if (showBtn) showBtn.hidden = false
  }

  #startPlay() {
    this.playBtnTarget.classList.add("is-playing")
    if (this.hasPlayIconTarget)  this.playIconTarget.hidden  = true
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = false

    this.playTimer = setInterval(() => {
      if (this.index < this.slides.length - 1) {
        this.#resetFlip()
        this.#goTo(this.index + 1)
      } else {
        this.#stopPlay()
      }
    }, 3000)
  }

  #stopPlay() {
    clearInterval(this.playTimer)
    this.playTimer = null
    this.playBtnTarget.classList.remove("is-playing")
    if (this.hasPlayIconTarget)  this.playIconTarget.hidden  = false
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = true
  }

  #starCurrent() {
    const slide = this.slides[this.index]
    if (!slide) return
    slide.querySelector(".star-btn")?.click()
  }

  #isFormElementFocused() {
    const tag = document.activeElement?.tagName
    return ["INPUT", "BUTTON", "TEXTAREA", "SELECT", "A"].includes(tag)
  }
}
