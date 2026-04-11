#!/usr/bin/env bash
#
# NOTE: This script is hard-linked to the ai-project-configuration/scripts/clean.sh script. 
# Do not modify this file.
# Last edit: 2026-04-10 by Mike
#

set -e

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

# Final resolution: Prefer manual override, then local discovery, then VSCODE_CWD
PROJECT_ROOT="${PROJECT_ROOT:-$(get_project_root "$PWD")}"

TEMP_DIR="${PROJECT_ROOT}/temp"
if [ -d "$TEMP_DIR" ]; then
    echo "Removing temp directory contents..."
    rm -rf "$TEMP_DIR"/*
else
    echo "Temp directory does not exist. Creating temp directory..."
    mkdir -p "$TEMP_DIR"
fi


if [ "$(ls -A "$TEMP_DIR" | wc -l)" -eq 0 ]; then
    echo "Temp folder is now empty."
else
    echo "Failed to clean temp folder. Current contents:"
    ls -la "$TEMP_DIR"
fi
