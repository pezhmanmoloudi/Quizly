import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "label", "menu", "option", "input", "search", "form"]
  static values  = {
    searchable: { type: Boolean, default: false },
    autosubmit: { type: Boolean, default: false }
  }

  #scrollHandler = () => this.#positionMenu()
  #resizeHandler  = () => this.#positionMenu()

  connect() {
    this.menuTarget.dataset.open = "false"
    this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  disconnect() {
    this.#removeGlobalListeners()
  }

  toggle() {
    this.menuTarget.dataset.open === "true" ? this.#close() : this.#open()
  }

  select(event) {
    this.#selectByValue(event.currentTarget.dataset.value)
  }

  filter() {
    const q = this.searchTarget.value.toLowerCase().trim()
    this.optionTargets.forEach(opt => {
      opt.hidden = q.length > 0 && !opt.dataset.name.includes(q)
    })
  }

  close() {
    this.#close()
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.#close()
  }

  onKeydown(event) {
    if (this.menuTarget.dataset.open !== "true") return

    const focused  = document.activeElement
    const onSearch = this.searchableValue && this.hasSearchTarget && focused === this.searchTarget
    const options  = this.optionTargets.filter(o => !o.hidden)
    const idx      = options.indexOf(focused)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (onSearch) {
          options[0]?.focus()
        } else {
          options[Math.min(idx + 1, options.length - 1)]?.focus()
        }
        break
      case "ArrowUp":
        event.preventDefault()
        if (idx <= 0) {
          if (this.searchableValue && this.hasSearchTarget) {
            this.searchTarget.focus()
          } else {
            this.#close()
            this.triggerTarget.focus()
          }
        } else {
          options[idx - 1].focus()
        }
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

    if (this.searchableValue && this.hasSearchTarget) {
      this.searchTarget.value = ""
      this.#showAll()
      this.searchTarget.focus()
    } else {
      const selected = this.optionTargets.find(o => o.getAttribute("aria-selected") === "true")
      ;(selected ?? this.optionTargets[0])?.focus()
    }
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

    const menu    = this.menuTarget
    const vp      = window.innerHeight
    const GAP     = 6    // px between trigger edge and menu edge
    const MARGIN  = 8    // min breathing room from viewport edge
    const MAX_H   = 320  // desired max height

    const spaceBelow = vp - rect.bottom - MARGIN
    const spaceAbove = rect.top - MARGIN

    // Flip detection: prefer below → above → whichever side has more room
    const openUpward = spaceBelow >= MAX_H ? false
                     : spaceAbove >= MAX_H ? true
                     : spaceAbove > spaceBelow

    const available         = openUpward ? spaceAbove : spaceBelow
    menu.style.maxHeight    = `${Math.max(Math.min(MAX_H, available - GAP), 80)}px`
    menu.dataset.direction  = openUpward ? "up" : "down"

    if (openUpward) {
      menu.style.top    = "auto"
      menu.style.bottom = `${vp - rect.top + GAP}px`
    } else {
      menu.style.top    = `${rect.bottom + GAP}px`
      menu.style.bottom = "auto"
    }

    // Horizontal: match trigger width (min 220px), RTL-aware
    const isRTL = document.documentElement.dir === "rtl"
    menu.style.width = `${Math.max(rect.width, 220)}px`

    if (isRTL) {
      menu.style.right = `${window.innerWidth - rect.right}px`
      menu.style.left  = "auto"
    } else {
      menu.style.left  = `${rect.left}px`
      menu.style.right = "auto"
    }
  }

  #selectByValue(value) {
    const matched = this.optionTargets.find(o => o.dataset.value === value)
    if (!matched) return

    this.labelTarget.textContent = matched.textContent.trim()
    this.inputTarget.value = value
    this.optionTargets.forEach(o =>
      o.setAttribute("aria-selected", String(o.dataset.value === value))
    )
    this.#close()
    this.triggerTarget.focus()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))

    if (this.autosubmitValue && this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  #showAll() {
    this.optionTargets.forEach(opt => (opt.hidden = false))
  }

  #removeGlobalListeners() {
    window.removeEventListener("scroll", this.#scrollHandler, { capture: true })
    window.removeEventListener("resize", this.#resizeHandler)
  }
}
