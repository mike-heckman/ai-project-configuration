#!/bin/bash

# Usage: ./worker-bridge.sh <project_path> <role> <language>

PROJECT_PATH=$(realpath "$1")
ROLE=$2
LANGUAGE=$3 # python or typescript
if [ -z "$LANGUAGE" ]; then
    HAS_PY=false
    HAS_TS=false
    [ -f "$PROJECT_PATH/.python-version" ] || [ -f "$PROJECT_PATH/pyproject.toml" ] || [ -f "$PROJECT_PATH/requirements.txt" ] && HAS_PY=true
    [ -f "$PROJECT_PATH/package.json" ] || [ -f "$PROJECT_PATH/tsconfig.json" ] && HAS_TS=true

    if $HAS_PY && $HAS_TS; then
        LANGUAGE="polyglot"
    elif $HAS_PY; then
        LANGUAGE="python"
    elif $HAS_TS; then
        LANGUAGE="typescript"
    else
        LANGUAGE="general"
    fi
    echo "Auto-detected project language: $LANGUAGE"
fi

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

# Generate a unique port between 8000 and 8999 based on VM_NAME for the Browser UI
PORT_OFFSET=$(echo "$VM_NAME" | cksum | awk '{print $1 % 1000}')
HOST_PORT=$((8000 + PORT_OFFSET))

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
    
    # Pi Sessions (intercept to host central directory)
    PI_SESSIONS_DIR="${HOME}/.agents/pi-sessions"
    mkdir -p "$PI_SESSIONS_DIR"
    
    # Prune session files/directories that are > 14 days old
    find "$PI_SESSIONS_DIR" -type f -mtime +14 -delete
    find "$PI_SESSIONS_DIR" -mindepth 1 -type d -empty -delete
    
    incus config device remove "$VM_NAME" pi-sessions >/dev/null 2>&1 || true
    incus config device add "$VM_NAME" pi-sessions disk source="$PI_SESSIONS_DIR" path="/home/ubuntu/.pi/agent/sessions"

    # Pi UI (ttyd) Proxy - Intercepts guest port 7681 to a unique host port
    incus config device remove "$VM_NAME" pi-ui >/dev/null 2>&1 || true
    incus config device add "$VM_NAME" pi-ui proxy listen=tcp:127.0.0.1:$HOST_PORT connect=tcp:127.0.0.1:7681
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
echo "Browser UI: http://127.0.0.1:${HOST_PORT}"

# Launch browser terminal (Chromium preferred for --app mode)
if command -v chromium &> /dev/null; then
    chromium --app="http://127.0.0.1:${HOST_PORT}" >/dev/null 2>&1 &
elif command -v chromium-browser &> /dev/null; then
    chromium-browser --app="http://127.0.0.1:${HOST_PORT}" >/dev/null 2>&1 &
elif command -v google-chrome &> /dev/null; then
    google-chrome --app="http://127.0.0.1:${HOST_PORT}" >/dev/null 2>&1 &
else
    xdg-open "http://127.0.0.1:${HOST_PORT}" >/dev/null 2>&1 &
fi

echo "To attach via CLI, run: incus exec ${VM_NAME} -- su - ubuntu -c \"tmux attach -t worker\""
