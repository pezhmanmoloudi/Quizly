import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  refresh(event) {
    const label = event.target.closest("label")
    label.classList.toggle("notif-channel-btn--active", event.target.checked)
  }
}
