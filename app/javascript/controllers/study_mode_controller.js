import { Controller } from "@hotwired/stimulus"
import KeyboardManager from "keyboard_manager"

const STORAGE_KEY = "quizly.study.settings"

export default class extends Controller {
  static targets = [
    "showButton", "againBtn", "hardBtn", "goodBtn", "easyBtn",
    "exitLink", "streak",
    "settingsDrawer", "settingsOverlay", "settingsBtn", "newLimitSelect", "prioritySelect"
  ]

  #isSubmitting = false

  connect() {
    this.element.focus()
    this.#applyStoredSettings()
    // Keyboard routing is owned by the global KeyboardManager; we expose live state via a
    // provider (pulled at keydown time) so phase/lock are always current across Turbo swaps.
    KeyboardManager.register(this, "study", () => ({
      phase:       (this.hasShowButtonTarget && this.showButtonTarget.hidden) ? "revealed" : "question",
      inputLocked: this.#isSubmitting
    }))
  }

  disconnect() {
    this.#isSubmitting = false
    KeyboardManager.unregister(this)
  }

  openSettings() {
    this.settingsDrawerTarget.classList.add("is-open")
    this.settingsDrawerTarget.setAttribute("aria-hidden", "false")
    this.settingsOverlayTarget.hidden = false
    this.settingsBtnTarget.setAttribute("aria-expanded", "true")
  }

  closeSettings() {
    this.settingsDrawerTarget.classList.remove("is-open")
    this.settingsDrawerTarget.setAttribute("aria-hidden", "true")
    this.settingsOverlayTarget.hidden = true
    this.settingsBtnTarget.setAttribute("aria-expanded", "false")
  }

  saveSettings() {
    const settings = {
      new_limit: this.newLimitSelectTarget.value,
      priority:  this.prioritySelectTarget.value
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings))
  }

  resetSubmitLock() {
    this.#isSubmitting = false
  }

  trackRating() {
    // streak is server-managed via session; page reloads after rating with updated value
  }

  // ── Keyboard actions (routed by KeyboardManager) ───────────
  reveal()     { this.#revealCard() }
  gradeAgain() { this.#submitRating("againBtn") }
  gradeHard()  { this.#submitRating("hardBtn") }
  gradeGood()  { this.#submitRating("goodBtn") }
  gradeEasy()  { this.#submitRating("easyBtn") }

  onEscape() {
    if (this.hasSettingsDrawerTarget && this.settingsDrawerTarget.classList.contains("is-open")) {
      this.closeSettings()
    } else if (this.hasExitLinkTarget) {
      this.exitLinkTarget.click()
    }
  }

  // Study mode is server-rendered: the runtime (due query, hidden rating fields, due count) is
  // derived from URL params, defaulting to 10/"due". localStorage is the persisted source of truth
  // but only reaches the modal. On a plain revisit (no URL params) we reapply the persisted values
  // through the request — a one-time navigation — so runtime + hidden fields + modal all agree.
  // When URL params are present they stay authoritative (and the reloaded page has params, so this
  // early-returns: no loop).
  #applyStoredSettings() {
    if (!this.hasNewLimitSelectTarget || !this.hasPrioritySelectTarget) return
    const params = new URLSearchParams(window.location.search)
    if (params.has("new_limit") || params.has("priority")) return

    let stored
    try {
      stored = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}")
    } catch {
      return // malformed storage — leave the server-rendered defaults in place
    }
    if (stored.new_limit == null && stored.priority == null) return

    // Server-rendered values are the current runtime; fall back to them for any missing key.
    const currentLimit    = this.newLimitSelectTarget.value
    const currentPriority = this.prioritySelectTarget.value
    const targetLimit     = stored.new_limit != null ? String(stored.new_limit) : currentLimit
    const targetPriority  = stored.priority  != null ? String(stored.priority)  : currentPriority

    // Already consistent with the runtime (e.g. stored equals the default) — nothing to reapply.
    if (targetLimit === currentLimit && targetPriority === currentPriority) return

    // Reapply persisted settings via the request so the session initializes with them.
    const url = new URL(window.location.href)
    url.searchParams.set("new_limit", targetLimit)
    url.searchParams.set("priority", targetPriority)

    if (window.Turbo) {
      window.Turbo.visit(url.toString(), { action: "replace" })
    } else {
      window.location.replace(url.toString())
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

    // Submit first, THEN disable — disabling before the click would make target.click() a
    // no-op (a disabled submit input does nothing), silently swallowing keyboard ratings.
    this.#isSubmitting = true
    target.click()
    this.#disableRatingButtons()
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

}
