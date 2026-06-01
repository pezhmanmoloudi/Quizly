
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
5. If approval was requested: present plan and wait before proceeding

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
IMPORTANT RULE

Keep changes small, focused, and reversible.
Avoid mixing unrelated changes.
