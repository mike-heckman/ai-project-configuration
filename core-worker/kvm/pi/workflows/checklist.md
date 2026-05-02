---
description: Run the full verification suite (lint, test, coverage) as a dry-run diagnostic tool. Does NOT advance task status.
---

# /checklist
1. **Execution:**
    - Execute the global workflow `/lint`.
    - Execute the global workflow `/test`.
2. **Validation:**
    - Analyze `./coverage.md` against minimum thresholds specified in `./.agent-context.md`.
3. **Output:** "Status: Checklist Complete. All quality checks passed."
