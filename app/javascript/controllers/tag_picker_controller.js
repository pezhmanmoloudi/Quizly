import { Controller } from "@hotwired/stimulus"

// Powers the "New tag" modal: clicking a recommended/current chip fills the
// name input, and chips matching the current input value get a selected state.
export default class extends Controller {
  static targets = ["input", "chip"]

  connect() {
    this.refresh()
  }

  fill(event) {
    const name = event.currentTarget.dataset.tagPickerNameParam ||
                 event.currentTarget.textContent.trim()
    this.inputTarget.value = name
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.focus()
    this.refresh()
  }

  refresh() {
    const current = this.inputTarget.value.trim().toLowerCase()
    this.chipTargets.forEach((chip) => {
      const name = (chip.dataset.tagPickerNameParam || chip.textContent).trim().toLowerCase()
      chip.classList.toggle("tag-chip--selected", current !== "" && name === current)
    })
  }
}
