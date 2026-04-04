---
description: Run the full verification suite (lint, test, coverage) and re-index the project for release readiness.
---

# /checklist
1. Call the workflow `/lint`.
2. Call the workflow `/test`.
3. If both pass:
    - Read `coverage.md` to ensure no coverage regression.
    - Call `jCodeMunch.index_folder` on the current workspace.
    - Call `jDocMunch.index_documentation` if docs were changed.
4. Output: "Status: Release Ready. All checks passed and indices synchronized."