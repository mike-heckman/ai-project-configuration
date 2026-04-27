# Sample Workflow: Building a Weather CLI Tool

This document outlines the end-to-end workflow for creating a small-to-medium project using the **Hybrid KVM-Worker Architecture**.

## 1. Project Initialization (Planner)

First, the User and Gemini (Planner) initialize the global environment and scaffold the new project.

```bash
# 1. Ensure global AI rules are linked
./scripts/init-agents.sh

# 2. Scaffold a new Python project
mkdir weather-cli && cd weather-cli
/path/to/ai-project-configuration/scripts/init-py-project.sh
```

## 2. Architectural Design (Architect Mode)

The Planner enters **Architect Mode** to define the system and record decisions.

1.  **Run `/design`**:
    *   Goal: "Design a CLI tool that fetches weather data from OpenWeatherMap API and displays it in a formatted table."
    *   Architect defines: `WeatherClient`, `ResponseParser`, and `TableFormatter`.
2.  **Run `/record-adr`**:
    *   Decision: "Use `httpx` for async requests and `rich` for terminal formatting."
3.  **Scaffold Backlog**:
    *   Architect creates `docs/backlog/task-0001-weather-client.md` and `docs/backlog/task-0002-cli-interface.md`.
    *   Status is set to `READY`.

## 3. Transition to Implementation (Coder Mode)

The Planner reviews the implementation plan for the first task and triggers the Worker.

1.  **Select Task**: `task-0001-weather-client.md`.
2.  **Run `/start-mission`**:
    *   This triggers `scripts/worker-bridge.sh`.
    *   An Incus VM is launched (e.g., `worker-python-weather-cli`).
    *   The project root is mounted to `/workspace`.
    *   Claude Code is launched inside the VM with `coder-rules`.

## 4. Autonomous Execution (Worker Plane)

Inside the Incus VM, **Claude Code (Worker)** takes over.

1.  **Implement**: Claude Code writes the `WeatherClient` logic in `src/client.py`.
2.  **Verify**:
    *   Claude runs `/test` to verify unit tests in `tests/test_client.py`.
    *   Claude runs `/lint` to ensure compliance with `ruff` and `pyright`.
3.  **Graduate**:
    *   Once the task is complete and verified, Claude runs **`/ready`**.
    *   This updates the task status to `COMPLETED` and prepares the hand-off.

## 5. Final Audit & Review (Planner)

The Worker VM is stopped/deleted, and the Planner (Gemini) reviews the work on the host.

1.  **Run `/ux` (Product Mode)**:
    *   Gemini critiques the CLI output ergonomics.
2.  **Run `/scale` (Performance Mode)**:
    *   Gemini checks the async overhead and API latency handling.
3.  **Close Task**: Gemini updates the project documentation and prepares for the next backlog item.

---

> [!TIP]
> Use `incus list` on the host to monitor your active workers and `incus exec <vm_name> -- bash` if you need to manually inspect the guest environment.
