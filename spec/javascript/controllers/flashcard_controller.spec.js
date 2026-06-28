import { startController, nextTick } from "../support/stimulus_helpers.js"
import FlashcardController from "../../../app/javascript/controllers/flashcard_controller.js"

describe("FlashcardController", () => {
  let app, element, back, showButton, form1, form2

  const htmlWithoutCard = `
    <div data-controller="test">
      <div data-test-target="back" hidden></div>
      <button data-test-target="showButton"
              data-action="click->test#reveal">Show Answer</button>
      <form data-test-target="ratingForm" style="display: none"></form>
      <form data-test-target="ratingForm" style="display: none"></form>
    </div>
  `

  const htmlWithCard = `
    <div class="flashcard-card">
      <div class="flashcard-card__inner">
        <div class="flashcard-card__front">
          <div data-controller="test">
            <button data-test-target="showButton"
                    data-action="click->test#reveal">Show</button>
            <div data-test-target="back" hidden></div>
            <form data-test-target="ratingForm" style="display: none"></form>
          </div>
        </div>
      </div>
    </div>
  `

  afterEach(() => {
    if (app) app.stop()
    document.body.innerHTML = ""
  })

  describe("reveal() — without .flashcard-card ancestor", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(FlashcardController, htmlWithoutCard))
      back = element.querySelector("[data-test-target='back']")
      showButton = element.querySelector("[data-test-target='showButton']")
      form1 = element.querySelectorAll("[data-test-target='ratingForm']")[0]
      form2 = element.querySelectorAll("[data-test-target='ratingForm']")[1]
    })

    it("shows the back content", async () => {
      showButton.click()
      await nextTick()
      expect(back.hidden).toBe(false)
    })

    it("hides the show button", async () => {
      showButton.click()
      await nextTick()
      expect(showButton.hidden).toBe(true)
    })

    it("makes rating forms visible", async () => {
      showButton.click()
      await nextTick()
      expect(form1.style.display).toBe("")
      expect(form2.style.display).toBe("")
    })
  })

  describe("reset()", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(FlashcardController, htmlWithoutCard))
      back = element.querySelector("[data-test-target='back']")
      showButton = element.querySelector("[data-test-target='showButton']")
      form1 = element.querySelectorAll("[data-test-target='ratingForm']")[0]

      // Reveal first, then reset
      showButton.click()
      await nextTick()
    })

    it("hides the back content again", async () => {
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.reset()
      await nextTick()
      expect(back.hidden).toBe(true)
    })

    it("shows the show button again", async () => {
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.reset()
      await nextTick()
      expect(showButton.hidden).toBe(false)
    })

    it("hides rating forms", async () => {
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.reset()
      await nextTick()
      expect(form1.style.display).toBe("none")
    })
  })

  describe("reveal() — with .flashcard-card ancestor", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(FlashcardController, htmlWithCard))
      showButton = element.querySelector("[data-test-target='showButton']")
    })

    it("toggles is-flipped on .flashcard-card__inner", async () => {
      const inner = document.querySelector(".flashcard-card__inner")
      showButton.click()
      await nextTick()
      expect(inner.classList.contains("is-flipped")).toBe(true)
    })

    it("does not change the back target hidden state", async () => {
      back = element.querySelector("[data-test-target='back']")
      showButton.click()
      await nextTick()
      expect(back.hidden).toBe(true)
    })
  })
})
