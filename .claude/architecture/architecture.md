Quizly Architecture Overview

SYSTEM:
Rails Monolith + Hotwire-first UI

CORE PRINCIPLE:
- Simplicity first
- Rails conventions first
- Avoid over-engineering
- Optimize only when needed

------------------------------------

ARCHITECTURE LAYERS:

- Controllers → orchestration only
- Models → domain logic + validations
- Services → complex workflows only
- Jobs → async processing
- Views → Hotwire UI

------------------------------------

MODES:

MVP MODE:
- minimal abstractions
- avoid service objects unless needed

PRODUCTION MODE:
- services for workflows
- background jobs
- caching + optimization

------------------------------------

IMPORTANT:
Keep system easy to understand and easy to modify.