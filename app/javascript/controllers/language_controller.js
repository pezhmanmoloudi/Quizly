import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "search", "option", "triggerLabel", "form", "input", "yourSection"]
  static values = { current: String }

  connect() {
    this.#insertYourLanguage()
  }

  toggle() {
    const open = this.menuTarget.dataset.open === "true"
    this.menuTarget.dataset.open = open ? "false" : "true"
    if (!open) {
      this.searchTarget.value = ""
      this.#showAll()
      this.searchTarget.focus()
    }
  }

  close() {
    this.menuTarget.dataset.open = "false"
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  filter() {
    const q = this.searchTarget.value.toLowerCase().trim()
    this.optionTargets.forEach(opt => {
      opt.hidden = q.length > 0 && !opt.dataset.name.includes(q)
    })
    this.yourSectionTarget.hidden = q.length > 0
    if (this.#yourClone) this.#yourClone.hidden = q.length > 0
  }

  select(event) {
    const btn = event.currentTarget
    if (btn.dataset.isClone) return this.#selectByCode(btn.dataset.code)
    this.#selectByCode(btn.dataset.code)
  }

  #selectByCode(code) {
    const matched = this.optionTargets.find(o => o.dataset.code === code)
    if (!matched) return
    this.triggerLabelTarget.textContent = matched.textContent.trim()
    this.inputTarget.value = code
    this.currentValue = code
    this.optionTargets.forEach(o => o.classList.toggle("is-active", o.dataset.code === code))
    if (this.#yourClone) {
      this.#yourClone.textContent = matched.textContent.trim()
      this.#yourClone.dataset.code = code
    }
    this.close()
    this.formTarget.requestSubmit()
  }

  #yourClone = null

  #insertYourLanguage() {
    const active = this.optionTargets.find(o => o.dataset.code === this.currentValue)
    if (!active || !this.hasYourSectionTarget) return
    const clone = active.cloneNode(true)
    clone.dataset.isClone = "true"
    clone.addEventListener("click", () => this.#selectByCode(clone.dataset.code))
    this.yourSectionTarget.after(clone)
    this.#yourClone = clone
  }

  #showAll() {
    this.optionTargets.forEach(opt => opt.hidden = false)
    this.yourSectionTarget.hidden = false
    if (this.#yourClone) this.#yourClone.hidden = false
  }
}
