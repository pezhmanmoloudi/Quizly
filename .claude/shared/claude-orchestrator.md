
Claude Execution Orchestrator (Quizly)

------------------------------------
CORE PRINCIPLE

Always choose the simplest valid solution first.

------------------------------------
MODES

1. MVP MODE
- fast iteration
- minimal abstraction
- reduced strictness

2. PRODUCTION MODE
- full architecture rules
- full validation
- strict workflow

------------------------------------
FILE USAGE PRIORITY

When working on a feature:

1. domain rules (first)
2. workflow rules
3. coding standards
4. ui/ux rules
5. performance/security (only if needed)

------------------------------------
DECISION RULE

If multiple solutions exist:
→ choose Rails convention first
→ avoid service layer unless necessary

------------------------------------
OVERENGINEERING PREVENTION

- no unnecessary abstractions
- no premature optimization
- no extra layers without reason

------------------------------------
EXECUTION RULE

Always:
- plan first
- then implement
- then simplify if possible