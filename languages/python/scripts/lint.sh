#!/usr/bin/env bash
#
# NOTE: This script is hard-linked to the ai-project-configuration/scripts/lint.sh script. 
# Do not modify this file. If an override is needed, create a _local_lint.sh
# script in the same directory with the desired changes. 
# Last edit: 2026-04-10 by Mike
#

set -e
set -o pipefail

if [ -x scripts/_local_lint.sh ]; then
    echo "Running local override script..."
    exec scripts/_local_lint.sh
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

# Use script directory as the starting point for root discovery to ensure it works even if run from a different CWD.
PROJECT_ROOT="$(get_project_root "$PWD")"

# Use local configuration files. These should be present in the project root.
export RUFF_CONFIG="${PROJECT_ROOT}/.ruff-master-config.toml"
export PYRIGHT_CONFIG="${PROJECT_ROOT}/.pyrightconfig.json"

if [ ! -d "${PROJECT_ROOT}/logs" ]; then
    mkdir -p "${PROJECT_ROOT}/logs"
fi
LINT_LOG="${PROJECT_ROOT}/logs/lint.log"
if [ -f "${LINT_LOG}" ]; then
    echo "Clearing existing lint log at ${LINT_LOG}" 
    rm -f "${LINT_LOG}"
fi

echo "Verifying multi-line docstring compliance..." | tee -a "${LINT_LOG}"

if grep -rn '""".*"""' src/ --exclude-dir=tests; then
    echo "ERROR: Single-line docstrings are forbidden. Please use 'Tall' format." | tee -a "${LINT_LOG}"
    exit 1
fi

echo "Running Ruff Linter and Import Sorter (auto-fix)..." | tee -a "${LINT_LOG}"
uv run ruff check . --config "$RUFF_CONFIG" --fix  2>&1 | tee -a "${LINT_LOG}"

echo "Running Ruff Formatter..." | tee -a "${LINT_LOG}"
uv run ruff format . --config "$RUFF_CONFIG" 2>&1 | tee -a "${LINT_LOG}"

echo "Running Pyright Type Checker..." | tee -a "${LINT_LOG}"
uv run pyright --project "${PYRIGHT_CONFIG}" 2>&1 | tee -a "${LINT_LOG}"

echo "Completed successfully at $(date)" | tee -a "${LINT_LOG}"
