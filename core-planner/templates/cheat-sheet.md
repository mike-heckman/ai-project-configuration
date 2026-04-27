
## 🚀 Command Center

### 🛠️ Core Project Workflows
Standard routines to keep the codebase "Release Ready."

| Command | Purpose | When to use? |
| :--- | :--- | :--- |
| **`/lint`** | Syncs `master_ruff.toml` and fixes code. | Before every commit. |
| **`/ready`** | Runs lint, tests, and updates `./.agent-context.md`. | Before requesting a "Manual Review." |
| **`/sync-global`** | Re-indexes `{{CORE_DIR}}/` into MCP memory. | After you tweak a `role_*.md` file. |
| **`/record-adr`** | Captures a "Why" behind a major change. | When adding libraries or shifting schemas. |

---

### 🏛️ Strategy & Design (Architect Mode)
*Trigger: **Lead Architect** (`role_architect.md`)*

| Command | Purpose | Focus |
| :--- | :--- | :--- |
| **`/design`** | Multi-phase interactive design session. | Building a new feature from scratch. |
| **`/interact [topic]`** | Deep-dive into a specific architectural pivot. | Evaluating "Should we switch to X?" |

---

### 🛡️ Specialist Audits (Specialist Mode)
*Trigger: Various **Staff Personas** (`role_*.md`)*

| Command | Persona | Goal |
| :--- | :--- | :--- |
| **`/audit [module]`** | **Security Auditor** | Find OWASP holes and exploit paths. |
| **`/scale [topic]`** | **Performance Eng.** | Fix N+1 queries and $O(n^2)$ bottlenecks. |
| **`/ux`** | **Product Advocate** | Critique CLI flags and error actionability. |
| **`/docs-audit`** | **Librarian** | Identify "Documentation Drift" vs. Code. |

---

## 🧠 Behavioral Mode HUD (Heads-Up Display)
When you see these prefixes, the agent is locked into specific constraints:

* **`[MODE: 🏛️ ARCHITECT]`**: Implementation is **LOCKED**. Focus is on Pros/Cons/Debt.
* **`[MODE: 🛡️ SECURITY]`**: Adversarial mindset. High-alert for vulnerabilities.
* **`[MODE: ⚡ PERFORMANCE]`**: Math/Big O mindset. Efficiency over readability.
* **`[MODE: 🎨 UX/PRODUCT]`**: End-user mindset. CLI ergonomics over logic.

---

## ⚖️ Global Guardrails (The "Always-On" Rules)
1.  **Naming:** No generic suffixes (`_data`, `_info`).
2.  **Identity:** Never use `id` alone; always `[resource]_id`.
3.  **Booleans:** Must start with a verb (`is_`, `has_`, `can_`).
4.  **ADRs:** Any change > 5 files or new library **requires** a `/record-adr`.
5.  **Persistence:** Use "Pause" or "Stop" to trigger an auto-save to `./.agent-context.md`.
