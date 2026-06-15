import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "label", "menu", "option", "nativeSelect"]

  #scrollHandler = () => this.#positionMenu()
  #resizeHandler  = () => this.#positionMenu()
  #observer       = null

  connect() {
    this.menuTarget.dataset.open = "false"
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.#syncFromNative()

    this.#observer = new MutationObserver(() => this.#syncFromNative())
    this.#observer.observe(this.nativeSelectTarget, {
      attributes: true,
      attributeFilter: ["disabled"],
    })
  }

  disconnect() {
    this.#observer?.disconnect()
    this.#removeGlobalListeners()
  }

  toggle() {
    this.menuTarget.dataset.open === "true" ? this.#close() : this.#open()
  }

  select(event) {
    const btn   = event.currentTarget
    const value = btn.dataset.value

    this.nativeSelectTarget.value = value
    this.labelTarget.textContent  = btn.textContent.trim()
    this.optionTargets.forEach(o =>
      o.setAttribute("aria-selected", String(o.dataset.value === value))
    )
    this.nativeSelectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.#close()
    this.triggerTarget.focus()
  }

  closeIfOutside(event) {
    if (
      !this.element.contains(event.target) &&
      !this.menuTarget.contains(event.target)
    ) {
      this.#close()
    }
  }

  onKeydown(event) {
    if (this.menuTarget.dataset.open !== "true") return

    const options = this.optionTargets
    const idx     = options.indexOf(document.activeElement)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        options[Math.min(idx + 1, options.length - 1)]?.focus()
        break
      case "ArrowUp":
        event.preventDefault()
        if (idx <= 0) { this.#close(); this.triggerTarget.focus() }
        else options[idx - 1].focus()
        break
      case "Escape":
        this.#close()
        this.triggerTarget.focus()
        break
      case "Tab":
        this.#close()
        break
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  #open() {
    this.#positionMenu()
    this.menuTarget.dataset.open = "true"
    this.triggerTarget.setAttribute("aria-expanded", "true")
    window.addEventListener("scroll", this.#scrollHandler, { passive: true, capture: true })
    window.addEventListener("resize", this.#resizeHandler, { passive: true })

    const selected = this.optionTargets.find(o => o.getAttribute("aria-selected") === "true")
    ;(selected ?? this.optionTargets[0])?.focus()
  }

  #close() {
    this.menuTarget.dataset.open = "false"
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.#removeGlobalListeners()
  }

  #positionMenu() {
    const rect = this.triggerTarget.getBoundingClientRect()

    if (rect.bottom < 0 || rect.top > window.innerHeight) {
      this.#close()
      return
    }

    const menu  = this.menuTarget
    const isRTL = document.documentElement.dir === "rtl"

    menu.style.top   = `${rect.bottom + 4}px`
    menu.style.width = `${rect.width}px`

    if (isRTL) {
      menu.style.right = `${window.innerWidth - rect.right}px`
      menu.style.left  = "auto"
    } else {
      menu.style.left  = `${rect.left}px`
      menu.style.right = "auto"
    }
  }

  #syncFromNative() {
    const disabled    = this.nativeSelectTarget.disabled
    const currentVal  = this.nativeSelectTarget.value

    this.triggerTarget.disabled = disabled

    const match = this.optionTargets.find(o => o.dataset.value === currentVal)
    if (match) this.labelTarget.textContent = match.textContent.trim()

    this.optionTargets.forEach(o =>
      o.setAttribute("aria-selected", String(o.dataset.value === currentVal))
    )
  }

  #removeGlobalListeners() {
    window.removeEventListener("scroll", this.#scrollHandler, { capture: true })
    window.removeEventListener("resize", this.#resizeHandler)
  }
}
