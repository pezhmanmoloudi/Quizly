# Contributing

---

## Workflow

1. Branch off `main`: `git checkout -b feature/your-description`
2. Make your changes
3. Run the checklist below before pushing
4. Open a pull request against `main`

---

## Before Opening a PR

```bash
# Tests must pass
bundle exec rspec

# Style must be clean
bin/rubocop

# No new security warnings
bin/brakeman --no-pager
```

CI runs Brakeman, importmap audit, and Rubocop automatically on every PR. RSpec is not in CI — run it locally.

---

## Code Conventions

### Models

- One model per file, one responsibility
- No multi-class model files
- Models hold associations, validations, scopes, and simple query methods only
- Business logic belongs in `app/services/`

### Controllers

- Keep actions thin — delegate to services or model scopes
- Per-action request specs live at `spec/requests/controllers/<controller>/<action>_spec.rb`

### Delete Confirmations

All destructive actions use an inline two-step confirmation pattern driven by `inline_confirm_controller.js`:

- First click reveals a confirmation message: "Are you sure you want to remove [item]?"
- Second click submits the DELETE request

Do not use `turbo_confirm`, browser `confirm()` dialogs, or modal overlays for delete confirmations.

### Views and Turbo

- Use Turbo Frames and Turbo Streams for partial page updates
- Keep Stimulus controllers focused on a single UI behaviour
- New Stimulus controllers go in `app/javascript/controllers/`

---

## Adding Tests

### Models
`spec/models/<model>_spec.rb` — validations, associations, scopes, instance methods

### Controllers / Request specs
`spec/requests/controllers/<controller>/<action>_spec.rb` — one file per action

### Services
`spec/services/<service>_spec.rb`

### Factories
Add FactoryBot factories in `spec/factories/<model>.rb` for any new model.

---

## Adding a New Study Mode

Existing modes follow a consistent pattern:

1. **Model** — a session table (`*_sessions`) and optionally an items table (`*_session_items`)
2. **Route** — a member action on `decks` (e.g. `get :my_mode`) and answer submission routes
3. **Controller** — session creation, answer handling, redirect on completion
4. **Service** (if needed) — question generation or scoring logic in `app/services/`
5. **View** — Turbo-enabled view with a dedicated Stimulus controller for interactivity
6. **Specs** — model spec + per-action request specs

Look at `LearnSession` / `LearnAnswersController` or `TestSession` / `TestAnswersController` as reference implementations.
