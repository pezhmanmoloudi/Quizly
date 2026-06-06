import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabBtn", "panel", "textarea", "preview"]
  static values  = { activeTab: String }

  connect() {
    this.#showTab(this.activeTabValue || "text")
    this.updatePreview()
  }

  switchTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.#showTab(tab)
  }

  updatePreview() {
    if (!this.hasTextareaTarget || !this.hasPreviewTarget) return
    const lines = this.textareaTarget.value
      .split("\n")
      .map(l => l.trim())
      .filter(l => l.length > 0)
    const count = lines.length
    this.previewTarget.textContent = count > 0
      ? `${count} card${count === 1 ? "" : "s"} detected`
      : ""
  }

  #showTab(tab) {
    this.tabBtnTargets.forEach(btn => {
      const active = btn.dataset.tab === tab
      btn.setAttribute("aria-selected", active)
      btn.classList.toggle("import-tab-btn--active", active)
    })
    this.panelTargets.forEach(panel => {
      panel.hidden = panel.dataset.tab !== tab
    })
  }
}
