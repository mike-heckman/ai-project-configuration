---
name: start-mission
description: "Promotes a task to ACTIVE and launches the KVM Worker."
triggers:
  - on_command: "/start-mission"
  - on_intent: ["Approved", "Proceed", "Start implementation"]
---

# 🚀 Workflow: /start-mission

## 1. Task Promotion
- **Read:** `./.agent-context.md`.
- **Identify:** Find the task in `./docs/backlog/` that is marked `READY` and matches the approved plan.
- **Update:** Set the task status to `IN_PROGRESS` in `.agent-context.md`.

## 2. Worker Launch
- **Invoke:** Run `scripts/worker-bridge.sh <project_path> <role> <language>`.
- **Parameters:**
    - `project_path`: The current workspace root.
    - `role`: `coder-rules` (or `debugger-rules` if it's a bug).
    - `language`: Determined by the project type (e.g., `python`).

## 3. Hand-off
- **Confirm:** Inform the user that the Worker VM is launching and the mission is starting autonomously.
- **Console:** Provide the command to view the worker console: `virsh console <vm_name>`.
