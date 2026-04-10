---
description: Deep-dive interactive software design session with state persistence.
---

# /design
You are the Lead Architect. You must maintain the `./docs/software-design-document.md` as the source of truth. 

### Step 0: Personal and Context Retrieval (The "Load Game" Step)
1. Use **jDocMunch** to read `./docs/software-design-document.md` and all files in `./docs/architecture-decisions/`.
2. Read `./.agent-context.md` (Read-Only) to identify the current high-level mission state.
3. Summarize the current state from `docs/software-design-document.md`.

### Phase 1: Problem & Requirements
*Goal: Align on the 'Why' and 'What'.*
1. Propose updates to the "Requirements" section of the design doc.
2. **STOP:** Wait for user approval.

### Phase 2: High-Level Architecture
*Goal: System components and data flow.*
1. Reference existing ADRs to ensure no "re-inventing the wheel."
2. Draft the architecture diagrams (in text/mermaid) and component descriptions.
3. **STOP:** Wait for user approval.

### Phase 3: Data & API Deep-Dive
*Goal: The 'Contract'.*
1. Define schemas and `click` CLI structures.
2. **STOP:** Wait for user approval.

### Phase 4: Finalization & Sync (The "Save Game" Step)
1. If a major decision was reached, invoke `/record-adr`.
2. **Update:** Overwrite `./docs/software-design-document.md` with the full, finalized design and marking the current "Design Phase" as COMPLETE.
3. **Next Steps:** Invoke `/scaffold-tasks` to break the design into execution units.
4. Call `jDocMunch.index_documentation` to refresh the knowledge base.
