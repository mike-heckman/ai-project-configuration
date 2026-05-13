import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  let missionComplete = false;

  pi.registerTool({
    name: "autonomous_mission_complete",
    label: "Autonomous Mission Complete",
    description: "Call this tool ONLY when you have finished your current task, verified it with linting and tests, and confirmed there are no more READY tasks in the backlog. This will gracefully terminate the agent process.",
    parameters: Type.Object({
      summary: Type.String({ description: "A detailed summary of all tasks completed and verification results." }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      missionComplete = true;
      ctx.ui.notify("Mission complete! Shutting down...", "success");

      // Reset TDD state for next session
      try {
        const fs = require("node:fs");
        const STATE_FILE = "/workspace/.tdd-state.json";
        if (fs.existsSync(STATE_FILE)) {
          const state = JSON.parse(fs.readFileSync(STATE_FILE, "utf-8"));
          state.currentState = 0; // TDDState.STEP_0_START_TASK
          state.activeTaskFile = null;
          fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
        }
      } catch (e) {
        // Ignore if TDD extension not in use
      }

      // Request shutdown and force exit after a short delay
      ctx.shutdown();
      setTimeout(() => {
        process.exit(0);
      }, 1000);

      return {
        content: [{ type: "text", text: "Mission complete. Shutdown requested." }],
        details: { summary: params.summary },
      };
    },
  });

  // Nudge the agent if it stops without calling the exit tool
  pi.on("agent_end", async (event, ctx) => {
    if (missionComplete) return;

    ctx.ui.notify("Agent stalled without completion. Nudging to continue...", "warning");
    pi.sendUserMessage(
      "You stopped without calling the `autonomous_mission_complete` tool. As an autonomous worker, you must continue working until the task is completely verified and finished. If you are waiting on a process, use tools to check its status. If you are fully done, you MUST call the `autonomous_mission_complete` tool.",
      { streamingBehavior: "followUp" }
    );
  });
}
