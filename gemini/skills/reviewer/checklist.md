---
description: Run the full verification suite (lint, test, coverage) and re-index the project for release readiness.
---

# /checklist
1. **Persona Load:** Load `./gemini/skills/reviewer/SKILL.md` and adhere to its persona constraints.
2. **Visual Status:** Prefix all subsequent responses in this session with: `[MODE: 🔍 REVIEWER | TARGET: QUALITY]`.
3. **Execution:**
    - Execute the global workflow `/lint`.
    - Execute the global workflow `/test`.
4. **Validation:**
    - Analyze `./coverage.md` against `./.agent-context.md` per the **Coverage & Metrics Protocol** in `SKILL.md`.
5. **Synchronization:**
    - Call `jCodeMunch.index_folder` on the current workspace.
    - Call `jDocMunch.index_documentation` on the `./docs/` folder.
6. **Output:** "Status: Release Ready. All quality checks passed and indices synchronized."