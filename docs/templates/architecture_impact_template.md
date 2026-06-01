# Architecture Impact Report

**Feature:** [Feature Name]
**Date:** YYYY-MM-DD
**Related Feature Report:** [docs/features/YYYY-MM-DD-feature-name.md]

---

## Affected Areas

List each domain or area of the application that is affected by this change:

- [ ] Authentication / Sessions
- [ ] Dashboard
- [ ] Decks
- [ ] Flashcards
- [ ] Study Flow
- [ ] Review / Spaced Repetition
- [ ] API
- [ ] Background Jobs
- [ ] Caching
- [ ] WebSockets / Action Cable
- [ ] File Storage
- [ ] Other: [specify]

---

## Dependencies

**Models depended on:**
- `ModelName` — [how it is used]

**Services used:**
- `ServiceName` — [what it does in this context]

**Queries / Scopes used:**
- `Model.scope_name` — [what it returns]

**Policies / Authorization:**
- [Any policy objects or authorization checks introduced]

**Components / Partials:**
- `_partial_name` — [where it is rendered]

---

## New Couplings Introduced

Describe any new relationships or dependencies between previously independent parts of the system:

- [e.g. `Deck` now depends on `User` presence check in `FlashcardsController`]
- [e.g. `StudySession` is now created implicitly when a Deck is opened]

If none: None

---

## Future Features Impacted

List features that are planned or likely, and how this implementation affects them:

| Future Feature | Impact |
|----------------|--------|
| [Feature name] | [How this change enables, constrains, or requires adjustment for it] |

---

## Technical Debt

List any shortcuts, workarounds, or known imperfections introduced:

- [Debt item] — [why it was accepted, what the ideal solution would be]

If none: None

---

## Refactoring Opportunities

Possible future improvements that were identified but not acted on:

- [Refactor opportunity] — [what benefit it would provide]

---

## Risks

Potential issues this change could cause in the future:

- [Risk] — [likelihood, impact, mitigation]

---

## Scalability Notes

How this design behaves as the application grows:

- **Data volume:** [How does this perform with 10x, 100x more records?]
- **Concurrency:** [Any race conditions or locking concerns?]
- **Query efficiency:** [N+1 risks, missing indexes, eager loading needs?]
- **Caching:** [What could be cached in the future?]
