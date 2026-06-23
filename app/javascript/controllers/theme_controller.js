import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "option", "menu", "triggerLabel", "dropdownWrapper"]
  STORAGE_KEY = "color-theme"

  #mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")

  connect() {
    this.#mediaQuery.addEventListener("change", this.#onSystemChange)
    this.#syncUI()
  }

  disconnect() {
    this.#mediaQuery.removeEventListener("change", this.#onSystemChange)
  }

  toggle() {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark"
    this.#save(next)
  }

  set(event) {
    this.#save(event.params.value)
    this.closeDropdown()
  }

  toggleDropdown() {
    if (!this.hasMenuTarget) return
    this.menuTarget.dataset.open = this.menuTarget.dataset.open === "true" ? "false" : "true"
  }

  closeDropdown() {
    if (this.hasMenuTarget) this.menuTarget.dataset.open = "false"
  }

  closeIfOutside(event) {
    if (!this.hasDropdownWrapperTarget) return
    if (!this.dropdownWrapperTarget.contains(event.target)) this.closeDropdown()
  }

  #save(value) {
    localStorage.setItem(this.STORAGE_KEY, value)
    const theme = value === "auto"
      ? (this.#mediaQuery.matches ? "dark" : "light")
      : value
    document.documentElement.dataset.theme = theme
    this.#setColorSchemeMeta(theme)
    this.#syncUI()
  }

  #onSystemChange = (e) => {
    if ((localStorage.getItem(this.STORAGE_KEY) || "auto") === "auto") {
      const theme = e.matches ? "dark" : "light"
      document.documentElement.dataset.theme = theme
      this.#setColorSchemeMeta(theme)
      this.#syncLabel()
    }
  }

  #setColorSchemeMeta(theme) {
    const meta = document.querySelector('meta[name="color-scheme"]')
    if (meta) meta.content = theme
  }

  #syncUI() {
    this.#syncLabel()
    this.#syncTriggerLabel()
    this.#syncOptions()
  }

  #syncLabel() {
    if (!this.hasLabelTarget) return
    const isDark = document.documentElement.dataset.theme === "dark"
    this.labelTarget.textContent = isDark
      ? (this.labelTarget.dataset.lightLabel || "Light mode")
      : (this.labelTarget.dataset.darkLabel || "Dark mode")
  }

  #syncTriggerLabel() {
    if (!this.hasTriggerLabelTarget) return
    const stored = localStorage.getItem(this.STORAGE_KEY) || "auto"
    const wrapper = this.hasDropdownWrapperTarget ? this.dropdownWrapperTarget : null
    this.triggerLabelTarget.textContent =
      stored === "dark"  ? (wrapper?.dataset.themeDarkLabel  || "Dark")  :
      stored === "light" ? (wrapper?.dataset.themeLightLabel || "Light") :
                           (wrapper?.dataset.themeAutoLabel  || "Auto")
  }

  #syncOptions() {
    if (!this.hasOptionTargets) return
    const stored = localStorage.getItem(this.STORAGE_KEY) || "auto"
    this.optionTargets.forEach(opt =>
      opt.classList.toggle("is-active", opt.dataset.themeValueParam === stored)
    )
  }
}
