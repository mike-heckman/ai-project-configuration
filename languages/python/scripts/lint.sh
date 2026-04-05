#!/usr/bin/env bash
#
# NOTE: This script is hard-linked via the ai-project-configuration/_setup.sh script. 
# Edits to this file should be made in that location to ensure that edits are 
# intentionally applied to the project template and not just the test script.
# Last edit: 2026-04-02 by Mike
#

set -e

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

# Final resolution
PROJECT_ROOT="${PROJECT_ROOT:-${VSCODE_CWD:-$(get_project_root "$PWD")}}"

# Defines the install location of the project template, which is used for sourcing shared functions and configs.
source "${PROJECT_ROOT}/../.project_template_dir.sh"

# Copying the configuration to the project root allows it to be checked into git with the project.
export RUFF_CONFIG="${PROJECT_ROOT}/.ruff-master-config.toml"
export SOURCE_RUFF_CONFIG="${PROJECT_TEMPLATE_DIR}/ruff-master-config.toml"
if [ -f "$SOURCE_RUFF_CONFIG" ]; then
    cp -a "$SOURCE_RUFF_CONFIG" "$RUFF_CONFIG"
fi

export PYRIGHT_CONFIG="${PROJECT_ROOT}/.pyrightconfig.json"
export PYRIGHT_SOURCE_CONFIG="${PROJECT_TEMPLATE_DIR}/pyright-master-config.json"
if [ -f "$PYRIGHT_SOURCE_CONFIG" ]; then
    cp -a "$PYRIGHT_SOURCE_CONFIG" "${PYRIGHT_CONFIG}"
fi

if [ ! -d "${PROJECT_ROOT}/logs" ]; then
    mkdir -p "${PROJECT_ROOT}/logs"
fi
LINT_LOG="${PROJECT_ROOT}/logs/lint.log"
if [ -f "${LINT_LOG}" ]; then
    echo "Clearing existing lint log at ${LINT_LOG}" 
    rm -f "${LINT_LOG}"
fi

echo "Verifying multi-line docstring compliance..."
touch "${LINT_LOG}"
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
