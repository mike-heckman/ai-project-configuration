#!/bin/bash

# Usage: ./worker-bridge.sh <project_path> <role> <language>

PROJECT_PATH=$(realpath "$1")
ROLE=$2
LANGUAGE=$3 # python or typescript

# 1. Resolve core worker assets
# Prioritize ~/.agents/core-worker link created by init-agents.sh
if [ -d "${HOME}/.agents/core-worker" ]; then
    CORE_WORKER_PATH="${HOME}/.agents/core-worker"
    # Derive REPO_ROOT from the source of the symlink if possible, or assume it's the parent
    REPO_ROOT="$(dirname $(realpath "${CORE_WORKER_PATH}"))"
else
    # Fallback to relative path if standard link is missing
    REPO_ROOT="$(dirname $(realpath $(dirname "$0")))"
    CORE_WORKER_PATH="${REPO_ROOT}/core-worker"
fi

if [ ! -d "$CORE_WORKER_PATH" ]; then
    echo "Error: Core worker assets not found at ${CORE_WORKER_PATH}"
    echo "Please run ./scripts/init-agents.sh first."
    exit 1
fi

# 2. Define VM parameters
VM_NAME="worker-${LANGUAGE}-$(basename "$PROJECT_PATH" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')"
IMAGE="images:ubuntu/22.04" # Default base image

# 3. Launch the VM if it doesn't exist
VM_EXISTS=true
if ! incus list --format csv -c n | grep -q "^${VM_NAME}$"; then
    echo "Launching new Incus VM: ${VM_NAME}"
    incus launch "$IMAGE" "$VM_NAME" --vm -c limits.cpu=2 -c limits.memory=4GiB
    VM_EXISTS=false
    
    # Wait for the VM to be ready
    echo "Waiting for VM to initialize..."
    sleep 5
fi

# 4. Configure Devices (virtiofs mounts)
# Only reconfigure if the VM is stopped to avoid crashing virtiofsd
if [ "$(incus info "${VM_NAME}" | grep Status: | awk '{print $2}')" != "RUNNING" ]; then
    echo "Configuring mounts..."
    # Project Workspace
    incus config device remove "$VM_NAME" workspace >/dev/null 2>&1 || true
    incus config device add "$VM_NAME" workspace disk source="$PROJECT_PATH" path="/workspace"
    # Core Worker Rules
    incus config device remove "$VM_NAME" core-worker >/dev/null 2>&1 || true
    incus config device add "$VM_NAME" core-worker disk source="$CORE_WORKER_PATH" path="/opt/core-worker"
    # Pi Config
    incus config device remove "$VM_NAME" pi-config >/dev/null 2>&1 || true
    incus config device add "$VM_NAME" pi-config disk source="${CORE_WORKER_PATH}/kvm/pi" path="/home/ubuntu/.pi/agent"
fi

# 5. Handle environment variables and ROLE passing
echo "Generating environment configuration..."
ENV_TEMPLATE="${CORE_WORKER_PATH}/templates/agent-env.template"
ENV_PATH="${PROJECT_PATH}/.agent-worker-env"

sed -e "s|{{ROLE}}|${ROLE}|g" \
    -e "s|{{HOST_WORKSPACE_PATH}}|${PROJECT_PATH}|g" \
    "$ENV_TEMPLATE" > "$ENV_PATH"

# Set Incus environment variables for immediate access
incus config set "$VM_NAME" environment.ROLE="$ROLE"
incus config set "$VM_NAME" environment.HOST_WORKSPACE_PATH="$PROJECT_PATH"
incus config set "$VM_NAME" environment.COLUMNS="$(tput cols)"
incus config set "$VM_NAME" environment.LINES="$(tput lines)"




# 6. Start the VM (if stopped)
incus start "$VM_NAME" >/dev/null 2>&1 || true

# 7. Wait for VM agent and Trigger the Guest Init
echo "Waiting for VM agent to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0
while ! incus exec "$VM_NAME" -- true >/dev/null 2>&1; do
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "Error: VM agent failed to start within ${MAX_RETRIES} seconds."
        exit 1
    fi
done

# Wait for mounts to appear inside the guest
echo "Verifying mount availability..."
MAX_MOUNT_RETRIES=10
MOUNT_RETRY=0
while ! incus exec "$VM_NAME" -- ls /opt/core-worker/kvm/guest-init.sh >/dev/null 2>&1; do
    sleep 1
    MOUNT_RETRY=$((MOUNT_RETRY + 1))
    if [ $MOUNT_RETRY -ge $MAX_MOUNT_RETRIES ]; then
        echo "Error: Mount point /opt/core-worker not found inside guest."
        exit 1
    fi
done

echo "Triggering guest initialization..."
incus exec "$VM_NAME" -- bash /opt/core-worker/kvm/guest-init.sh

echo "Worker VM ${VM_NAME} is active."
echo "To attach to the live session, run:"
echo "  incus exec ${VM_NAME} -- su - ubuntu -c \"tmux attach -t worker\""
exec incus exec ${VM_NAME} -- su - ubuntu -c "tmux attach -t worker"
