---
name: submit
description: "Global Handoff Protocol for Coders and Debuggers. Prepares task for Reviewer audit."
on_intent: ["Submit for review", "Request review", "Handover to reviewer"]
---

# 🏁 Workflow: /submit

## 1. Persona Handoff
- **Active Task:** Update the `Active Task` in `./.agent-context.md` to:
  `{Persona} {filename} Ready for Review.`
  *Example: Coder task-0001.md Ready for Review.*
- **Backlog:** Update the `Status` in `./docs/backlog/{filename}` to `READY FOR REVIEW`.
- **Outcome:** Provide a brief summary of the changes and verification results (if any) to the user.

## 2. Janitor & Sync
- **Janitor:** Execute the **`/clean`** workflow to purge `./temp/`.
- **Sync:** Call `jCodeMunch.index_file` on all modified source files.

## 3. Mandatory Stop
- You are strictly **PROHIBITED** from executing the `/ready` workflow or setting the Active Task to `NONE`.
- Your turn ends immediately after the handoff statement.
