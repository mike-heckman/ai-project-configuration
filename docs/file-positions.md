# Framework File Positions

This document details every file and directory that is used in a project workspace for any reason by this framework.

| Location | Mount Type | Git Ignore | Purpose |
| :--- | :---- | :--- | :---- |
| ../.ai_config_root.sh | auto-generated | Yes | Global pointer to AI configuration root directory |
| .agent-context.md | copy template | No | Store agent context |
| .eslint.config.js | copy template | No | Global ESLint configuration |
| .gitignore | copy template | No | Define ignored files for the project |
| .prettierrc | copy template | No | Global Prettier configuration |
| .languages | auto-generated | No | Environment variables defining the languages used for this project. |
| .pi/sessions/ | auto-generated | Yes | Pi session files |
| .pre-commit-config.yaml | copy template | No | Pre-commit hook configuration |
| .pyrightconfig.json | copy template | No | Global Pyright type-checking configuration |
| .ruff-master-config.toml | copy template | No | Global Ruff formatting and linting configuration |
| .tsconfig.json | copy template | No | Global TypeScript configuration |
| docs/cheat-sheet.md | copy template | No | Global cheat sheet and reference for the project |
| docs/software-design-document.md | copy template | No | Template for software design documents |
| docs/architecture-decisions/ | directory | No | Store architectural decision records (ADRs) |
| docs/backlog/done/ | directory | No | Store completed backlog items |
| docs/performance/ | directory | No | Store performance metrics and reports |
| docs/ux/ | directory | No | Store user experience design assets |
| docs/security/ | directory | No | Store security reports and guidelines |
| extract/ | directory | Yes | Temporary directory for extractions |
| logs/ | directory | Yes | Store temporary execution logs |
| public-dev/ | directory | Yes | Public development assets |
| scripts/ | directory | No | Store execution and utility scripts |
| scripts/lint.sh | hard link | Yes | Run linting during code checks |
| scripts/test.sh | hard link | Yes | Run automated testing suite |
| scripts/run.sh | hard link | Yes | Execute the project application |
| scripts/clean.sh | hard link | Yes | Clean temporary and built files |
| scripts/read-workflows.sh | hard link | Yes | Read and list available workflows |
| scripts/pre-commit.sh | hard link | Yes | Pre-commit hook execution script |
| src/ | directory | No | Primary source code directory |
| temp/ | directory | Yes | Store temporary files during execution |
| tests/ | directory | No | Automated test suites |

| Location | Mount Type | Git Ignore | Purpose |
| :--- | :---- | :--- | :---- |
| ~/.agents/pi/ | directory (host) | N/A | Pi agent assets and rules mapped to KVM |
| ~/.agents/pi-sessions/ | directory (host) | N/A | Centralized persistent storage for Pi worker session logs |
| ~/.agents/registered/ | directory (host) | N/A | Registry of initialized project locations for global updates |
| ~/.code-index/config.jsonc | file (host/KVM) | N/A | Global jcodemunch-mcp configuration |
| ~/.config/claude/mcp_config.json | symlink (KVM) | N/A | MCP configuration for agent tooling |
| ~/.doc-index/config.jsonc | file (host/KVM) | N/A | Global jdocmunch-mcp configuration |
| ~/.gemini/antigravity/ | directory (host) | N/A | Host planner agent global workflows and skills |
| ~/.gemini/rules/ | directory (host) | N/A | Host planner agent instructions |
| ~/.pi/agent/ | virtiofs mount (KVM) | N/A | Pi coding agent configuration and consolidated rules directory |
| /tmp/worker-wrapper.sh | auto-generated (KVM) | N/A | Temporary wrapper script to launch Pi worker session |
| /tmp/worker.log | auto-generated (KVM) | N/A | Output logs from the Pi worker session |

## KVM Mounts

| Host Directory | Mounted Directory | Purpose | When Mounted |
| :--- | :--- | :--- | :--- |
| `<Project Workspace Path>` | `<Project Workspace Path>` | Provides the worker agent access to the target project codebase | when a worker-bridge is called |
| `~/.agents/pi` | `/home/ubuntu/.pi/agent` | Provides core worker scripts, templates, and Pi agent configuration | when a worker-bridge is called |

## Network & Proxy Devices

| Device Name | Host Port | Guest Port | Purpose | When Configured |
| :--- | :--- | :--- | :--- | :--- |
| `pi-ui` | `8000-8999` (Dynamic) | `7681` | Maps the `ttyd` web terminal to the host for browser access | when a worker-bridge is called |
