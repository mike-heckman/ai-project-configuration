#!/usr/bin/env bash

set -e

SOURCE_DIR="$(dirname $(realpath $(dirname "$0")))/gemini"
GEMINI_DIR="$(realpath ${HOME}/.gemini)" 

if [ ! -d "$SOURCE_DIR" ]; then
    echo "No existing Gemini source directory found at $SOURCE_DIR. Aborting!"
    exit 1
fi

##
## Setup Gemini/Antigravity rules and workflows
##

# Link global rules for Gemini
if [ ! -d "${GEMINI_DIR}" ]; then
    mkdir -p "${GEMINI_DIR}"
fi

# Conditional rules
if [ -d "${GEMINI_DIR}/rules" ]; then
    echo "Existing Gemini rules directory found, removing..."
    rm -rf "${GEMINI_DIR}/rules"
fi
ln -sf "${SOURCE_DIR}/conditional-rules" "${GEMINI_DIR}/rules"

# Global rules
if [ -f "${GEMINI_DIR}/GEMINI.md" ]; then
    echo "Existing global Gemini rules file found, removing..."
    rm -f "${GEMINI_DIR}/GEMINI.md"
fi
ln -sf "${SOURCE_DIR}/global-rules.md" "${GEMINI_DIR}/GEMINI.md"

# Workflows
if [ -d "${GEMINI_DIR}/antigravity/global_workflows" ]; then
    echo "Existing Gemini workflows directory found, removing..."
    rm -rf "${GEMINI_DIR}/antigravity/global_workflows"
fi
ln -sf "${SOURCE_DIR}/global-workflows" "${GEMINI_DIR}/antigravity/global_workflows"

# Document templates
if [ -d "${GEMINI_DIR}/document-templates" ]; then
    echo "Existing Gemini document templates directory found, removing..."
    rm -rf "${GEMINI_DIR}/document-templates"
fi
ln -sf "${SOURCE_DIR}/document-templates" "${GEMINI_DIR}/document-templates"

echo "Gemini initialization complete. Global rules, workflows, and document templates are now linked to ${GEMINI_DIR}."

##
## Setup git global ignore
##

# Using \n for newlines in the payload
PAYLOAD="logs/\ntemp/\npublic-dev/\nextract/"

# 1. Get the path
GLOBAL_IGNORE=$(git config --get core.excludesfile)
[ -z "$GLOBAL_IGNORE" ] && GLOBAL_IGNORE="$HOME/.config/git/ignore"

# 2. Create the directory/file if they don't exist
mkdir -p "$(dirname "$GLOBAL_IGNORE")"
touch "$GLOBAL_IGNORE"

# 3. Markers (escaped for safety)
MARKER_START="# <ANTIGRAVITY_LLM_BYPASS>"
MARKER_END="# </ANTIGRAVITY_LLM_BYPASS>"

if [ -f "$GLOBAL_IGNORE" ] && grep -q "$MARKER_START" "$GLOBAL_IGNORE"; then
    echo "Marker found. Updating..."
    # We use ':' as a delimiter for sed to avoid the '/' in the closing tag
    # This deletes the range including markers
    sed -i "\:${MARKER_START}:,\:${MARKER_END}:d" "$GLOBAL_IGNORE"
fi

# Append the new block
printf "\n$MARKER_START\n$PAYLOAD\n$MARKER_END\n" >> "$GLOBAL_IGNORE"

