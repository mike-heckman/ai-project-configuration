# Skills Breakdown Proposal

## Overview
Currently, all developer commands and specialized persona actions were abstracted into a single `gemini/global-workflows` directory.

We migrated specialized workflows into a modular "Skills" pattern. By grouping workflows under their respective specialist roles, we enabled an autonomous SDLC pipeline. 

To take this encapsulation to its logical conclusion, the persona definitions (`role_*.md`) governing each skill group have been moved directly into the skill packages as `SKILL.md`. This establishes true Feature Modules—a skill folder now contains both the actionable workflows and the governing rules constraints.

### The Autonomous Pipeline
This structure supports a sequential, autonomous pipeline bridging the roles:
1. **Architect** creates a design and breaks it into discrete "Units of Work".
2. **Coder** pulls the next pending unit and implements it.
3. Upon completion, the Coder automatically triggers a hand-off to the **Reviewer**.
4. The **Reviewer** runs the checks (`lint`, `test`, `run`). 
    - **Active Development Loop**: If a test fails, the Reviewer pushes the Unit of Work **back to the Coder** to apply the fix, establishing a `Coder <-> Reviewer` loop until standards are met.
5. Pending complexity, it may pass through **Librarian** (for doc updates), **Security**, or **Product**.
6. The process only returns to the User when the unit is fully verified.

### The Diagnostic Pipeline (Debugger)
The Debugger is reserved strictly for post-production or complex live-environment anomalies.
1. When a post-production issue is identified, the **Debugger** takes over to actively reproduce and track down the root cause.
2. It loops through its application and testing until the anomaly is resolved.
3. Once solved, it hands off to the **Reviewer** for formal QA gating.

## Modular Skill Mapping

Each of the following folders contains a core `SKILL.md` defining the persona, alongside its operational workflows:

**1. Architect Skills (`gemini/skills/architect/`)**
* `SKILL.md` (Design governance rules)
* `design.md`, `interact.md`, `record-adr.md`

**2. Coder Skills (`gemini/skills/coder/`)**
* `SKILL.md` (Implementation constraints)
* `start-mission.md`

**3. Reviewer Skills (`gemini/skills/reviewer/`)**
* `SKILL.md` (QA gating rules)
* `lint.md`, `test.md`, `run.md`, `ready.md`, `checklist.md`

**4. Debugger Skills (`gemini/skills/debugger/`)**
* `SKILL.md` (Diagnostic looping rules)
* `bugfix.md`, `bug-iteration.md`

**5. Librarian Skills (`gemini/skills/librarian/`)**
* `SKILL.md` (Knowledge constraints)
* `docs-audit.md`, `update-docs.md`

**6. Performance Skills (`gemini/skills/performance/`)**
* `SKILL.md`
* `scale.md`

**7. Product Skills (`gemini/skills/product/`)**
* `SKILL.md`
* `ux.md`

**8. Security Skills (`gemini/skills/security/`)**
* `SKILL.md`
* `audit.md`

---

## Retained Global Workflows
These represent universal administrative hooks:
* `clean.md`
* `git-diff-summary.md`
* `help.md`
* `exit.md`

## Centralized Rules
Only global condition rules remain in `gemini/conditional-rules/`:
* `lang_python.md`
* `lang_typescript.md`
