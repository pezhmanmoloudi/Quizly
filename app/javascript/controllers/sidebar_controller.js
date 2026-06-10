import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "searchInput"]

  connect() {
    this._onNavigate = this.#closeDrawer.bind(this)
    document.addEventListener("turbo:navigate", this._onNavigate)
  }

  disconnect() {
    document.removeEventListener("turbo:navigate", this._onNavigate)
  }

  focusSearch(event) {
    event.preventDefault()
    this.searchInputTarget.focus()
    this.searchInputTarget.select()
  }

  #closeDrawer() {
    if (this.hasToggleTarget) this.toggleTarget.checked = false
  }
}
