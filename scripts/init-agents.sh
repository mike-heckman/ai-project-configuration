#!/usr/bin/env bash

set -e

REPO_ROOT="$(dirname $(realpath $(dirname "$0")))"
PLANNER_SRC="${REPO_ROOT}/core-planner"
WORKER_SRC="${REPO_ROOT}/core-worker"

AGENTS_DIR="$(realpath ${HOME}/.agents)"
GEMINI_DIR="$(realpath ${HOME}/.gemini)"
ANTIGRAVITY_DIR="${GEMINI_DIR}/antigravity"

echo "Initializing AI Agent configuration..."

# 1. Setup Host-side Planner (Gemini)
echo "Setting up Planner (Host)..."
mkdir -p "${ANTIGRAVITY_DIR}/global_workflows"
mkdir -p "${GEMINI_DIR}/rules"

# Link Planner rules to Gemini
ln -sf "${PLANNER_SRC}/rules/planner-rules.md" "${GEMINI_DIR}/GEMINI.md"
for rule in "${PLANNER_SRC}/rules/"*; do
    [ -e "$rule" ] || continue
    ln -sf "$rule" "${GEMINI_DIR}/rules/$(basename "$rule")"
done

# Link Planner workflows
for wf in "${PLANNER_SRC}/workflows/"*; do
    [ -e "$wf" ] || continue
    ln -sf "$wf" "${ANTIGRAVITY_DIR}/global_workflows/$(basename "$wf")"
done

# Link Planner skills
rm -rf "${ANTIGRAVITY_DIR}/skills"
ln -sf "${PLANNER_SRC}/skills" "${ANTIGRAVITY_DIR}/skills"

# Link Planner MCP config
ln -sf "${PLANNER_SRC}/mcp_config.json" "${ANTIGRAVITY_DIR}/mcp_config.json"

# Link jcodemunch-mcp central config
mkdir -p "${HOME}/.code-index"
ln -sf "${PLANNER_SRC}/config.jsonc" "${HOME}/.code-index/config.jsonc"

# 2. Setup Worker Configuration (for KVM access)
echo "Setting up Worker configs..."
mkdir -p "${AGENTS_DIR}"
ln -sf "${WORKER_SRC}" "${AGENTS_DIR}/core-worker"

# 3. Setup global Git ignore
echo "Updating global Git ignore..."
PAYLOAD="logs/\ntemp/\npublic-dev/\nextract/\n.agent-worker-env"
GLOBAL_IGNORE=$(git config --get core.excludesfile)
[ -z "$GLOBAL_IGNORE" ] && GLOBAL_IGNORE="$HOME/.config/git/ignore"
mkdir -p "$(dirname "$GLOBAL_IGNORE")"
touch "$GLOBAL_IGNORE"

MARKER_START="# <ANTIGRAVITY_LLM_BYPASS>"
MARKER_END="# </ANTIGRAVITY_LLM_BYPASS>"

if grep -q "$MARKER_START" "$GLOBAL_IGNORE"; then
    sed -i "\:${MARKER_START}:,\:${MARKER_END}:d" "$GLOBAL_IGNORE"
fi
printf "\n$MARKER_START\n$PAYLOAD\n$MARKER_END\n" >> "$GLOBAL_IGNORE"

echo "Initialization complete."
echo "Host (Gemini) is now configured with core-planner rules."
echo "Worker (KVM) rules are linked to ${AGENTS_DIR}/core-worker for KVM mounting."
