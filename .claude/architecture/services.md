Service Object Rules

PURPOSE:
Use only for complex workflows.

WHEN TO USE:
- multi-step processes
- transactions
- external integrations

WHEN NOT TO USE:
- simple CRUD
- single model updates

RULES:
- keep services small
- one responsibility
- no view logic
- no controller logic

FLOW:
Controller → Service → Model (complex cases)
Controller → Model (simple cases)