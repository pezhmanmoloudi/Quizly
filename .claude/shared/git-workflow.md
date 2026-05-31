
Git Workflow Rules (Quizly)

------------------------------------
CORE PRINCIPLE
------------------------------------

All changes must be small, traceable, and human-approved.

------------------------------------
BRANCH RULES
------------------------------------

- one branch per feature or fix
- descriptive branch names required
- never work directly on main

Examples:
- feature/auth-system
- feature/deck-management
- fix/login-bug

------------------------------------
COMMIT RULES
------------------------------------

- one logical, coherent change per commit
- never mix unrelated changes in a single commit
- descriptive commit messages required
- NEVER auto-commit without approval

Message style:
- action-based: Add / Update / Implement / Refactor / Improve / Fix
- short and clear — describe what changed and why if non-obvious

Examples:
- Add authentication system
- Implement core feature
- Improve user flow
- Refactor application logic
- Fix validation error on form submission

------------------------------------
REVIEW FLOW
------------------------------------

After implementation:
1. summarize changes
2. explain decisions
3. suggest commit message
4. wait for approval

------------------------------------
MERGE RULES
------------------------------------

- never auto-merge
- all merges require human review

------------------------------------
IMPORTANT
------------------------------------

Human approval is required for:
- commits
- merges
- destructive actions