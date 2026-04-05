# 🌐 Global Agent Instructions

## 🏁 Session Initialization
1. **Sync:** Run `jCodeMunch.resolve_repo` and read `./.agent_context.md`.
2. **ACK:** Briefly summarize the "Current Mission" and "Known Gotchas" to confirm state.

## 🔍 Code & Docs (jMunch Suite)
- **Authority:** Use `jCodeMunch` for code and `jDocMunch` for all documentation.
- **Prohibition:** Manual analysis via `cat`, `grep`, `ls`, or `find` is **STRICTLY FORBIDDEN**.
- **Integrity:** `index_file` after any mod; `index_folder` after refactors (>3 files). Re-index if tool output is unexpected.
- **Standard:** Use `query_knowledge_base` (Global scope) for architectural alignment.

## 🧠 Specialist & ADR Protocol
- **Routing:** Trigger `/audit`, `/interact`, `/scale`, `/ux`, or `/docs-audit` for reviews. Load `role_*.md` from global index and prefix responses with the Specialist Header.
- **Implementation:** No code changes until "Consensus Reached."
- **ADR Authority:** Run `/record-adr` for library changes, schema shifts, or >5 file impacts. 
- **ADR as Context:** Always search `./docs/architectural-decisions/` via `jDocMunch` before refactoring. Respect past decisions unless explicitly superseded.

## 🛠 Workflow Exclusivity (Anti-Bypass)
- **Standardized Execution:** You are **PROHIBITED** from running `scripts/lint.sh`, `scripts/test.sh`, or `scripts/run.sh` directly via bash/shell. 
- **Mandatory Path:** You MUST use the designated workflows to ensure proper logging and error-trapping:
  - Use **`/lint`** for all linting/formatting.
  - Use **`/test [paths]`** for all testing and coverage.
  - Use **`/run`** for local testing mode.
- **Python:** Follow `~/.gemini/rules/lang_python.md`.

## 📐 Coding & Git
- **Naming:** Domain-specific only. Use `[resource]_id` and verb-prefixed booleans (e.g., `is_valid`).
- **SOLID:** Adhere strictly to SOLID; document patterns in class docstrings.
- **Git Authority:** Execution of `git add`, `commit`, `push`, or `stash` is **PROHIBITED**.

## ✅ Completion Protocol
- **MANDATORY:** You must successfully complete the **`/ready`** workflow before declaring any task finished. This is the sole path to "Release Ready" status.