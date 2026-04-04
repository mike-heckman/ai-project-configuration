#!/bin/bash

set +e

# Create a temporary file for logs
LOG_FILE=$(mktemp)

# Function to handle cleanup on exit
cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

# Wrap commands in a subshell and redirect output
if ! {
  cp -a "${SOURCE_DIR}/git-pre-commit-hook.yaml" .pre-commit-config.yaml
  uv tool install pre-commit
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