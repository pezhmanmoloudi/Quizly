import { Controller } from "@hotwired/stimulus"

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
  }

  disconnect() {
    this.#isSubmitting = false
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
        if (this.hasSettingsDrawerTarget && this.settingsDrawerTarget.classList.contains("is-open")) {
          this.closeSettings()
        } else if (this.hasExitLinkTarget) {
          this.exitLinkTarget.click()
        }
        break
    }
  }

  #applyStoredSettings() {
    if (!this.hasNewLimitSelectTarget || !this.hasPrioritySelectTarget) return
    const params = new URLSearchParams(window.location.search)
    if (params.has("new_limit") || params.has("priority")) return
    try {
      const stored = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}")
      if (stored.new_limit != null) this.newLimitSelectTarget.value = stored.new_limit
      if (stored.priority  != null) this.prioritySelectTarget.value = stored.priority
    } catch {
      // ignore malformed storage
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
}
