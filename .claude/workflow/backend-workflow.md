Backend Development Workflow (Quizly)

IMPORTANT:
Workflow is iterative, not strictly linear.

------------------------------------

STEPS:

1. Read architecture + relevant rule files
2. Design data model + flow
3. Create models + migrations
4. Implement business logic (services only if needed)
5. Create controllers / endpoints
6. Add tests (request + model + job)
7. Refactor if needed
8. Optimize only when necessary

------------------------------------

CHECKLIST:

- proper database indexes
- authorization checks
- input validation
- request specs coverage
- service objects only for complex logic
- no business logic in controllers

------------------------------------

MVP MODE:
- minimal abstractions
- avoid unnecessary services
- keep implementation simple

PRODUCTION MODE:
- full layering (services, jobs, caching)
- performance optimization
- strict separation of concerns

------------------------------------

IMPORTANT:
Backend architecture must remain maintainable, simple, and scalable.
Avoid over-engineering.