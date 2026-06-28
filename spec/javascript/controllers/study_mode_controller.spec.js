import { jest } from "@jest/globals"
import { startController, nextTick } from "../support/stimulus_helpers.js"
import StudyModeController from "../../../app/javascript/controllers/study_mode_controller.js"

const html = `
  <div data-controller="test"
       data-action="keydown->test#handleKey"
       tabindex="0">
    <button data-test-target="showButton">Show Answer</button>
    <button data-test-target="againBtn">Again</button>
    <button data-test-target="hardBtn">Hard</button>
    <button data-test-target="goodBtn">Good</button>
    <button data-test-target="easyBtn">Easy</button>
    <a data-test-target="exitLink" href="/exit">Exit</a>
    <div data-test-target="settingsDrawer" aria-hidden="true"></div>
    <div data-test-target="settingsOverlay" hidden></div>
    <button data-test-target="settingsBtn"
            aria-expanded="false"
            data-action="click->test#openSettings">Settings</button>
    <select data-test-target="newLimitSelect"><option value="10">10</option><option value="20">20</option></select>
    <select data-test-target="prioritySelect"><option value="due">Due</option><option value="new">New</option></select>
  </div>
`

describe("StudyModeController", () => {
  let app, element

  beforeEach(async () => {
    localStorage.clear()
    ;({ app, element } = await startController(StudyModeController, html))
  })

  afterEach(() => {
    app.stop()
    localStorage.clear()
  })

  describe("openSettings", () => {
    it("adds is-open to the settings drawer", async () => {
      const drawer = element.querySelector("[data-test-target='settingsDrawer']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.openSettings()
      await nextTick()
      expect(drawer.classList.contains("is-open")).toBe(true)
    })

    it("sets aria-hidden to false on the drawer", async () => {
      const drawer = element.querySelector("[data-test-target='settingsDrawer']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.openSettings()
      await nextTick()
      expect(drawer.getAttribute("aria-hidden")).toBe("false")
    })

    it("shows the overlay", async () => {
      const overlay = element.querySelector("[data-test-target='settingsOverlay']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.openSettings()
      await nextTick()
      expect(overlay.hidden).toBe(false)
    })

    it("sets aria-expanded to true on the settings button", async () => {
      const btn = element.querySelector("[data-test-target='settingsBtn']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.openSettings()
      await nextTick()
      expect(btn.getAttribute("aria-expanded")).toBe("true")
    })
  })

  describe("closeSettings", () => {
    beforeEach(async () => {
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.openSettings()
      await nextTick()
    })

    it("removes is-open from the settings drawer", async () => {
      const drawer = element.querySelector("[data-test-target='settingsDrawer']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.closeSettings()
      await nextTick()
      expect(drawer.classList.contains("is-open")).toBe(false)
    })

    it("sets aria-hidden back to true", async () => {
      const drawer = element.querySelector("[data-test-target='settingsDrawer']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.closeSettings()
      await nextTick()
      expect(drawer.getAttribute("aria-hidden")).toBe("true")
    })

    it("hides the overlay", async () => {
      const overlay = element.querySelector("[data-test-target='settingsOverlay']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.closeSettings()
      await nextTick()
      expect(overlay.hidden).toBe(true)
    })

    it("sets aria-expanded back to false", async () => {
      const btn = element.querySelector("[data-test-target='settingsBtn']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.closeSettings()
      await nextTick()
      expect(btn.getAttribute("aria-expanded")).toBe("false")
    })
  })

  describe("handleKey — Space reveals card", () => {
    it("clicks the show button when it is visible", () => {
      const showBtn = element.querySelector("[data-test-target='showButton']")
      const clicked = jest.fn()
      showBtn.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: " ", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })

    it("does not click when the show button is already hidden (card revealed)", () => {
      const showBtn = element.querySelector("[data-test-target='showButton']")
      showBtn.hidden = true
      const clicked = jest.fn()
      showBtn.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: " ", bubbles: true }))
      expect(clicked).not.toHaveBeenCalled()
    })
  })

  describe("handleKey — number keys submit rating", () => {
    beforeEach(() => {
      // Hide show button to indicate card has been revealed
      element.querySelector("[data-test-target='showButton']").hidden = true
    })

    // Rating submission disables all rating buttons (side effect of #disableRatingButtons).
    // Testing disabled state is more reliable than click-event detection in jsdom
    // because disabled buttons suppress click events before listeners fire.

    it("disables rating buttons on key '1' (Again)", () => {
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "1", bubbles: true }))
      const btn = element.querySelector("[data-test-target='againBtn']")
      expect(btn.disabled).toBe(true)
    })

    it("disables rating buttons on key '3' (Good)", () => {
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "3", bubbles: true }))
      const btn = element.querySelector("[data-test-target='goodBtn']")
      expect(btn.disabled).toBe(true)
    })

    it("disables rating buttons on key '4' (Easy)", () => {
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "4", bubbles: true }))
      const btn = element.querySelector("[data-test-target='easyBtn']")
      expect(btn.disabled).toBe(true)
    })

    it("does not disable buttons when show button is still visible (card not revealed)", () => {
      element.querySelector("[data-test-target='showButton']").hidden = false
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "3", bubbles: true }))
      const btn = element.querySelector("[data-test-target='goodBtn']")
      expect(btn.disabled).toBe(false)
    })
  })

  describe("handleKey — Escape", () => {
    it("closes open settings drawer", async () => {
      const drawer = element.querySelector("[data-test-target='settingsDrawer']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.openSettings()
      await nextTick()
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
      await nextTick()
      expect(drawer.classList.contains("is-open")).toBe(false)
    })

    it("clicks the exit link when settings drawer is closed", () => {
      const exitLink = element.querySelector("[data-test-target='exitLink']")
      const clicked = jest.fn()
      exitLink.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })
  })

  describe("handleKey — form element focus suppresses keyboard shortcuts", () => {
    it("does not click show button when an INPUT is focused", () => {
      const input = document.createElement("input")
      document.body.appendChild(input)
      input.focus()

      const showBtn = element.querySelector("[data-test-target='showButton']")
      const clicked = jest.fn()
      showBtn.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: " ", bubbles: true }))
      expect(clicked).not.toHaveBeenCalled()
    })
  })

  describe("saveSettings / #applyStoredSettings", () => {
    it("saves newLimitSelect and prioritySelect to localStorage", () => {
      const newLimitSelect = element.querySelector("[data-test-target='newLimitSelect']")
      const prioritySelect = element.querySelector("[data-test-target='prioritySelect']")
      newLimitSelect.value = "20"
      prioritySelect.value = "new"

      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.saveSettings()

      const stored = JSON.parse(localStorage.getItem("quizly.study.settings"))
      expect(stored.new_limit).toBe("20")
      expect(stored.priority).toBe("new")
    })

    it("restores stored values on connect", async () => {
      localStorage.setItem("quizly.study.settings", JSON.stringify({ new_limit: "20", priority: "new" }))

      // Restart controller to trigger connect → applyStoredSettings
      app.stop()
      ;({ app, element } = await startController(StudyModeController, html))

      const newLimitSelect = element.querySelector("[data-test-target='newLimitSelect']")
      const prioritySelect = element.querySelector("[data-test-target='prioritySelect']")
      expect(newLimitSelect.value).toBe("20")
      expect(prioritySelect.value).toBe("new")
    })
  })
})
