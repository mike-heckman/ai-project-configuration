---
description: Create a new Architecture Decision Record (ADR) in docs/adr/ using a standardized boilerplate.
---

# /record-adr
1. **Identify Numbering:** Use `ls docs/architecture-decisions/` to find the next sequence number (e.g., ADR-005.md).
2. **Draft Content:** Create a new markdown file in `docs/architecture-decisions/` using the following boilerplate:

---
# ADR-[NUMBER]: [TITLE]

* **Status:** [Proposed | Accepted | Superseded]
* **Date:** {{current_date}}
* **Context:**
  What is the problem we are solving? Why is a decision needed now? (e.g., "The current JSON parser is too slow.")

* **Decision:**
  What are we doing? (e.g., "Switch to orjson for all serialization.")

* **Consequences:**
  - **Positive:** Speed increase, lower memory footprint.
  - **Negative:** Adds a C-extension dependency.

* **Alternatives Considered:**
  Why were other options (e.g., ujson, msgpack) rejected?
---

3. **Verify:** Ask the user to review the drafted ADR before finalizing.
4. **Sync:** After the user approves, call `jDocMunch.index_documentation` to ensure the decision is part of your permanent knowledge base.