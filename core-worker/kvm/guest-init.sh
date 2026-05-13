#!/bin/bash

# 1. Wait for Incus Agent to handle mounts
# In Incus VMs, the agent typically mounts disk devices automatically.
# We'll check for our mount points.

# Pre-defined environment variables
# ROLE - The ruleset to use `coder`, `debugger`, etc
# VM_HOME - The home directory to use in the VM
# HOST_WORKSPACE_PATH - The mounted project path
# COLUMNS - screen width
# LINES - screen height

echo "Verifying mounts..."
# Disable IPv6 to prevent timeouts on systems where it's not fully routed
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
RETRY=0
CORE_WORKER_PATH="${VM_HOME}/.pi/agent"

while [ ! -d "${HOST_WORKSPACE_PATH}" ] || [ ! -d "${CORE_WORKER_PATH}" ]; do
    if [ $RETRY -gt 10 ]; then
        echo "Error: Mount points not found after 10 seconds. Is incus-agent running?"
        exit 1
    fi
    sleep 1
    ((RETRY++))
done
echo "Mounts verified."

# 1.5 Network Stabilization
# Prevent hanging on HTTPS/TCP handshakes in VPN/Tailscale environments by optimizing MTU
PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
if [ ! -z "$PRIMARY_IFACE" ]; then
    echo "Optimizing network MTU on $PRIMARY_IFACE for stability..."
    ip link set dev "$PRIMARY_IFACE" mtu 1300
fi

# Ensure DNS is functional
if ! ping -c 1 google.com &>/dev/null; then
    echo "DNS check failed. Adding fallback nameservers..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fi


if [ -f "${CORE_WORKER_PATH}/.env" ]; then
    echo "Sourcing environment from ${CORE_WORKER_PATH}/.env"
    source "${CORE_WORKER_PATH}/.env"
fi
# 2. Source environment variables from workspace
if [ -f "${HOST_WORKSPACE_PATH}/.agent-worker-env" ]; then
    echo "Sourcing environment from ${HOST_WORKSPACE_PATH}/.agent-worker-env"
    source "${HOST_WORKSPACE_PATH}/.agent-worker-env"
fi

# 4. User and Permissions setup
# Claude Code cannot run as root with --dangerously-skip-permissions.
# We use the default 'ubuntu' user which is typically UID 1000.
TARGET_USER="ubuntu"
if ! id "$TARGET_USER" &>/dev/null; then
    # Fallback to creating mike if ubuntu doesn't exist
    TARGET_USER="user"
    if ! id "user" &>/dev/null; then
        useradd -m -s /bin/bash -u 1000 "${TARGET_USER}"
    fi
fi

# Allow target user to use sudo without password
echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-agent-user

# Ensure config directories exist and are owned by target user
export USER_HOME="/home/$TARGET_USER"
mkdir -p "$USER_HOME/.agents"
chown -R $TARGET_USER:$TARGET_USER "$USER_HOME"

# 5. MCP & Pi Configuration link
echo "Configuring AI tools for Worker..."
mkdir -p "$USER_HOME/.config/claude" "$USER_HOME/.config/mcp" "$USER_HOME/.code-index" "$USER_HOME/.doc-index"
chown -R $TARGET_USER:$TARGET_USER "$USER_HOME/.config" "$USER_HOME/.code-index" "$USER_HOME/.doc-index" "$USER_HOME/.pi"

ln -sf "${CORE_WORKER_PATH}/mcp_config.json" "$USER_HOME/.config/claude/mcp_config.json"
ln -sf "${CORE_WORKER_PATH}/mcp_config.json" "$USER_HOME/.config/mcp/mcp.json"

# Link jcodemunch-mcp and jdocmunch-mcp central config
ln -sf "${CORE_WORKER_PATH}/config.jsonc" "$USER_HOME/.code-index/config.jsonc"
ln -sf "${CORE_WORKER_PATH}/config.jsonc" "$USER_HOME/.doc-index/config.jsonc"

INSTRUCTION_FILE="$USER_HOME/.pi/agent/AUTONOMOUS.md"
# 6. Launch pi.dev with the specified ROLE inside tmux
if [ ! -z "$ROLE" ]; then
    RULES_FILE="$USER_HOME/.pi/agent/rules/${ROLE}.md"
    # Fallback to -rules.md suffix
    if [ ! -f "$RULES_FILE" ]; then
        RULES_FILE="$USER_HOME/.pi/agent/rules/${ROLE}-rules.md"
    fi

    if [ -f "$RULES_FILE" ]; then
        echo "Launching pi.dev with role: $ROLE"
        
        # Provisioning: Ensure Node.js, uv, and dependencies are installed
        if ! command -v npm &> /dev/null; then
            echo "Node.js not found. Provisioning environment..."

            export DEBIAN_FRONTEND=noninteractive
            apt-get update && apt-get install -y curl
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
            apt-get install -y nodejs
        fi

        if ! su - "$TARGET_USER" -c "command -v uv" &> /dev/null; then
            echo "uv not found for $TARGET_USER. Provisioning environment..."
            su - "$TARGET_USER" -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
        fi

        # Pre-install MCP tools to avoid uvx latency/connection issues
        echo "Pre-installing MCP tools..."
        su - "$TARGET_USER" -c "uv tool install jcodemunch-mcp"
        su - "$TARGET_USER" -c "uv tool install jdocmunch-mcp"

        # Ensure pi coding agent is installed
        if ! command -v pi &> /dev/null; then
            echo "Pi coding agent not found. Installing..."
            npm install -g @mariozechner/pi-coding-agent
        # Upgrade pi
        else
            ALREADY_INSTALLED=true
        fi

        # Install the pi-mcp-adapter extension for the agent
        if ! pi extension list | grep -q "pi-mcp-adapter"; then
            echo "Installing pi-mcp-adapter extension..."
            # We use the pi CLI to install it so it registers correctly as an extension
            su - "$TARGET_USER" -c "pi extension install npm:pi-mcp-adapter"
        fi
        
        # Cleanup any legacy .npmrc from previous local-prefix attempts
        rm -f "$USER_HOME/.npmrc"

        # Ensure tmux and ttyd are available
        if ! command -v tmux &> /dev/null || ! command -v ttyd &> /dev/null; then
            apt-get update && apt-get install -y tmux ttyd
        fi
        
        # Only update if we aren't already done. This speeds up "Mission Complete" views.
        if [ "${ALREADY_INSTALLED}" == "true" ]; then
            echo "Checking for Pi coding agent updates..."
            npm install -g @mariozechner/pi-coding-agent@latest
            echo "Checking for pi-mcp-adapter updates..."
            npm install -g pi-mcp-adapter@latest
        fi


        # Ensure common local bin paths are in PATH
        export PATH="$PATH:/usr/local/bin:$USER_HOME/.local/bin"
        
        # Write the wrapper script (remove old one first to avoid permission issues)
        rm -f /tmp/worker-wrapper.sh
        rm -f "${HOST_WORKSPACE_PATH}/.stop-worker" # Clear any old stop marker
        cat <<EOF > /tmp/worker-wrapper.sh
#!/bin/bash
# Check if we should even start
if [ -f "${HOST_WORKSPACE_PATH}/.stop-worker" ]; then
    echo "----------------------------------------------------------------"
    echo "MISSION COMPLETE: Worker has finished all tasks."
    echo "To restart, run: rm ${HOST_WORKSPACE_PATH}/.stop-worker"
    echo "----------------------------------------------------------------"
    # Wait forever to prevent ttyd/tmux from restarting in a loop
    read -p "Press Enter to exit..."
    rm -f "${HOST_WORKSPACE_PATH}/.stop-worker"
fi

# Source environment variables (API keys, etc.)
[ -f "${CORE_WORKER_PATH}/.env" ] && source "${CORE_WORKER_PATH}/.env" 
[ -f "${HOST_WORKSPACE_PATH}/.agent-worker-env" ] && source "${HOST_WORKSPACE_PATH}/.agent-worker-env"

export PATH="\$PATH:/usr/local/bin:$USER_HOME/.local/bin"
cd "${HOST_WORKSPACE_PATH}"

set -o pipefail
if ! pi --session-dir "${HOST_WORKSPACE_PATH}/.pi/sessions/" @"${RULES_FILE}" "$(cat ${INSTRUCTION_FILE})"  2>&1 | tee /tmp/worker.log; then
    echo "Pi failed with exit code \$?"
    read -p "Press Enter to exit..."
else
    echo "Mission successful. Creating stop marker..."
    touch "${HOST_WORKSPACE_PATH}/.stop-worker"
fi
EOF
        chmod +x /tmp/worker-wrapper.sh
        chown $TARGET_USER:$TARGET_USER /tmp/worker-wrapper.sh

        # Forcefully restart the session to pick up new environment/rules
        echo "Restarting worker session (Browser UI enabled)..."
        su - $TARGET_USER -c "tmux kill-session -t worker 2>/dev/null || true"
        pkill -f ttyd 2>/dev/null || true

        # Run ttyd as the target user in the background
        # -W: Allow writing
        TMUX_SIZE=""
        [ ! -z "$COLUMNS" ] && [ ! -z "$LINES" ] && TMUX_SIZE="-x $COLUMNS -y $LINES"
        su - $TARGET_USER -c "nohup ttyd -p 7681 -W tmux new-session -A -s worker $TMUX_SIZE /tmp/worker-wrapper.sh > /tmp/ttyd.log 2>&1 &"
        
        echo "Worker session started. Browser UI available on port 7681 (guest)."
        
        # Return quickly after launching
        sleep 1
        su - $TARGET_USER -c "tmux has-session -t worker"
    else
        echo "Error: Rules file $RULES_FILE not found."
        exit 1
    fi
else
    echo "Error: No ROLE specified in environment."
    exit 1
fi
