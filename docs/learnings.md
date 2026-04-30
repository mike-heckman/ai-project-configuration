# Repository Learnings

This document tracks systemic "gotchas," discoveries, and best practices identified during the development of the AI Project Configuration.

## Agent Orchestration

### Opencode Configuration (2026-04-28)
- **Config Path**: Opencode expects its global configuration at `~/.config/opencode/opencode.json`, NOT `config.json`.
- **Mounting Strategy**: When using Incus VMs, mounting the entire configuration directory (`./core-worker/kvm/opencode/`) to `~/.config/opencode/` is more robust than individual file symlinking. This allows for dynamic loading of `commands/` and `plugins/` without modifying the guest-init script.
- **Dependency Management**: Opencode configurations utilizing `uvx` for MCP servers require `uv` to be installed in the guest environment.

### Claude Code JSON Decoding (2026-04-28)
- **Local Model Friction**: Claude Code (v0.x) has significant difficulty parsing tool calls from local models (e.g., Gemma-4 via LM Studio) due to inconsistent JSON formatting. This leads to a terminal failure ("brick wall") in the autonomous loop.
- **Initial Solution**: Pivoted to `Opencode` as the worker agent for improved local model compatibility.

### Pivot to Pi (2026-04-30)
- **Opencode Limitations**: Even after extensive modification of rules, skills, and workflows, Opencode could not be stabilized in a fully autonomous loop. The process remained unreliable for long-running agentic tasks.
- **Final Solution**: Moving to `Pi` (@mariozechner/pi-coding-agent). Pi offers a minimal coding harness with robust `RPC` and `JSON event stream` modes, making it significantly more suitable for reliable autonomous orchestration.

## Virtualization (Incus)

### Mount Persistence
- **Virtiofs Limits**: Avoid reconfiguring mounts while a VM is `RUNNING` to prevent `virtiofsd` crashes. Always check status before running `incus config device add/remove`.
