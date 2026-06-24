import { Controller } from "@hotwired/stimulus"
import FlashcardAudioService from "flashcard_audio_service"
import FlashcardPlaybackService from "flashcard_playback_service"

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
    // Stable slide references — never reordered
    this.allSlides = Array.from(this.element.querySelectorAll(".flashcard-browse__slide"))
    // Navigation order — only this array is mutated on shuffle
    this.cardOrder = this.allSlides.map((_, i) => i)
    this.index = 0

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

    if (this.settings.shuffle) this.#buildShuffledOrder()
    this.#showOnly(0)
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
    if (this.index < this.#slideCount - 1) this.#goTo(this.index + 1)
  }

  previous() {
    this.playback.stop()
    if (this.index > 0) this.#goTo(this.index - 1)
  }

  flip() {
    this.playback.stop()
    this.#toggleFlipState(this.#currentSlide)
    this.#incrementFlipHint()
    this.#updateAudioBtnState()
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
    if (event.target.checked) {
      this.cardOrder = allIndices.filter(i => this.allSlides[i].dataset.starred === "true")
      if (this.settings.shuffle) this.#buildShuffledOrder()
    } else {
      this.cardOrder = allIndices
      if (this.settings.shuffle) this.#buildShuffledOrder()
    }
    this.#showOnly(0)
  }

  // ── Display section toggles ────────────────────────────────

  toggleShuffle(event) {
    this.settings.shuffle = event.target.checked
    this.#persistSettings()
    const starredOnly = this.element.querySelector("[data-setting='starredOnly']")?.checked
    const baseIndices  = this.allSlides.map((_, i) => i)
    this.cardOrder = starredOnly
      ? baseIndices.filter(i => this.allSlides[i].dataset.starred === "true")
      : baseIndices
    if (this.settings.shuffle) this.#buildShuffledOrder()
    this.#showOnly(0)
  }

  toggleStartSide(event) {
    this.settings.startWithBack = event.target.value === "back"
    this.#persistSettings()
    const slide = this.#currentSlide
    slide.dataset.flipped = this.settings.startWithBack ? "true" : "false"
    this.#applyFlipState(slide)
    this.#updateAudioBtnState()
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

  get #currentSlide() { return this.allSlides[this.cardOrder[this.index]] }
  get #slideCount()   { return this.cardOrder.length }

  #goTo(index) {
    this.#currentSlide.hidden = true
    this.index = index
    const slide = this.#currentSlide
    slide.hidden = false
    // startWithBack applies to manual navigation only; auto-advance ignores it
    slide.dataset.flipped = this.settings.startWithBack ? "true" : "false"
    this.#applyFlipState(slide)
    this.#updateCounter()
    this.#updateAudioBtnState()
    if (this.settings.autoPlayAudio) this.#speakCurrentSide()
  }

  #showOnly(index) {
    this.allSlides.forEach(s => { s.hidden = true })
    this.index = index
    if (!this.#currentSlide) return
    this.#currentSlide.hidden = false
    this.#currentSlide.dataset.flipped = this.settings.startWithBack ? "true" : "false"
    this.#applyFlipState(this.#currentSlide)
    this.#updateCounter()
    this.#updateAudioBtnState()
  }

  // ── Private: flip state ────────────────────────────────────

  #toggleFlipState(slide) {
    slide.dataset.flipped = slide.dataset.flipped === "true" ? "false" : "true"
    this.#applyFlipState(slide)
  }

  #applyFlipState(slide) {
    const flipped = slide.dataset.flipped === "true"
    slide.querySelector(".flashcard-card__inner")?.classList.toggle("is-flipped", flipped)
  }

  // Called by playback service — always flips to back, never toggles
  #flipToBack() {
    const slide = this.#currentSlide
    if (!slide) return
    slide.dataset.flipped = "true"
    this.#applyFlipState(slide)
    this.#updateAudioBtnState()
    if (this.settings.autoPlayAfterFlip) this.#speakCurrentSide()
  }

  // Called by playback service — returns false when at last card
  #advanceToNext() {
    if (this.index >= this.#slideCount - 1) return false
    this.#goTo(this.index + 1)
    return true
  }

  // ── Private: shuffle ───────────────────────────────────────

  #buildShuffledOrder() {
    const arr = [...this.cardOrder]
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[arr[i], arr[j]] = [arr[j], arr[i]]
    }
    this.cardOrder = arr
  }

  // ── Private: audio ─────────────────────────────────────────

  #speakCurrentSide() {
    const slide = this.#currentSlide
    if (!slide) return
    const isFlipped = slide.dataset.flipped === "true"
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
    const isFlipped = slide.dataset.flipped === "true"
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
    if (this.hasCurrentDisplayTarget) {
      this.currentDisplayTarget.textContent = this.index + 1
    }
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = this.#slideCount
    }
    if (this.hasProgressFillTarget && this.#slideCount) {
      const pct = Math.round((this.index + 1) / this.#slideCount * 100)
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
