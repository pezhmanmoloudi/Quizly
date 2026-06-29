// Global, state-driven keyboard router.
//
// A single module-level instance (importmap shares it) owns ONE document-level
// "keydown" listener for the app's lifetime. Stimulus controllers register on
// connect() and unregister on disconnect(); registering replaces the previous
// owner, so only one mode is ever active and cross-mode conflicts are impossible.
//
// Routing lives here (KEYMAPS); behaviour lives in the controllers' action methods.
// State is pulled from the controller at keydown time via its stateProvider, so it
// is always current (a push model goes stale because some transitions — e.g. Study's
// reveal — happen inside a different controller).

const NON_TEXT_INPUT = new Set(
  ["button", "submit", "reset", "checkbox", "radio", "range", "file", "image", "color"]
)

// Block shortcuts only when the user is genuinely typing. Buttons/links never block.
function isTypingTarget(el) {
  if (!el) return false
  if (el.isContentEditable) return true
  const tag = el.tagName
  if (tag === "TEXTAREA" || tag === "SELECT") return true
  if (tag === "INPUT") return !NON_TEXT_INPUT.has((el.getAttribute("type") || "text").toLowerCase())
  return false
}

// Canonical key token. Space from " "/"Spacebar"/code; Escape from "Esc"; letters lowercased.
function normalizeKey(event) {
  const k = event.key
  if (k === " " || k === "Spacebar" || event.code === "Space") return "Space"
  if (k === "Esc") return "Escape"
  if (/^[a-z]$/i.test(k)) return k.toLowerCase()
  return k // "Escape" | "Enter" | "ArrowLeft" | "ArrowRight" | "1".."9" | ...
}

// (state, key) -> actionName | [actionName, ...args] | null.  null = ignore (no preventDefault).
// State rules are checked before mode defaults, so state overrides mode.
const KEYMAPS = {
  study(state, key) {
    if (key === "Escape") return "onEscape"
    if (state.inputLocked) return null
    if (state.phase === "question") return key === "Space" ? "reveal" : null
    return { "1": "gradeAgain", "2": "gradeHard", "3": "gradeGood", "4": "gradeEasy" }[key] || null
  },

  learn(_state, key) {
    if (key === "Escape") return "closeLearnSettings"
    if (key === "Space") return "flip"
    return { g: "gotIt", c: "confused", d: "dontKnow" }[key] || null
  },

  flashcard(_state, key) {
    return { Space: "flip", ArrowLeft: "previous", ArrowRight: "next", s: "star" }[key] || null
  },

  // In-flashcard study sub-mode: reveal is a flip (no showButton), no prev/next.
  flashcard_study(state, key) {
    if (key === "Space") return "flip"
    if (!state.revealed) return null
    return { "1": "gradeAgain", "2": "gradeHard", "3": "gradeGood", "4": "gradeEasy" }[key] || null
  },

  test(state, key) {
    if (key === "Escape") return "onEscape"
    if (["1", "2", "3", "4"].includes(key)) return state.submitted ? null : ["selectOption", Number(key) - 1]
    if (key === "Enter" || key === "Space") return state.submitted ? "continue" : null
    return null
  }
}

class KeyboardManager {
  #mode = null
  #controller = null
  #stateProvider = () => ({})
  #installed = false

  register(controller, mode, stateProvider = () => ({})) {
    if (!this.#installed) {
      document.addEventListener("keydown", this.#onKeydown)
      this.#installed = true
    }
    this.#controller = controller
    this.#mode = mode
    this.#stateProvider = stateProvider
  }

  // Push shim for API compatibility; the stateProvider passed to register() is preferred.
  setState(snapshot) {
    const snap = snapshot || {}
    this.#stateProvider = () => snap
  }

  unregister(controller) {
    if (this.#controller !== controller) return
    this.#controller = null
    this.#mode = null
    this.#stateProvider = () => ({})
  }

  #onKeydown = (event) => {
    if (!this.#mode || !this.#controller) return
    if (event.ctrlKey || event.metaKey || event.altKey) return
    if (isTypingTarget(document.activeElement)) return

    const keymap = KEYMAPS[this.#mode]
    if (!keymap) return

    const action = keymap(this.#stateProvider() || {}, normalizeKey(event))
    if (!action) return

    const [method, ...args] = Array.isArray(action) ? action : [action]
    const fn = this.#controller[method]
    if (typeof fn !== "function") return

    event.preventDefault()
    fn.apply(this.#controller, args)
  }
}

export default new KeyboardManager()
