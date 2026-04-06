# TypeScript / JavaScript AI Configuration Template

This directory acts as the master blueprint for initializing and managing Greenfield Node.js/TypeScript projects in a strict, AI-friendly environment. It guarantees consistency across project bootstrapping and script lifecycles.

## 🛠 Software Decisions
The toolchain described here aligns with the strictness requirements of `ai-project-configuration` while bridging modern JavaScript standards:

| Tool | Purpose | Counterpart in Python Template |
| :--- | :--- | :--- |
| **`pnpm`** | Package management. Significantly faster than NPM, ensures strict node_modules boundaries to prevent phantom dependencies. | `uv` / `pip` |
| **`eslint`** | Strict static analysis (Linter). Configured with **v9 Flat Config** and `typescript-eslint` for deep semantic code checks. | `ruff` (linter) |
| **`prettier`** | Opinionated Code Formatter. Ensures identical coding styles across all modules. | `ruff` (formatter) |
| **`tsc` (TypeScript)** | Type checking via `--noEmit`. Guarantees robust domain models and prevents runtime type collisions. | `pyright` |
| **`vitest`** | Testing framework and coverage generator. Built on Vite configuration, it eliminates typical test-transpile overhead. | `pytest` |

## 🚀 Lifecycle Scripts (`scripts/`)
Just like the Python template, projects will receive hard-linked lifecycle scripts. AI Agents must strictly interact with projects via these scripts, preventing raw CLI deviations:
*   `lint.sh`: Checks code (`eslint`), auto-formats (`prettier`), and validates types (`tsc --noEmit`).

> [!NOTE]
> **Hard-Synced Lint Configurations**  
> To guarantee identical formatting across all TypeScript repositories, the `lint.sh` script automatically copies `.eslint.config.js`, `.prettierrc`, and `.tsconfig.json` from the master template to the local directory on every run. This exposes the rules to your IDE natively while preventing drift. To opt out, you can create a `scripts/_local_lint.sh` file.
*   `test.sh`: Executes `vitest run --coverage` and formats the metrics into a `coverage.md` markdown report.
*   `run.sh`: Triggers `pnpm run dev` or `pnpm start`, ensuring apps run identically whether they are a Vite UI or a standalone backend script.
*   `clean.sh`: Purges `dist/`, `node_modules/`, and logs.
