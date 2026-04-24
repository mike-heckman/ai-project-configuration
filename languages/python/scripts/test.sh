#!/usr/bin/env bash
#
# NOTE: This script is hard-linked to the ai-project-configuration/scripts/test.sh script. 
# Do not modify this file. If an override is needed, create a _local_test.sh
# script in the same directory with the desired changes. 
# Last edit: 2026-04-10 by Mike
#
set -e

if [ -x scripts/_local_test.sh ]; then
    echo "Running local override script..."
    exec scripts/_local_test.sh
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

# Defines the install location of the project template, which is used for sourcing shared functions and configs.
source "${PROJECT_ROOT}/../.ai_config_root.sh"

# 1. Gather Metadata
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "not-a-git-repo")
REPORT_FILE="${PROJECT_ROOT}/coverage.md"
TEMP_FILE="${PROJECT_ROOT}/logs/coverage_raw.md"
TEST_LOG="${PROJECT_ROOT}/logs/test.log"

echo "Running tests and generating coverage..."

if [ ! -d "${PROJECT_ROOT}/logs" ]; then
    mkdir -p "${PROJECT_ROOT}/logs"
fi
if [ -f "${TEMP_FILE}" ]; then
    rm -f "${TEMP_FILE}"
fi

LOC=$(find "${PROJECT_ROOT}" -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/.venv/*" -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
LOC=${LOC:-0}

if [ "$LOC" -lt 50 ]; then
    echo "Project has less than 50 lines of code ($LOC LOC). Bypassing coverage threshold."
    ARGS=(--cov=.)
else
    ARGS=(--cov=. --cov-fail-under=80)
fi
GENERATE_REPORT=false
if [ -n "$1" ]; then
    if [ "$1" == "--pre-commit" ]; then
        echo "Running pre-commit tests with coverage report in terminal..."
        ARGS+=(--cov-report=term-missing)
    else
        echo "Running only selected tests without coverage via additional arguments: $@"
        ARGS=("$@")
        if [ -e "${REPORT_FILE}" ]; then
            # Remove report to prevent confusion with a stale coverage report.
            rm -f "${REPORT_FILE}"
        fi
    fi
else
    echo "Running full test suite with coverage report generation..."
    ARGS+=(--cov-report=markdown:$TEMP_FILE)
    GENERATE_REPORT=true
fi

# 2. Run tests and generate raw markdown coverage
# Using --cov-report=markdown:DEST requires pytest-cov 6.3.0+
set +e
uv run pytest "${ARGS[@]}" 2>&1 | tee "${TEST_LOG}"
TEST_EXIT_CODE=${PIPESTATUS[0]}
set -e

if [ $TEST_EXIT_CODE -eq 0 ] && [ -x "scripts/verify.sh" ]; then
    echo "Running verification script..."
    scripts/verify.sh
fi

# 3. Create final report with custom Header
if [ $GENERATE_REPORT = true ]; then
    cat << EOF > $REPORT_FILE
# Test Coverage Report

- **Date:** $CURRENT_DATE
- **Branch:** \`$CURRENT_BRANCH\`
- **Status:** $( [ $TEST_EXIT_CODE -eq 0 ] && echo "PASS" || echo "FAIL" )

$(cat "$TEMP_FILE" 2>/dev/null || echo "No coverage data generated.")
EOF
    # 4. Cleanup
    if [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi

    echo "Coverage REPORT_LOCATION: ${REPORT_FILE}"
fi

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo "Tests failed with exit code $TEST_EXIT_CODE. Check ${TEST_LOG} for details."
else
    echo "Completed successfully at $(date)" | tee -a "${TEST_LOG}"
fi
exit $TEST_EXIT_CODE