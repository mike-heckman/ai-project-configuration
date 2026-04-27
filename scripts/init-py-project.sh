#!/usr/bin/env bash
# Initialize a new greenfield Python project using uv and ruff

set -e

# Avoid interference from active virtual environments and python pathing
unset VIRTUAL_ENV
unset PYTHONHOME
unset PYTHONPATH

# Defaults
PYTHON_VERSION="3.12"
PROJECT_TYPE="app"
FLAVOR="base"
TARGET_DIR="."
SKIP_HOOKS=false

# Help message
show_help() {
    echo "Usage: init-py-project.sh [options]"
    echo ""
    echo "Options:"
    echo "  -p, --python <version>   Set Python version (default: 3.14)"
    echo "  -t, --type <app|lib>     Set project type (default: app)"
    echo "  -f, --flavor <base|web|data> Add extra packages (default: base)"
    echo "  -d, --dir <path>         Target directory (default: .)"
    echo "  --no-hooks               Skip pre-commit hooks setup"
    echo "  -h, --help               Show this help message and exit"
    echo ""
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--python) PYTHON_VERSION="$2"; shift 2 ;;
        -t|--type) PROJECT_TYPE="$2"; shift 2 ;;
        -f|--flavor) FLAVOR="$2"; shift 2 ;;
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
SOURCE_DIR=$(realpath "${SCRIPT_DIR}/../languages/python")
if [ ! -d "$SOURCE_DIR" ]; then
    echo "No existing Python project structure found at $SOURCE_DIR. Aborting!"
    exit 1
fi

if [ -f "pyproject.toml" ]; then
    echo "The pyproject.toml file already exists."
    echo "Updating a greenfield Python project..."
    FRESH_INSTALL=false
else
    echo "Bootstrapping greenfield Python project..."
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

# 3. Initialize uv project -or- if pyproject.toml exists, check for Ruff configuration
if [ "${FRESH_INSTALL}" = true ]; then
    # Initialize uv project
    # --no-workspace prevents joining an existing monorepo
    if [ "$PROJECT_TYPE" = "lib" ]; then
        uv init --python "$PYTHON_VERSION" --lib --no-workspace
    else
        uv init --python "$PYTHON_VERSION" --app --no-workspace
    fi
elif grep -F "[tool.ruff" pyproject.toml > /dev/null; then
    echo "WARNING! Ruff configuration already exists in pyproject.toml, must removed manually!"
fi

# Ensure pyproject.toml requirement matches our intended version
if [ -f "pyproject.toml" ]; then
    sed -i "s/requires-python = \".*\"/requires-python = \">=$PYTHON_VERSION\"/" pyproject.toml
fi

# Force uv to recognize this version as the project's primary version
echo "Pinning project to Python $PYTHON_VERSION..."
echo "$PYTHON_VERSION" > .python-version

# 4. Ensure a clean, portable venv exists
if [ -d ".venv" ]; then
    echo "Refreshing virtual environment..."
    rm -rf .venv
fi

echo "Ensuring Python $PYTHON_VERSION is installed..."
uv python install "$PYTHON_VERSION"

echo "Creating portable virtual environment using uv..."
uv venv --python "$PYTHON_VERSION" .venv

# Verify the venv is healthy and report version
if ! .venv/bin/python3 --version; then
    echo "Error: Virtual environment creation failed."
    exit 1
fi
echo "Successfully created venv: $(.venv/bin/python3 --version)"

# 5. Add development dependencies
echo "Installing development tools..."
uv add --dev ruff pytest "pytest-cov>=6.3.0" pyright

if [ "$FLAVOR" = "web" ]; then
    echo "Installing web flavor dependencies..."
    uv add fastapi uvicorn
elif [ "$FLAVOR" = "data" ]; then
    echo "Installing data flavor dependencies..."
    uv add pandas numpy
fi

# 5. Create the .agent-context.md file if it doesn't exist
if [ ! -f ".agent-context.md" ]; then
    cp -a "${SOURCE_DIR}/.agent-context.md" .agent-context.md
fi

# 5.2 Copy master config files
if [ ! -f ".ruff-master-config.toml" ]; then
    cp -a "${SOURCE_DIR}/ruff-master-config.toml" .ruff-master-config.toml
fi
if [ ! -f ".pyrightconfig.json" ]; then
    cp -a "${SOURCE_DIR}/pyright-master-config.json" .pyrightconfig.json
fi

# 5.5 Inject Opencode integration files
if [ ! -f "AGENTS.md" ]; then
    cp -a "${SCRIPT_DIR}/../agents/templates/AGENTS.md" AGENTS.md
fi

# 6. Install pre-commit and set up the git hook
if [ "$SKIP_HOOKS" = false ]; then
    "${SOURCE_DIR}/git-pre-commit-hook.sh"
else
    echo "Skipping git pre-commit hook setup..."
fi

# 7. Setup .gitignore
echo "Creating .gitignore..."
cp -a "${SOURCE_DIR}/.gitignore" .gitignore

# 8. Link scripts to the project
# Get the AI-Config root directory since SOURCE_DIR points directly to languages/python/
ROOT_DIR=$(dirname "$(dirname "$SOURCE_DIR")")

# 9. Provide global pointer
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

# 10. Create document directories
for doc in "${SOURCE_DIR}/docs/"*; do
    local_doc="$(basename "$doc")"
    if [ ! -d "docs/${local_doc}" ]; then
        mkdir -p "docs/${local_doc}"
    fi
done

# 11. Initial formatting pass
echo "Applying initial formatting..."
scripts/lint.sh > /dev/null 2>&1 || true

# 12. Register project for global updates
REGISTRY_DIR="${HOME}/.agents/registered"
mkdir -p "$REGISTRY_DIR"
REGISTRY_FILE="${REGISTRY_DIR}/python_locations.conf"
PROJECT_PATH=$(pwd)
if ! grep -Fxq "$PROJECT_PATH" "$REGISTRY_FILE" 2>/dev/null; then
    echo "$PROJECT_PATH" >> "$REGISTRY_FILE"
    echo "Project registered for global updates."
fi

echo "Environment initialized!"
