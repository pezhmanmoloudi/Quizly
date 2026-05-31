
Language System (Quizly)

------------------------------------
CORE PRINCIPLE
------------------------------------

Languages are DATA-driven, not hardcoded.

------------------------------------
RULES

- System supports unlimited languages
- Languages are identified by ISO codes
- New languages can be added without code changes

------------------------------------
SUPPORTED LANGUAGE MODEL

Each language has:
- code (ISO 639-1)
- direction (ltr / rtl)
- display_name

------------------------------------
LANGUAGE PAIRS

- stored dynamically in database
- not hardcoded in domain layer
- can be created by users/admin system

------------------------------------
UI RULE

- RTL/LTR must be derived from language metadata
- UI must adapt automatically per language