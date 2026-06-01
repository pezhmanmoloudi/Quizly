import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "section"]
  static values  = { initialTab: { type: String, default: "profile" } }

  connect() {
    const hash = window.location.hash.slice(1)
    this.activate(hash || this.initialTabValue)
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    this.activate(tab)
    history.replaceState(null, "", `#${tab}`)
  }

  navigate(event) {
    if (!["ArrowDown", "ArrowUp"].includes(event.key)) return
    event.preventDefault()
    const tabs = this.tabTargets
    const idx  = tabs.findIndex(t => t.getAttribute("aria-selected") === "true")
    const next = event.key === "ArrowDown" ? idx + 1 : idx - 1
    if (next >= 0 && next < tabs.length) {
      tabs[next].click()
      tabs[next].focus()
    }
  }

  activate(tabName) {
    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === tabName
      tab.classList.toggle("settings-tab--active", active)
      tab.setAttribute("aria-selected", active)
    })
    this.sectionTargets.forEach(section => {
      section.classList.toggle("settings-section--hidden", section.dataset.section !== tabName)
    })
  }
}
