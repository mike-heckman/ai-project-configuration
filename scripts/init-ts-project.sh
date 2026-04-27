#!/usr/bin/env bash
# Initialize a new greenfield TypeScript/JavaScript project using pnpm, eslint, and prettier

set -e

# Defaults
PKG_MANAGER="pnpm"
TARGET_DIR="."
SKIP_HOOKS=false

# Help message
show_help() {
    echo "Usage: init-ts-project.sh [options]"
    echo ""
    echo "Options:"
    echo "  -m, --manager <pnpm|npm|yarn|bun> Set package manager (default: pnpm)"
    echo "  -d, --dir <path>         Target directory (default: .)"
    echo "  --no-hooks               Skip pre-commit hooks setup"
    echo "  -h, --help               Show this help message and exit"
    echo ""
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--manager) PKG_MANAGER="$2"; shift 2 ;;
        -d|--dir) TARGET_DIR="$2"; shift 2 ;;
        --no-hooks) SKIP_HOOKS=true; shift ;;
        -h|--help) show_help ;;
        *) echo "Unknown option: $1"; show_help ;;
    esac
done

# Handle target directory
if [ "$TARGET_DIR" != "." ]; then
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"
fi

# Safety checks - DO NOT RUN if you are not sure about the current directory or if it contains important files!
if [ ! -d ".git" ]; then
    echo "Warning: .git directory not found. Aborting..."
    exit 1
fi

# Get the scripts' location to find the source template
SCRIPT_DIR=$(dirname "$(realpath "$0")")
SOURCE_DIR=$(realpath "${SCRIPT_DIR}/../languages/typescript")
if [ ! -d "$SOURCE_DIR" ]; then
    echo "No existing TypeScript project structure found at $SOURCE_DIR. Aborting!"
    exit 1
fi

if [ -f "package.json" ]; then
    echo "The package.json file already exists."
    echo "Updating a greenfield TypeScript project..."
    FRESH_INSTALL=false
else
    echo "Bootstrapping greenfield TypeScript project..."
    FRESH_INSTALL=true
fi

# Build language independent project structure

# 1. Create directory structure
mkdir -p scripts src tests logs temp docs/architecture-decisions docs/backlog/done docs/performance docs/ux docs/security

# 2. Add document templates if they don't exist
cd docs
for doc in "${SCRIPT_DIR}/../agents/templates/"*; do
    # Skip non-markdown docs for the docs folder (like Dockerfiles)
    if [[ "$doc" != *.md ]]; then
        continue
    fi
    # Also skip AGENTS.md, OPENCODE.md and cheat-sheet.md here as they belong in the root or elsewhere
    BASE_DOC="$(basename "$doc")"
    if [ "$BASE_DOC" = "AGENTS.md" ] || [ "$BASE_DOC" = "OPENCODE.md" ] || [ "$BASE_DOC" = "cheat-sheet.md" ]; then
        continue
    fi
    if [ ! -f "${BASE_DOC}" ]; then
        cp -a "$doc" "${BASE_DOC}"
    fi
done
cd ..

# 3. Initialize package.json
if [ "${FRESH_INSTALL}" = true ]; then
    if [ "$PKG_MANAGER" = "pnpm" ]; then
        pnpm init
        pnpm pkg set type="module"
    elif [ "$PKG_MANAGER" = "npm" ]; then
        npm init -y
        npm pkg set type="module"
    elif [ "$PKG_MANAGER" = "yarn" ]; then
        yarn init -y
        npm pkg set type="module"
    elif [ "$PKG_MANAGER" = "bun" ]; then
        bun init -y
        npm pkg set type="module"
    else
        echo "Error: Unsupported package manager $PKG_MANAGER"
        exit 1
    fi
fi

# 4. Add development dependencies (matching standard stack)
echo "Installing development tools using $PKG_MANAGER..."
if [ "$PKG_MANAGER" = "pnpm" ]; then
    pnpm add -D typescript eslint prettier vitest @eslint/js typescript-eslint globals @vitest/coverage-v8
elif [ "$PKG_MANAGER" = "npm" ]; then
    npm install -D typescript eslint prettier vitest @eslint/js typescript-eslint globals @vitest/coverage-v8
elif [ "$PKG_MANAGER" = "yarn" ]; then
    yarn add -D typescript eslint prettier vitest @eslint/js typescript-eslint globals @vitest/coverage-v8
elif [ "$PKG_MANAGER" = "bun" ]; then
    bun add -d typescript eslint prettier vitest @eslint/js typescript-eslint globals @vitest/coverage-v8
fi

# Copy configs
if [ ! -f ".eslint.config.js" ]; then
    cp -a "${SOURCE_DIR}/.eslint.config.js" .eslint.config.js
fi
if [ ! -f ".prettierrc" ]; then
    cp -a "${SOURCE_DIR}/.prettierrc" .prettierrc
fi
if [ ! -f ".tsconfig.json" ]; then
    cp -a "${SOURCE_DIR}/.tsconfig.json" .tsconfig.json
fi

# 5. Create the .agent-context.md file if it doesn't exist
if [ ! -f ".agent-context.md" ]; then
    cp -a "${SOURCE_DIR}/.agent-context.md" .agent-context.md
fi

# 5.5 Inject Opencode integration files
if [ ! -f "AGENTS.md" ]; then
    cp -a "${SCRIPT_DIR}/../agents/templates/AGENTS.md" AGENTS.md
fi
if [ ! -f "OPENCODE.md" ]; then
    cp -a "${SCRIPT_DIR}/../agents/templates/OPENCODE.md" OPENCODE.md
fi

# 6. Install pre-commit and set up the git hook
if [ "$SKIP_HOOKS" = false ]; then
    if [ -x "${SOURCE_DIR}/git-pre-commit-hook.sh" ]; then
      "${SOURCE_DIR}/git-pre-commit-hook.sh"
    else
      # if not executable yet, run via bash
      bash "${SOURCE_DIR}/git-pre-commit-hook.sh"
    fi
else
    echo "Skipping git pre-commit hook setup..."
fi

# 7. Setup .gitignore
echo "Creating .gitignore..."
cp -a "${SOURCE_DIR}/.gitignore" .gitignore

# 8. Link scripts
# Get the AI-Config root directory since SOURCE_DIR points directly to languages/typescript/
ROOT_DIR=$(dirname "$(dirname "$SOURCE_DIR")")

# 7. Provide global pointer
if [ ! -f "../.ai_config_root.sh" ]; then
    echo "export AI_CONFIG_ROOT=\"${ROOT_DIR}\"" > ../.ai_config_root.sh
fi

cd scripts
for script in "${SOURCE_DIR}/scripts/"*.sh; do
    [ -e "$script" ] || continue
    BASE_SCRIPT="$(basename "$script")"
    if [ -e "$BASE_SCRIPT" ] || [ -L "$BASE_SCRIPT" ]; then
        rm -f "$BASE_SCRIPT"
    fi
    ln "$script"
    chmod +x "$(basename "$script")"
done
cd ..

# 9. Create document directories
for doc in "${SOURCE_DIR}/docs/"*; do
    local_doc="$(basename "$doc")"
    if [ ! -d "docs/${local_doc}" ]; then
        mkdir -p "docs/${local_doc}"
    fi
done

# 10. Initial formatting pass
echo "Applying initial formatting..."
scripts/lint.sh > /dev/null 2>&1 || true

# 11. Register project for global updates
REGISTRY_DIR="${HOME}/.agents/registered"
mkdir -p "$REGISTRY_DIR"
REGISTRY_FILE="${REGISTRY_DIR}/ts_locations.conf"
PROJECT_PATH=$(pwd)
if ! grep -Fxq "$PROJECT_PATH" "$REGISTRY_FILE" 2>/dev/null; then
    echo "$PROJECT_PATH" >> "$REGISTRY_FILE"
    echo "Project registered for global updates."
fi

echo "Environment initialized!"
