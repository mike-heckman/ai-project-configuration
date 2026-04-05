#!/bin/bash
#
# NOTE: This script is hard-linked via the .model/.python/_setup.sh script. 
# Edits to this file should be made in that location to ensure that edits are 
# intentionally applied to the project template and not just the test script.
# Last edit: 2026-04-02 by Mike
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

# Final resolution
PROJECT_ROOT="${PROJECT_ROOT:-${VSCODE_CWD:-$(get_project_root "$PWD")}}"

# Defines the install location of the project template, which is used for sourcing shared functions and configs.
source "${PROJECT_ROOT}/../.project_template_dir.sh"

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

ARGS=(--cov=. --cov-fail-under=80)
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
exit $TEST_EXIT_CODE