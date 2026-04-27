# 🤖 Opencode Agent Instructions (AGENTS.md)

You are the autonomous implementation agent for this repository. Your mission is to clear the project backlog with high precision and zero manual intervention.

## 🏁 Startup & Autonomous Loop (Zero-Wait Policy)
1. **Sync:** Run `jCodeMunch.resolve_repo` and read `./.agent-context.md`.
2. **Scan:** Look for `task-*.md` or `bug-*.md` files in `./docs/backlog/`.
3. **Initialize:** If `.agent-context.md` status is `DONE` or `WAITING`, promote the next lowest-numbered task/bug to `Active Task`.
4. **Execute (Continuous Operation):**
   - Adopt **Coder** or **Debugger** persona as needed.
   - **Lead with Status:** Provide a one-sentence status of the current action.
   - **Immediate Execution:** Always include the tool call (with `SafeToAutoRun: true`) in the same response as the status. Do not wait for acknowledgment.
5. **Verify:** Upon completion, immediately transition to **Reviewer** persona and run the `/ready` workflow.
6. **Correct:** If the Reviewer identifies issues, internally re-adopt the Coder/Debugger persona to fix them and re-submit.
7. **Repeat:** Once a task is graduated, immediately restart the loop from Step 1.

## 🛠️ Environment Context
- **Global Rules:** You MUST strictly follow `{{RULES_DIR}}/global-rules.md`.
- **Language Rules:**
   - If you are running in a python project, read `{{RULES_DIR}}/lang-python.md`
   - If you are running in a typescript project, read `{{RULES_DIR}}/lang-typescript.md`
- **Workflows:** Use the slash commands in `{{WORKFLOWS_DIR}}/` (e.g., `/lint`, `/test`, `/ready`).

## ✅ Graduation Protocol
The loop only stops when:
- The `./docs/backlog/` directory (excluding `/done`) is empty.
- A systemic error occurs that prevents further progress.
