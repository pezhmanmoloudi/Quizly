# Project Skill: Localization & Internationalization Guard

You are enforcing Quizly's localization rules. No user-facing string may ever be hardcoded. Follow every step below without skipping any.

Supported locales: `en` · `es` · `de` · `fr` · `pt` · `ar` · `fa` · `ckb` · `tr` · `ru`
Source of truth: `config/locales/en.yml`

---

## Core Rule

Every user-facing string MUST use a Rails I18n key (`t()` / `t!()` in views and controllers, data attributes in Stimulus). No exceptions.

---

# Phase 1 — Pre-Implementation: Identify User-Facing Text

Before writing any feature code, scan the planned feature and list every piece of user-facing text it will introduce.

Check for ALL of the following:

| Category | Examples |
|----------|---------|
| Buttons | Submit, Cancel, Save, Delete, Edit |
| Links | "Back to Deck", "See all →" |
| Labels | form labels, field hints |
| Headings | page titles, section headers |
| Placeholders | input placeholder attributes |
| Tooltips | title attributes, aria-label, aria-describedby |
| Flash messages | notice, alert in controllers |
| Validation messages | model error messages |
| Modal / dialog content | any inline confirmation text |
| Empty states | "No decks yet", "Nothing here" |
| Search UI | search placeholder, result labels |
| Dropdown items | option text, option group labels |
| Table headers | `<th>` content |
| Card titles and stats | dashboard/explore card text |
| Study mode text | Flashcard, Study, Learn, Test, Match UI strings |
| Turbo Stream content | any string inside `turbo_stream.` calls |
| Turbo Frame content | any string inside lazily loaded frames |
| Stimulus-generated text | any string a `.js` controller inserts into the DOM |
| Email subjects | `mail(subject:)` in mailers |
| Email bodies | all body text in mailer views |

For each item found: determine the correct `en.yml` namespace following the existing key hierarchy.

**Existing namespace conventions (use as model):**
- Controllers: `decks.created`, `decks.updated`, `flashcards.deleted`
- Flash messages: flat key under resource namespace
- View-local keys: `decks.index.empty_title`, `study_modes.learn.summary_title`
- Shared actions: `shared.cancel`, `shared.save`
- Email: `passwords_mailer.reset_subject`
- Study engines: `study_modes.<mode>.<key>`

---

# Phase 2 — Implementation Rules

## ERB Views

✅ Allowed:
```erb
<%= t("decks.index.empty_title") %>
<%= t(".empty_title") %>   <%# relative key — resolves to the view's namespace %>
```

❌ Forbidden:
```erb
<span>No decks yet</span>
<%= "Save" %>
placeholder="Enter your email"
```

Every string that reaches the browser must pass through `t()`. This includes:
- Text nodes
- `placeholder`, `title`, `aria-label`, `aria-describedby` attributes
- Button text
- Link text
- `value` attributes on submit inputs
- Turbo Stream response fragments

## Controllers

✅ Allowed:
```ruby
flash[:notice] = t("decks.created")
redirect_to decks_path, notice: t("decks.deleted")
```

❌ Forbidden:
```ruby
flash[:notice] = "Deck created."
```

## Mailers

✅ Allowed:
```ruby
mail(to: @user.email, subject: t("passwords_mailer.reset_subject"))
```

Mailer view body text follows the same ERB rules above.

## JavaScript / Stimulus

✅ Required pattern — pass translations from Rails via data attributes:
```erb
<%# In the ERB view, on the controller element: %>
<div data-controller="my-feature"
     data-my-feature-success-message-value="<%= t("my_feature.success") %>"
     data-my-feature-error-message-value="<%= t("my_feature.error") %>">
```

```js
// In the Stimulus controller — read from values, never hardcode:
static values = { successMessage: String, errorMessage: String }

showSuccess() {
  this.element.textContent = this.successMessageValue  // ✅
}
```

❌ Forbidden in any `.js` file:
```js
element.textContent = "Card saved!"   // ❌
this.errorTarget.textContent = "Invalid input"  // ❌
```

## Model Validation Messages

✅ Preferred — use Rails i18n validation keys:
```yaml
# en.yml
activerecord:
  errors:
    models:
      deck:
        attributes:
          name:
            blank: "Name can't be blank."
```

✅ Also acceptable — inline with I18n lookup:
```ruby
validates :name, presence: { message: -> (obj, data) { I18n.t("decks.errors.name_blank") } }
```

❌ Forbidden:
```ruby
validates :name, presence: { message: "can't be blank" }
```

---

# Phase 3 — Verification Checklist

Run this checklist before marking any feature complete.

## Step 1: Key Existence

For every `t("...")` call introduced by the feature, confirm the key exists in `config/locales/en.yml`.

Run:
```bash
grep -rn 't("' app/views/ app/controllers/ app/mailers/ | grep -v '.swp'
```

Compare each key against `config/locales/en.yml`. Flag any missing key as a **blocker**.

## Step 2: All Locales Covered

For every new key added to `en.yml`, confirm the same key exists in all other locale files:

```
config/locales/es.yml
config/locales/de.yml
config/locales/fr.yml
config/locales/pt.yml
config/locales/ar.yml
config/locales/fa.yml
config/locales/ckb.yml
config/locales/tr.yml
config/locales/ru.yml
```

Missing keys in any locale file = **blocker**. Add the key with the English value as a placeholder if the translation is not yet available (the app will fall back to `en` but the key must exist to prevent silent gaps).

## Step 3: Interpolation Variables

For every key whose value contains `%{variable}`, confirm the `t()` call passes that variable:

```ruby
t("accounts.username_hint_html", email: current_user.email)  # ✅
t("accounts.username_hint_html")  # ❌ — missing interpolation
```

## Step 4: Pluralization

Any string that depends on a count MUST use Rails pluralization format:

```yaml
# ✅ Correct
deck_card:
  count:
    one: "%{count} card"
    other: "%{count} cards"
```

```yaml
# ❌ Wrong
deck_card:
  count: "%{count} card(s)"
```

Call site must use `count:` key:
```erb
<%= t("decks.deck_card.count", count: @deck.flashcards.count) %>
```

## Step 5: Namespace Consistency

New keys must follow the existing hierarchy. Check `config/locales/en.yml` to find the correct parent namespace before adding a key.

Rules:
- Page-level keys go under the controller name: `decks.index.*`, `explore.index.*`
- Shared UI actions go under `shared.*`
- Study modes go under `study_modes.<mode>.*`
- Do not create a new top-level namespace unless absolutely no existing parent fits

## Step 6: RTL Compatibility

If the feature introduces layout or positioning:
- Do not use `margin-left` / `margin-right` where `margin-inline-start` / `margin-inline-end` would work
- Do not use `text-align: left` where `start` would work
- Do not use `float: left` — use flexbox with `flex-direction` or logical properties
- Icons adjacent to text must use inline-flex so they flip with RTL direction

Affected locales for RTL: `ar`, `fa`, `ckb`

## Step 7: No New Hardcoded Strings

Run a final grep to confirm no new bare strings were introduced:

```bash
# Check ERB views for text nodes that are not wrapped in t()
grep -rn --include="*.erb" '>[A-Z][a-zA-Z ]' app/views/

# Check for hardcoded placeholder attributes
grep -rn --include="*.erb" 'placeholder="[^<]' app/views/

# Check for hardcoded aria-label
grep -rn --include="*.erb" 'aria-label="[^<]' app/views/

# Check controllers for hardcoded flash strings
grep -rn --include="*.rb" 'flash\[.*\] = "' app/controllers/

# Check JS for hardcoded user-facing strings
grep -rn --include="*.js" 'textContent\s*=' app/javascript/
grep -rn --include="*.js" 'innerHTML\s*=' app/javascript/
```

Any match that is not already wrapped in `t()` or passed via a data attribute = **violation that must be fixed before merge**.

---

# Phase 4 — Report

Output the following after completing all phases:

---

## I18n Guard — Feature: `<feature name>`

### New Keys Added
| `en.yml` key | English value | All 10 locales? |
|--------------|--------------|----------------|
| `...` | `...` | ✅ / ❌ |

### Hardcoded String Violations
| File | Line | String | Fix |
|------|------|--------|-----|
| (none) | — | — | — |

### JS Translation Approach
| Stimulus controller | Data attribute | Source key |
|---------------------|---------------|------------|
| `...` | `data-...-value` | `t("...")` |

### Verification Checklist
- [ ] All keys exist in `en.yml`
- [ ] All 10 locale files contain the key
- [ ] Interpolation variables match at every call site
- [ ] Count-based strings use `one:` / `other:` pluralization
- [ ] New keys follow existing namespace hierarchy
- [ ] No `margin-left` / `text-align: left` in RTL-affected layouts
- [ ] Grep clean — no new hardcoded strings in views, controllers, mailers, or JS

### Verdict
✅ Feature is localization-ready  /  ❌ Violations must be fixed before merge

---

## Rules (Non-Negotiable)

- No hardcoded user-facing string anywhere in the codebase — ever
- JavaScript controllers must receive all text via data attributes from Rails views
- Every new `en.yml` key must exist in all 10 locale files
- Count-dependent strings must use Rails pluralization (`one:` / `other:`)
- RTL layouts must use logical CSS properties, not physical directional values
- `en.yml` is the source of truth — all other locale files mirror its structure
- A feature is NOT complete until the full verification checklist passes
