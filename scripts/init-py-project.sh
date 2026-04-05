#!/usr/bin/env bash
# Initialize a new greenfield Python project using uv and ruff

set -e

# Safety checks
if [ ! -d ".git" ]; then
    echo "Error: .git directory not found. This script must be run at the root of a git repository."
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
mkdir -p scripts src tests logs temp docs/architecture-decisions

# 2. Add document templates if they don't exist
cd docs
for doc in "${SCRIPT_DIR}/../gemini/document-templates/"*; do
    BASE_DOC="$(basename "$doc")"
    if [ ! -f "${BASE_DOC}" ]; then
        cp -a "$doc" "${BASE_DOC}"
    fi
done
cd ..

# 3. Initialize uv project -or- if pyproject.toml exists, check for Ruff configuration
if [ "${FRESH_INSTALL}" = true ]; then
    # Initialize uv project (pinning Python 3.14)
    # --app sets up a basic application structure
    # --no-workspace prevents joining an existing monorepo
    uv init --python 3.14 --app --no-workspace
elif grep -F "[tool.ruff" pyproject.toml > /dev/null; then
    echo "WARNING! Ruff configuration already exists in pyproject.toml, must removed manually!"
fi

# 4. Add development dependencies
echo "Installing development tools..."
uv add --dev ruff pytest "pytest-cov>=6.3.0" pyright

# 5. Create the .agent-context.md file if it doesn't exist
if [ ! -f ".agent-context.md" ]; then
    cp -a "${SOURCE_DIR}/.agent-context.md" .agent-context.md
fi

# 6. Install pre-commit and set up the git hook
"${SOURCE_DIR}/git-pre-commit-hook.sh"

# 7. Setup .gitignore
echo "Creating .gitignore..."
cp -a "${SOURCE_DIR}/.gitignore" .gitignore

# 8. Link scripts to the project
if [ ! -f "../project_template_dir.sh" ]; then
    echo "export PROJECT_TEMPLATE_DIR=\"${SOURCE_DIR}\"" > ../.project_template_dir.sh
fi

cd scripts

for script in "${SOURCE_DIR}/scripts/"*.sh; do
    BASE_SCRIPT="$(basename "$script")"
    if [ -e "$BASE_SCRIPT" ]; then
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

echo "Environment initialized!"
