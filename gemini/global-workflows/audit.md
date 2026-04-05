---
description: Run an adversarial security audit on a specific module.
---
# /audit {{module}}
1. **Persona Load:** Read `~/.gemini/rules/role_security.md` via `jDocMunch`.
2. **Visual Status:** Prefix all subsequent responses in this session with: `[MODE: 🛡️ SECURITY AUDIT | TARGET: {{module}}]`.
3. **Analyze:** Scan {{module}} for OWASP vulnerabilities and logic flaws.
4. **Report:** Provide a "Threat Report" with remediation steps.

