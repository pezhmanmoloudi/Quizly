import { jest } from "@jest/globals"
import { startController, nextTick } from "../support/stimulus_helpers.js"
import MatchController from "../../../app/javascript/controllers/match_controller.js"

const html = `
  <div data-controller="test" data-test-total-value="2">
    <div data-test-target="complete" hidden></div>
    <div data-test-target="timer">00:00</div>
    <div data-test-target="pairsLeft">2</div>
    <div data-test-target="streak">0</div>
    <div data-test-target="progressFill" style="width: 0%"></div>
    <button class="match-tile" data-action="click->test#select"
            data-match-id="1" data-match-side="front">Hello</button>
    <button class="match-tile" data-action="click->test#select"
            data-match-id="1" data-match-side="back">World</button>
    <button class="match-tile" data-action="click->test#select"
            data-match-id="2" data-match-side="front">Foo</button>
    <button class="match-tile" data-action="click->test#select"
            data-match-id="2" data-match-side="back">Bar</button>
  </div>
`

describe("MatchController", () => {
  let app, element, tiles

  beforeEach(async () => {
    jest.useFakeTimers()
    ;({ app, element } = await startController(MatchController, html))
    tiles = [...element.querySelectorAll(".match-tile")]
  })

  afterEach(() => {
    app.stop()
    jest.useRealTimers()
  })

  describe("select — first tile", () => {
    it("adds is-selected when a tile is clicked", () => {
      tiles[0].click()
      expect(tiles[0].classList.contains("is-selected")).toBe(true)
    })

    it("deselects a tile when it is clicked a second time", () => {
      tiles[0].click()
      tiles[0].click()
      expect(tiles[0].classList.contains("is-selected")).toBe(false)
    })
  })

  describe("select — correct pair (same match-id, opposite sides)", () => {
    beforeEach(() => {
      tiles[0].click()  // id=1 front
      tiles[1].click()  // id=1 back
    })

    it("adds is-matched to both tiles", () => {
      expect(tiles[0].classList.contains("is-matched")).toBe(true)
      expect(tiles[1].classList.contains("is-matched")).toBe(true)
    })

    it("removes is-selected from both tiles", () => {
      expect(tiles[0].classList.contains("is-selected")).toBe(false)
      expect(tiles[1].classList.contains("is-selected")).toBe(false)
    })

    it("decrements the pairsLeft counter", () => {
      const pairsLeft = element.querySelector("[data-test-target='pairsLeft']")
      expect(pairsLeft.textContent).toBe("1")
    })

    it("updates progressFill width", () => {
      const fill = element.querySelector("[data-test-target='progressFill']")
      expect(fill.style.width).toBe("50%")
    })
  })

  describe("select — wrong pair (same side or different match-id)", () => {
    beforeEach(() => {
      tiles[0].click()  // id=1 front
      tiles[2].click()  // id=2 front — wrong pair
    })

    it("adds is-wrong to both tiles", () => {
      expect(tiles[0].classList.contains("is-wrong")).toBe(true)
      expect(tiles[2].classList.contains("is-wrong")).toBe(true)
    })

    it("removes is-selected from both tiles", () => {
      expect(tiles[0].classList.contains("is-selected")).toBe(false)
      expect(tiles[2].classList.contains("is-selected")).toBe(false)
    })

    it("removes is-wrong from both tiles after 700ms", async () => {
      jest.advanceTimersByTime(700)
      await nextTick()
      expect(tiles[0].classList.contains("is-wrong")).toBe(false)
      expect(tiles[2].classList.contains("is-wrong")).toBe(false)
    })

    it("locks interaction while isProcessing is true", () => {
      tiles[0].click()  // should be a no-op while processing
      expect(tiles[0].classList.contains("is-selected")).toBe(false)
    })
  })

  describe("select — already matched tiles are skipped", () => {
    it("cannot re-select a matched tile", () => {
      tiles[0].click()
      tiles[1].click()
      // Now both are matched — clicking a matched tile does nothing
      tiles[0].click()
      expect(tiles[0].classList.contains("is-selected")).toBe(false)
    })
  })

  describe("completion", () => {
    it("reveals the complete overlay when all pairs are matched", () => {
      const complete = element.querySelector("[data-test-target='complete']")
      tiles[0].click(); tiles[1].click()   // pair 1
      tiles[2].click(); tiles[3].click()   // pair 2
      expect(complete.hidden).toBe(false)
    })
  })

  describe("#tickTimer", () => {
    it("updates the timer display after each second", async () => {
      const timer = element.querySelector("[data-test-target='timer']")
      jest.advanceTimersByTime(1000)
      await nextTick()
      expect(timer.textContent).toBe("00:01")
    })

    it("formats minutes and seconds correctly at 61 seconds", async () => {
      const timer = element.querySelector("[data-test-target='timer']")
      jest.advanceTimersByTime(61000)
      await nextTick()
      expect(timer.textContent).toBe("01:01")
    })
  })
})
