import { jest } from "@jest/globals"
import { startController, nextTick } from "../support/stimulus_helpers.js"
import TestModeController from "../../../app/javascript/controllers/test_mode_controller.js"

const html = `
  <div data-controller="test"
       data-action="keydown->test#handleKey">
    <div data-test-target="timer">00:00</div>
    <button data-test-target="continueBtn">Continue</button>
    <a data-test-target="exitLink" href="/exit">Exit</a>
    <button class="test-option">Option A</button>
    <button class="test-option">Option B</button>
    <button class="test-option">Option C</button>
    <button class="test-option">Option D</button>
  </div>
`

describe("TestModeController", () => {
  let app, element

  beforeEach(async () => {
    jest.useFakeTimers()
    ;({ app, element } = await startController(TestModeController, html))
  })

  afterEach(() => {
    app.stop()
    jest.useRealTimers()
  })

  describe("#tickTimer", () => {
    it("updates the timer to 00:01 after one second", async () => {
      const timer = element.querySelector("[data-test-target='timer']")
      jest.advanceTimersByTime(1000)
      await nextTick()
      expect(timer.textContent).toBe("00:01")
    })

    it("formats minutes correctly at 60 seconds", async () => {
      const timer = element.querySelector("[data-test-target='timer']")
      jest.advanceTimersByTime(60000)
      await nextTick()
      expect(timer.textContent).toBe("01:00")
    })

    it("formats 90 seconds as 01:30", async () => {
      const timer = element.querySelector("[data-test-target='timer']")
      jest.advanceTimersByTime(90000)
      await nextTick()
      expect(timer.textContent).toBe("01:30")
    })
  })

  describe("handleKey — Enter", () => {
    it("clicks the continue button", () => {
      const continueBtn = element.querySelector("[data-test-target='continueBtn']")
      const clicked = jest.fn()
      continueBtn.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })
  })

  describe("handleKey — Space", () => {
    it("clicks the continue button", () => {
      const continueBtn = element.querySelector("[data-test-target='continueBtn']")
      const clicked = jest.fn()
      continueBtn.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: " ", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })
  })

  describe("handleKey — Escape", () => {
    it("clicks the exit link", () => {
      const exitLink = element.querySelector("[data-test-target='exitLink']")
      const clicked = jest.fn()
      exitLink.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })
  })

  describe("handleKey — number keys select options", () => {
    it("clicks the first option on key '1'", () => {
      const options = element.querySelectorAll(".test-option")
      const clicked = jest.fn()
      options[0].addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "1", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })

    it("clicks the third option on key '3'", () => {
      const options = element.querySelectorAll(".test-option")
      const clicked = jest.fn()
      options[2].addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "3", bubbles: true }))
      expect(clicked).toHaveBeenCalled()
    })
  })

  describe("handleKey — modifier keys are suppressed", () => {
    it("does not click continueBtn when Ctrl+Enter is pressed", () => {
      const continueBtn = element.querySelector("[data-test-target='continueBtn']")
      const clicked = jest.fn()
      continueBtn.addEventListener("click", clicked)
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", ctrlKey: true, bubbles: true }))
      expect(clicked).not.toHaveBeenCalled()
    })
  })
})
