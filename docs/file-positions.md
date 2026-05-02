# Framework File Positions

This document details every file and directory that is used in a project workspace for any reason by this framework.

| Location | Mount Type | Git Ignore | Purpose |
| :--- | :---- | :--- | :---- |
| .worker-agent-env | copy template | Yes | Store environment values for the worker |
| .agent-worker-env | auto-generated | Yes | Store environment values for the worker (alternate name) |
| .agent-context.md | copy template | No | Store agent context |
| scripts/lint.sh | hard link | Yes | Run linting during code checks |
| scripts/test.sh | hard link | Yes | Run automated testing suite |
| scripts/run.sh | hard link | Yes | Execute the project application |
| scripts/clean.sh | hard link | Yes | Clean temporary and built files |
| scripts/read-workflows.sh | hard link | Yes | Read and list available workflows |
| scripts/pre-commit.sh | hard link | Yes | Pre-commit hook execution script |
| .pre-commit-config.yaml | copy template | No | Pre-commit hook configuration |
| .ruff-master-config.toml | copy template | No | Global Ruff formatting and linting configuration |
| .pyrightconfig.json | copy template | No | Global Pyright type-checking configuration |
| .eslint.config.js | copy template | No | Global ESLint configuration |
| .prettierrc | copy template | No | Global Prettier configuration |
| .tsconfig.json | copy template | No | Global TypeScript configuration |
| .gitignore | copy template | No | Define ignored files for the project |
| docs/cheat-sheet.md | copy template | No | Global cheat sheet and reference for the project |
| docs/software-design-document.md | copy template | No | Template for software design documents |
| ../.ai_config_root.sh | auto-generated | Yes | Global pointer to AI configuration root directory |
| src/ | directory | No | Primary source code directory |
| tests/ | directory | No | Automated test suites |
| scripts/ | directory | No | Store execution and utility scripts |
| logs/ | directory | Yes | Store temporary execution logs |
| temp/ | directory | Yes | Store temporary files during execution |
| extract/ | directory | Yes | Temporary directory for extractions |
| public-dev/ | directory | Yes | Public development assets |
| docs/architecture-decisions/ | directory | No | Store architectural decision records (ADRs) |
| docs/backlog/done/ | directory | No | Store completed backlog items |
| docs/performance/ | directory | No | Store performance metrics and reports |
| docs/ux/ | directory | No | Store user experience design assets |
| docs/security/ | directory | No | Store security reports and guidelines |
| ~/.agents/core-worker/ | symlink (host) | N/A | Core worker assets and rules mapped to KVM |
| ~/.agents/pi-sessions/ | directory (host) | N/A | Centralized persistent storage for Pi worker session logs |
| ~/.agents/registered/ | directory (host) | N/A | Registry of initialized project locations for global updates |
| ~/.gemini/antigravity/ | directory (host) | N/A | Host planner agent global workflows and skills |
| ~/.gemini/rules/ | directory (host) | N/A | Host planner agent instructions |
| ~/.code-index/config.jsonc | file (host/KVM) | N/A | Global jcodemunch-mcp configuration |
| /opt/core-worker/ | virtiofs mount (KVM) | N/A | Mount point for core worker assets inside KVM |
| /tmp/worker-wrapper.sh | auto-generated (KVM) | N/A | Temporary wrapper script to launch Pi worker session |
| /tmp/worker.log | auto-generated (KVM) | N/A | Output logs from the Pi worker session |
| ~/.pi/agent/ | virtiofs mount (KVM) | N/A | Pi coding agent configuration and rules directory |
| ~/.config/claude/mcp_config.json | symlink (KVM) | N/A | MCP configuration for agent tooling |

## KVM Mounts

| Host Directory | Mounted Directory | Purpose | When Mounted |
| :--- | :--- | :--- | :--- |
| `<Project Workspace Path>` | `/workspace` | Provides the worker agent access to the target project codebase | when a worker-bridge is called |
| `~/.agents/core-worker` | `/opt/core-worker` | Provides core worker scripts, assets, and configs to the agent | when a worker-bridge is called |
| `~/.agents/core-worker/kvm/pi` | `/home/ubuntu/.pi/agent` | Direct configuration and rules mount for the Pi coding agent | when a worker-bridge is called |
| `~/.agents/pi-sessions` | `/home/ubuntu/.pi/agent/sessions` | Intercepts session state out of the repository into a centralized host directory | when a worker-bridge is called |
