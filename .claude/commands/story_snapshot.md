# Project Skill: Story Snapshot (Read-Only CLI Inspector)

This skill generates a **read-only architectural + UI snapshot** of a feature (story).

It MUST NOT:

* create or modify files
* suggest refactors as actions
* write to disk
* generate implementation code
* change repository state

It ONLY analyzes existing code and prints a structured terminal summary.

---

# Core Purpose

Convert a feature (story) into a **clear, human-readable architecture overview** including:

* Routes
* Controllers
* Models
* Services (if exist)
* Policies (if exist)
* Request flow
* UI structure

---

# Step 1 — Identify Story

### Case A: Argument provided

Example:

```
/story_snapshot deck creation
```

→ Use it as the story name.

---

### Case B: No argument provided

→ Infer ONLY from the most recent feature discussed in conversation.

If no clear story is found:

```
ERROR: STORY_NOT_FOUND
```

---

# Step 2 — Read-Only Code Inspection Rules

You MAY ONLY inspect:

* config/routes.rb
* app/controllers/** related to story
* app/models/** related to story
* app/services/** related to story (if exists)
* app/policies/** related to story (if exists)

DO NOT scan entire repository.

DO NOT modify anything.

---

# Step 3 — Output Format (STRICT CLI FORMAT)

Output must be printed directly to terminal.

No extra commentary before or after.

---

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STORY SNAPSHOT: {Story Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WHAT IT DOES
- {2 short sentences explaining the feature}

USER STORY
As a {user role}, I can {action} so that {benefit}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ROUTES
METHOD   PATH                  PURPOSE
───────  ────────────────────  ─────────────────────────
GET      /example              {purpose}
POST     /example              {purpose}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONTROLLERS
{ControllerName}
- {action} → {what it does in 1 line}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MODELS
{ModelName}
- Fields: {list}
- Validations: {list}
- Associations: {list}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SERVICES (if any)
{ServiceName}
- responsibility → {what it does}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POLICIES (if any)
{PolicyName}
- rule → {allowed / denied behavior}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REQUEST FLOW (HIGH LEVEL)
Client → Controller → Service → Model → DB

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

UI SNAPSHOT

LAYOUT
- Page structure: grid / list / dashboard / centered layout
- Navigation: top / sidebar / minimal

COMPONENTS
- Cards: {what cards exist}
- Buttons: {primary actions}
- Forms: {inputs if any}
- Sections: {main page blocks}

DESIGN STYLE
- Color: {primary / accent colors if visible}
- Style: clean / modern / minimal / dense
- Spacing: compact / medium / spacious
- Visual tone: friendly / professional / playful

MOBILE BEHAVIOR
- Layout changes on small screens
- Stack behavior
- Navigation adaptation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXPECTED BEHAVIOR
Success → {what user sees}
Failure → {error / unauthorized behavior}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

# Output Rules

* MUST be terminal-friendly
* MUST NOT include implementation suggestions
* MUST NOT modify code
* MUST NOT generate new files
* MUST only describe existing system
* Omit sections that do not exist in the codebase

---

# Non-Negotiable Rules

* Read-only mode only
* No refactoring suggestions
* No code generation
* No architectural changes
* Pure inspection + visualization only
