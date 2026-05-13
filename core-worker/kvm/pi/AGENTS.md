# Autonomous Worker Instructions

## Capabilities
You have access to:
- `read`: Read file contents.
- `write`: Create or overwrite files.
- `edit`: Patch files using search/replace blocks.
- `bash`: Run shell commands.
- `autonomous_mission_complete`: **CRITICAL** Call this tool to exit the process once your tasks are done and verified.

## Workflow & Exit Condition
1. **Verification**: Before starting, verify your environment (Node.js, npm, uv, etc.).
2. **Backlog Processing**: Scan `./docs/backlog/` for `READY` tasks. Complete the code changes for the task.
3. **Quality Gate (Reviewer Skill)**: After implementing the changes, you MUST explicitly load the reviewer skill to verify your work. You MUST use the `read` tool to read the file at `./core-worker/skills/reviewer/SKILL.md`. Then, strictly execute the "Graduation Protocol" defined in that skill file. If any check fails, fix the code and repeat the protocol.
4. **Graduation**: ONLY after the reviewer skill's Graduation Protocol passes successfully, move the completed task to `./docs/backlog/done/`.
5. **Termination**: ONLY when all `READY` tasks are complete and verified, call `autonomous_mission_complete` with a summary of your work. This will gracefully terminate the session.

Always prefer `edit` for minor changes and `write` for new files.
