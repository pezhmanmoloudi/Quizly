## Core Rules (Always Follow)

You must follow rules defined in:
- shared/git-workflow.md
- shared/workflow.md
- shared/ROADMAP.md
- THIS FILE (highest priority if conflict exists)

------------------------------------

## Development Philosophy

- Break work into small, isolated tasks
- One responsibility per branch
- One logical change per commit
- Prefer small iterative changes

------------------------------------

## Git Workflow Rules

- Always propose branch name before creation
- Always propose commit message before committing
- Wait for explicit approval before:
  - branch creation
  - commit
  - push

IMPORTANT:
You may suggest actions freely, but must not execute without approval.

------------------------------------

## Working Process

### Before Implementation

1. Analyze task
2. Generate a detailed plan covering: objectives, scope, routes, models, controllers, views, UI/UX, database changes, testing strategy, acceptance criteria, implementation order, risks
3. Save plan to `docs/plans/YYYY-MM-DD-{plan-name}.md`
4. Propose branch name
5. If user requested approval: present plan and wait — do not proceed until approved

### Implementation

6. Implement in the order defined in the plan
7. Run tests; fix all failures before continuing

### After Implementation

8. Summarize changes
9. Generate documentation — run /project:feature_documentation_system
   - `docs/features/YYYY-MM-DD-{name}.md` — feature report (routes, models, controllers, views, UI/UX, CSS, tests, files created/modified, breaking changes, future improvements)
   - `docs/architecture/YYYY-MM-DD-{name}-impact.md` — architecture impact report
   - Prepend entry to `docs/changelog/CHANGELOG.md`
   - `docs/plans/YYYY-MM-DD-{name}.md` — already created in step 3; update status to "Executed"
   - NEVER skip this step
10. Suggest commit message
11. Wait for approval

A task is NOT complete until steps 9 and 10 are done. Documentation is a first-class deliverable.

------------------------------------

## Project Phases

- Phase 1 completed
- Currently working from Phase 2 onwards
- Maintain consistency with existing architecture

------------------------------------

## Important Constraints

- Production-quality code required
- Maintain consistent architecture
- Avoid unnecessary complexity
- Prefer Rails conventions

------------------------------------

## Documentation Rules

Documentation is a first-class deliverable, not an optional step.

### Before every task
- Generate a detailed plan and save it to `docs/plans/YYYY-MM-DD-{name}.md`

### After every completed task (feature, bugfix, refactor, UI update, migration, architecture change)
- `docs/features/YYYY-MM-DD-{name}.md` — feature report including: routes, models, controllers, views, UI/UX, CSS, Hotwire/Stimulus, authorization, validations, business rules, tests, acceptance criteria, files created, files modified, breaking changes, future improvements
- `docs/architecture/YYYY-MM-DD-{name}-impact.md` — architecture impact report
- Prepend entry to `docs/changelog/CHANGELOG.md`
- Update the plan doc status to "Executed"

Templates: `docs/templates/`
Full instructions: `.claude/commands/feature_documentation_system.md`

A task is NOT considered complete until all documentation files are created and the changelog is updated.

------------------------------------

## Execution Philosophy

- Optimize for clarity over speed
- Prefer correctness over shortcuts
- Keep changes small and reversible

------------------------------------

## Reminder

Human approval is required for:
- branch creation
- commits
- merges