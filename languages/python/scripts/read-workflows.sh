#!/usr/bin/env bash
#
# Helper script to discover and list all active workflows.
# Satisfies the MANDATORY session initialization requirements.
#

set -e

echo "--- Global Workflows (~/.gemini) ---"
if [ -d "${HOME}/.gemini/antigravity/global_workflows" ]; then
    ls -F "${HOME}/.gemini/antigravity/global_workflows"
fi

echo -e "\n--- Specialist Skills (~/.gemini) ---"
if [ -d "${HOME}/.gemini/antigravity/skills" ]; then
    ls -F "${HOME}/.gemini/antigravity/skills"
fi

echo -e "\n--- Project Local Skills and Workflows ---"
ls -FR .agents/workflows/ .agents/skills/
