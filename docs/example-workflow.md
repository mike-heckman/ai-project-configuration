# Example End-to-End Workflow

This document provides a complete example of a project session from inception to completion using the Antigravity framework.

## 1. Create the Project in Git
Start by creating a new repository on your Git provider (e.g., GitHub) and clone it locally, or initialize a new one.

```bash
mkdir my-awesome-project
cd my-awesome-project
git init
```

## 2. Initialize the Project Directory
Use the framework's initialization scripts to set up the project structure, language environment, and agent configuration.

### Example: Initializing a Python Web App
Assuming the `ai-project-configuration` repository is at `~/Projects/ai-project-configuration`:

```bash
# Initialize a Python project with the 'web' flavor
~/Projects/ai-project-configuration/scripts/init-py-project.sh --type app --flavor web --dir .
```

This script will:
- Create the `src`, `tests`, `scripts`, and `docs` directories.
- Copy master linting and type-checking configs (`.ruff-master-config.toml`, etc.).
- Set up the local `.agent-context.md`.
- Link utility scripts like `/lint`, `/test`, and `/run` into the `./scripts` folder.

## 3. Architect Phase: Scaffolding and Task Creation
Open a session with Antigravity and enter Architect mode. The goal here is to define the technical design and break it down into actionable tasks.

**Prompt Example:**
> "Enter architect mode. We are building a FastAPI backend with a simple dashboard. Scaffold the initial `src/` structure and create the implementation plan in `docs/backlog/` using `task-XXXX.md` files."

### Actions in Architect Mode
1. **Scaffold:** Antigravity will create the skeleton files (e.g., `src/main.py`, `src/api.py`).
2. **Plan:** It will generate a series of task files in `./docs/backlog/`:
   - `docs/backlog/task-0001.md`: Implement the Metrics API.
   - `docs/backlog/task-0002.md`: Build the Frontend Dashboard.
   - `docs/backlog/task-0003.md`: Add Unit Tests for the API.

Set the status of the first task to `READY` in the task markdown file to signal it is ready for the worker.

## 4. Execution Phase: Running the Worker Bridge
Once the tasks are defined and the project is initialized, use the `worker-bridge.sh` to hand off implementation to a local LLM running inside a hardened KVM environment.

```bash
# Launch the worker for the current project
# Usage: ./worker-bridge.sh <project_path> <role> <language>
~/Projects/ai-project-configuration/scripts/worker-bridge.sh $(pwd) coder python
```

### What happens next:
1. **VM Spin-up:** An Incus VM is launched or attached.
2. **Mounting:** Your project code is mounted into the VM at `/workspace`.
3. **Autonomous Loop:** The worker agent (running Pi) scans `docs/backlog/` for `READY` tasks.
4. **Implementation:** It executes the code changes, runs `/lint` and `/test`, and moves the task to `done/` upon success.
5. **Session Monitoring:** You can watch the progress via the attached tmux session.

## 5. Finalizing and Git Check-in
After the worker has completed the tasks, verify the changes on your host machine.

```bash
# Run the project locally to verify
./scripts/run.sh

# If everything looks good, commit and push
git add .
git commit -m "Initial implementation of FastAPI dashboard via Antigravity Worker"
git push
```
