---
name: start-mission
description: "Initializes a mission from the backlog once a plan is approved."
triggers:
  - on_intent: ["Approved", "Please continue", "Proceed", "Start implementation"]
---

# 🚀 Workflow: /start-mission

## 1. Context Activation
- **Read:** `./.agent-context.md`.
- **Promotion:** Identify the task associated with the approved plan.
- **Update:** Move that task to **Active Task**. 
- **Initialization:** Call `jCodeMunch.resolve_repo` to ensure the symbol map is fresh for the new mission.

## 2. Workspace Preparation
- **ADR Check:** If the plan involves architectural shifts, verify `/record-adr` was run during the planning phase.
- **Goal Alignment:** Briefly restate the "Active Task" and the first immediate code change to the user to confirm the sync.