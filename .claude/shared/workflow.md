
Development Workflow (Quizly)

------------------------------------
BEFORE STARTING
------------------------------------

1. Read architecture rules
2. Read relevant domain files
3. Understand feature scope
4. Generate a detailed plan covering:
   - Objectives and scope
   - Out of scope items
   - Routes (table: Method | Path | Purpose)
   - Model changes (associations, validations, scopes, callbacks, methods)
   - Controller changes (actions, authorization)
   - View changes (pages, partials, forms, empty states, error states)
   - UI/UX decisions
   - Database changes (migrations, columns, indexes, constraints)
   - Testing strategy (request, model, system specs)
   - Acceptance criteria checklist
   - Implementation order
   - Risks and future phases
5. Save plan to docs/plans/YYYY-MM-DD-{plan-name}.md
6. If approval was requested: present plan and wait before proceeding

------------------------------------
FEATURE DEVELOPMENT FLOW
------------------------------------

IMPORTANT:
Flow is iterative, not strictly linear.
Follow the implementation order defined in the plan.

1. Analyze feature
2. Create and save implementation plan (see above)
3. Break into small tasks
4. Create backend structure
5. Implement core logic
6. Add UI integration (Hotwire)
7. Write tests
8. Refactor if needed
9. Optimize if required

------------------------------------
TESTING FLOW
------------------------------------

- run backend tests
- run system tests
- fix errors before completion

------------------------------------
CODE QUALITY CHECK

- readable code
- reusable logic
- no duplication
- proper naming
- proper structure

------------------------------------
DOCUMENTATION (MANDATORY)
------------------------------------

A task is NOT complete until all documentation is written.
Documentation is a first-class deliverable.

After every completed task, generate all of the following:

1. docs/features/YYYY-MM-DD-{name}.md
   Include: routes, models, controllers, views, UI/UX, CSS,
   Hotwire/Stimulus, authorization, validations, business rules,
   tests, acceptance criteria, files created, files modified,
   breaking changes, future improvements

2. docs/architecture/YYYY-MM-DD-{name}-impact.md
   Include: affected areas, dependencies, new couplings,
   future features impacted, technical debt, refactoring
   opportunities, risks, scalability notes

3. docs/changelog/CHANGELOG.md
   Prepend entry: date, feature name, type, summary, files changed

4. docs/plans/YYYY-MM-DD-{name}.md
   Already created before implementation — update status to "Executed"

Run: /project:feature_documentation_system
Templates: docs/templates/

------------------------------------
IMPORTANT RULE

Keep changes small, focused, and reversible.
Avoid mixing unrelated changes.
