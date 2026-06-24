export default class StudySRS {
  #progresses
  #gradeUrlTemplate

  constructor(progressesArray, gradeUrlTemplate) {
    this.#progresses = new Map(progressesArray.map(p => [p.flashcard_id, { ...p }]))
    this.#gradeUrlTemplate = gradeUrlTemplate
  }

  // Returns slide indices sorted: overdue first, then by next_review_at ascending.
  // Slides without a progress record go last (treated as furthest future due date).
  getNextQueue(slideElements) {
    const now = new Date()
    return [...slideElements]
      .map((el, index) => {
        const flashcardId = parseInt(el.dataset.flashcardId, 10)
        const progress    = this.#progresses.get(flashcardId)
        const due         = progress?.next_review_at ? new Date(progress.next_review_at) : new Date(8640000000000000)
        return { index, due, isDue: due <= now }
      })
      .sort((a, b) => {
        if (a.isDue !== b.isDue) return a.isDue ? -1 : 1
        return a.due - b.due
      })
      .map(item => item.index)
  }

  getDueCount(slideElements) {
    const now = new Date()
    return [...slideElements].filter(el => {
      const flashcardId = parseInt(el.dataset.flashcardId, 10)
      const progress    = this.#progresses.get(flashcardId)
      return progress?.next_review_at ? new Date(progress.next_review_at) <= now : true
    }).length
  }

  // rating: "again" | "hard" | "good" | "easy"
  async gradeCard(cardProgressId, rating) {
    const qualityMap = { again: 1, hard: 3, good: 4, easy: 5 }
    const quality    = qualityMap[rating]
    const url        = this.#gradeUrlTemplate.replace(":id", cardProgressId)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""
    const response  = await fetch(url, {
      method:  "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
      body:    JSON.stringify({ quality })
    })

    if (response.ok) {
      const updated = await response.json()
      this.#progresses.set(updated.flashcard_id, updated)
    }
  }
}
