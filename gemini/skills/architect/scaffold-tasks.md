---
description: "Initializes a mission from the backlog once a plan is approved."
---

# /scaffold-tasks
*Goal: Transform a design or ADR into a set of discrete, actionable tasks.*

1. **Analysis:** Read the approved `docs/software-design-document.md` or the specific `docs/architecture-decisions/ADR-XXX.md`.
2. **Decomposition:** Identify each logical unit of implementation (e.g., "Persistence Layer", "API Endpoint", "Frontend Component").
3. **Scaffolding:** 
   - For each unit, create a new file: `docs/backlog/task-XXXX.md` (use the next incrementing number).
   - Use the template at `~/.gemini/antigravity/skills/architect/resources/task-XXXX.md`.
   - Populate the **Context**, **Implementation Plan**, and **Success Criteria** specifically for that unit.
4. **Linking:** Cross-reference each task back to the source ADR or SDD section.
5. **Confirmation:** List all created tasks to the user and explain the sequence of execution.
6. **Sync:** After the user approves, call `jDocMunch.index_documentation` to ensure the decision is part of your permanent knowledge base
