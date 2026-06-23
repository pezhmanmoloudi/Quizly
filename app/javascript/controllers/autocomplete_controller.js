import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "frame"]
  static values  = {
    url:   String,
    field: String,
    lang:  String,
    delay: { type: Number, default: 300 }
  }

  #timer = null
  #scrollHandler = () => this.#positionFrame()
  #resizeHandler  = () => this.#positionFrame()

  disconnect() {
    clearTimeout(this.#timer)
    this.#removeGlobalListeners()
  }

  search() {
    clearTimeout(this.#timer)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) { this.close(); return }

    this.#timer = setTimeout(async () => {
      this.#positionFrame()
      const url = `${this.urlValue}?q=${encodeURIComponent(q)}&field=${encodeURIComponent(this.fieldValue)}&lang=${encodeURIComponent(this.langValue)}`
      try {
        const response = await fetch(url, { headers: { Accept: "text/html" } })
        if (response.ok) {
          this.frameTarget.innerHTML = await response.text()
          this.inputTarget.classList.add("ac-input--active")
        }
      } catch { /* ignore transient network errors */ }
    }, this.delayValue)
  }

  handleFocus() {
    if (this.inputTarget.value.trim().length >= 2) this.search()
  }

  // 200ms delay lets a click on a list item fire before blur hides the list
  handleBlur() {
    setTimeout(() => this.close(), 200)
  }

  handleKeydown(event) {
    if (!this.hasFrameTarget) return
    const items = this.frameTarget.querySelectorAll(".ac-item")
    if (!items.length) return

    switch (event.key) {
      case "ArrowDown": event.preventDefault(); this.#moveFocus(1);   break
      case "ArrowUp":   event.preventDefault(); this.#moveFocus(-1);  break
      case "Enter":     event.preventDefault(); this.#selectFocused(); break
      case "Escape":
      case "Tab":       this.close(); break
    }
  }

  select({ params: { word } }) {
    this.inputTarget.value = word
    // Notify card-autosave and any other input listeners of the programmatic change
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.close()
    this.inputTarget.focus()
    this.inputTarget.dispatchEvent(
      new CustomEvent("autocomplete:selected", { bubbles: true, detail: { word } })
    )
  }

  updateLang(event) {
    this.langValue = event.target.value
  }

  close() {
    clearTimeout(this.#timer)
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = ""
    }
    this.inputTarget.classList.remove("ac-input--active")
    this.#removeGlobalListeners()
  }

  #positionFrame() {
    if (!this.hasFrameTarget) return
    const rect  = this.inputTarget.getBoundingClientRect()
    const frame = this.frameTarget
    const isRTL = document.documentElement.dir === "rtl"

    frame.style.top   = `${rect.bottom + 4}px`
    frame.style.width = `${rect.width}px`
    if (isRTL) {
      frame.style.right = `${window.innerWidth - rect.right}px`
      frame.style.left  = "auto"
    } else {
      frame.style.left  = `${rect.left}px`
      frame.style.right = "auto"
    }

    window.addEventListener("scroll", this.#scrollHandler, { passive: true, capture: true })
    window.addEventListener("resize", this.#resizeHandler, { passive: true })
  }

  #removeGlobalListeners() {
    window.removeEventListener("scroll", this.#scrollHandler, { capture: true })
    window.removeEventListener("resize", this.#resizeHandler)
  }

  #moveFocus(dir) {
    const items   = [...this.frameTarget.querySelectorAll(".ac-item")]
    if (!items.length) return
    const current = this.frameTarget.querySelector(".ac-item--focused")
    const idx     = items.indexOf(current)
    items.forEach(i => i.classList.remove("ac-item--focused"))
    // Wrap around: items.at() handles negative indices naturally
    items.at(((idx + dir) % items.length + items.length) % items.length)
         ?.classList.add("ac-item--focused")
  }

  #selectFocused() {
    const word = this.frameTarget
      .querySelector(".ac-item--focused")
      ?.dataset?.autocompleteWordParam
    if (word) this.select({ params: { word } })
  }
}
