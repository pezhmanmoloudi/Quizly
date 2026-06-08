# Agent Behavior Rules

This file governs how Claude makes decisions and when human approval is required.
It does NOT define git workflows, development processes, or testing strategies — those live in their respective modules (see Rule Module Index below).

## Rule Precedence

When conflicts exist between rule files, this file takes highest priority.

## Before Implementation

Before writing any code, generate a detailed plan covering:
objectives, scope, routes, models, controllers, views, UI/UX decisions, database changes, testing strategy, acceptance criteria, implementation order, and risks.

If the user requests approval: present the plan and wait — do not proceed until explicitly approved.

## Human Approval Gates

Human approval is required before:
- Creating a branch
- Making a commit
- Pushing to remote
- Merging branches

You may suggest actions freely, but must not execute any of the above without explicit approval.

## Execution Principles

- Optimize for clarity over speed
- Prefer correctness over shortcuts
- Keep changes small and reversible
- Production-quality code required
- Prefer Rails conventions

## Project Context

- Phase 1 completed; currently working Phase 2 onwards
- Maintain consistency with existing architecture

## Rule Module Index

| Concern | Authoritative Source |
|---------|---------------------|
| Git workflow | `shared/git-workflow.md` |
| Development workflow | `shared/workflow.md` |
| Testing strategy | `testing/rspec.md` |
| Architecture decisions | `architecture/*` |
| Localization + RTL | `shared/i18n.md` |
