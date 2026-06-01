# Project Skill: Strict File Update & Test Sync Rule

This rule defines how ALL changes in the project must be handled.

It applies to:

* Controllers
* Models
* Services
* Queries
* Policies
* Views (if applicable)
* Tests

---

# Core Principle

Every change MUST result in a **fully updated and consistent file state**.

No partial updates are allowed.

---

# 1. File Lifecycle Rule (MANDATORY)

For every feature, change, or refactor:

## Step 1 — Check Existence

Before doing anything:

* Check if the file already exists
* Check if corresponding test file exists

---

## Step 2 — Decision

### If file EXISTS:

👉 You MUST update the existing file
👉 You MUST update ALL related test files

### If file DOES NOT exist:

👉 You MUST create the file
👉 You MUST create full test coverage for it

---

# 2. No Partial Update Rule (VERY IMPORTANT)

If a file is modified:

You MUST NOT:

* leave tests outdated
* leave partial implementation
* leave mismatched behavior between code and tests

Everything must stay synchronized.

---

# 3. Test Sync Rule (STRICT)

After ANY change:

You MUST:

* update existing tests if behavior changed
* add missing tests if new logic was introduced
* remove outdated tests if logic was removed
* ensure full coverage is still valid

---

# 4. Required Output Format After Each Change

After finishing ANY implementation, you MUST output:

---

## Affected Files

* Created files:
* Updated files:

---

## Test Changes

* Created tests:
* Updated tests:
* Removed tests:

---

## Final State Guarantee

* All tests are aligned with implementation: YES / NO
* Any mismatch fixed: YES / NO

---

# 5. File Consistency Rule (CRITICAL)

A file is ONLY valid if:

* implementation matches tests
* tests fully cover behavior
* no outdated logic remains
* no orphan files exist

---

# 6. Hard Rule: "No Silent Changes"

You MUST NOT:

* change behavior without updating tests
* modify logic without updating documentation/tests
* add features without test update
* delete logic without cleaning tests

---

# 7. Final Golden Rule

> Every code change must leave the project in a fully consistent state.

If consistency is broken:

👉 the change is considered incomplete
👉 must be fixed before finishing

---

# 8. Definition of Done

A feature is ONLY done when:

* implementation is complete
* tests are fully updated
* no orphan tests exist
* no outdated logic remains
* all related files are synchronized

---

# End of Rule
