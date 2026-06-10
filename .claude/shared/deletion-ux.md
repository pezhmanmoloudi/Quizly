# Quizly — UX & Deletion Guidelines

Deletion UX must be proportional to the importance of the item being deleted.
Do not apply the same confirmation pattern to all resources.

---

## Flashcard Deletion

Flashcards are lightweight items that users frequently create and remove.

**Rules:**
- Do NOT show a confirmation modal or inline confirm panel.
- Delete immediately on action.
- Use Turbo Streams to remove the card from the UI without a page reload.
- Show a toast notification: `"Flashcard removed"` (i18n key required).
- Provide an Undo action in the toast for a few seconds.
- Keep the interaction fast and frictionless.

**Flow:**
```
Delete Flashcard → Remove from UI (Turbo Stream) → Show Toast with Undo
```

---

## Deck Deletion

Decks are high-value resources that may contain many flashcards.

**Rules:**
- Always show a confirmation modal before deleting.
- Display the deck name in the modal.
- Display the flashcard count if available.
- Clearly warn that the deck and all associated flashcards will be permanently removed.
- Require explicit user confirmation via a "Delete Deck" button.

**Flow:**
```
Delete Deck → Confirmation Modal → Confirm → Delete → Redirect → Success Toast
```

**Example modal content:**
```
Delete Deck?

Deck: German A1
523 flashcards

This action cannot be undone.

[Cancel]  [Delete Deck]
```

---

## Account Deletion

Account deletion is an irreversible, high-stakes action.

**Rules:**
- Use a dedicated confirmation screen or a strong confirmation modal — not a simple click.
- Require the user to type the confirmation phrase `DELETE` before enabling the action.
- Clearly explain all consequences (data loss, subscriptions, etc.).
- Do not allow one-click account deletion under any circumstances.

---

## Design System Consistency

Before building any new UI component:

- Check whether a similar component already exists in the codebase.
- Reuse existing components whenever possible.
- Avoid duplicate implementations.

**Example:** The searchable language selector in Settings is the preferred implementation
and must be reused across the application wherever language selection is required.

---

## Confirmation Modals — When to Use

Use confirmation modals only for high-impact, hard-to-reverse actions.

**Good candidates:**
- Delete Deck
- Delete Account
- Bulk Delete operations

**Avoid for:**
- Removing a flashcard
- Removing a temporary form row
- Removing a draft card before saving

---

## Hotwire Guidelines

**Prefer:**
- Turbo Streams for in-place UI updates
- Toast notifications for feedback
- Undo actions for low-risk deletions

**Avoid:**
- Full page reloads after destructive actions
- `data: { turbo_confirm: "..." }` (browser confirm dialogs)
- Blocking modal flows for lightweight operations

---

## MVP Principle

Always prefer the simplest UX that:

- Prevents accidental destructive actions
- Minimises user friction
- Is easy to maintain in a Rails + Hotwire application

Avoid over-engineering confirmation flows.
