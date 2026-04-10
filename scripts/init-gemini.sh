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

# Workflows & Skills
WORKFLOWS_DIR="${GEMINI_DIR}/antigravity/global_workflows"
if [ ! -d "${WORKFLOWS_DIR}" ]; then
    mkdir -p "${WORKFLOWS_DIR}"
fi

# Hardlink global baseline workflows
if [ -d "${SOURCE_DIR}/global-workflows" ]; then
    for workflow in "${SOURCE_DIR}/global-workflows/"*.md; do
        [ -e "$workflow" ] || continue
        BASE_WORKFLOW="$(basename "$workflow")"
        if [ -f "${WORKFLOWS_DIR}/${BASE_WORKFLOW}" ]; then
            echo "Existing Gemini workflow ${BASE_WORKFLOW} found, removing..."
            rm -f "${WORKFLOWS_DIR}/${BASE_WORKFLOW}"
        fi
        ln -f "$workflow" "${WORKFLOWS_DIR}/${BASE_WORKFLOW}"
    done
fi

# Hardlink nested skill workflows
SKILLS_DIR="${GEMINI_DIR}/antigravity/skills"
if [ ! -d "${SKILLS_DIR}" ]; then
    mkdir -p "${SKILLS_DIR}"
fi

if [ -d "${SOURCE_DIR}/skills" ]; then
    for skill in "${SOURCE_DIR}/skills/"*; do
        [ -d "$skill" ] || continue
        BASE_SKILL="$(basename "$skill")"
        if [ -d "${SKILLS_DIR}/${BASE_SKILL}" ] || [ -l "${SKILLS_DIR}/${BASE_SKILL}" ]; then
            echo "Existing Gemini skill ${BASE_SKILL} found, removing..."
            rm -rf "${SKILLS_DIR}/${BASE_SKILL}"
        fi
        ln -s "$skill" "${SKILLS_DIR}/${BASE_SKILL}"
    done
fi

echo "Gemini initialization complete. Global rules, workflows, and document templates are now linked to ${GEMINI_DIR}."

# Cheatsheet
CHEATSHEET_SOURCE="${SOURCE_DIR}/cheat-sheet.md"
CHEATSHEET_DEST="${GEMINI_DIR}/cheat-sheet.md"
if [ -f "${CHEATSHEET_DEST}" ]; then
    echo "Existing Gemini cheat sheet found, removing..."
    rm -f "${CHEATSHEET_DEST}"
fi
ln -sf "${CHEATSHEET_SOURCE}" "${CHEATSHEET_DEST}"

##
## Setup git global ignore
##

# Using \n for newlines in the payload
PAYLOAD="logs/\ntemp/\npublic-dev/\nextract/\nextract"

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

echo ""
echo "--------------------------------------------------------"
echo "  TIP: Update all registered downstream projects by"
echo "       running: ./scripts/update-all.sh"
echo "--------------------------------------------------------"
echo ""

