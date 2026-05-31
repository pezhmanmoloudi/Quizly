Backend Security Rules (Quizly)

VALIDATION:
- validate all inputs
- whitelist permitted parameters
- sanitize uploaded files

API SECURITY:
- rate limit sensitive endpoints (login, API)
- enforce authorization checks
- validate all requests

UPLOADS:
- validate file size
- validate file type
- store files securely (not in public execution paths)
- never execute uploaded content

DATABASE:
- use ActiveRecord queries
- avoid SQL injection risks
- never interpolate user input in raw SQL

ERROR HANDLING:
- never expose stack traces
- return safe error messages to client
- log internal errors separately

IMPORTANT:
Backend security is mandatory for production safety.