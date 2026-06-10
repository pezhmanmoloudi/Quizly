import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "search", "option", "triggerLabel", "form", "input"]
  static values  = { current: String, autosubmit: { type: Boolean, default: true } }

  // Arrow-function properties so they can be removed via removeEventListener
  #scrollHandler = () => this.#positionMenu()
  #resizeHandler = () => this.#positionMenu()

  toggle() {
    const open = this.menuTarget.dataset.open === "true"
    if (open) {
      this.close()
    } else {
      this.#positionMenu()
      this.menuTarget.dataset.open = "true"
      this.#triggerButton()?.setAttribute("aria-expanded", "true")
      this.searchTarget.value = ""
      this.#showAll()
      this.searchTarget.focus()
      window.addEventListener("scroll", this.#scrollHandler, { passive: true, capture: true })
      window.addEventListener("resize", this.#resizeHandler, { passive: true })
    }
  }

  close() {
    this.menuTarget.dataset.open = "false"
    this.#triggerButton()?.setAttribute("aria-expanded", "false")
    window.removeEventListener("scroll", this.#scrollHandler, { capture: true })
    window.removeEventListener("resize", this.#resizeHandler)
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  filter() {
    const q = this.searchTarget.value.toLowerCase().trim()
    this.optionTargets.forEach(opt => {
      opt.hidden = q.length > 0 && !opt.dataset.name.includes(q)
    })
  }

  select(event) {
    this.#selectByCode(event.currentTarget.dataset.code)
  }

  // ── Private ──────────────────────────────────────────────────────

  #positionMenu() {
    const trigger = this.#triggerButton()
    if (!trigger) return

    const rect = trigger.getBoundingClientRect()

    // Trigger has scrolled out of view — close rather than leave dropdown floating
    if (rect.bottom < 0 || rect.top > window.innerHeight) {
      this.close()
      return
    }

    const menu  = this.menuTarget
    const isRTL = document.documentElement.dir === "rtl"

    menu.style.top   = `${rect.bottom + 6}px`
    menu.style.width = `${Math.max(rect.width, 220)}px`

    if (isRTL) {
      menu.style.right = `${window.innerWidth - rect.right}px`
      menu.style.left  = "auto"
    } else {
      menu.style.left  = `${rect.left}px`
      menu.style.right = "auto"
    }
  }

  #selectByCode(code) {
    const matched = this.optionTargets.find(o => o.dataset.code === code)
    if (!matched) return
    this.triggerLabelTarget.textContent = matched.textContent.trim()
    this.inputTarget.value = code
    this.currentValue = code
    this.optionTargets.forEach(o => o.classList.toggle("is-active", o.dataset.code === code))
    this.close()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    if (this.autosubmitValue && this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  #showAll() {
    this.optionTargets.forEach(opt => opt.hidden = false)
  }

  #triggerButton() {
    return this.element.querySelector("[aria-haspopup='listbox']")
  }
}
