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

vm_state() {
    local vm_name=$1
    incus list "${vm_name}" --format csv -c s
}

is_vm_running() {
    local vm_name=$1
    [[ "$(vm_state "${vm_name}")" == "RUNNING" ]]
}

stop_vm_if_running() {
    local vm_name=$1
    local max_stop_wait=${2:-60}
    local stop_wait=0
    local sleep_duration=${3:-2}

    if [[ "$(vm_state "${vm_name}")" != "STOPPED" ]]; then
        echo "Stopping VM: ${vm_name}..."
        incus stop "${vm_name}"
        while [[ "$(vm_state "${vm_name}")" != "STOPPED" ]]; do
            stop_wait=$((stop_wait + $sleep_duration))
            if [ $stop_wait -ge $max_stop_wait ]; then
                echo "Error: VM ${vm_name} Hasn't stopped in ${max_stop_wait} seconds, aborting..."
                exit 1
            fi        
            sleep $sleep_duration
        done
    fi
}

start_vm_if_not_running() {
    local vm_name=$1
    local max_wait=${2:-60}
    local sleep_duration=${3:-1}
    local waited=0

    if ! is_vm_running "${vm_name}"; then
        echo "Starting VM: ${vm_name}..."
        if ! incus start "$vm_name" >"/tmp/incus.start" 2>&1; then
            echo "incus ${vm_name} returned non-zero:"
            cat "/tmp/incus.start"
        fi
        waited=5
        sleep $waited
    fi
    echo "Waiting for VM ${vm_name} to be fully ready (hardware + agent)..."

    if ! run_vm_command_timeout "${vm_name}" "${max_wait}" "${sleep_duration}" "true"; then
        echo "Error: VM ${vm_name} (or its agent) failed to reach ready state within ${max_wait} seconds."
        incus list
        exit 1
    fi
}

run_vm_command_timeout() {
    local vm_name=$1
    local max_wait=${2:-60}
    local sleep_duration=${3:-1}
    shift 3
    # The remaining arguments ($@) are now the command and its parameters
    local waited=0

    while ! is_vm_running "$vm_name" || ! incus exec "$vm_name" -- "$@" >/dev/null 2>&1; do
        sleep $sleep_duration
        waited=$((waited + $sleep_duration))
        if [ $waited -ge $max_wait ]; then
            return 1
        fi
    done

    return 0
}

get_bridge_ip() {
    local bridge_name=${1:-incusbr0}
    local ip=$(incus network get "${bridge_name}" ipv4.address 2>/dev/null | cut -d'/' -f1)
    echo "${ip:-127.0.0.1}"
}

# --- Main Script ---

# 1. Network Configuration
BRIDGE_NAME="incusbr0"

# Only apply iptables rules if they are missing to reduce sudo prompts
if ! sudo iptables -C FORWARD -i "$BRIDGE_NAME" -j ACCEPT >/dev/null 2>&1; then
    echo "Updating host firewall for ${BRIDGE_NAME}..."
    sudo iptables -I FORWARD 1 -i "$BRIDGE_NAME" -j ACCEPT
    sudo iptables -I FORWARD 1 -o "$BRIDGE_NAME" -j ACCEPT
fi

# 2. Resolve core worker assets
# If we have a local override, use that
if [ -d "${PROJECT_PATH}/.core-worker" ]; then
    CORE_WORKER_PATH="${PROJECT_PATH}/.core-worker"
# Prioritize ~/.agents/pi directory created by init-agents.sh
else
    CORE_WORKER_PATH="${HOME}/.agents/pi"
    # Throw an error if the system isn't initialized
    if [ ! -d "${CORE_WORKER_PATH}" ]; then
        echo "Error: Core worker assets not found at ${CORE_WORKER_PATH}"
        echo "Please run ./scripts/init-agents.sh first."
        exit 1
    fi
fi

# 3. Define VM parameters
VM_NAME="worker-${LANGUAGE}-$(basename "$PROJECT_PATH" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')"
IMAGE="images:ubuntu/22.04" # Default base image

# Generate a unique port between 8000 and 8999 based on VM_NAME for the Browser UI
PORT_OFFSET=$(echo "$VM_NAME" | cksum | awk '{print $1 % 1000}')
HOST_PORT=$((8000 + PORT_OFFSET))

# 4. Launch the VM if it doesn't exist
VM_EXISTS=true
if ! incus list --format csv -c n | grep -q "^${VM_NAME}$"; then
    echo "Launching new Incus VM: ${VM_NAME}"
    incus launch "$IMAGE" "$VM_NAME" --vm -c limits.cpu=2 -c limits.memory=4GiB
    VM_EXISTS=false
    
    # Wait for the VM to be ready
    echo "Waiting for VM to initialize..."
    start_vm_if_not_running "$VM_NAME"
fi

if [ "$VM_EXISTS" == "false" ] || [ "$(incus config device get "$VM_NAME" workspace path 2>/dev/null)" != "$PROJECT_PATH" ]; then
    echo "Updating legacy VM configuration..."
    start_vm_if_not_running "${VM_NAME}"
    incus exec "${VM_NAME}" -- mkdir -p "${PROJECT_PATH}" "${VM_HOME}/.agents" "${VM_HOME}/.pi"
fi

# 5. Configure Devices (virtiofs mounts)

# Only reconfigure if the VM is stopped to avoid crashing virtiofsd
stop_vm_if_running "${VM_NAME}"

# Fetch bridge IP for proxy and UI
BRIDGE_IP=$(get_bridge_ip "$BRIDGE_NAME")
BRIDGE_PREFIX=$(echo "$BRIDGE_IP" | cut -d'.' -f1-3)
VM_IP="${BRIDGE_PREFIX}.$((200 + (PORT_OFFSET % 50)))"
echo "Bridge IP: $BRIDGE_IP | VM Static IP: $VM_IP"

echo "Configurating mount points..."
# Project Workspace
incus config device remove "$VM_NAME" workspace >/dev/null 2>&1 || true
incus config device add "$VM_NAME" workspace disk source="$PROJECT_PATH" path="$PROJECT_PATH"

# Core Worker Rules
incus config device remove "$VM_NAME" core-worker >/dev/null 2>&1 || true

# Consolidated Pi & Core Worker mount
# This maps the flat directory from ~/.agents/pi to the guest's Pi agent dir
incus config device remove "$VM_NAME" pi-config >/dev/null 2>&1 || true
incus config device add "$VM_NAME" pi-config disk source="$CORE_WORKER_PATH" path="${VM_HOME}/.pi/agent"

# This maps the jCodeMunch storage location into the VM
# DISABLED: SQLite Disk I/O errors occur when WAL-mode databases are on virtiofs mounts.
# The worker will now maintain its own local index for stability.
incus config device remove "$VM_NAME" codemunch-config >/dev/null 2>&1 || true
# if [ -d "${HOME}/.code-index" ]; then
#     incus config device add "$VM_NAME" codemunch-config disk source="${HOME}/.code-index" path="${VM_HOME}/.code-index"
# fi

# Static IP NIC (Required for NAT proxies on VMs)
incus config device remove "$VM_NAME" eth0 >/dev/null 2>&1 || true
incus config device add "$VM_NAME" eth0 nic nictype=bridged parent="$BRIDGE_NAME" name=eth0 ipv4.address="$VM_IP"

# Pi UI (ttyd) Proxy - Intercepts guest port 7681 to a unique host port
# Note: VMs REQUIRE nat=true, which forbids 127.0.0.1. We use the static VM_IP.
incus config device remove "$VM_NAME" pi-ui >/dev/null 2>&1 || true
incus config device add "$VM_NAME" pi-ui proxy "listen=tcp:${BRIDGE_IP}:${HOST_PORT}" "connect=tcp:${VM_IP}:7681" nat=true

# 6. Handle environment variables and ROLE passing
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
incus config set "$VM_NAME" environment.COLUMNS="$(tput cols 2>/dev/null || echo 120)"
incus config set "$VM_NAME" environment.LINES="$(tput lines 2>/dev/null || echo 80)"

# 7. Start the VM (if stopped)
start_vm_if_not_running "$VM_NAME" 120 2

# 8. Trigger the Guest Init
# Wait for mounts to appear inside the guest
echo "Verifying mount availability..."
MAX_MOUNT_SECONDS=60
WAIT=2
GUEST_INIT="${VM_HOME}/.pi/agent/guest-init.sh"

if ! run_vm_command_timeout "${VM_NAME}" "${MAX_MOUNT_SECONDS}" "${WAIT}" ls "${GUEST_INIT}"; then
    echo "Error: Agent assets not found at ${GUEST_INIT} inside guest."
    incus list
    exit 1
fi

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
