# Hybrid KVM-Worker Architecture

This repository implements a **Hybrid Agent Architecture** that separates high-level planning from low-level execution using KVM isolation via **Incus**.

## 🏗️ The Model

The architecture is divided into two distinct logical planes:

1.  **Planner Plane (Host System)**:
    *   **Agent**: Gemini (Antigravity).
    *   **Roles**: Architect, Librarian, Product.
    *   **Responsibility**: Strategic design, Architectural Decision Records (ADRs), and scaffolding "tickets" in `./docs/backlog/`.
    *   **Context**: Reads from `core-planner/`.

2.  **Worker Plane (Incus VM)**:
    *   **Agent**: Opencode.
    *   **Roles**: Coder, Debugger, Performance, Security.
    *   **Responsibility**: Autonomous implementation of tickets, linting, testing, and graduation.
    *   **Context**: Reads from `core-worker/` (mounted via virtiofs).

## 📂 Core Separation

To prevent context contamination and optimize for token usage, rules and tool configurations are physically separated:

*   `core-planner/`: Instructions for high-level strategy and Architect/Librarian roles. Includes a `config.jsonc` that restricts `jcodemunch-mcp` tools to analytical and structural discovery.
*   `core-worker/`: Instructions for implementation and debugging. Includes a `config.jsonc` that restricts `jcodemunch-mcp` tools to implementation-level file indexing and symbol navigation.

### Role-Based Tool Filtering (MCP)
Both agents use a global `~/.code-index/config.jsonc` file to configure their MCP tools.
- The **Planner** (Host) links its config from `core-planner/config.jsonc`.
- The **Worker** (VM) links its config from `/home/mike/.agents/core-worker/config.jsonc`.
This ensures that the Planner doesn't see "Worker-only" tools and vice-versa, significantly reducing token noise and accidental tool misuse.

## 🚀 The Autonomous Loop

The transition from Planning to Execution is handled by the **Bridge**:

1.  **Ticket Creation**: Gemini creates a `task-XXXX.md` with `status: READY`.
2.  **Trigger**: You run **`/start-mission`** (or call `scripts/worker-bridge.sh` manually).
3.  **Provisioning**: The bridge script launches an Incus VM, mounts the project and core rules, and injects a `ROLE` (e.g., `coder-rules`).
4.  **Execution**: Inside the VM, Opencode launches in the background, consuming the ruleset associated with the `ROLE` and clearing the backlog.

## 🛠️ Working with Incus KVM

Incus provides the virtualization layer. Here are the common commands you'll need:

### Monitoring & Access
*   **List active workers**: `incus list`
*   **View Worker Console**: `incus console <vm_name>` (Ctrl+a q to exit)
*   **Execute command in worker**: `incus exec <vm_name> -- <command>`
*   **Open a shell in worker**: `incus exec <vm_name> -- bash`

### Management
*   **Stop a worker**: `incus stop <vm_name>`
*   **Start a worker**: `incus start <vm_name>`
*   **Delete a worker**: `incus delete -f <vm_name>`

### Configuration
Mounts and environment variables are handled automatically by `scripts/worker-bridge.sh`. If you need to manually add a mount:
```bash
incus config device add <vm_name> <device_name> disk source=<host_path> path=<guest_path>
```

## 🔧 Bridge & Init Internals

### `scripts/worker-bridge.sh`
This is the host-side orchestrator. It:
1.  Creates the VM name based on project and language.
2.  Adds `virtiofs` devices for the project and `core-worker/`.
3.  Generates `.agent-worker-env` in the project root.
4.  Triggers the guest-side initialization.

### `core-worker/kvm/guest-init.sh`
This script runs inside the VM. It:
1.  Verifies the `virtiofs` mounts are active.
2.  Sources the environment configuration.
3.  Establishes path parity (symlinking `/workspace` to match the host path).
4.  Launches Opencode with the prompt derived from `ROLE`.

## 🐞 Troubleshooting

*   **Mounts not appearing**: Ensure `incus-agent` is installed and running in the base image. Run `incus exec <vm_name> -- systemctl status incus-agent`.
*   **Opencode permission errors**: Verify that the UID/GID inside the VM matches your host user (Mike) or that the mount has appropriate mapping.
*   **Path mismatches**: The architecture uses identical path mapping. If your host project is at `/home/mike/Projects/foo`, the VM will symlink `/workspace` to `/home/mike/Projects/foo` internally.
