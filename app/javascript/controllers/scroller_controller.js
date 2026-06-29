import { Controller } from "@hotwired/stimulus"

// Horizontally scrolls a track by roughly one viewport-width on demand.
// Used by the dashboard achievements carousel arrow.
export default class extends Controller {
  static targets = ["track"]

  scrollNext() {
    this.#scrollByPage(1)
  }

  scrollPrev() {
    this.#scrollByPage(-1)
  }

  #scrollByPage(direction) {
    const track  = this.hasTrackTarget ? this.trackTarget : this.element
    const amount = track.clientWidth * 0.8 * direction
    // inline-end direction flips under RTL automatically with scrollLeft sign,
    // so honor the document direction.
    const rtl = getComputedStyle(track).direction === "rtl"
    track.scrollBy({ left: rtl ? -amount : amount, behavior: "smooth" })
  }
}
