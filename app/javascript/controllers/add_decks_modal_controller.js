import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["doneButton"]

  connect() {
    this.initialState = this.checkedValues().sort().join(",")
    this.syncDoneButton()
  }

  handleChange(event) {
    const checkbox = event.target
    const row = checkbox.closest(".add-decks-deck-row")
    row.classList.toggle("add-decks-deck-row--selected", checkbox.checked)
    this.syncDoneButton()
  }

  syncDoneButton() {
    const current = this.checkedValues().sort().join(",")
    this.doneButtonTarget.disabled = (current === this.initialState)
  }

  checkedValues() {
    return [...this.element.querySelectorAll("input[type=checkbox]:checked")]
      .map(cb => cb.value)
  }
}
