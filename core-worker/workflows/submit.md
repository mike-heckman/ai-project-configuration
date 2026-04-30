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
- **Sync:** Call `jcodemunch-mcp.index_file` on all modified source files.

## 3. Automatic Review Transition
- **Continuous Integration:** You MUST now transition to the **Reviewer** persona to begin the Graduation Protocol.
- **Action:** Load `skills/reviewer/SKILL.md`, adopt the `[MODE: 🔍 REVIEWER]` prefix, and execute the **`/ready`** workflow immediately.
- **Turn Integrity:** Do NOT end your turn until the Graduation Protocol is complete or has been kicked back for correction.
