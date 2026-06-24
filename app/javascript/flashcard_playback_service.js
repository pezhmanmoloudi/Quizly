// Auto-advance service: front → wait → flip to back → wait → next card
// Always follows this fixed sequence regardless of startWithBack setting.
export default class FlashcardPlaybackService {
  #timer    = null
  #onFlip   = null
  #onNext   = null
  #getDelay = null

  constructor({ onFlip, onNext, getDelay }) {
    this.#onFlip   = onFlip
    this.#onNext   = onNext
    this.#getDelay = getDelay
  }

  start() {
    if (this.#timer) return
    this.#scheduleFlip()
  }

  stop() {
    clearTimeout(this.#timer)
    this.#timer = null
  }

  get isRunning() { return this.#timer !== null }

  #scheduleFlip() {
    this.#timer = setTimeout(() => {
      this.#onFlip()
      this.#scheduleNext()
    }, this.#getDelay())
  }

  #scheduleNext() {
    this.#timer = setTimeout(() => {
      const hasNext = this.#onNext()
      if (hasNext) {
        this.#scheduleFlip()
      } else {
        this.stop()
      }
    }, this.#getDelay())
  }
}
