import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "search", "option", "triggerLabel", "form", "input"]
  static values = { current: String }

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
  }

  select(event) {
    this.#selectByCode(event.currentTarget.dataset.code)
  }

  #selectByCode(code) {
    const matched = this.optionTargets.find(o => o.dataset.code === code)
    if (!matched) return
    this.triggerLabelTarget.textContent = matched.textContent.trim()
    this.inputTarget.value = code
    this.currentValue = code
    this.optionTargets.forEach(o => o.classList.toggle("is-active", o.dataset.code === code))
    this.close()
    this.formTarget.requestSubmit()
  }

  #showAll() {
    this.optionTargets.forEach(opt => opt.hidden = false)
  }
}
