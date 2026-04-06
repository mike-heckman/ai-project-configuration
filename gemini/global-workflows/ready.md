---
name: ready
description: "Global Task Completion Protocol (Definition of Done). Mandatory before task handover."
on_intent: ["Complete task", "I am done", "Finished", "Release ready"]
---

# 🏁 Workflow: /ready

## 1. Verification & Coverage
- **Execute `/lint`** (Must return Exit 0).
- **Execute `/test`** (Must return Exit 0).
- **Check `./coverage.md`:** If new logic is "Missing" or coverage decreased, **STOP** and fix.

## 2. Documentation & Sync
- **Janitor (First):** Execute the **`/clean`** workflow to purge `./temp/`. This ensures no ephemeral "trash" code is indexed.
- **Execute `/update-docs`:** (Updates README, API docs, and Tribal Knowledge).
- **MCP Index:** Call `jCodeMunch.index_file` (code) and `jDocMunch.index_documentation` (docs).

## 3. Mission Finalization (The Hallucination Killer)
- **Verify Lint:** The file `./logs/lint.log` must end in "Completed successfully at" followed by a timestamp from the last 60 seconds.
- **Verify Test:** Teh file `./logs/test.log` must end in "Completed successfully at" followed by a timestamp from the last 60 seconds.
- **Open:** `./.agent-context.md`.
- **Close Task:** Move the current "Active Task" to the "Session Log" with a timestamp and summary.
- **Set State:** Update "Active Task" to **`NONE / AWAITING INSTRUCTION`**.
- **Constraint:** You are strictly **PROHIBITED** from promoting a task from "Backlog" to "Active" until the user issues a new mission.

## 4. Final Handover Statement
Every /ready statement MUST include the literal text of the 'Completion' line found in the lint.log and test.log (see below).
> ### ✅ Status: **Release Ready**
> - **Lint workflow passed**: Exit 0, Completed successfully at Sun Apr 5 11:00 PM
> - **Test workflow passed**: Exit 0, Completed successfully at Sun Apr 5 11:00 PM
> - **Coverage valid**: Now at 82.3%
> - **Mission Status:** [ADR-XXX] Closed. Active Task set to NONE.
> - **Sync:** Re-indexed all modified files.
> - **Git Policy:** No Git actions performed.
