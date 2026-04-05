---
description: Create a new Architecture Decision Record (ADR) in docs/adr/ using a standardized boilerplate.
---

# /record-adr
1. **Identify Numbering:** Use `ls docs/architecture-decisions/` to find the next sequence number (e.g., ADR-005.md).
2. **Draft Content:** Create a new markdown file in `docs/architecture-decisions/` using the following boilerplate:

---
# ADR-[NUMBER]: [Discreet Title of Change]

* **Status:** [Proposed | Accepted | Implemented | Superseded | Refused | Deferred]
* **Date:** {{current_date}} (Initial) / {{completion_date}} (Completed)
* **Corpus/Module:** [e.g., icarus-calculator: src/icarus_calculator/registry.py]

## 📋 Context
What is the technical or architectural problem we are solving? Why is a decision needed now? Describe the "Status Quo" and any identified risks (e.g., "The `DataGenerator` complexity score is 45, making it a high-risk hotspot.").

## 🎯 Decision
What specific action are we taking? Define the "Definition of Done" for this decision (e.g., "Extract all row formatting into `_format_row` sub-methods to reduce complexity to < 15.").

## ⚖️ Consequences
- **Positive:** [e.g., Improved testability, lower maintenance cost, clear separation of concerns.]
- **Negative:** [e.g., Increased method count, slight performance overhead for extra calls.]

## 🔄 Alternatives Considered
Briefly list alternative technical paths and why they were rejected (e.g., "Functional programming approach rejected for consistency with the existing Class-based architecture.").

## ✅ Summary of Result
*Update this section ONLY when the ADR transitions to 'Implemented'.*
- **Action Taken:** [e.g., Refactored 9 methods across 4 modules.]
- **Key Metrics:** [e.g., Complexity reduced from 40 to 12; test coverage maintained at 81%.]
- **Verification:** [e.g., All unit and regression tests passed (Exit 0).]
---

3. **Verify:** Ask the user to review the drafted ADR before finalizing.
4. **Sync:** After the user approves, call `jDocMunch.index_documentation` to ensure the decision is part of your permanent knowledge base.