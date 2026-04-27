#!/bin/bash

# 1. Wait for Incus Agent to handle mounts
# In Incus VMs, the agent typically mounts disk devices automatically.
# We'll check for our mount points.

echo "Verifying mounts..."
RETRY=0
while [ ! -d "/workspace" ] || [ ! -d "/home/mike/.agents/core-worker" ]; do
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

# 4. Launch Claude Code with the specified ROLE inside tmux
if [ ! -z "$ROLE" ]; then
    RULES_FILE="/home/mike/.agents/core-worker/rules/${ROLE}.md"
    if [ -f "$RULES_FILE" ]; then
        echo "Launching Claude Code with role: $ROLE"
        
        # Ensure tmux and claude are available
        if ! command -v tmux &> /dev/null; then
            apt-get update && apt-get install -y tmux
        fi
        
        # Start a detached tmux session and run Claude inside it
        # This allows the user to attach and watch from other terminals
        tmux new-session -d -s worker "claude --yolo --prompt '$(cat "$RULES_FILE")'; read -p 'Task complete. Press enter to close session...'"
        
        echo "Claude is running in a background tmux session named 'worker'."
        echo "To watch the live output, run: incus exec $VM_NAME -- tmux attach -t worker"
        
        # Keep the exec process alive so the bridge doesn't exit prematurely
        tmux wait-for worker_done || tail -f /dev/null
    else
        echo "Error: Rules file $RULES_FILE not found."
        exit 1
    fi
else
    echo "Error: No ROLE specified in environment."
    exit 1
fi
