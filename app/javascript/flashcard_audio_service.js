export default class FlashcardAudioService {
  constructor(onVoicesReady) {
    this.#initVoices(onVoicesReady)
  }

  speak(text, lang) {
    if (!window.speechSynthesis || !text) return
    const utterance = new SpeechSynthesisUtterance(text)
    if (lang) utterance.lang = lang
    window.speechSynthesis.cancel()
    window.speechSynthesis.speak(utterance)
  }

  isLangSupported(lang) {
    if (!lang || !window.speechSynthesis) return true
    const voices = speechSynthesis.getVoices()
    if (!voices.length) return true
    return voices.some(v => v.lang.toLowerCase().startsWith(lang.toLowerCase()))
  }

  #initVoices(callback, attempts = 0) {
    if (!window.speechSynthesis) return
    if (speechSynthesis.getVoices().length) {
      callback?.()
      return
    }
    speechSynthesis.addEventListener('voiceschanged', () => callback?.(), { once: true })
    // Safari fallback: voiceschanged may never fire
    if (attempts < 3) {
      setTimeout(() => this.#initVoices(callback, attempts + 1), 600)
    }
  }
}
