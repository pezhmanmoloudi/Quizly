# Quizly — Project Rules

## Stack

Rails 8 · Hotwire (Turbo + Stimulus) · Importmap · Solid Queue · Propshaft
Database: SQLite (dev/test) · configurable via environment for production

## Philosophy

Rails conventions first. Thin controllers, domain logic in models, services only for complex multi-step workflows. Hotwire is the primary UI layer — no SPA frameworks. Optimize for clarity and maintainability over abstraction.

## Architecture Principles

- One model per file, one responsibility — associations, validations, scopes, simple methods only
- Complex logic → `app/services/`, authorization → `app/policies/`, complex queries → `app/queries/`
- One class per file — never bundle unrelated classes in a single file

## Definition of Done

A feature is only complete when all of the following are true:

- Implementation is complete and all tests pass
- All user-facing text goes through `t()` — zero hardcoded strings
- Every new `en.yml` key exists in all 10 locale files
- RTL locales are unaffected — no physical directional CSS introduced
- RuboCop passes with no offenses
- Tests are fully synchronized with the implementation (no orphan tests, no outdated logic)

---
Detailed rules: `.claude/shared/i18n.md` · `.claude/architecture/*` · `.claude/testing/*`
