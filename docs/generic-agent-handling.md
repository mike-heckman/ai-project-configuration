Ran command: `./scripts/read-workflows.sh`
Used MCP tool: jcodemunch/index_folder
Used MCP tool: jcodemunch/get_file_tree
Viewed output.txt
Viewed init-gemini.sh:1-120
Viewed init-py-project.sh:1-113
Listed directory ai-project-configuration
Listed directory gemini
Listed directory conditional-rules
Viewed global-rules.md:1-54

Here is my feedback and architectural suggestions for adapting your current "installation primary" project to support multiple AI vendors (Antigravity/Gemini, Cursor, Claude, Copilot/Codex) from a single source of truth.

### 1. Assessment of the Current Architecture
Right now, your source of truth is tightly coupled to Gemini. 
*   **Directory Structure:** You have a `gemini/` directory containing `global-workflows/`, `skills/`, and `global-rules.md`.
*   **Hardcoded Paths:** Files like `global-rules.md` explicitly reference `~/.gemini/rules/lang_python.md` and `jCodeMunch`/`jDocMunch` (MCP servers specific to your current environment).
*   **Distribution Strategy:** `init-gemini.sh` hardlinks these files into global directories (`~/.gemini/antigravity/`), which is a paradigm not natively supported by all AI agents (e.g. Cursor relies heavily on project-local `.cursorrules` and `.cursor/rules/`).

### 2. Proposed "Universal Agent" Architecture
To prevent state-drift and support a multi-agent environment, you want an architecture where workflows and rules sit in an **agnostic core** and are dynamically "rendered" or "adapted" for each target agent via initialization scripts.

```text
ai-project-configuration/
├── core/                       # (Formerly 'gemini/') Agnostic source of truth
│   ├── rules/                  # Base global and language rules
│   ├── skills/                 # Personas and boundaries
│   ├── workflows/              # Standardized workflows (/test, /run)
│   └── document-templates/     # task-XXXX.md, etc.
├── agents/                     # Agent-specific adapters & templates
│   ├── gemini/
│   │   └── adapter.sh          # Handles ~/.gemini linking
│   ├── cursor/
│   │   └── adapter.sh          # Renders markdown into .cursor/rules/*.mdc
│   ├── opencode/
│   │   └── adapter.sh          # Renders into opencode context files
│   └── copilot/
│       └── adapter.sh          # Concatenates rules for .github/copilot-instructions.md
├── scripts/
│   ├── init-workspace.sh       # Interactively triggers relevant adapters
│   └── template_processor.py   # Helper to render {{PLACEHOLDERS}} into final files
└── ...
```

### 3. Implementation Suggestions

#### A. Implement a Lightweight Templating System
Because each agent expects different contexts, you cannot use hardcoded paths. You should replace hardcoded strings in your markdown files with agnostic placeholders. For example, in `global-rules.md`:
*   *Current:* `Follow ~/.gemini/rules/lang_python.md`
*   *Future:* `Follow {{AGENT_RULES_DIR}}/lang_python.md`

A simple python or `envsubst` bash script can take the `core/` files, inject the correct variables based on the target agent, and output the customized files.

#### B. Accommodate Different "Ingestion" Methods
Not all agents understand rules in the same way. Your "adapters" will need to bridge the gap:
*   **Antigravity/Gemini:** Can continue using the global `~/.gemini` directory structure. The adapter handles variable injection and symlinking.
*   **Cursor:** Cursor relies on `.mdc` files in a `.cursor/rules/` directory per-project. Your `cursor/adapter.sh` would take the core workflows and skills, inject frontmatter constraints (e.g., `globs: *`, `description: ...`), and symlink them into the project workspace during the `init-py-project.sh` phase.
*   **Copilot/Codex:** Expects heavily condensed instructions. The adapter might concatenate the most critical rules into a single `.github/copilot-instructions.md`.
*   **Opencode:** Using Opencode, the adapter might orchestrate custom tools or generate an `.opencode.json` configuration prioritizing specific workflows.

#### C. Handling Multi-Agent Concurrency
To allow a developer to use Cursor (for inline autocomplete and local editing) alongside Gemini (for heavy lifting/research/planning) on the same project:
1.  **Isolated Rule Ingestion:** By running both `cursor/adapter.sh` and `gemini/adapter.sh` during project configuration, Cursor gets its local `.cursor/` folder while Gemini reads from its global config. They won't step on each other's toes.
2.  **Universal State Tracking:** Ensure the `.agent-context.md` file remains completely agent-agnostic. All agents should be instructed to read from and write state to this exact same file. This allows Gemini to set the "Active Task" and Cursor to read it and know exactly what the current mission is.
3.  **Command Discrepancies:** Some agents struggle with the arbitrary "slash command" syntax (e.g., `/test`). In your adapters, you can tweak the triggers. For Cursor `.mdc` files, the command might be transformed into a natural language trigger like "When the user asks to test the project, follow the test workflow...".

### 4. Next Steps for Refactoring
If you decide to proceed with this architecture, the iterative progression would look like:
1. Rename `gemini/` to `core/` and genericize the content inside the markdown documents.
2. Build a simple `template_processor` (either bash or python) to replace variables like `{{AGENT_CONFIG_DIR}}`.
3. Break the current `scripts/init-gemini.sh` logic into a new `agents/gemini/adapter.sh` that leverages the template processor.
4. Add the second adapter (e.g., `agents/cursor/adapter.sh`) to prove the templating model works.
5. Update `scripts/init-py-project.sh` to allow the user to define which AI adapters to install into the local directory workspace.