# Feature Report: [Feature Name]

**Date:** YYYY-MM-DD
**Branch:** feature/[branch-name]
**PR:** #[number]

---

## Feature Summary

**What was built:**
[Describe what was implemented]

**Why it was built:**
[Describe the motivation or business reason]

**User problem solved:**
[Describe the user-facing problem this resolves]

---

## User Story

As a [role], I want to [action] so that [benefit].

[Describe the end-to-end user-facing behavior: what the user sees, what they can do, what happens as a result]

---

## Routes

| Method | Path | Purpose |
|--------|------|---------|
| GET | /example | Description |
| POST | /example | Description |

---

## Controllers

### [ControllerName]

**Actions added/modified:**
- `action_name` — [what it does, params it accepts, response it returns]

**Authorization:** [Who can access, any before_action filters]

---

## Models

### [ModelName]

**Associations:**
- `belongs_to :x`
- `has_many :y`

**Validations:**
- `validates :field, presence: true`

**Scopes:**
- `scope :name, -> { ... }`

**Callbacks:**
- `before_save :method`

**Methods:**
- `method_name` — [what it does]

---

## Database

### Migrations

| Migration | Table | Change |
|-----------|-------|--------|
| YYYYMMDDHHMMSS_migration_name | table_name | add column / add index / etc. |

**New columns:**
- `table.column_name` (type) — purpose

**Indexes:**
- `index_table_on_column` — reason

**Constraints:**
- [Any NOT NULL, UNIQUE, or FK constraints added]

---

## Views

**Pages added/modified:**
- `app/views/[resource]/[action].html.erb` — [purpose]

**Partials:**
- `app/views/[resource]/_partial.html.erb` — [purpose]

**Forms:**
- [Describe forms, fields, submission behavior]

**Empty states:**
- [What the user sees when there is no data]

**Error states:**
- [What the user sees on validation failure or error]

---

## UI / UX

**Layout:**
- [Describe page layout, grid, columns]

**Cards / Containers:**
- [Describe any card or container components used]

**Buttons:**
- [Primary, secondary, destructive buttons and their actions]

**Navigation:**
- [Nav items added, breadcrumbs, back links]

**Responsive behavior:**
- [How layout adapts on mobile vs desktop]

**Design decisions:**
- [Any notable UX choices and their rationale]

---

## CSS

**New classes:**
- `.class-name` — [purpose]

**Modified classes:**
- `.class-name` — [what changed and why]

**Removed classes:**
- `.class-name` — [reason for removal]

---

## Hotwire / Stimulus

**Stimulus Controllers:**

### `[controller-name]_controller.js`
- **Targets:** `[list targets]`
- **Actions:** `[list actions and triggers]`
- **Behavior:** [describe what it does]

**Turbo Frames:**
- `[frame-id]` — [what it wraps, when it updates]

**Turbo Streams:**
- [Any broadcast or inline stream responses]

---

## Authorization

**Ownership rules:**
- [Who owns the resource, e.g. user owns deck]

**Access rules:**
- [Who can read, create, update, destroy]

**Restrictions:**
- [What is blocked and for whom]

---

## Validation Rules

- `Model#field`: [rule] — [reason]
- `Model#field`: [rule] — [reason]

---

## Business Rules

- [Rule 1: describe the invariant or constraint enforced]
- [Rule 2: describe another business rule]

---

## Tests

### Request Specs

- `spec/requests/[resource]_spec.rb`
  - [test name] — [what it verifies]

### Model Specs

- `spec/models/[model]_spec.rb`
  - [test name] — [what it verifies]

### System Specs

- `spec/system/[feature]_spec.rb`
  - [test name] — [what it verifies]

---

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

## Files Created

| File | Purpose |
|------|---------|
| `path/to/file.rb` | [purpose] |

---

## Files Modified

| File | Change |
|------|--------|
| `path/to/file.rb` | [what changed] |

---

## Breaking Changes

None

<!-- If breaking changes exist, list them here:
- [Change and migration path]
-->

---

## Future Improvements

- [Enhancement intentionally left out of this implementation]
- [Another potential future improvement]
