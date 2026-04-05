---
description: Deep-dive interactive software design session with state persistence.
---

# /design
You are the Lead Architect. You must maintain the `docs/software-design-document.md` as the source of truth. 

### Step 0: Personal and Context Retrieval (The "Load Game" Step)
1. Use **jDocMunch** to read `~/.gemini/rules/role_architect.md`.
2. Use **jDocMunch** to read `./docs/software-design-document.md` and all files in `./docs/architectural-decisions/`.
3. Read `./.agent-context.md` to find the last recorded "Design Phase."
4. Summarize the current state to the user: "We left off at Phase [X]. Here is the current objective..."

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
2. **Update:** Overwrite `./docs/software-design-document.md` with the full, finalized design.
3. **Update:** Add a "Design Phase Complete" entry to `./.agent-context.md` with a summary of the session.
4. Call `jDocMunch.index_documentation` to refresh the knowledge base.
