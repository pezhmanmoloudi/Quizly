# Feature Documentation System

You are generating project documentation after a completed task. Follow every step below without skipping any.

---

## Step 1: Determine Context

Identify:
- **Today's date** in YYYY-MM-DD format
- **Feature/task name** in kebab-case (e.g. `deck-management`, `auth-split-layout`, `flashcard-crud`)
- **What was just completed** (feature, bugfix, refactor, migration, UI update, architecture change, plan execution)
- **Whether a plan was written** before implementation (if yes, also create a plan doc)

---

## Step 2: Create Feature Report

Create file: `docs/features/YYYY-MM-DD-{feature-name}.md`

Use this exact structure, filled with real content from the completed work (no placeholders left blank):

```markdown
# Feature Report: {Feature Name}

**Date:** YYYY-MM-DD
**Branch:** {branch name}
**PR:** #{number or N/A}

---

## Feature Summary

**What was built:**
{Concrete description of what was implemented}

**Why it was built:**
{Motivation — user need, product goal, or technical requirement}

**User problem solved:**
{The specific problem a user would recognize as solved}

---

## User Story

As a {role}, I want to {action} so that {benefit}.

{Narrative description of the end-to-end user experience}

---

## Routes

| Method | Path | Purpose |
|--------|------|---------|
| {METHOD} | {/path} | {purpose} |

If no routes were changed: "No routes changed."

---

## Controllers

### {ControllerName}

**Actions added/modified:**
- `{action}` — {what it does, params, response}

**Authorization:** {before_action filters, who can access}

If no controllers changed: "No controller changes."

---

## Models

### {ModelName}

**Associations:** {list}
**Validations:** {list}
**Scopes:** {list}
**Callbacks:** {list}
**Methods:** {list}

If no model changes: "No model changes."

---

## Database

### Migrations

| Migration | Table | Change |
|-----------|-------|--------|
| {filename} | {table} | {change} |

**New columns:** {list with types and purpose}
**Indexes:** {list with reason}
**Constraints:** {list}

If no database changes: "No database changes."

---

## Views

**Pages added/modified:** {list with purpose}
**Partials:** {list with purpose}
**Forms:** {describe fields and submission behavior}
**Empty states:** {what user sees with no data}
**Error states:** {what user sees on failure}

If no view changes: "No view changes."

---

## UI / UX

**Layout:** {describe structure}
**Cards / Containers:** {describe}
**Buttons:** {list with actions}
**Navigation:** {changes to nav}
**Responsive behavior:** {mobile vs desktop}
**Design decisions:** {notable choices and rationale}

If no UI changes: "No UI changes."

---

## CSS

**New classes:** {list with purpose}
**Modified classes:** {list with what changed}
**Removed classes:** {list with reason}

If no CSS changes: "No CSS changes."

---

## Hotwire / Stimulus

### {controller-name}_controller.js

**Targets:** {list}
**Actions:** {list with triggers}
**Behavior:** {description}

**Turbo Frames:** {frame-id — what it wraps, when it updates}
**Turbo Streams:** {any broadcast or inline stream responses}

If no Hotwire changes: "No Hotwire / Stimulus changes."

---

## Authorization

**Ownership rules:** {who owns the resource}
**Access rules:** {who can read, create, update, destroy}
**Restrictions:** {what is blocked and for whom}

---

## Validation Rules

- `{Model}#{field}`: {rule} — {reason}

---

## Business Rules

- {Rule: describe the invariant or constraint enforced}

---

## Tests

### Request Specs
- `{spec file}`: {test name} — {what it verifies}

### Model Specs
- `{spec file}`: {test name} — {what it verifies}

### System Specs
- `{spec file}`: {test name} — {what it verifies}

If no tests: "No tests written in this task."

---

## Acceptance Criteria

- [x] {Completed criterion}
- [x] {Completed criterion}

---

## Files Created

| File | Purpose |
|------|---------|
| `{path}` | {purpose} |

---

## Files Modified

| File | Change |
|------|--------|
| `{path}` | {what changed} |

---

## Breaking Changes

{None — or list each breaking change and migration path}

---

## Future Improvements

- {Enhancement intentionally left out}
```

---

## Step 3: Create Architecture Impact Report

Create file: `docs/architecture/YYYY-MM-DD-{feature-name}-impact.md`

```markdown
# Architecture Impact Report

**Feature:** {Feature Name}
**Date:** YYYY-MM-DD
**Related Feature Report:** docs/features/YYYY-MM-DD-{feature-name}.md

---

## Affected Areas

{List each impacted domain: Authentication, Dashboard, Decks, Flashcards, Study, Review, API, Jobs, etc.}

---

## Dependencies

**Models:** {list with how each is used}
**Services:** {list with what each does here}
**Queries / Scopes:** {list}
**Policies / Authorization:** {list}
**Components / Partials:** {list}

---

## New Couplings Introduced

{Describe any new relationships between previously independent parts. If none: "None."}

---

## Future Features Impacted

| Future Feature | Impact |
|----------------|--------|
| {feature} | {how this change affects it} |

---

## Technical Debt

{List shortcuts or imperfections with reason accepted. If none: "None."}

---

## Refactoring Opportunities

{Improvements identified but not acted on. If none: "None."}

---

## Risks

{Potential future issues with likelihood, impact, mitigation. If none: "None identified."}

---

## Scalability Notes

**Data volume:** {performance at 10x/100x records}
**Concurrency:** {race conditions, locking concerns}
**Query efficiency:** {N+1 risks, indexes, eager loading}
**Caching:** {what could be cached in the future}
```

---

## Step 4: Update Changelog

Open `docs/changelog/CHANGELOG.md` and **prepend** (add after the `---` divider, before any existing entries) a new entry:

```markdown
## YYYY-MM-DD — {Feature Name}

**Type:** {Feature | Bug Fix | Refactor | UI Update | Migration | Architecture | Plan Execution}

**Summary:** {One paragraph describing what changed and why}

**Files Changed:**
- `{path}` — {created | modified | deleted}
- `{path}` — {created | modified | deleted}

---
```

---

## Step 5: Create Plan Document (if a plan was written)

If a plan was created before this implementation, create: `docs/plans/YYYY-MM-DD-{plan-name}.md`

```markdown
# Plan: {Plan Name}

**Date:** YYYY-MM-DD
**Status:** Executed

---

## Objectives

{What this plan aimed to accomplish}

---

## Scope

{What was in scope}

## Out of Scope

{What was explicitly excluded}

---

## User Story

{The user-facing goal}

---

## Routes

{Planned routes}

---

## Models

{Planned model changes}

---

## Controllers

{Planned controller changes}

---

## Views

{Planned view changes}

---

## UI / UX

{Planned UI decisions}

---

## Database Changes

{Planned migrations}

---

## Testing Strategy

{How the feature was to be tested}

---

## Acceptance Criteria

{The checklist used to verify completion}

---

## Implementation Order

{The order in which changes were to be made}

---

## Risks

{Risks identified before implementation}

---

## Future Phases

{What was left for later}
```

---

## Rules

- Never skip any step.
- Never leave placeholder text unfilled.
- If a section genuinely has no content (e.g. no CSS changes), write "No CSS changes." — do not omit the section.
- Documentation must be detailed enough that a new developer can understand the entire feature without reading source code.
- All file paths must be relative to the project root.
