#!/usr/bin/env bash
# Build the global Opencode sandbox image

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
SANDBOX_DIR="$(realpath "${SCRIPT_DIR}/../agents/sandbox")"

echo "Building opencode-sandbox image for user: $USER (UID: $(id -u), GID: $(id -g))"

docker build -t opencode-sandbox \
  --build-arg USERNAME="$USER" \
  --build-arg USER_UID="$(id -u)" \
  --build-arg USER_GID="$(id -g)" \
  "$SANDBOX_DIR"

echo "Build complete! You can now run the sandbox using the opencode-sandbox wrapper."
