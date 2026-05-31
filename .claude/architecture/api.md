API Design Rules

ARCHITECTURE:
- Rails Monolith (NOT API-only)
- Hotwire is primary UI
- API only when necessary

ROUTES:
- /api/v1/ only for external/internal API usage

RESPONSE FORMAT:

Success:
{
  data: {},
  meta: {}
}

Error:
{
  error: {
    type: string,
    message: string,
    details: object
  }
}

RULES:
- RESTful APIs
- Proper HTTP status codes
- No deeply nested routes
- Stable API contracts

IMPORTANT:
Do NOT force API usage for UI.