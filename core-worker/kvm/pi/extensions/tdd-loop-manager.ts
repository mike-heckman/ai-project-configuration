import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { execSync } from "node:child_process";

enum TDDState {
  STEP_0_START_TASK = 0,
  STEP_1_VERIFY_CURRENT_TESTS = 1,
  STEP_2_BUILD_NEW_TESTS = 2,
  STEP_3_VERIFY_NEW_TESTS_FAIL = 3,
  STEP_4_MAKE_CHANGES_SUCCEED = 4,
  STEP_5_HANDOFF = 5,
  STEP_6_REVIEW_LINT = 6,
  STEP_7_REVIEW_TESTS = 7,
  STEP_8_REVIEW_COVERAGE = 8,
  STEP_9_FAIL_RETURN = 9,
  STEP_10_DONE = 10
}

interface StateData {
  currentState: TDDState;
  cutoffMarkerId: string | null;
  pendingCutoff: boolean;
  activeTaskFile: string | null;
}

const STATE_FILE = "/workspace/.tdd-state.json";

function loadState(): StateData {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, "utf-8"));
    }
  } catch (e) {
    console.error("Failed to load TDD state:", e);
  }
  return {
    currentState: TDDState.STEP_0_START_TASK,
    cutoffMarkerId: null,
    pendingCutoff: false,
    activeTaskFile: null
  };
}

function saveState(state: StateData) {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  } catch (e) {
    console.error("Failed to save TDD state:", e);
  }
}

function getStepInstructions(state: TDDState): string {
  switch (state) {
    case TDDState.STEP_0_START_TASK:
      return "STEP 0: Assume Coder/Debugger role. Check for task files in `./docs/backlog/`. Only process files that explicitly contain `status: READY`. Ignore any tasks with no status, or statuses like `IN_PROGRESS` or `COMPLETED`. If no READY tasks exist, the mission is COMPLETE—report final status and end the session. If tasks exist, read the most urgent one, and call `advance_tdd_step` when you have understood it.";
    case TDDState.STEP_1_VERIFY_CURRENT_TESTS:
      return "STEP 1: Verify current tests are working by running `/test`. Call `advance_tdd_step` once verified.";
    case TDDState.STEP_2_BUILD_NEW_TESTS:
      return "STEP 2: Build new tests for the new functionality or bug. Write the test code. Call `advance_tdd_step` when the tests are written.";
    case TDDState.STEP_3_VERIFY_NEW_TESTS_FAIL:
      return "STEP 3: Verify the new tests fail (TDD Red) by running `/test`. Call `advance_tdd_step` once confirmed they fail.";
    case TDDState.STEP_4_MAKE_CHANGES_SUCCEED:
      return "STEP 4: Make code changes so that ALL tests succeed (TDD Green). Run `/test` to verify. Call `advance_tdd_step` when they pass.";
    case TDDState.STEP_5_HANDOFF:
      return "STEP 5: Handoff to Reviewer. Call `advance_tdd_step` with a comprehensive summary of your changes to be recorded in the task file.";
    case TDDState.STEP_6_REVIEW_LINT:
      return "STEP 6 [REVIEWER]: Verify that linting passes by running `/lint`. If it passes, check off relevant items in the task file and call `advance_tdd_step` with action='next'. If it fails, do NOT check off failed items and call `advance_tdd_step` with action='fail_review'.";
    case TDDState.STEP_7_REVIEW_TESTS:
      return "STEP 7 [REVIEWER]: Verify that all tests succeed by running `/test`. If it passes, check off relevant items in the task file and call `advance_tdd_step` with action='next'. If it fails, do NOT check off failed items and call `advance_tdd_step` with action='fail_review'.";
    case TDDState.STEP_8_REVIEW_COVERAGE:
      return "STEP 8 [REVIEWER]: Verify test coverage meets the minimum required. If it passes, check off relevant items in the task file and call `advance_tdd_step` with action='next'. If it fails, do NOT check off failed items and call `advance_tdd_step` with action='fail_review'.";
    case TDDState.STEP_9_FAIL_RETURN:
      return "STEP 9: The Reviewer rejected the work. Call `advance_tdd_step` to handoff back to the Coder with feedback appended to the task file. Ensure that any items that failed review remain UNCHECKED in the task file.";
    case TDDState.STEP_10_DONE:
      return "STEP 10 [REVIEWER]: The task is complete. 1. Update the `status` field in the task file to `COMPLETED`. 2. Move the task file to `./docs/backlog/done/`. 3. Call `advance_tdd_step` with action='next' to finish, commit changes, and check for the next task.";
    default:
      return "UNKNOWN STEP. Call advance_tdd_step.";
  }
}

export default function (pi: ExtensionAPI) {
  let state = loadState();

  pi.on("before_agent_start", async (event, ctx) => {
    // Inject the TDD State Machine instructions into the system prompt
    state = loadState();

    const isReviewer = state.currentState >= 6 && state.currentState <= 8;
    const persona = isReviewer ? "REVIEWER" : "CODER/DEBUGGER";

    // Auto-detect languages and load rules
    const rulesDir = path.join(os.homedir(), ".pi", "agent", "rules");
    let detectedLangs = [];
    let additiveRules = "";

    if (fs.existsSync("/workspace/.python-version") || fs.existsSync("/workspace/pyproject.toml") || fs.existsSync("/workspace/requirements.txt")) {
      detectedLangs.push("Python");
      const pythonRules = path.join(rulesDir, "lang_python.md");
      if (fs.existsSync(pythonRules)) {
        additiveRules += `\n### PYTHON RULES:\n${fs.readFileSync(pythonRules, "utf8")}\n`;
      }
    }

    if (fs.existsSync("/workspace/package.json") || fs.existsSync("/workspace/tsconfig.json")) {
      detectedLangs.push("TypeScript/JavaScript");
      const tsRules = path.join(rulesDir, "lang_typescript.md");
      if (fs.existsSync(tsRules)) {
        additiveRules += `\n### TYPESCRIPT/JAVASCRIPT RULES:\n${fs.readFileSync(tsRules, "utf8")}\n`;
      }
    }

    const langInfo = detectedLangs.length > 0
      ? `Project Environment: **${detectedLangs.join(" + ")}**`
      : "Project Environment: **General**";

    const injection = `
=========================================
🔥 TDD ORCHESTRATOR OVERRIDE ACTIVE 🔥
=========================================
You are currently operating as the **${persona}**.
Current TDD State: **${TDDState[state.currentState]}**
${langInfo}

**MANDATORY INSTRUCTIONS FOR THIS STEP:**
${getStepInstructions(state.currentState)}

${additiveRules}

You MUST execute the tool \`advance_tdd_step\` when you complete the requirements of this step. Do NOT proceed to the next conceptual step until you have called \`advance_tdd_step\` and received confirmation.
=========================================
`;

    return {
      systemPrompt: injection + "\n" + event.systemPrompt,
    };
  });

  pi.on("context", async (event, ctx) => {
    // Handle context pruning for "clean slate" on role transition
    if (state.pendingCutoff) {
      if (event.messages.length >= 2) {
        // We set the cutoff ID to the assistant message that made the tool call.
        // This drops everything before the handoff, giving the new role a clean slate.
        const assistantMsg = event.messages[event.messages.length - 2];
        state.cutoffMarkerId = assistantMsg.id;
        state.pendingCutoff = false;
        saveState(state);
      }
    }

    if (state.cutoffMarkerId) {
      const idx = event.messages.findIndex(m => m.id === state.cutoffMarkerId);
      if (idx !== -1) {
        const filtered = event.messages.filter((m, i) => m.type === "system" || i >= idx);
        return { messages: filtered };
      }
    }
  });

  pi.registerTool({
    name: "advance_tdd_step",
    label: "Advance TDD Step",
    description: "Advances the TDD state machine to the next step. If you are handing off or failing a review, provide the taskFilePath and a summaryOrFeedback to record it.",
    parameters: Type.Object({
      action: Type.String({ description: "'next' to advance to the next step, 'fail_review' to reject the code (Reviewer only)." }),
      taskFilePath: Type.Optional(Type.String({ description: "Path to the active task file (e.g. ./docs/backlog/task-0001.md). Required for handoffs/failures." })),
      summaryOrFeedback: Type.Optional(Type.String({ description: "Summary or feedback to append to the task file. Required for handoffs/failures." })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      state = loadState();

      // Handle Git Branching at Step 0
      if (state.currentState === TDDState.STEP_0_START_TASK && params.taskFilePath) {
        state.activeTaskFile = params.taskFilePath;
        try {
          const branch = execSync("git rev-parse --abbrev-ref HEAD", { cwd: "/workspace" }).toString().trim();
          const dateStr = new Date().toISOString().split('T')[0].replace(/-/g, '');

          // If on main/master, pull latest changes before branching
          if (branch === "main" || branch === "master") {
            try {
              execSync("git pull", { cwd: "/workspace" });
              ctx.ui.notify("Pulled latest changes from main", "info");
            } catch (e) {
              ctx.ui.notify("Failed to git pull", "warning");
            }
          }

          // If on main/master, or on a legacy task branch, switch to the daily branch
          if (branch === "main" || branch === "master" || branch.startsWith("task/")) {
            if (branch !== dateStr) {
              try {
                // Try to checkout existing daily branch
                execSync(`git checkout ${dateStr}`, { cwd: "/workspace", stdio: 'ignore' });
                ctx.ui.notify(`Switched to daily branch: ${dateStr}`, "success");
              } catch (e) {
                // Create new daily branch
                execSync(`git checkout -b ${dateStr}`, { cwd: "/workspace" });
                ctx.ui.notify(`Created daily branch: ${dateStr}`, "success");
              }
            }
          }
        } catch (e) {
          // git operations might fail if not a git repo, ignore
        }
      }

      let previousState = state.currentState;

      // Handle Fail Review
      if (params.action === "fail_review" && state.currentState >= 6 && state.currentState <= 8) {
        state.currentState = TDDState.STEP_9_FAIL_RETURN;
      }
      // Handle Next
      else if (params.action === "next") {
        if (state.currentState === TDDState.STEP_10_DONE) {
          state.currentState = TDDState.STEP_0_START_TASK;
          state.activeTaskFile = null;
        } else if (state.currentState < TDDState.STEP_10_DONE) {
          if (state.currentState === TDDState.STEP_9_FAIL_RETURN) {
            state.currentState = TDDState.STEP_0_START_TASK;
          } else {
            state.currentState++;
          }
        }
      }

      const isRoleChange =
        (previousState === TDDState.STEP_5_HANDOFF && state.currentState === TDDState.STEP_6_REVIEW_LINT) ||
        (previousState === TDDState.STEP_9_FAIL_RETURN && state.currentState === TDDState.STEP_0_START_TASK);

      if (isRoleChange) {
        state.pendingCutoff = true;

        if (params.taskFilePath && params.summaryOrFeedback) {
          try {
            const absolutePath = path.resolve("/workspace", params.taskFilePath);
            let content = fs.readFileSync(absolutePath, "utf-8");
            const heading = previousState === TDDState.STEP_5_HANDOFF ? "## Coder Handoff Summary" : "## Reviewer Feedback";
            content += `\n\n${heading}\n${params.summaryOrFeedback}\n`;
            fs.writeFileSync(absolutePath, content);
            ctx.ui.notify(`Appended notes to ${params.taskFilePath}`, "info");
          } catch (e) {
            ctx.ui.notify(`Failed to append to task file: ${e}`, "error");
          }
        }
      }

      // Handle Git Commit at Done
      if (state.currentState === TDDState.STEP_10_DONE) {
        try {
          execSync("git add .", { cwd: "/workspace" });
          const taskId = state.activeTaskFile ? path.basename(state.activeTaskFile, ".md") : "unknown-task";
          execSync(`git commit -m "Completed ${taskId}"`, { cwd: "/workspace" });
          ctx.ui.notify(`Changes committed for ${taskId}`, "success");
        } catch (e) {
          ctx.ui.notify(`Failed to commit changes`, "warning");
        }
      }

      saveState(state);

      return {
        content: [{ type: "text", text: `Advanced from ${TDDState[previousState]} to ${TDDState[state.currentState]}. Role change: ${isRoleChange}. New instructions will be provided in the next system prompt.` }],
        details: { state: TDDState[state.currentState] }
      };
    }
  });
}
