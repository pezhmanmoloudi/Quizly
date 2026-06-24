export default class LearnEngine {
  static MASTERY_THRESHOLD = 70
  static WEAK_THRESHOLD    = 40
  static FEEDBACK_DELTAS   = { got_it: +20, confused: -10, dont_know: -25 }
  static WAVE_SIZE         = 3

  #items          // Map<flashcardId(int), item>
  #initialStates  // Map<flashcardId(int), string> — localState snapshot at session start
  #slides         // Array of slide DOM elements
  #masteryThreshold
  #weakPriority
  #newCardsLimit
  #waveSize
  #activatedFids  // Set of flashcard IDs released into the active wave pool

  constructor(itemsData, slideElements, settings = {}) {
    this.#slides           = slideElements
    this.#masteryThreshold = settings.masteryThreshold ?? LearnEngine.MASTERY_THRESHOLD
    this.#weakPriority     = settings.weakCardsPriority ?? "normal"
    this.#newCardsLimit    = settings.newCardsLimit ?? null

    this.#items = new Map(itemsData.map(i => [i.flashcard_id, {
      ...i,
      localState: i.status === "mastered" ? "mastered"
                : i.status === "unseen"   ? "unseen"
                : i.mastery_score >= LearnEngine.WEAK_THRESHOLD ? "improving"
                : "learning",
      urgency:   0,
      seenCount: 0
    }]))

    this.#initialStates = new Map(
      [...this.#items.entries()].map(([fid, item]) => [fid, item.localState])
    )

    const limit = this.#newCardsLimit && this.#newCardsLimit > 0
      ? this.#newCardsLimit
      : Infinity
    this.#waveSize = Math.min(LearnEngine.WAVE_SIZE, isFinite(limit) ? limit : LearnEngine.WAVE_SIZE)

    this.#activatedFids = new Set()
    this.#activateNextWave()
  }

  // Returns slide indices ordered for the adaptive queue.
  // Urgent cards (recently wrong) are interleaved near the front;
  // new cards are gated by wave until current wave is stable.
  getLearnQueue() {
    const all = [...this.#slides].map((el, index) => {
      const fid  = parseInt(el.dataset.flashcardId, 10)
      const item = this.#items.get(fid) ?? { mastery_score: 0, localState: "unseen", urgency: 0 }
      return { index, fid, score: item.mastery_score, localState: item.localState, urgency: item.urgency || 0 }
    })

    // Include: non-mastered cards that are either already seen, or activated unseen
    const active = all.filter(i =>
      i.localState !== "mastered" &&
      (i.localState !== "unseen" || this.#activatedFids.has(i.fid))
    )
    if (active.length === 0) return []

    // Split: cards needing immediate repetition vs normal flow
    const urgent = active
      .filter(i => i.urgency > 0)
      .sort((a, b) => a.score - b.score || b.urgency - a.urgency)

    const base = active
      .filter(i => i.urgency === 0)
      .sort((a, b) => this.#basePriority(a) - this.#basePriority(b))

    // Insert urgent cards at position-based slots:
    // dont_know (u=3) → pos 1, confused (u=2) → pos 2, fading (u=1) → pos 3
    const result = [...base]
    urgent.slice().reverse().forEach(item => {
      const insertAt = Math.min(4 - item.urgency, result.length)
      result.splice(insertAt, 0, item)
    })

    return result.map(({ index }) => index)
  }

  recordFeedback(flashcardId, feedback) {
    const item = this.#items.get(flashcardId)
    if (!item) return

    item.seenCount = (item.seenCount || 0) + 1
    const delta = LearnEngine.FEEDBACK_DELTAS[feedback] ?? 0
    item.mastery_score = Math.max(0, Math.min(100, item.mastery_score + delta))

    switch (feedback) {
      case "got_it":    item.urgency = Math.max(0, (item.urgency || 0) - 1); break
      case "confused":  item.urgency = 2; break
      case "dont_know": item.urgency = 3; break
    }

    if (item.mastery_score >= this.#masteryThreshold) {
      item.localState = "mastered"
      item.urgency    = 0
    } else if (feedback === "dont_know" || feedback === "confused") {
      item.localState = "weak"
    } else if (item.mastery_score >= LearnEngine.WEAK_THRESHOLD) {
      item.localState = "improving"
    } else {
      item.localState = "learning"
    }

    this.#items.set(flashcardId, item)
    this.#maybeAdvanceWave()
  }

  getItemId(flashcardId) {
    return this.#items.get(flashcardId)?.id ?? null
  }

  getStats() {
    const all      = [...this.#items.values()]
    const total    = all.length
    const mastered = all.filter(i => i.localState === "mastered").length
    return {
      newCount:      all.filter(i => i.localState === "unseen").length,
      weakCount:     all.filter(i => i.localState === "weak").length,
      masteredCount: mastered,
      masteryPct:    total ? Math.round(mastered / total * 100) : 0
    }
  }

  isComplete() {
    return [...this.#items.values()].every(i => i.localState === "mastered")
  }

  getCompletionStats() {
    const all = [...this.#items.values()]
    const learnedCount = all.filter(i =>
      this.#initialStates.get(i.flashcard_id) !== "mastered" &&
      i.localState === "mastered"
    ).length
    const weakImprovedCount = all.filter(i => {
      const init = this.#initialStates.get(i.flashcard_id)
      return (init === "weak" || init === "learning") &&
             (i.localState === "improving" || i.localState === "mastered")
    }).length
    const { masteryPct } = this.getStats()
    return { learnedCount, weakImprovedCount, masteryPct }
  }

  // ── Private ──────────────────────────────────────────────────

  #basePriority({ localState, score }) {
    const weakOffset = { high: 50, normal: 100, low: 150 }[this.#weakPriority] ?? 100
    switch (localState) {
      case "unseen":    return 0
      case "weak":      return weakOffset       + Math.max(0, LearnEngine.WEAK_THRESHOLD - score)
      case "learning":  return weakOffset + 100  + Math.max(0, LearnEngine.WEAK_THRESHOLD - score)
      case "improving": return weakOffset + 200  + score
      default:          return 999
    }
  }

  #activateNextWave() {
    const cap       = this.#newCardsLimit && this.#newCardsLimit > 0 ? this.#newCardsLimit : Infinity
    const remaining = cap - this.#activatedFids.size
    if (remaining <= 0) return

    const limit = Math.min(this.#waveSize, remaining)
    ;[...this.#items.entries()]
      .filter(([fid, item]) => item.localState === "unseen" && !this.#activatedFids.has(fid))
      .slice(0, limit)
      .forEach(([fid]) => this.#activatedFids.add(fid))
  }

  #maybeAdvanceWave() {
    // Block if any activated card is still in unseen state (waiting to be shown)
    const activatedUnseen = [...this.#activatedFids]
      .map(fid => this.#items.get(fid))
      .filter(i => i?.localState === "unseen")
    if (activatedUnseen.length > 0) return

    // "low" priority: introduce next wave without waiting for weak cards to resolve
    if (this.#weakPriority !== "low") {
      const anyUnstable = [...this.#items.values()].some(i =>
        i.localState !== "mastered" && (i.localState === "weak" || i.urgency > 0)
      )
      if (anyUnstable) return
    }

    this.#activateNextWave()
  }
}
