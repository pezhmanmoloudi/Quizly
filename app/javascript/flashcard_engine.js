export default class FlashcardEngine {
  #totalCards
  #currentIndex
  #cardOrder
  #flipped
  #listeners

  static #EVENTS = ['onCardChange', 'onFlip', 'onNext', 'onPrevious']

  constructor(totalCards) {
    this.#totalCards = totalCards
    this.#cardOrder = Array.from({ length: totalCards }, (_, i) => i)
    this.#currentIndex = 0
    this.#flipped = false
    this.#listeners = {}
  }

  // --- Getters ---

  get currentIndex() { return this.#currentIndex }
  get cardOrder() { return [...this.#cardOrder] }
  get flipped() { return this.#flipped }
  get currentCardIndex() { return this.#cardOrder[this.#currentIndex] }
  get total() { return this.#totalCards }
  get size() { return this.#cardOrder.length }

  // --- Navigation ---

  next() {
    if (this.#currentIndex >= this.#cardOrder.length - 1) return
    this.#currentIndex++
    this.#emit('onNext', this.#cardPayload())
    this.#emit('onCardChange', this.#cardPayload())
  }

  previous() {
    if (this.#currentIndex <= 0) return
    this.#currentIndex--
    this.#emit('onPrevious', this.#cardPayload())
    this.#emit('onCardChange', this.#cardPayload())
  }

  goTo(index) {
    if (index < 0 || index >= this.#cardOrder.length) return
    this.#currentIndex = index
    this.#emit('onCardChange', this.#cardPayload())
  }

  // --- Flip ---

  flip() {
    this.#flipped = !this.#flipped
    this.#emit('onFlip', { flipped: this.#flipped })
  }

  setFlipped(bool) {
    this.#flipped = bool
    this.#emit('onFlip', { flipped: this.#flipped })
  }

  resetFlip(bool) {
    this.#flipped = (bool === true)
  }

  // --- Shuffle ---

  shuffle() {
    for (let i = this.#cardOrder.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [this.#cardOrder[i], this.#cardOrder[j]] = [this.#cardOrder[j], this.#cardOrder[i]]
    }
    this.#currentIndex = 0
    this.#emit('onCardChange', this.#cardPayload())
  }

  setOrder(indices) {
    this.#cardOrder = [...indices]
    this.#currentIndex = 0
  }

  // --- Events ---

  on(eventName, callback) {
    if (!FlashcardEngine.#EVENTS.includes(eventName)) return
    this.#listeners[eventName] ||= []
    this.#listeners[eventName].push(callback)
  }

  // --- Private ---

  #emit(eventName, payload) {
    const callbacks = this.#listeners[eventName]
    if (!callbacks) return
    const event = { eventName, ...payload }
    callbacks.forEach(cb => cb(event))
  }

  #cardPayload() {
    return { index: this.#currentIndex, cardIndex: this.currentCardIndex }
  }
}
