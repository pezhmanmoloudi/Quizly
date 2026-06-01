# Project Skill: Strict Model File Isolation

You are auditing and enforcing the project's model isolation rules. Follow every step below without skipping any.

---

## Core Rule

Every ActiveRecord model MUST have:
- Exactly **one class** per file
- Exactly **one responsibility** per model file
- Its own dedicated file at `app/models/<model_name>.rb`

---

## Step 1: Audit File Isolation

Scan every file in `app/models/`:

For each file, count the number of `class` definitions:
- **1 class** → ✅ compliant
- **2+ classes** → ❌ critical violation — must be split immediately

Also check for:
- Module definitions that wrap multiple classes → flag if they bundle unrelated concerns
- `class << self` blocks containing business workflow logic → flag as responsibility violation

---

## Step 2: Audit Model Responsibilities

For each model file, verify it contains ONLY:

✅ Allowed:
- `belongs_to`, `has_many`, `has_one`, `has_and_belongs_to_many`
- `validates`, `validate`
- `scope`
- Simple computed instance methods (e.g. `display_name`, `full_name`)
- Simple class methods that are direct queries on self (e.g. `User.active`)
- `before_validation`, `before_save`, `after_save` callbacks for data normalization only
- `enum`, `store`, `serialize`

❌ Prohibited — must be extracted to a service:
- Methods that create or modify records on *other* models in bulk
- API calls or HTTP requests
- Complex multi-step business workflows
- Authorization logic (use a policy instead)
- Query construction returning results for another model
- `after_create` callbacks that trigger background jobs or emails (use a service/observer)

If a prohibited pattern is found:
1. Note the model and method name
2. Determine the correct destination (`app/services/`, `app/policies/`, `app/queries/`)
3. Extract it — create the new file, move the logic, update callers, update tests

---

## Step 3: Audit Model Specs

For each file in `app/models/` (excluding `application_record.rb` and `current.rb`):
- Does `spec/models/<model_name>_spec.rb` exist?
- If missing → create it
- If present but only has `pending` → replace with real tests

Each model spec MUST cover:
- All `belongs_to` / `has_many` / `has_one` associations and their options
- All `validates` rules — presence, length, uniqueness, format, numericality
- Edge cases — nil inputs, boundary values, duplicate records
- All instance and class methods defined in the model

---

## Step 4: Fix All Violations

### Split multi-class files
If any file contains 2+ classes:
1. Create separate `app/models/<class_name>.rb` for each class
2. Ensure each new file has a corresponding `spec/models/<class_name>_spec.rb`
3. Remove the original multi-class file

### Extract prohibited logic
If any model contains prohibited logic:
1. Create `app/services/<domain>/<action>_service.rb`
2. Move the logic there with the same behavior
3. Replace the original model method with a call to the service (or remove it and update all callers)
4. Create `spec/services/<domain>/<action>_service_spec.rb`
5. Update the model spec to remove tests of the extracted logic

### Create missing model specs
For each missing spec file, create `spec/models/<model_name>_spec.rb` with full coverage.

---

## Step 5: Run Tests

Run:
```
bundle exec rspec spec/models/
bundle exec rspec spec/
```

All examples must pass (0 failures). Fix any failures before proceeding.

---

## Step 6: Report

Output the following:

### Model Isolation Audit
| File | Classes | Responsibility | Spec |
|------|---------|----------------|------|
| `app/models/deck.rb` | ✅ 1 | ✅ clean | ✅ exists |
| ... | | | |

### Violations Found & Fixed
- List each violation, what was wrong, what was done to fix it

### Files Created
| File | Purpose |
|------|---------|
| `path` | reason |

### Files Modified
| File | Change |
|------|--------|
| `path` | what changed |

### Suite Result
`X examples, 0 failures`

---

## Rules (Non-Negotiable)

- One model = one file = one responsibility
- No model file may contain more than one `class` definition
- Models must not contain service/business workflows — extract to `app/services/`
- Every model must have a `spec/models/<model>_spec.rb` with real tests
- `application_record.rb` and `current.rb` are exempt from the spec requirement
