# 🌐 Global Agent Instructions

## 📋 Task State & Initialization
**Mandatory Initial Action:** When entering a project or starting a new session, you must:
1.  **Read** `./.agent_context.md` to synchronize with the current mission and project quirks.
2.  **Resolve:** Call `jCodeMunch.resolve_repo`.
3.  **Acknowledge:** Briefly summarize the "Current Mission" and any "Known Gotchas" to the user to confirm state synchronization before beginning work.

## 🔍 Code Exploration (jCodeMunch)
**Requirement:** Use `jCodeMunch` for all source code exploration. Standard file utilities (`cat`, `grep`, `find`, `ls`) are strictly prohibited for code analysis.
- **Bootstrapping:** Your first action in any repo must be `resolve_repo`. If not indexed, immediately call `index_folder`.
- **Navigation:** Use `get_repo_outline` for a bird's-eye view and `get_file_tree` for directory structure.
- **Analysis:** Use `get_file_outline` to understand symbols before reading. Use `get_symbol_source` to retrieve exact implementations.
- **Search:** Use `search_symbols` for AST-aware lookups and `search_text` for literal strings.

## 🔄 Index Maintenance (jCodeMunch)
The index is a snapshot and does not auto-update. You MUST maintain index integrity:
- **After File Modification:** If you change a function signature, move code, or add a new module, you MUST call `jCodeMunch.index_file` for that specific path.
- **After Large Refactors:** If you modify more than 3 files, call `jCodeMunch.index_folder` on the relevant directory.
- **Validation:** If a tool returns unexpected code, re-index the file before further troubleshooting.
- **Scope Constraint:** Only index source code and documentation. **Prohibited:** Do not attempt to index large data files (.csv, .json), build artifacts, or dependency folders (.venv, node_modules).

## 📚 Documentation Retrieval (jDocMunch)
**Requirement:** Use `jDocMunch` for searching and reading the `docs/` folder and external library documentation.
- **Primary Tool:** Always prefer `jDocMunch.search_documentation` over `grep`.
- **Knowledge Base:** Use `jDocMunch.query_knowledge_base` for conceptual questions instead of hunting for files.
- **Token Hygiene:** Do not read full `.md` files; use the MCP to retrieve specific sections or summaries.
- **Global Authority:** In addition to the local `./docs/` folder, you have a global knowledge base at `~/.gemini/rules/`. 
- **Priority:** Always query the global index for `role_*.md` and `lang_*.md` files when a specialist workflow is triggered.
- **Search Strategy:** Use `jDocMunch.query_knowledge_base` with the "Global" scope to find architectural standards that apply across all your projects.


## 🚀 Workflow Protocol
### You have access to the following global workflows. Always prefer these over manual bash commands:
- `/lint`
- `/test`
- `/run`
- `/checklist`
- `/ready`

## Software Design Interaction Policies

## 🧠 Behavioral Modes
- **Task Mode (Default):** Standard execution. No prefix required.
- **Specialist Mode:** Triggered by `/audit`, `/interact`, `/scale`, `/ux`, or `/docs-audit`.
    - **Mapping:** - `/audit` -> `role_security.md`
        - `/interact` & `/design` -> `role_architect.md`
        - `/scale` -> `role_performance.md`
        - `/ux` -> `role_product.md`
        - `/docs-audit` -> `role_librarian.md`
    - **Requirement:** You MUST prefix every response with the Visual Status Header defined in the workflow.
    - **Constraint:** Do not implement code until the Specialist has issued a "Review Passed" or "Consensus Reached" statement.

## ⚖️ Architectural Guardrails
- **Decision Threshold:** If a change involves adding a library, shifting a schema/pattern, or affecting >5 files, you MUST run `/record-adr` before implementation.
- **ADR as Context:** Always search `./docs/architectural-decisions/` via `jDocMunch` before refactoring. Respect past decisions unless explicitly superseded.

## 🛠 General Coding Requirements
- **Naming Precision:** Use specific domain terms. Avoid generic suffixes/prefixes (`info`, `data`). 
- **Rule of Identity:** Never use `id` alone; use `[resource]_id` (e.g., `user_id`).
- **Boolean Clarity:** All booleans must be prefixed with a verb (e.g., `is_valid`, `has_permission`).
- **SOLID Principles:** Adhere strictly to SOLID. Document the design pattern used in every new class docstring.

---

## 🌍 Language-Specific Activation
*Rulesets below are ONLY active if the workspace matches the criteria.*

### Python Environment (Trigger: **/*.py or pyproject.toml)
- Load and strictly follow: @/home/mike/.gemini/python_rules.md
- Use `uv` for all environment and package operations.

---

## 🛑 Git Authority & Submission Policy
- **Strict Constraint:** You are PROHIBITED from executing `git add`, `git commit`, `git push`, or `git stash`.
- **Role:** You provide "Release Ready" code. The user retains sole authority over the Git index.
- **Reporting:** Provide a "Summary of Changes" and confirmation that verification scripts passed.

## ✅ Task Completion Protocol
**MANDATORY:** Before declaring a task finished or notifying the user, you must successfully complete the **`/ready`** workflow. This is the only path to a "Release Ready" status.