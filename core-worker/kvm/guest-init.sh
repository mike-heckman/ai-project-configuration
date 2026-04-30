#!/bin/bash

# 1. Wait for Incus Agent to handle mounts
# In Incus VMs, the agent typically mounts disk devices automatically.
# We'll check for our mount points.

echo "Verifying mounts..."
# Disable IPv6 to prevent timeouts on systems where it's not fully routed
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
RETRY=0
while [ ! -d "/workspace" ] || [ ! -d "/opt/core-worker" ]; do
    if [ $RETRY -gt 10 ]; then
        echo "Error: Mount points not found after 10 seconds. Is incus-agent running?"
        exit 1
    fi
    sleep 1
    ((RETRY++))
done

# 2. Source environment variables from workspace
if [ -f "/workspace/.agent-worker-env" ]; then
    echo "Sourcing environment from /workspace/.agent-worker-env"
    source /workspace/.agent-worker-env
fi

# 3. Path parity (symlink workspace to original host path if needed)
if [ ! -z "$HOST_WORKSPACE_PATH" ]; then
    echo "Creating path parity for $HOST_WORKSPACE_PATH..."
    mkdir -p "$(dirname "$HOST_WORKSPACE_PATH")"
    ln -sf /workspace "$HOST_WORKSPACE_PATH"
fi

# 4. User and Permissions setup
# Claude Code cannot run as root with --dangerously-skip-permissions.
# We use the default 'ubuntu' user which is typically UID 1000.
TARGET_USER="ubuntu"
if ! id "$TARGET_USER" &>/dev/null; then
    # Fallback to creating mike if ubuntu doesn't exist
    TARGET_USER="mike"
    if ! id "mike" &>/dev/null; then
        useradd -m -s /bin/bash -u 1000 mike
    fi
fi

# Allow target user to use sudo without password
echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-agent-user

# Path parity for /home/mike (common in scripts)
# We use -n to treat existing symlink/dir as a file to be replaced
if [ "$TARGET_USER" = "ubuntu" ]; then
    if [ -d "/home/mike" ] && [ ! -L "/home/mike" ]; then
        # If it's a real directory, move it or remove it to make room for the link
        rmdir "/home/mike" 2>/dev/null || mv "/home/mike" "/home/mike.bak"
    fi
    ln -sfn /home/ubuntu /home/mike
fi

# Ensure config directories exist and are owned by target user
mkdir -p "/home/$TARGET_USER/.agents"
ln -sfn /opt/core-worker "/home/$TARGET_USER/.agents/core-worker"
ln -sfn /opt/core-worker/skills "/home/$TARGET_USER/.agents/skills"
chown -R $TARGET_USER:$TARGET_USER "/home/$TARGET_USER"

# 5. MCP & Pi Configuration link
echo "Configuring AI tools for Worker..."
mkdir -p "/home/$TARGET_USER/.config/claude"
mkdir -p "/home/$TARGET_USER/.config/mcp"
ln -sf "/opt/core-worker/mcp_config.json" "/home/$TARGET_USER/.config/claude/mcp_config.json"
ln -sf "/opt/core-worker/mcp_config.json" "/home/$TARGET_USER/.config/mcp/mcp.json"

# Pi Configuration (Handled via direct mount in worker-bridge.sh)
# mkdir -p "/home/$TARGET_USER/.pi/agent"
# ln -sf "/opt/core-worker/kvm/pi/models.json" "/home/$TARGET_USER/.pi/agent/models.json"

# Link jcodemunch-mcp central config
mkdir -p "/home/$TARGET_USER/.code-index"
ln -sf "/opt/core-worker/config.jsonc" "/home/$TARGET_USER/.code-index/config.jsonc"

chown -R $TARGET_USER:$TARGET_USER "/home/$TARGET_USER/.config" "/home/$TARGET_USER/.code-index" "/home/$TARGET_USER/.pi"

# 6. Launch pi.dev with the specified ROLE inside tmux
if [ ! -z "$ROLE" ]; then
    RULES_FILE="/opt/core-worker/rules/${ROLE}.md"
    # Fallback to -rules.md suffix
    if [ ! -f "$RULES_FILE" ]; then
        RULES_FILE="/opt/core-worker/rules/${ROLE}-rules.md"
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

        # Ensure pi coding agent is installed
        if ! command -v pi &> /dev/null; then
            echo "Pi coding agent not found. Installing..."
            npm install -g @mariozechner/pi-coding-agent
        fi

        # Install pi-mcp-adapter for the target user if not present
        if ! su - "$TARGET_USER" -c "pi list | grep -q pi-mcp-adapter 2>/dev/null"; then
            echo "Installing pi-mcp-adapter..."
            # First ensure pi is initialized for the user
            su - "$TARGET_USER" -c "mkdir -p ~/.pi/agent"
            # Since 'pi install' might be interactive or wait for confirmation, we should ensure it runs non-interactively or we can just run it. 
            su - "$TARGET_USER" -c "pi install npm:pi-mcp-adapter"
        fi

        # Ensure tmux is available
        if ! command -v tmux &> /dev/null; then
            apt-get update && apt-get install -y tmux
        fi
        
        # Ensure common local bin paths are in PATH
        export PATH="$PATH:/usr/local/bin:/home/$TARGET_USER/.local/bin"
        
        # Write the wrapper script (remove old one first to avoid permission issues)
        rm -f /tmp/worker-wrapper.sh
        cat <<EOF > /tmp/worker-wrapper.sh
#!/bin/bash
# Source environment variables (API keys, etc.)
[ -f /workspace/.agent-worker-env ] && source /workspace/.agent-worker-env

export ANTHROPIC_API_KEY=ollama
export PATH="\$PATH:/usr/local/bin:/home/$TARGET_USER/.local/bin"
cd /workspace

# Run Pi as the target user
# We use the prompt to trigger the autonomous loop
set -o pipefail
if ! pi @"${RULES_FILE}" "Immediately begin your autonomous mission. 1. Verify your environment (Node.js, npm, uv). 2. Scan the backlog in ./docs/backlog/ for READY tasks. 3. Complete and verify each task using the instructions in the rules file. 4. Once the backlog is empty and all work is verified, call the 'autonomous_mission_complete' tool to terminate the session. Do not wait for user input." 2>&1 | tee /tmp/worker.log; then
    echo "Pi failed with exit code \$?"
    read -p "Press Enter to exit..."
fi

# Cleanup dead symlinks from the workspace
echo "Cleaning up temporary worker symlinks..."
#rm -f /workspace/.yolo.json /workspace/workspace
EOF
        chmod +x /tmp/worker-wrapper.sh
        chown $TARGET_USER:$TARGET_USER /tmp/worker-wrapper.sh

        # Forcefully restart the session to pick up new environment/rules
        echo "Restarting worker session..."
        su - $TARGET_USER -c "tmux kill-session -t worker 2>/dev/null || true"

        # Run tmux as the target user
        # We force the window size to match the host terminal dimensions if available
        TMUX_SIZE=""
        [ ! -z "$COLUMNS" ] && [ ! -z "$LINES" ] && TMUX_SIZE="-x $COLUMNS -y $LINES"
        su - $TARGET_USER -c "tmux new-session -d -s worker $TMUX_SIZE /tmp/worker-wrapper.sh"
        
        echo "Pi is running in a background tmux session named 'worker' (User: $TARGET_USER)."
        
        # Return quickly after launching
        su - $TARGET_USER -c "tmux has-session -t worker"
    else
        echo "Error: Rules file $RULES_FILE not found."
        exit 1
    fi
else
    echo "Error: No ROLE specified in environment."
    exit 1
fi
