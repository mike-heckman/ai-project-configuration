---
name: update-docs
description: "Synchronizes README, Architecture docs, and .agent_context.md with recent changes."
---

# 📚 Workflow: /update-docs

## 1. Delta Analysis
- **Detect:** Use `jCodeMunch.get_repo_outline` and `get_file_outline` to identify new public APIs, modified modules, or changed signatures.
- **Scope:** Identify which `docs/` files are impacted by these code deltas.

## 2. External & Internal Documentation
- **README.md:** Update "Features," "Usage," or "Installation" if user-facing interfaces or dependencies changed.
- **API Reference:** Update `docs/api_reference.md` or equivalent for all public symbol changes.
- **Setup:** Update `docs/setup.md` if environment variables or `uv` configurations shifted.

## 3. Agent Context Maintenance (Crucial)
- **Review:** Open `./.agent_context.md`.
- **Tribal Knowledge:** Add any "Gotchas" or non-obvious logic discovered during this task.
- **Focus Shift:** Remove completed items from "Current Mission." Update "Pending Tasks" based on current state.

## 4. MCP Synchronization
- **Commit to Index:** Call `jDocMunch.index_documentation` on all modified `.md` files.
- **Verification:** Briefly query `jDocMunch.query_knowledge_base` for one updated fact to confirm the index is hot.

## 5. Summary
- Report to the user: "Documentation synchronized and re-indexed."