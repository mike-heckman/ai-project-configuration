#!/bin/bash
#
# NOTE: This script is hard-linked via the ai-project-configuration/_setup.sh script. 
# Edits to this file should be made in that location to ensure that edits are 
# intentionally applied to the project template and not just the test script.
# Last edit: 2026-04-02 by Mike
#
set -e

if [ -x scripts/_local_run.sh ]; then
    echo "Running local override script..."
    exec scripts/_local_run.sh
fi

# Heuristic check: Look for the root anchor (e.g., .git, package.json, or GEMINI.md)
# This walks up the directory tree until it finds a marker.
get_project_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return
        fi
        dir="$(dirname "$dir")"
    done
    # Fallback to script's parent directory if no marker found
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
}

# Final resolution
PROJECT_ROOT="${PROJECT_ROOT:-${VSCODE_CWD:-$(get_project_root "$PWD")}}"
if [ ! -d "${PROJECT_ROOT}/logs" ]; then
    mkdir -p "${PROJECT_ROOT}/logs"
fi
if [ -f "${PROJECT_ROOT}/logs/run.log" ]; then
    rm -f "${PROJECT_ROOT}/logs/run.log"
fi

uv run python3 main.py 2>&1 | tee "${PROJECT_ROOT}/logs/run.log"
