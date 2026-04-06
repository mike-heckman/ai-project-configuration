#!/bin/bash

# NOTE: Similar to Python, this relies on `pre-commit` binary to orchestrate the YAML hook.
# The `pre-commit` binary is often installed system-wide via pip or brew.

set +e

# Create a temporary file for logs
LOG_FILE=$(mktemp)

# Function to handle cleanup on exit
cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

# Resolve source dir accurately
SCRIPT_DIR=$(dirname "$(realpath "$0")")
SOURCE_DIR=$(realpath "${SCRIPT_DIR}")

# Wrap commands in a subshell and redirect output
if ! {
  cp -a "${SOURCE_DIR}/git-pre-commit-hook.yaml" .pre-commit-config.yaml
  # We assume pre-commit is installed on the host system or via uv tool from previous configs.
  # If it is not present, we will install it globally using uv (since it's a global dependency).
  if ! command -v pre-commit &> /dev/null; then
    uv tool install pre-commit
  fi
  pre-commit install
  pre-commit migrate-config
} > "$LOG_FILE" 2>&1; then
  echo "Error: Command failed. See output below:"
  cat "$LOG_FILE"
  exit 1
else
  echo "Pre-commit hook setup completed successfully."
fi

echo "All commands completed successfully."
