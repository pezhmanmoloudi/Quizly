Authentication Rules (Quizly)

SYSTEM:
- Session-based authentication (preferred)
- Optional JWT for API clients

RULES:
- validate tokens/sessions securely
- expire sessions properly
- never trust frontend user IDs
- protect authenticated endpoints

AUTHORIZATION:
- verify ownership
- validate permissions
- enforce access control strictly

PASSWORDS:
- secure password hashing
- never log passwords

IMPORTANT:
Authentication is a critical security boundary.