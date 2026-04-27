---
description: Run an adversarial security audit on a specific module.
---
# /audit {{module}}
1. **Persona Load:** Load `{{SKILLS_DIR}}/security/SKILL.md` and adhere to its persona constraints.
2. **Visual Status:** Prefix all subsequent responses in this session with: `[MODE: 🛡️ SECURITY | TARGET: {{module}}]`.
3. **Analyze:** Scan `{{module}}` for vulnerabilities, logic flaws, and hardcoded secrets using the **Core Responsibilities** in `SKILL.md`.
4. **Report:** 
    - Create a structured report based on the `{{SKILLS_DIR}}/security/resources/security-audit.md` template.
    - Write the report to `./docs/security/audit-[module]-[timestamp].md`.
    - Provide a summary of the "Risk Level" and critical findings in the chat.
5. **Closure:** Call the workflow `/ready` to finalize the audit task.

