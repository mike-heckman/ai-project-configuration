---
description: Create a new Architecture Decision Record (ADR) in docs/adr/ using a standardized boilerplate.
---

# /record-adr {{topic}}
1. **Identify Numbering:** Use `ls ./docs/architecture-decisions/ADR-*.md` to find the next sequence number (e.g., ADR-005.md).
2. **Draft Content:** Create a new markdown file in `./docs/architecture-decisions/` using the template in `{{SKILLS_DIR}}/architect/resources/ADR-XXX.md`
3. **Verify:** Ask the user to review the drafted ADR before finalizing.
4. **Next Steps:** Once the user approves, immediately invoke `/scaffold-tasks` to bridge the decision to the execution backlog.