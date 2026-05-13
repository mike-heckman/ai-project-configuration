#!/usr/bin/env bash

set -e

REPO_ROOT="$(dirname $(dirname $(realpath "$0")))"
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


hardlink_directory() {
    local src="${1}"
    local dest="${2}"

    mkdir -p "${dest}"
    # Use cp -al with the /. trick to merge contents and hardlink files recursively
    cp -al "${src}/." "${dest}/"
}

link_if_missing_or_not_hardlink() {
    local src="${1}"
    local dest="${2}"

    if [ -L "${dest}" ]; then
        rm -f "${dest}"
    fi
    if [ ! -e "${dest}" ]; then
        if [ -d "${src}" ]; then
            hardlink_directory "${src}" "${dest}"
        else
            ln "${src}" "${dest}"
        fi
    fi    
}

ensure_git_ignore_value() {
    local value="$1"
    local file_path="${2:-.gitignore}"

    # Create file if missing
    if [ ! -f "$file_path" ]; then
        touch "$file_path"
    fi

    # Check for exact match using grep -Fxq.
    if grep -Fxq "$value" "$file_path"; then
        return 0
    fi

    # Handle trailing newline issues before appending.
    if [ -s "$file_path" ] && [ "$(tail -c 1 "$file_path" | wc -l)" -eq 0 ]; then
        echo "" >> "$file_path"
    fi

    echo "$value" >> "$file_path"
}


# Link Planner rules to Gemini
[ -L "${GEMINI_DIR}/GEMINI.md" ] && rm -f "${GEMINI_DIR}/GEMINI.md"
if [ ! -f "${GEMINI_DIR}/GEMINI.md" ]; then
   ln "${PLANNER_SRC}/rules/planner-rules.md" "${GEMINI_DIR}/GEMINI.md"
fi

hardlink_directory "${PLANNER_SRC}/rules" "${GEMINI_DIR}/rules"
# Link Planner workflows
hardlink_directory "${PLANNER_SRC}/workflows" "${ANTIGRAVITY_DIR}/global_workflows"
# Link Planner skills
hardlink_directory "${PLANNER_SRC}/skills" "${ANTIGRAVITY_DIR}/skills"

# Link Planner MCP config
link_if_missing_or_not_hardlink "${PLANNER_SRC}/mcp_config.json" "${ANTIGRAVITY_DIR}/mcp_config.json"

# Link jcodemunch-mcp central config
mkdir -p "${HOME}/.code-index"
link_if_missing_or_not_hardlink "${PLANNER_SRC}/config.jsonc" "${HOME}/.code-index/config.jsonc"


# 2. Setup Worker Configuration (for KVM access)
echo "Setting up Worker configs in ${AGENTS_DIR}/pi..."
[ -L "${AGENTS_DIR}/pi" ] && rm -f "${AGENTS_DIR}/pi"
mkdir -p "${AGENTS_DIR}/pi" "${AGENTS_DIR}/registered"

# Hardlink the bootstrapper
link_if_missing_or_not_hardlink "${WORKER_SRC}/kvm/guest-init.sh" "${AGENTS_DIR}/pi/guest-init.sh"

# Cleanup old core-worker directories
[ -d "${AGENTS_DIR}/core-worker" ] && rm -rf "${AGENTS_DIR}/core-worker"

# Populate Pi directory contents
echo "Setting up Pi directory..."
link_if_missing_or_not_hardlink "${PLANNER_SRC}/mcp_config.json" "${AGENTS_DIR}/pi/mcp.json"
# Restore template link first as it is required by the bridge
hardlink_directory "${WORKER_SRC}/templates" "${AGENTS_DIR}/pi/templates"

for source in "${WORKER_SRC}/kvm/pi/"*; do
    base=$(basename "$source")
    dest="${AGENTS_DIR}/pi/$base"

    if [ -d "${source}" ]; then
        hardlink_directory "${source}" "${dest}"
    else
        link_if_missing_or_not_hardlink "${source}" "${dest}"
    fi
done

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

# Create the private AI environment info
VM_ENV="${AGENTS_DIR}/pi/.env"
if [ ! -e "${VM_ENV}" ]; then
   DATETIME=$(date -Iseconds)
   sed -e "s|{{DATETIME}}|${DATETIME}|g" "${REPO_ROOT}/core-worker/templates/vm-env.template" > "${VM_ENV}"
fi

echo "Initialization complete."
echo "Host (Gemini) is now configured with core-planner rules."
echo "Worker (KVM) rules are linked to ${AGENTS_DIR}/pi for KVM mounting."
