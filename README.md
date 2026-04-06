# AI Project Configuration (`ai-project-configuration`)

An infrastructure and configuration repository designed to establish a standardized, AI-aware development environment. This project centrally manages AI system rules, execution workflows, and boilerplate project templates, serving as the "source of truth" for AI agents (specifically Anthropic/Gemini operating via Antigravity) running on your local machine.

## 🎯 Project Purpose

- **Centralized AI Governance**: Maintains a strict set of global rules, behavioral roles, and standardized operating procedures (workflows) for your AI coding assistants.
- **Project Bootstrapping**: Automates the scaffolding of new, greenfield projects (e.g., modern Python with `uv` and `ruff`) using strict structural and linting standards.
- **Workflow Standardization**: Enforces consistent execution paths for tasks like linting, testing, and continuous integration, ensuring AI agents cannot bypass standard pipeline checks.

> [!WARNING]
> This configuration is heavily tailored for Anthropic/Gemini/Antigravity environments. Using these workflows with other AI systems will likely require modifications (e.g., removing YAML descriptions from markdown workflows).

## ⚠️ System Requirements

- **OS**: Ubuntu or Linux Mint. *(Execution on Windows environments is unsupported and expected to be non-functional).*
- **Dependencies**: bash, git. Python bootstrapping requires `uv`.

## 🚀 Getting Started

### 1. Initialize Global AI Constraints

After cloning or bringing down an update for this repository, bootstrap your local AI rules engine by running:

```bash
./scripts/init-gemini.sh
```

**What this does:**
- Soft-links `global-rules.md`, conditional language rules, and specialized agent personas into `~/.gemini/`.
- Registers 18+ standardized AI workflows into `~/.gemini/antigravity/global_workflows`.
- Installs document templates and the global `cheat-sheet.md`.
- Automatically configures your global Git ignores (`~/.config/git/ignore`) to properly exclude ephemeral AI directories (e.g., `temp/`, `logs/`).

### 2. Scaffold a New Project (Python)

To bootstrap or update an existing Python repository with strict configuration standards, navigate to your target project repository and run:

```bash
/path/to/ai-project-configuration/scripts/init-py-project.sh
```

**What this does:**
- Scaffolds consistent directory structures (`scripts/`, `src/`, `tests/`, `logs/`, `temp/`, `docs/`).
- Initializes a greenfield Python 3.14 project using `uv` if `pyproject.toml` is absent.
- Links standard scripts (like `lint.sh`, `test.sh`) to enforce pipeline integrity via shared logic.
- Injects a baseline `.agent-context.md`.
- Sets up Git pre-commit hooks and testing dependencies (`ruff`, `pytest`, `pyright`).

## 📂 Core Architecture

### `gemini/`
The brain of the operation. Contains the directives fed to AI agents.
- **`global-rules.md`**: The strict overarching axioms for the AI (enforcing file modifications, code standards, workflow usage).
- **`global-workflows/`**: Specialized operation routines like `/audit`, `/design`, `/test`, `/ready`.
- **`conditional-rules/`**: Language-specific constraints (e.g., `lang_python.md`, `lang_typescript.md`) and behavioral specialist personas (`role_architect.md`, `role_security.md`).
- **`document-templates/`**: Boilerplates for Architecture Decision Records (ADRs) and context files.

### `scripts/`
Execution utilities to bridge the gap between AI configuration and the actual operating system environment. 

### `languages/`
Holds language-specific project templates and scaffolds. Currently primarily configured for strictly modern Python setups and Greenfield Node/TypeScript environments.

#### Hard-Synced Lint Configurations
To ensure your global toolchains are never out-of-sync across disjointed repositories, all generated `scripts/lint.sh` files automatically synchronize and overwrite local configuration files (`.eslint.config.js`, `.prettierrc`, `.ruff-master-config.toml`, `.tsconfig.json`, etc.) upon execution directly from the `ai-project-configuration` source directory. The rationale for this copying architecture is two-fold:
1. It guarantees that strict coding rules remain absolutely uniform across all projects on your machine.
2. It allows the configurations to physically reside inside the target project repository so they are visible to your local IDEs and committed accurately into the project's Git history.

If you ever need to deliberately circumvent this master synchronization for experimental reasons, you can create an executable `.sh` script named `scripts/_local_lint.sh` within your target repository. The master lint lifecycle wrappers automatically respect the presence of this file and will yield complete execution control to your local explicit instructions.

## 🧠 Integrated Workflows & Roles

This repository wires your AI environment to recognize specialized slash-commands defined in `gemini/cheat-sheet.md`. AI agents interact using these workflows as standardized execution paths for regular project maintenance and deep design sessions.

### 🛠️ Simple & Functional Workflows
These commands manage standard project routines, test suites, and codebase hygiene.

- **`/checklist`**: Runs the full verification suite (lint, test, coverage) and re-indexes the project for release readiness.
- **`/clean`**: Cleans up ephemeral build files, caches, and temp items in the project workspace.
- **`/exit`**: Exits the current active Specialist or Architect mode and returns the AI to general Task Mode.
- **`/git-diff-summary`**: Creates a diff summary between the current branch and the specified origin branch (or `main` if not specified).
- **`/help`**: Displays the AI Command Center cheat sheet for reference.
- **`/lint`**: Runs the project's centralized linting and formatting scripts.
- **`/ready`**: **Mandatory step.** Executes the Global Task Completion Protocol (Definition of Done) to mark a task as finished.
- **`/run`**: Executes the project in local testing/development mode.
- **`/start-mission`**: Initializes a mission from the backlog once an implementation plan is approved.
- **`/test`**: Runs the standardized unit test and coverage scripts (e.g., `pytest`).
- **`/update-docs`**: Synchronizes the core architecture documentation (`README`, `.agent-context.md`) with the repository's recent changes.

### 🧠 Interactive & Strategic Workflows
These commands lock the AI into specific behavioral personas (Modes) designed for deep technical strategy, audits, and architectural pivoting.

- **`/audit`** *(Security Mode)*: Runs an adversarial security audit on a specific module or logical component.
- **`/design`** *(Architect Mode)*: Initiates a deep-dive interactive software design session with state persistence.
- **`/docs-audit`** *(Librarian Mode)*: Audits the repository's documentation for "drift" and searches for missing context.
- **`/interact`** *(Architect Mode)*: Evaluates architectural and functional pivots with the Lead Architect persona.
- **`/record-adr`**: Generates a new Architecture Decision Record (ADR) using the standardized boilerplate. Required for new libraries or structural schema shifts >5 files.
- **`/scale`** *(Performance Mode)*: Analyzes performance footprints, latencies, and Big O complexity bottlenecks.
- **`/ux`** *(Product Mode)*: Critiques API ergonomics, CLI flags, output formatting, and the overall developer/user experience.
