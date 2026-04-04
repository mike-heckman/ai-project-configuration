#!/usr/bin/env bash

set -e

SOURCE_DIR="$(dirname "$0")/gemini"
GEMINI_DIR="${HOME}/.gemini"

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
ln -sf "${SOURCE_DIR}/global-workflows" "${GEMINI_DIR}/antirgravity/global_workflows"

# Document templates
if [ -d "${GEMINI_DIR}/document-templates" ]; then
    echo "Existing Gemini document templates directory found, removing..."
    rm -rf "${GEMINI_DIR}/document-templates"
fi
ln -sf "${SOURCE_DIR}/document-templates" "${GEMINI_DIR}/document-templates"

echo "Gemini initialization complete. Global rules, workflows, and document templates are now linked to ${GEMINI_DIR}."