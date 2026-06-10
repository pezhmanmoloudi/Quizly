import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "languageSelect", "dropdown", "list"]
  static values  = {
    url:        String,
    minChars:   { type: Number, default: 2 },
    debounceMs: { type: Number, default: 300 }
  }

  #timer = null
  #abort = null

  disconnect() {
    clearTimeout(this.#timer)
    this.#abort?.abort()
  }

  // ── Public actions ───────────────────────────────────────────────

  handleInput() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this.#timer)

    if (q.length < this.minCharsValue) {
      this.#hide()
      return
    }

    this.#timer = setTimeout(() => this.#fetch(q), this.debounceMs)
  }

  handleKeydown(event) {
    if (!this.hasDropdownTarget || this.dropdownTarget.hidden) return

    const items = [...this.listTarget.querySelectorAll("li")]
    const focused = this.listTarget.querySelector("[aria-selected='true']")
    const idx = items.indexOf(focused)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.#focusItem(items[(idx + 1) % items.length])
        break
      case "ArrowUp":
        event.preventDefault()
        this.#focusItem(items[(idx - 1 + items.length) % items.length])
        break
      case "Enter":
        if (focused) { event.preventDefault(); this.#select(focused.textContent) }
        break
      case "Escape":
        this.#hide()
        break
    }
  }

  selectSuggestion(event) {
    const li = event.target.closest("li")
    if (li) this.#select(li.textContent)
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.#hide()
  }

  // ── Private ──────────────────────────────────────────────────────

  async #fetch(q) {
    this.#abort?.abort()
    this.#abort = new AbortController()

    const lang = this.hasLanguageSelectTarget ? (this.languageSelectTarget.value || "") : ""
    const url  = `${this.urlValue}?q=${encodeURIComponent(q)}&lang=${encodeURIComponent(lang)}`

    try {
      const resp = await fetch(url, {
        signal:  this.#abort.signal,
        headers: { "Accept": "application/json" }
      })
      if (!resp.ok) { this.#hide(); return }

      const { suggestions } = await resp.json()
      this.#render(suggestions || [])
    } catch (err) {
      if (err.name !== "AbortError") this.#hide()
    }
  }

  #render(words) {
    if (!words.length) { this.#hide(); return }

    this.listTarget.innerHTML = words
      .map(w => `<li class="term-suggest__item" role="option" tabindex="-1">${this.#escape(w)}</li>`)
      .join("")
    this.dropdownTarget.hidden = false
  }

  #select(word) {
    this.inputTarget.value = word.trim()
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.#hide()
    this.inputTarget.focus()
  }

  #focusItem(item) {
    this.listTarget.querySelectorAll("li").forEach(li => li.removeAttribute("aria-selected"))
    if (!item) return
    item.setAttribute("aria-selected", "true")
    item.scrollIntoView({ block: "nearest" })
  }

  #hide() {
    if (this.hasDropdownTarget) this.dropdownTarget.hidden = true
    if (this.hasListTarget) this.listTarget.innerHTML = ""
  }

  #escape(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
