import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Restore correct badge count when browser restores page from bfcache.
    this._pageshowHandler = (e) => { if (e.persisted) this._reloadFrame() }
    window.addEventListener("pageshow", this._pageshowHandler)
  }

  disconnect() {
    window.removeEventListener("pageshow", this._pageshowHandler)
  }

  toggle() {
    this.menuTarget.dataset.open === "true" ? this.close() : this.open()
  }

  open() {
    this.menuTarget.dataset.open = "true"
    this.buttonTarget.setAttribute("aria-expanded", "true")
    // Reload the notification list each time the dropdown opens so the user
    // never sees a stale list from a previous session.
    this._reloadFrame()
    const firstFocusable = this.menuTarget.querySelector("button, a, [tabindex]:not([tabindex='-1'])")
    ;(firstFocusable ?? this.menuTarget).focus()
  }

  close() {
    this.menuTarget.dataset.open = "false"
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.focus()
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.dataset.open = "false"
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }

  _reloadFrame() {
    const frame = this.menuTarget.querySelector("turbo-frame")
    if (frame) frame.reload()
  }
}
