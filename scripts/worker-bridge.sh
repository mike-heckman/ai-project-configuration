#!/bin/bash

# Usage: ./worker-bridge.sh <project_path> <role> <language>

PROJECT_PATH=$(realpath "$1")
ROLE=$2
LANGUAGE=$3 # python or typescript

REPO_ROOT="$(dirname $(realpath $(dirname "$0")))"
CORE_WORKER_PATH="${REPO_ROOT}/core-worker"

# 1. Define VM parameters
VM_NAME="worker-${LANGUAGE}-$(basename "$PROJECT_PATH" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')"
IMAGE="images:ubuntu/22.04" # Default base image

# 2. Launch the VM if it doesn't exist
if ! incus list --format csv -c n | grep -q "^${VM_NAME}$"; then
    echo "Launching new Incus VM: ${VM_NAME}"
    incus launch "$IMAGE" "$VM_NAME" --vm -c limits.cpu=2 -c limits.memory=4GiB
    
    # Wait for the VM to be ready
    echo "Waiting for VM to initialize..."
    sleep 5
fi

# 3. Configure Devices (virtiofs mounts)
echo "Configuring mounts..."
# Project Workspace
incus config device add "$VM_NAME" workspace disk source="$PROJECT_PATH" path="/workspace" || true
# Core Worker Rules
incus config device add "$VM_NAME" core-worker disk source="$CORE_WORKER_PATH" path="/home/mike/.agents/core-worker" || true

# 4. Handle environment variables and ROLE passing
echo "Generating environment configuration..."
ENV_TEMPLATE="${REPO_ROOT}/core-worker/templates/agent-env.template"
ENV_PATH="${PROJECT_PATH}/.agent-worker-env"

sed -e "s|{{ROLE}}|${ROLE}|g" \
    -e "s|{{HOST_WORKSPACE_PATH}}|${PROJECT_PATH}|g" \
    "$ENV_TEMPLATE" > "$ENV_PATH"

# Set Incus environment variables for immediate access
incus config set "$VM_NAME" environment.ROLE="$ROLE"
incus config set "$VM_NAME" environment.HOST_WORKSPACE_PATH="$PROJECT_PATH"

# 5. Start the VM (if stopped)
incus start "$VM_NAME" || true

# 6. Trigger the Guest Init
# Note: This assumes the guest-init.sh is already in the core-worker mount
echo "Triggering guest initialization..."
incus exec "$VM_NAME" -- bash -c "source /home/mike/.agents/core-worker/kvm/guest-init.sh"

echo "Worker VM ${VM_NAME} is active."
