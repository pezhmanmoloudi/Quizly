
API Contract Rules (Quizly)

------------------------------------
RESPONSE FORMAT

All API responses must follow:

{
  data: {},
  error: null,
  meta: {}
}

------------------------------------
ERROR FORMAT

{
  data: null,
  error: {
    message: "human readable",
    code: "ERROR_CODE"
  }
}

------------------------------------
PAGINATION

{
  data: [],
  meta: {
    page: 1,
    total_pages: 10,
    total_count: 100
  }
}

------------------------------------
RULES

- consistent response structure
- never expose internal errors
- always use HTTP status codes correctly

------------------------------------
IMPORTANT

Frontend must never guess API structure.