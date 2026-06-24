import { Controller } from "@hotwired/stimulus"
import FlashcardAudioService from "flashcard_audio_service"
import FlashcardPlaybackService from "flashcard_playback_service"
import FlashcardEngine from "flashcard_engine"

export default class extends Controller {
  static SETTINGS_KEY  = "quizly.flashcard.settings"
  static FLIP_HINT_KEY = "quizly.flashcard.flip_hint_count"

  static targets = [
    "currentDisplay", "totalDisplay", "progressFill", "progressTrack",
    "optionsPanel", "optionsOverlay",
    "audioBtn",
    "flipBar",
    "shortcutsPanel", "shortcutsToggleBtn",
    "trackProgressToggle"
  ]

  static values = { total: Number }

  // ── Lifecycle ──────────────────────────────────────────────

  connect() {
    // Stable slide references — never reordered, used for DOM rendering only
    this.allSlides = Array.from(this.element.querySelectorAll(".flashcard-browse__slide"))

    this.engine = new FlashcardEngine(this.allSlides.length)
    this.engine.on('onCardChange', ({ index, cardIndex }) => this.#renderCard(index, cardIndex))
    this.engine.on('onFlip',       ({ flipped })          => this.#renderFlip(flipped))

    this.#loadSettings()
    this.flipHintCount = parseInt(
      localStorage.getItem(this.constructor.FLIP_HINT_KEY) || "0"
    )

    this.audio = new FlashcardAudioService(() => this.#updateAudioBtnState())
    this.playback = new FlashcardPlaybackService({
      onFlip:   () => this.#flipToBack(),
      onNext:   () => this.#advanceToNext(),
      getDelay: () => this.settings.autoAdvanceDelay
    })

    if (this.settings.shuffle) {
      const order = this.allSlides.map((_, i) => i)
      this.engine.setOrder(this.#buildShuffledIndices(order))
    }

    this.#initRender()
    this.#syncSettingsUI()
    this.#updateFlipHint()
    this.element.focus()
  }

  disconnect() {
    this.playback.stop()
    if (window.speechSynthesis) window.speechSynthesis.cancel()
  }

  // ── Public actions ─────────────────────────────────────────

  next() {
    this.playback.stop()
    if (this.engine.currentIndex < this.engine.size - 1) {
      this.engine.resetFlip(this.settings.startWithBack)
      this.engine.next()
      if (this.settings.autoPlayAudio) this.#speakCurrentSide()
    }
  }

  previous() {
    this.playback.stop()
    if (this.engine.currentIndex > 0) {
      this.engine.resetFlip(this.settings.startWithBack)
      this.engine.previous()
      if (this.settings.autoPlayAudio) this.#speakCurrentSide()
    }
  }

  flip() {
    this.playback.stop()
    this.engine.flip()
    this.#incrementFlipHint()
    if (this.settings.autoPlayAfterFlip) this.#speakCurrentSide()
  }

  speak() {
    this.#speakCurrentSide()
  }

  handleKey(event) {
    if (this.#isFormElementFocused()) return
    if (event.ctrlKey || event.metaKey || event.altKey) return

    switch (event.key) {
      case " ":
        event.preventDefault()
        this.flip()
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

  // ── Study section toggles ──────────────────────────────────

  toggleTrackProgress(event) {
    if (this.hasProgressTrackTarget) {
      this.progressTrackTarget.hidden = !event.target.checked
    }
  }

  toggleStarredOnly(event) {
    const allIndices = this.allSlides.map((_, i) => i)
    let order = event.target.checked
      ? allIndices.filter(i => this.allSlides[i].dataset.starred === "true")
      : allIndices
    if (this.settings.shuffle) order = this.#buildShuffledIndices(order)
    this.engine.setOrder(order)
    this.#initRender()
  }

  // ── Display section toggles ────────────────────────────────

  toggleShuffle(event) {
    this.settings.shuffle = event.target.checked
    this.#persistSettings()
    const starredOnly = this.element.querySelector("[data-setting='starredOnly']")?.checked
    const baseIndices = this.allSlides.map((_, i) => i)
    let order = starredOnly
      ? baseIndices.filter(i => this.allSlides[i].dataset.starred === "true")
      : baseIndices
    if (this.settings.shuffle) order = this.#buildShuffledIndices(order)
    this.engine.setOrder(order)
    this.#initRender()
  }

  toggleStartSide(event) {
    this.settings.startWithBack = event.target.value === "back"
    this.#persistSettings()
    this.engine.resetFlip(this.settings.startWithBack)
    this.#renderFlip(this.engine.flipped)
  }

  toggleBothSides(event) {
    this.settings.showBothSides = event.target.checked
    this.#persistSettings()
    this.element.querySelectorAll(".flashcard-card").forEach(card => {
      card.classList.toggle("fb--both-sides", event.target.checked)
    })
  }

  // ── Audio section toggles ──────────────────────────────────

  toggleAutoPlayAudio(event) {
    this.settings.autoPlayAudio = event.target.checked
    this.#persistSettings()
  }

  toggleAutoPlayAfterFlip(event) {
    this.settings.autoPlayAfterFlip = event.target.checked
    this.#persistSettings()
  }

  // ── Playback section toggles ───────────────────────────────

  toggleAutoAdvance(event) {
    this.settings.autoAdvance = event.target.checked
    this.#persistSettings()
    if (event.target.checked) this.playback.start()
    else this.playback.stop()
  }

  setAutoAdvanceDelay(event) {
    this.settings.autoAdvanceDelay = parseInt(event.target.value)
    this.#persistSettings()
    if (this.playback.isRunning) {
      this.playback.stop()
      this.playback.start()
    }
  }

  // ── Keyboard shortcuts toggle ──────────────────────────────

  toggleShortcuts() {
    const panel = this.shortcutsPanelTarget
    const btn   = this.shortcutsToggleBtnTarget
    panel.hidden = !panel.hidden
    btn.textContent = panel.hidden
      ? (btn.dataset.showLabel || "Show")
      : (btn.dataset.hideLabel || "Hide")
  }

  // ── Private: slide resolution ──────────────────────────────

  get #currentSlide() { return this.allSlides[this.engine.currentCardIndex] }

  // ── Private: render handlers ───────────────────────────────

  #renderCard(index, cardIndex) {
    this.allSlides.forEach(s => { s.hidden = true })
    const slide = this.allSlides[cardIndex]
    if (!slide) return
    slide.hidden = false
    this.#renderFlip(this.engine.flipped)
    this.#updateCounter()
  }

  #renderFlip(flipped) {
    const slide = this.#currentSlide
    if (!slide) return
    slide.dataset.flipped = flipped ? "true" : "false"
    slide.querySelector(".flashcard-card__inner")?.classList.toggle("is-flipped", flipped)
    this.#updateAudioBtnState()
  }

  #initRender() {
    this.allSlides.forEach(s => { s.hidden = true })
    const slide = this.allSlides[this.engine.currentCardIndex]
    if (!slide) return
    slide.hidden = false
    this.engine.resetFlip(this.settings.startWithBack)
    this.#renderFlip(this.engine.flipped)
    this.#updateCounter()
  }

  // ── Private: playback callbacks ────────────────────────────

  // Called by playback service — always flips to back, never toggles
  #flipToBack() {
    if (!this.#currentSlide) return
    this.engine.setFlipped(true)
    if (this.settings.autoPlayAfterFlip) this.#speakCurrentSide()
  }

  // Called by playback service — returns false when at last card
  #advanceToNext() {
    if (this.engine.currentIndex >= this.engine.size - 1) return false
    this.engine.resetFlip(this.settings.startWithBack)
    this.engine.next()
    if (this.settings.autoPlayAudio) this.#speakCurrentSide()
    return true
  }

  // ── Private: shuffle ───────────────────────────────────────

  #buildShuffledIndices(arr) {
    const result = [...arr]
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[result[i], result[j]] = [result[j], result[i]]
    }
    return result
  }

  // ── Private: audio ─────────────────────────────────────────

  #speakCurrentSide() {
    const slide = this.#currentSlide
    if (!slide) return
    const isFlipped = this.engine.flipped
    const selector  = isFlipped
      ? ".flashcard-card__face--back"
      : ".flashcard-card__face--front"
    const text = slide.querySelector(selector)?.textContent?.trim()
    const lang = isFlipped
      ? (slide.dataset.backLang || "")
      : (slide.dataset.frontLang || "")
    this.audio.speak(text, lang)
  }

  #updateAudioBtnState() {
    if (!this.hasAudioBtnTarget) return
    const slide = this.#currentSlide
    if (!slide) return
    const isFlipped = this.engine.flipped
    const lang = isFlipped ? slide.dataset.backLang : slide.dataset.frontLang
    const ok   = this.audio.isLangSupported(lang)
    this.audioBtnTarget.disabled = !ok
    this.audioBtnTarget.classList.toggle("is-unavailable", !ok)
    this.audioBtnTarget.setAttribute(
      "aria-label",
      ok ? this.audioBtnTarget.getAttribute("aria-label")?.replace(" (unavailable)", "") || "Play audio"
         : "Play audio (unavailable)"
    )
  }

  // ── Private: flip hint ─────────────────────────────────────

  #incrementFlipHint() {
    this.flipHintCount++
    try {
      localStorage.setItem(this.constructor.FLIP_HINT_KEY, this.flipHintCount)
    } catch { /* storage blocked */ }
    this.#updateFlipHint()
  }

  #updateFlipHint() {
    const condensed = this.flipHintCount >= 5
    this.element.querySelectorAll(".fb__flip-bar").forEach(bar => {
      bar.classList.toggle("fb__flip-bar--condensed", condensed)
    })
  }

  // ── Private: counter ───────────────────────────────────────

  #updateCounter() {
    const pos   = this.engine.currentIndex + 1
    const total = this.engine.size
    if (this.hasCurrentDisplayTarget) {
      this.currentDisplayTarget.textContent = pos
    }
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = total
    }
    if (this.hasProgressFillTarget && total) {
      const pct = Math.round(pos / total * 100)
      this.progressFillTarget.style.width = `${pct}%`
    }
  }

  // ── Private: settings persistence ─────────────────────────

  #loadSettings() {
    const defaults = {
      autoPlayAudio:      false,
      autoPlayAfterFlip:  false,
      startWithBack:      false,
      shuffle:            false,
      showBothSides:      false,
      autoAdvance:        false,
      autoAdvanceDelay:   3000
    }
    try {
      const saved = JSON.parse(
        localStorage.getItem(this.constructor.SETTINGS_KEY) || "{}"
      )
      this.settings = { ...defaults, ...saved }
    } catch {
      this.settings = defaults
    }
  }

  #persistSettings() {
    try {
      localStorage.setItem(
        this.constructor.SETTINGS_KEY,
        JSON.stringify(this.settings)
      )
    } catch { /* storage full or blocked */ }
  }

  #syncSettingsUI() {
    const panel = this.optionsPanelTarget
    if (!panel) return

    // Sync checkboxes by data-setting attribute
    const settingMap = {
      autoPlayAudio:     this.settings.autoPlayAudio,
      autoPlayAfterFlip: this.settings.autoPlayAfterFlip,
      shuffle:           this.settings.shuffle,
      showBothSides:     this.settings.showBothSides,
      autoAdvance:       this.settings.autoAdvance
    }
    Object.entries(settingMap).forEach(([key, value]) => {
      const el = panel.querySelector(`[data-setting="${key}"]`)
      if (el) el.checked = value
    })

    // Sync start side radio
    const startSide = this.settings.startWithBack ? "back" : "front"
    const radio = panel.querySelector(`[name="start_side"][value="${startSide}"]`)
    if (radio) radio.checked = true

    // Sync delay select
    const delaySelect = panel.querySelector("[data-setting='autoAdvanceDelay']")
    if (delaySelect) delaySelect.value = this.settings.autoAdvanceDelay

    // Apply side effects of restored settings
    if (this.settings.showBothSides) {
      this.element.querySelectorAll(".flashcard-card").forEach(c =>
        c.classList.add("fb--both-sides")
      )
    }
    if (this.settings.autoAdvance) this.playback.start()
  }

  // ── Private: helpers ───────────────────────────────────────

  #starCurrent() {
    this.#currentSlide?.querySelector(".star-btn")?.click()
  }

  #isFormElementFocused() {
    const tag = document.activeElement?.tagName
    return ["INPUT", "BUTTON", "TEXTAREA", "SELECT", "A"].includes(tag)
  }
}
