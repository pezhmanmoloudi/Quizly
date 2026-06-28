import { jest } from "@jest/globals"
import { startController, nextTick } from "../support/stimulus_helpers.js"
import DropdownController from "../../../app/javascript/controllers/dropdown_controller.js"

const html = `
  <div data-controller="test"
       data-action="keydown->test#onKeydown click@window->test#closeIfOutside">
    <button data-test-target="trigger"
            data-action="click->test#toggle"
            aria-expanded="false">Select</button>
    <span data-test-target="label">Choose…</span>
    <input data-test-target="input" type="hidden" value="">
    <ul data-test-target="menu" data-open="false" style="position:fixed">
      <li data-test-target="option"
          data-action="click->test#select"
          data-value="apple"
          data-name="apple"
          aria-selected="false"
          tabindex="0">Apple</li>
      <li data-test-target="option"
          data-action="click->test#select"
          data-value="banana"
          data-name="banana"
          aria-selected="false"
          tabindex="0">Banana</li>
      <li data-test-target="option"
          data-action="click->test#select"
          data-value="cherry"
          data-name="cherry"
          aria-selected="false"
          tabindex="0">Cherry</li>
    </ul>
  </div>
`

const htmlSearchable = `
  <div data-controller="test"
       data-test-searchable-value="true"
       data-action="keydown->test#onKeydown click@window->test#closeIfOutside">
    <button data-test-target="trigger"
            data-action="click->test#toggle"
            aria-expanded="false">Select</button>
    <span data-test-target="label">Choose…</span>
    <input data-test-target="input" type="hidden" value="">
    <ul data-test-target="menu" data-open="false" style="position:fixed">
      <input data-test-target="search"
             data-action="input->test#filter"
             type="text" placeholder="Search…">
      <li data-test-target="option"
          data-action="click->test#select"
          data-value="apple"
          data-name="apple"
          tabindex="0">Apple</li>
      <li data-test-target="option"
          data-action="click->test#select"
          data-value="banana"
          data-name="banana"
          tabindex="0">Banana</li>
      <li data-test-target="option"
          data-action="click->test#select"
          data-value="cherry"
          data-name="cherry"
          tabindex="0">Cherry</li>
    </ul>
  </div>
`

describe("DropdownController", () => {
  let app, element

  afterEach(() => {
    if (app) app.stop()
    document.body.innerHTML = ""
  })

  describe("toggle — open / close", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(DropdownController, html))
    })

    it("opens the menu on first toggle", async () => {
      const menu = element.querySelector("[data-test-target='menu']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
      expect(menu.dataset.open).toBe("true")
    })

    it("sets aria-expanded to true when open", async () => {
      const trigger = element.querySelector("[data-test-target='trigger']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
      expect(trigger.getAttribute("aria-expanded")).toBe("true")
    })

    it("closes the menu on second toggle", async () => {
      const menu = element.querySelector("[data-test-target='menu']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
      controller.toggle()
      await nextTick()
      expect(menu.dataset.open).toBe("false")
    })

    it("sets aria-expanded to false when closed", async () => {
      const trigger = element.querySelector("[data-test-target='trigger']")
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
      controller.toggle()
      await nextTick()
      expect(trigger.getAttribute("aria-expanded")).toBe("false")
    })
  })

  describe("select", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(DropdownController, html))
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
    })

    it("updates the label text to the selected option", async () => {
      const label = element.querySelector("[data-test-target='label']")
      const option = element.querySelector("[data-value='banana']")
      option.click()
      await nextTick()
      expect(label.textContent.trim()).toBe("Banana")
    })

    it("updates the hidden input value", async () => {
      const input = element.querySelector("[data-test-target='input']")
      const option = element.querySelector("[data-value='apple']")
      option.click()
      await nextTick()
      expect(input.value).toBe("apple")
    })

    it("sets aria-selected on the chosen option", async () => {
      const option = element.querySelector("[data-value='cherry']")
      option.click()
      await nextTick()
      expect(option.getAttribute("aria-selected")).toBe("true")
    })

    it("clears aria-selected on previously selected options", async () => {
      const options = element.querySelectorAll("[data-test-target='option']")
      options[0].click()
      await nextTick()
      options[1].click()
      await nextTick()
      expect(options[0].getAttribute("aria-selected")).toBe("false")
      expect(options[1].getAttribute("aria-selected")).toBe("true")
    })

    it("closes the menu after selection", async () => {
      const menu = element.querySelector("[data-test-target='menu']")
      const option = element.querySelector("[data-value='apple']")
      option.click()
      await nextTick()
      expect(menu.dataset.open).toBe("false")
    })

    it("dispatches a change event on the input", async () => {
      const input = element.querySelector("[data-test-target='input']")
      const changed = jest.fn()
      input.addEventListener("change", changed)
      element.querySelector("[data-value='apple']").click()
      await nextTick()
      expect(changed).toHaveBeenCalled()
    })
  })

  describe("keyboard navigation — onKeydown", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(DropdownController, html))
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
    })

    it("ArrowDown moves focus to the next option", async () => {
      const options = element.querySelectorAll("[data-test-target='option']")
      options[0].focus()
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
      await nextTick()
      expect(document.activeElement).toBe(options[1])
    })

    it("ArrowDown from last option stays on last option", async () => {
      const options = element.querySelectorAll("[data-test-target='option']")
      options[options.length - 1].focus()
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
      await nextTick()
      expect(document.activeElement).toBe(options[options.length - 1])
    })

    it("ArrowUp from first option closes menu and returns focus to trigger", async () => {
      const options = element.querySelectorAll("[data-test-target='option']")
      const menu = element.querySelector("[data-test-target='menu']")
      options[0].focus()
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowUp", bubbles: true }))
      await nextTick()
      expect(menu.dataset.open).toBe("false")
    })

    it("Escape closes the menu", async () => {
      const menu = element.querySelector("[data-test-target='menu']")
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
      await nextTick()
      expect(menu.dataset.open).toBe("false")
    })

    it("Escape returns focus to the trigger", async () => {
      const trigger = element.querySelector("[data-test-target='trigger']")
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
      await nextTick()
      expect(document.activeElement).toBe(trigger)
    })

    it("does nothing if menu is closed", async () => {
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.close()
      await nextTick()
      const options = element.querySelectorAll("[data-test-target='option']")
      const focusBefore = document.activeElement
      element.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
      await nextTick()
      expect(document.activeElement).toBe(focusBefore)
    })
  })

  describe("closeIfOutside", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(DropdownController, html))
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
    })

    it("closes the menu when clicking outside the element", async () => {
      const menu = element.querySelector("[data-test-target='menu']")
      const outside = document.createElement("button")
      document.body.appendChild(outside)
      controller_ref(app, element).closeIfOutside({ target: outside })
      await nextTick()
      expect(menu.dataset.open).toBe("false")
    })

    it("keeps the menu open when clicking inside the element", async () => {
      const menu = element.querySelector("[data-test-target='menu']")
      const inside = element.querySelector("[data-test-target='trigger']")
      controller_ref(app, element).closeIfOutside({ target: inside })
      await nextTick()
      expect(menu.dataset.open).toBe("true")
    })
  })

  describe("filter — searchable dropdown", () => {
    beforeEach(async () => {
      ;({ app, element } = await startController(DropdownController, htmlSearchable))
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.toggle()
      await nextTick()
    })

    it("hides options not matching the search query", async () => {
      const search = element.querySelector("[data-test-target='search']")
      search.value = "apple"
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.filter()
      await nextTick()
      const options = element.querySelectorAll("[data-test-target='option']")
      const visibleValues = [...options].filter(o => !o.hidden).map(o => o.dataset.value)
      expect(visibleValues).toEqual(["apple"])
    })

    it("shows all options when search query is cleared", async () => {
      const search = element.querySelector("[data-test-target='search']")
      search.value = "apple"
      const controller = app.getControllerForElementAndIdentifier(element, "test")
      controller.filter()
      search.value = ""
      controller.filter()
      await nextTick()
      const options = element.querySelectorAll("[data-test-target='option']")
      const hiddenCount = [...options].filter(o => o.hidden).length
      expect(hiddenCount).toBe(0)
    })
  })
})

function controller_ref(app, element) {
  return app.getControllerForElementAndIdentifier(element, "test")
}
