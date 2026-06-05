import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "searchInput", "section", "sectionBody"]

  STORAGE_KEY       = "sidebar_sections"
  COLLAPSE_KEY      = "sidebar_collapsed"
  MOBILE_BREAKPOINT = 768

  connect() {
    this.restoreCollapseState()
    this.restoreState()
  }

  // ── Collapse / expand ──────────────────────────────────────

  get isCollapsed() {
    return this.element.classList.contains("is-collapsed")
  }

  toggleCollapse(event) {
    event.stopPropagation()
    const nowCollapsed = !this.isCollapsed
    this.element.classList.toggle("is-collapsed", nowCollapsed)
    localStorage.setItem(this.COLLAPSE_KEY, JSON.stringify(nowCollapsed))
  }

  expandIfCollapsed(event) {
    if (!this.isCollapsed) return
    if (event.target.closest("a")) return
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.remove("is-collapsed")
    localStorage.setItem(this.COLLAPSE_KEY, "false")
  }

  restoreCollapseState() {
    if (window.innerWidth <= this.MOBILE_BREAKPOINT) return
    try {
      const collapsed = JSON.parse(localStorage.getItem(this.COLLAPSE_KEY) || "false")
      this.element.classList.toggle("is-collapsed", collapsed)
    } catch { /* ignore */ }
  }

  // ── Mobile drawer ──────────────────────────────────────────

  openMobile() {
    this.sidebarTarget.classList.add("is-open")
    document.body.classList.add("sidebar-open")
  }

  closeMobile() {
    this.sidebarTarget.classList.remove("is-open")
    document.body.classList.remove("sidebar-open")
  }

  // ── Search ────────────────────────────────────────────────

  focusSearch(event) {
    event.preventDefault()
    if (this.isCollapsed) {
      this.element.classList.remove("is-collapsed")
      localStorage.setItem(this.COLLAPSE_KEY, "false")
      setTimeout(() => this.#doFocusSearch(), 260)
    } else {
      this.#doFocusSearch()
    }
  }

  expandAndFocusSearch(event) {
    event.preventDefault()
    this.focusSearch(event)
  }

  #doFocusSearch() {
    this.searchInputTarget.focus()
    this.searchInputTarget.select()
  }

  // ── Collapsible sections ──────────────────────────────────

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
