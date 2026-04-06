# 🌐 Global Agent Instructions


## 🏁 Session Initialization
1. **Sync:** Run `jCodeMunch.resolve_repo` and read `./.agent-context.md`.
2. **ACK:** Briefly summarize the "Current Mission" and "Known Gotchas".
3. **Workflow Discovery (MANDATORY):** You MUST run `./scripts/read-workflows.sh` at the start of every session. 
4. **Workflow Usage (MANDATORY):** If a slash command or workflow (e.g., /test, /ready) is relevant, you are strictly forbidden from executing any terminal command until you have first called view_file on that workflow's .md file.
5. **Wait:** If Active Task is NONE in .agent-context.md, you must wait for a plan approval or a /start-mission trigger before modifying source code.
6. **Enforcement:** You are STRICTLY PROHIBITED from executing any `.sh` script manually if a corresponding `.md` workflow exists. You MUST follow the workflow steps EXACTLY.

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
- **Temporary Files:** You are STRICTLY FORBIDDEN from writing to `/tmp` or any path outside the project root. 
- **Workspace Temp:** Use `./temp/` for all ephemeral scripts, scratchpads, or intermediate data. Create this directory if it does not exist.
- **Git Authority:** Execution of `git add`, `commit`, `push`, or `stash` is **PROHIBITED**.

## ✅ Completion Protocol
- **MANDATORY:** You must successfully complete the **`/ready`** workflow before declaring any task finished. This is the sole path to "Release Ready" status.