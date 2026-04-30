---
name: ready
description: "Global Task Completion Protocol (Definition of Done). Executes the final quality gate and graduates the task."
on_intent: ["Graduate task", "Task is ready", "Complete mission"]
---

# 🏁 Workflow: /ready

## 1. Quality Gate (Reviewer Persona)
- **Action:** Execute the following workflows in sequence:
  1. **`/lint`**: Must return 0 errors.
  2. **`/test`**: All critical tests must pass.
- **Coverage Check:** 
  - Read `./coverage.md`.
  - If total lines in project > 50, enforce `Min Coverage Threshold` from `.agent-context.md`.
  - If project is < 50 lines, skip coverage minimum check but log result.
- **Regression Check:** Ensure current coverage >= `Last Known Coverage`.

## 2. Failure Recovery
- **Action:** If any check fails:
  1. Update `Active Task` in `.agent-context.md` to include `REJECTED: [Reason]`.
  2. Log specific errors (lint/test output) to `./docs/backlog/{task_id}.md`.
  3. **Self-Correction:** Immediately re-adopt the **Coder/Debugger** persona and begin fixing the reported issues. **DO NOT STOP THE LOOP.**

## 3. Graduation (Success)
- **Action:** If all checks pass:
  1. Execute **`/clean`** to purge `./temp/`.
  2. Move `./docs/backlog/{task_id}.md` to `./docs/backlog/done/`.
  3. Update `Last Known Coverage` in `.agent-context.md`.
  4. Call `jcodemunch-mcp.index_folder` to finalize the state.

## 4. Loop Advancement
- **Action:** 
  1. Scan `./docs/backlog/` for the next available task/bug.
  2. If found, update `Active Task` in `.agent-context.md` with the new ID and set status to `IN_PROGRESS`.
  3. If backlog is empty, set `Active Task` to `NONE` and status to `DONE`.
  4. **Continue:** Restart the loop as defined in `AGENTS.md`.
