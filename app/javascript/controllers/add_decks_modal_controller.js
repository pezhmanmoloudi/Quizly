import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["doneButton", "searchInput", "deckRow", "section", "noResults"]

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

  filter() {
    const q = this.searchInputTarget.value.toLowerCase().trim()
    this.deckRowTargets.forEach(row => {
      row.hidden = q.length > 0 && !row.dataset.deckName.includes(q)
    })
    this.sectionTargets.forEach(section => {
      const rows = section.querySelectorAll('[data-add-decks-modal-target="deckRow"]')
      section.hidden = [...rows].every(r => r.hidden)
    })
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.hidden = !this.deckRowTargets.every(r => r.hidden)
    }
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
