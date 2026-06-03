import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "searchInput", "section", "sectionBody"]

  STORAGE_KEY = "sidebar_sections"

  connect() {
    this.restoreState()
  }

  openMobile() {
    this.sidebarTarget.classList.add("is-open")
    document.body.classList.add("sidebar-open")
  }

  closeMobile() {
    this.sidebarTarget.classList.remove("is-open")
    document.body.classList.remove("sidebar-open")
  }

  focusSearch(event) {
    event.preventDefault()
    this.searchInputTarget.focus()
    this.searchInputTarget.select()
  }

  toggleSection(event) {
    const trigger  = event.currentTarget
    const section  = trigger.closest("[data-sidebar-target='section']")
    const expanded = trigger.getAttribute("aria-expanded") === "true"

    trigger.setAttribute("aria-expanded", String(!expanded))
    section.classList.toggle("is-expanded", !expanded)

    this.#saveState()
  }

  restoreState() {
    const saved = this.#loadState()
    this.sectionTargets.forEach(section => {
      const key     = section.dataset.sectionKey
      const trigger = section.querySelector("[data-action*='toggleSection']")
      const open    = Object.prototype.hasOwnProperty.call(saved, key) ? saved[key] : key === "decks"
      section.classList.toggle("is-expanded", open)
      if (trigger) trigger.setAttribute("aria-expanded", String(open))
    })
  }

  #saveState() {
    const state = {}
    this.sectionTargets.forEach(section => {
      state[section.dataset.sectionKey] = section.classList.contains("is-expanded")
    })
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(state))
  }

  #loadState() {
    try { return JSON.parse(localStorage.getItem(this.STORAGE_KEY) || "{}") }
    catch { return {} }
  }
}
