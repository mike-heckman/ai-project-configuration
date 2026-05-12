#!/bin/bash

# Usage: ./worker-bridge.sh <project_path> <role> <language>

PROJECT_PATH=$(realpath "$1")
ROLE=$2
LANGUAGE=$3 # python or typescript
VM_HOME="/home/ubuntu"

if [ -z "$LANGUAGE" ]; then
    HAS_PY=false
    HAS_TS=false
    [ -f "$PROJECT_PATH/.languages" ] && source "$PROJECT_PATH/.languages"
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

# --- Helper Functions ---

is_vm_running() {
    local vm_name=$1
    [ "$(incus info "${vm_name}" 2>/dev/null | grep -i "Status:" | awk '{print $2}')" = "RUNNING" ]
}

stop_vm_if_running() {
    local vm_name=$1
    echo "Stopping VM: ${vm_name}..."
    while is_vm_running "${vm_name}"; do
        incus stop "${vm_name}"
        sleep 2
    fi
}

get_bridge_ip() {
    local bridge_name=${1:-incusbr0}
    local ip=$(incus network get "${bridge_name}" ipv4.address 2>/dev/null | cut -d'/' -f1)
    echo "${ip:-127.0.0.1}"
}

# --- Main Script ---

# 1. Resolve core worker assets
# If we have a local override, use that
if [ -d "${PROJECT_PATH}/core-worker" ]; then
    CORE_WORKER_PATH="${PROJECT_PATH}/core-worker"
# Prioritize ~/.agents/core-worker link created by init-agents.sh
else
    CORE_WORKER_PATH="${HOME}/.agents/core-worker"
    # Throw an error if the system isn't initialized
    if [ ! -d "${CORE_WORKER_PATH}" ]; then
        echo "Error: Core worker assets not found at ${CORE_WORKER_PATH}"
        echo "Please run ./scripts/init-agents.sh first."
        exit 1
    fi
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
    while ! is_vm_running "$VM_NAME"; do sleep 1; done
fi

if [ "$VM_EXISTS" == "false" ] || [ "$(incus config device get "$VM_NAME" workspace path 2>/dev/null)" != "$PROJECT_PATH" ]; then
    echo "Updating legacy VM configuration..."
    incus exec "${VM_NAME}" -- mkdir -p "${PROJECT_PATH}" "${VM_HOME}/.agents" "${VM_HOME}/.pi"
    stop_vm_if_running "${VM_NAME}"
fi

# 4. Configure Devices (virtiofs mounts)


# Only reconfigure if the VM is stopped to avoid crashing virtiofsd
stop_vm_if_running "${VM_NAME}"

echo "Configuring mounts..."
# Project Workspace
incus config device remove "$VM_NAME" workspace >/dev/null 2>&1 || true
incus config device add "$VM_NAME" workspace disk source="$PROJECT_PATH" path="$PROJECT_PATH"
# Core Worker Rules
incus config device remove "$VM_NAME" core-worker >/dev/null 2>&1 || true
incus config device add "$VM_NAME" core-worker disk source="$CORE_WORKER_PATH" path="${VM_HOME}/.agents/core-worker"
# Pi Config
incus config device remove "$VM_NAME" pi-config >/dev/null 2>&1 || true
incus config device add "$VM_NAME" pi-config disk source="${CORE_WORKER_PATH}/kvm/pi" path="${VM_HOME}/.pi/agent"

# Pi UI (ttyd) Proxy - Intercepts guest port 7681 to a unique host port
incus config device remove "$VM_NAME" pi-ui >/dev/null 2>&1 || true
incus config device add "$VM_NAME" pi-ui proxy "listen=tcp:${BRIDGE_IP}:${HOST_PORT}" "connect=tcp:127.0.0.1:7681" nat=true

# 5. Handle environment variables and ROLE passing
echo "Generating environment configuration..."
ENV_TEMPLATE="${CORE_WORKER_PATH}/templates/agent-env.template"
ENV_PATH="${PROJECT_PATH}/.agent-worker-env"

sed -e "s|{{ROLE}}|${ROLE}|g" \
    -e "s|{{HOST_WORKSPACE_PATH}}|${PROJECT_PATH}|g" \
    -e "s|{{VM_HOME}}|${VM_HOME}|g" \
    "$ENV_TEMPLATE" > "$ENV_PATH"

# Set Incus environment variables for immediate access
incus config set "$VM_NAME" environment.ROLE="$ROLE"
incus config set "$VM_NAME" environment.VM_HOME="$VM_HOME"
incus config set "$VM_NAME" environment.HOST_WORKSPACE_PATH="$PROJECT_PATH"
incus config set "$VM_NAME" environment.COLUMNS="$(tput cols)"
incus config set "$VM_NAME" environment.LINES="$(tput lines)"

# 6. Start the VM (if stopped)
incus start "$VM_NAME" >/dev/null 2>&1 || true
while ! is_vm_running "$VM_NAME"; do sleep 1; done

# Always fetch the bridge IP for consistent UI URLs
BRIDGE_IP=$(get_bridge_ip "incusbr0")
echo "Bridge IP: $BRIDGE_IP"


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
GUEST_INIT="${VM_HOME}/.agents/core-worker/kvm/guest-init.sh"

while ! incus exec "$VM_NAME" -- ls ${GUEST_INIT} >/dev/null 2>&1; do
    sleep 1
    MOUNT_RETRY=$((MOUNT_RETRY + 1))
    if [ $MOUNT_RETRY -ge $MAX_MOUNT_RETRIES ]; then
        echo "Error: Mount point "${VM_HOME}" not found inside guest."
        exit 1
    fi
done

echo "Triggering guest initialization..."
incus exec "$VM_NAME" -- bash "${GUEST_INIT}"

echo "Worker VM ${VM_NAME} is active."
echo "Browser UI: http://${BRIDGE_IP}:${HOST_PORT}"

# Launch browser terminal (Chromium preferred for --app mode)
if command -v chromium &> /dev/null; then
    chromium --app="http://${BRIDGE_IP}:${HOST_PORT}" >/dev/null 2>&1 &
elif command -v chromium-browser &> /dev/null; then
    chromium-browser --app="http://${BRIDGE_IP}:${HOST_PORT}" >/dev/null 2>&1 &
elif command -v google-chrome &> /dev/null; then
    google-chrome --app="http://${BRIDGE_IP}:${HOST_PORT}" >/dev/null 2>&1 &
else
    xdg-open "http://${BRIDGE_IP}:${HOST_PORT}" >/dev/null 2>&1 &
fi

echo "To attach via CLI, run: incus exec ${VM_NAME} -- su - ubuntu -c \"tmux attach -t worker\""
