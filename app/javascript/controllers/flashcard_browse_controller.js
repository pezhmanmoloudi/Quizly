import { Controller } from "@hotwired/stimulus"
import FlashcardAudioService from "flashcard_audio_service"
import FlashcardPlaybackService from "flashcard_playback_service"
import FlashcardEngine from "flashcard_engine"
import StudySRS from "study_srs"
import LearnEngine from "learn_engine"
import KeyboardManager from "keyboard_manager"

export default class extends Controller {
  static SETTINGS_KEY  = "quizly.flashcard.settings"
  static FLIP_HINT_KEY = "quizly.flashcard.flip_hint_count"

  static targets = [
    "currentDisplay", "totalDisplay", "progressFill", "progressTrack",
    "optionsPanel", "optionsOverlay",
    "audioBtn",
    "flipBar",
    "shortcutsPanel", "shortcutsToggleBtn",
    "trackProgressToggle",
    "ratingBar", "studyBar", "dueCount", "studyComplete",
    "prevBtn", "nextBtn",
    "learnFeedbackBar", "learnComplete", "learnHintZone",
    "learnNewCount", "learnWeakCount", "learnMasteryPct",
    "learnCompleteCount", "learnCompleteWeakImproved", "learnCompleteMastery"
  ]

  static values = {
    total:         Number,
    mode:          { type: String,  default: "browse" },
    progress:      { type: Array,   default: [] },
    learnItems:    { type: Array,   default: [] },
    learnSettings: { type: Object,  default: {} }
  }

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

    this.studySRS = null
    if (this.modeValue === "study" && this.progressValue.length > 0) {
      this.studySRS = new StudySRS(this.progressValue, "/card_progresses/:id/grade")
      this.engine.setOrder(this.studySRS.getNextQueue(this.allSlides))
    } else if (this.settings.shuffle) {
      const order = this.allSlides.map((_, i) => i)
      this.engine.setOrder(this.#buildShuffledIndices(order))
    }

    this.learnEngine = null
    if (this.modeValue === "learn" && this.learnItemsValue.length > 0) {
      this.learnEngine = new LearnEngine(this.learnItemsValue, this.allSlides, this.learnSettingsValue)
      this.engine.setOrder(this.learnEngine.getLearnQueue())
    }

    this.#initRender()
    if (this.modeValue === "study") this.#initStudyUI()
    if (this.modeValue === "learn") this.#initLearnUI()
    this.#syncSettingsUI()
    this.#updateFlipHint()
    this.element.focus()

    // Keyboard routing is owned by the global KeyboardManager. Map this controller's three
    // modeValues onto manager modes; the in-flashcard "study" sub-mode reveals via flip (not a
    // showButton) so it uses its own keymap. State (flip = revealed) is pulled at keydown time.
    const kbMode = { browse: "flashcard", learn: "learn", study: "flashcard_study" }[this.modeValue]
    KeyboardManager.register(this, kbMode, () => ({ revealed: !!this.engine?.flipped }))
  }

  disconnect() {
    this.playback.stop()
    if (window.speechSynthesis) window.speechSynthesis.cancel()
    KeyboardManager.unregister(this)
  }

  // ── Public actions ─────────────────────────────────────────

  next() {
    if (this.modeValue === "study" || this.modeValue === "learn") return
    this.playback.stop()
    if (this.engine.currentIndex < this.engine.size - 1) {
      this.engine.resetFlip(this.settings.startWithBack)
      this.engine.next()
      if (this.settings.autoPlayAudio) this.#speakCurrentSide()
    }
  }

  previous() {
    if (this.modeValue === "study" || this.modeValue === "learn") return
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
    if (this.modeValue === "study" && this.engine.flipped) this.#showRatingButtons()
    if (this.modeValue === "learn") {
      if (this.engine.flipped) {
        this.#showLearnFeedbackBar()
        this.#hideLearnHintZone()
      } else {
        this.#hideLearnFeedbackBar()
        this.#showLearnHintZone()
      }
    }
  }

  speak() {
    this.#speakCurrentSide()
  }

  // Keyboard action (routed by KeyboardManager in browse mode)
  star() {
    this.#starCurrent()
  }

  // ── Learn mode: settings drawer ────────────────────────────

  openLearnSettings() {
    if (this.hasOptionsPanelTarget) {
      this.optionsPanelTarget.classList.add("is-open")
      this.optionsPanelTarget.setAttribute("aria-hidden", "false")
    }
    if (this.hasOptionsOverlayTarget) this.optionsOverlayTarget.hidden = false
  }

  closeLearnSettings() {
    if (this.hasOptionsPanelTarget) {
      this.optionsPanelTarget.classList.remove("is-open")
      this.optionsPanelTarget.setAttribute("aria-hidden", "true")
    }
    if (this.hasOptionsOverlayTarget) this.optionsOverlayTarget.hidden = true
  }

  showHint() {
    this.#currentSlide?.querySelector(".learn-hint")?.classList.add("learn-hint--visible")
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

  // ── Study mode: public grade actions ──────────────────────

  async gradeAgain() { await this.#grade("again") }
  async gradeHard()  { await this.#grade("hard")  }
  async gradeGood()  { await this.#grade("good")  }
  async gradeEasy()  { await this.#grade("easy")  }

  // ── Learn mode: public feedback actions ───────────────────

  gotIt()    { this.#recordLearnFeedback("got_it")    }
  confused() { this.#recordLearnFeedback("confused")  }
  dontKnow() { this.#recordLearnFeedback("dont_know") }

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
    if (this.modeValue === "study") this.#hideRatingButtons()
    if (this.modeValue === "learn") {
      this.#hideLearnFeedbackBar()
      this.#showLearnHintZone()
      slide.querySelector(".learn-hint")?.classList.remove("learn-hint--visible")
    }
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

  // ── Private: study mode ────────────────────────────────────

  async #grade(rating) {
    if (!this.studySRS) return
    const slide = this.#currentSlide
    if (!slide?.dataset.cardProgressId) return

    await this.studySRS.gradeCard(slide.dataset.cardProgressId, rating)

    const newOrder  = this.studySRS.getNextQueue(this.allSlides)
    this.engine.setOrder(newOrder)
    this.#updateDueCount()

    if (this.studySRS.getDueCount(this.allSlides) === 0) {
      this.#showStudyComplete()
    } else {
      this.engine.resetFlip(false)
      this.engine.goTo(0)
    }
  }

  #initStudyUI() {
    if (this.hasPrevBtnTarget) this.prevBtnTarget.hidden = true
    if (this.hasNextBtnTarget) this.nextBtnTarget.hidden = true
    if (this.hasStudyBarTarget) this.studyBarTarget.hidden = false
    this.#updateDueCount()
  }

  #showRatingButtons() {
    if (this.hasRatingBarTarget) this.ratingBarTarget.hidden = false
  }

  #hideRatingButtons() {
    if (this.hasRatingBarTarget) this.ratingBarTarget.hidden = true
  }

  #updateDueCount() {
    if (!this.studySRS || !this.hasDueCountTarget) return
    this.dueCountTarget.textContent = this.studySRS.getDueCount(this.allSlides)
  }

  #showStudyComplete() {
    this.#hideRatingButtons()
    const stage = this.element.querySelector(".fb__stage")
    if (stage) stage.hidden = true
    if (this.hasStudyCompleteTarget) this.studyCompleteTarget.hidden = false
    if (this.hasDueCountTarget) this.dueCountTarget.textContent = "0"
  }

  // ── Private: learn mode ────────────────────────────────────

  #initLearnUI() {
    if (this.hasPrevBtnTarget) this.prevBtnTarget.hidden = true
    if (this.hasNextBtnTarget) this.nextBtnTarget.hidden = true
    // Never leave a blank stage: if the queue is empty (no current card) or the
    // session is already mastered, show the completion screen instead.
    if (this.engine.size === 0 || this.learnEngine?.isComplete()) {
      this.#showLearnComplete()
    } else {
      this.#updateLearnStats()
    }
  }

  #showLearnFeedbackBar() {
    if (this.hasLearnFeedbackBarTarget) this.learnFeedbackBarTarget.hidden = false
  }

  #hideLearnFeedbackBar() {
    if (this.hasLearnFeedbackBarTarget) this.learnFeedbackBarTarget.hidden = true
  }

  #showLearnHintZone() {
    if (this.hasLearnHintZoneTarget) this.learnHintZoneTarget.hidden = false
  }

  #hideLearnHintZone() {
    if (this.hasLearnHintZoneTarget) this.learnHintZoneTarget.hidden = true
  }

  #updateLearnStats() {
    if (!this.learnEngine) return
    const { newCount, weakCount, masteryPct } = this.learnEngine.getStats()
    if (this.hasLearnNewCountTarget)   this.learnNewCountTarget.textContent   = newCount
    if (this.hasLearnWeakCountTarget)  this.learnWeakCountTarget.textContent  = weakCount
    if (this.hasLearnMasteryPctTarget) this.learnMasteryPctTarget.textContent = `${masteryPct}%`
    if (this.hasProgressFillTarget)    this.progressFillTarget.style.width    = `${masteryPct}%`
  }

  #recordLearnFeedback(feedback) {
    if (!this.learnEngine) return
    const slide = this.#currentSlide
    if (!slide) return
    const flashcardId = parseInt(slide.dataset.flashcardId, 10)
    const itemId      = this.learnEngine.getItemId(flashcardId)

    this.learnEngine.recordFeedback(flashcardId, feedback)
    this.#updateLearnStats()
    this.#postLearnFeedback(itemId, feedback)

    if (this.learnEngine.isComplete()) { this.#showLearnComplete(); return }

    this.engine.setOrder(this.learnEngine.getLearnQueue())
    this.engine.resetFlip(false)
    this.#hideLearnFeedbackBar()
    this.engine.goTo(0)
  }

  async #postLearnFeedback(itemId, feedback) {
    if (!itemId) return
    const token = document.querySelector('meta[name="csrf-token"]')?.content || ""
    try {
      await fetch("/learn_feedbacks", {
        method:  "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
        body:    JSON.stringify({ learn_session_item_id: itemId, feedback })
      })
    } catch { /* non-blocking */ }
  }

  #showLearnComplete() {
    this.#hideLearnFeedbackBar()
    if (this.hasLearnHintZoneTarget) this.learnHintZoneTarget.hidden = true
    const stage = this.element.querySelector(".fb__stage")
    if (stage) stage.hidden = true
    if (this.hasLearnCompleteTarget) this.learnCompleteTarget.hidden = false

    if (this.learnEngine) {
      const { learnedCount, weakImprovedCount, masteryPct } = this.learnEngine.getCompletionStats()
      if (this.hasLearnCompleteCountTarget)          this.learnCompleteCountTarget.textContent          = learnedCount
      if (this.hasLearnCompleteWeakImprovedTarget)   this.learnCompleteWeakImprovedTarget.textContent   = weakImprovedCount
      if (this.hasLearnCompleteMasteryTarget)        this.learnCompleteMasteryTarget.textContent        = `${masteryPct}%`
    }
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
    if (!this.audio) return
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
    // In learn mode the progress bar reflects mastery (#updateLearnStats owns it); the queue
    // resets to index 0 each feedback, so a position-based width here would look stuck.
    if (this.modeValue !== "learn" && this.hasProgressFillTarget && total) {
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

    // Apply side effects of restored settings — browse-only.
    // showBothSides and autoAdvance are flashcard-browse features stored in the shared
    // settings localStorage; never let them bleed into study/learn modes.
    if (this.modeValue === "browse") {
      if (this.settings.showBothSides) {
        this.element.querySelectorAll(".flashcard-card").forEach(c =>
          c.classList.add("fb--both-sides")
        )
      }
      if (this.settings.autoAdvance) this.playback.start()
    }
  }

  // ── Private: helpers ───────────────────────────────────────

  #starCurrent() {
    this.#currentSlide?.querySelector(".star-btn")?.click()
  }

}
