---
name: update-docs
description: "Synchronizes README, Architecture docs, and ./.agent-context.md with recent changes."
---

# 📚 Workflow: /update-docs

## 1. Delta Analysis
- **Detect:** Use `jCodeMunch.get_repo_outline` and `get_file_outline` to identify new public APIs, modified modules, or changed signatures.
- **Scope:** Identify which `./docs/` files are impacted by these code deltas.

## 2. External & Internal Documentation
- **README.md:** Update "Features," "Usage," or "Installation" if user-facing interfaces or dependencies changed.
- **API Reference:** Update `./docs/api_reference.md` or equivalent for all public symbol changes.
- **Setup:** Update `./docs/setup.md` if environment variables or `uv` configurations shifted.

## 3. Agent Context Maintenance (.agent-context.md)
- **Review:** Open `./.agent-context.md`.
- **Status Update:** Move the finished task to the Session Log.
- **The "Hard Stop":** Set "Active Task" to `NONE`. 
- **Constraint:** You are strictly FORBIDDEN from moving a task from "Backlog" to "Active" or creating new ADR drafts without a direct user prompt.
- **Discovery:** Record only NEW tribal knowledge (e.g., "Code requires `AUTH_METHOD=trust` for local dev").

## 4. MCP Synchronization
- **Commit to Index:** Call `jDocMunch.index_documentation` on all modified `.md` files.
- **Verification:** Briefly query `jDocMunch.query_knowledge_base` for one updated fact to confirm the index is hot.

## 5. Summary
- Report to the user: "Documentation synchronized and re-indexed."