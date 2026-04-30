# Generic Agent Handling & Multi-Agent Support

This document outlines how the repository supports multiple AI agents (Gemini/Antigravity, Claude Code, Cursor) from a single source of truth.

## 🏗️ Implemented Architecture: Hybrid KVM-Worker

We have successfully refactored the initial Gemini-only setup into a **Hybrid Agent Architecture**. The "agnostic core" has been split into two role-based directories:

- **`core-planner/`**: Source of truth for planning-heavy agents (Gemini/Antigravity) running on the host.
- **`core-worker/`**: Source of truth for execution-heavy agents (Claude Code) running inside the KVM.

### 🔌 Agent Adapters
The repository uses adapters to "render" or "inject" these core rules into the specific environments expected by different agents:

1.  **Gemini (Antigravity) Adapter**: Handled by `scripts/init-agents.sh`. It symlinks `core-planner/` to `~/.gemini/antigravity/` on the host.
2.  **Claude Code (Worker) Adapter**: Handled by `scripts/worker-bridge.sh` and `core-worker/kvm/guest-init.sh`. It mounts `core-worker/` into the Incus VM and symlinks rules to the guest's home directory.
3.  **Cursor Support**: The `init-py-project.sh` script is being updated to optionally generate `.cursor/rules/*.mdc` files derived from the `core-planner/` skills.

## 🧩 Universal State Tracking: `.agent-context.md`
To ensure multiple agents can work on the same project without stepping on each other's toes, we use a mandatory `.agent-context.md` file in the project root.

- **Planner** writes the "Active Task" and "Strategic Intent" to this file.
- **Worker** reads this file upon entry to understand the current mission.
- **User** can read this file to see the unified state of all agents.

## 🚀 Roadmap & Next Steps

### 1. Unified Templating
Continue replacing hardcoded paths in `core-*` markdown files with placeholders (e.g., `{{AGENT_ROOT}}`) that are injected during initialization.

### 2. Expanded Language Support
Standardize the "graduation" workflows (lint/test/ready) for non-Python environments (Node/TypeScript, Rust) inside the Worker KVM.

### 3. Integrated Diagnostics
Enhance the `Debugger` skill inside `core-worker` to automatically ingest logs and traces from the KVM and summarize them for the Planner.