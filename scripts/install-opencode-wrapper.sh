#!/usr/bin/env bash
# Install the global opencode-sandbox wrapper

set -e

# Create the bin directory if it doesn't exist
mkdir -p "$HOME/bin"

WRAPPER_PATH="$HOME/bin/opencode-sandbox"

cat > "$WRAPPER_PATH" << 'EOF'
#!/usr/bin/env bash
# Global Opencode Sandbox Wrapper

PROJECT_DIR=$(pwd)

# Default to current user and typical endpoints if not set
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-http://host.docker.internal:4000}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-sk-ant-dummy-key}"

# Ensure configuration directories exist on the host
mkdir -p "$HOME/.config/opencode"
mkdir -p "$HOME/.local/share/opencode"

# Auto-seed the configuration file if it doesn't exist to use the local LLM proxy by default
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CONF_EOF'
{
  "server": {
    "port": 4096,
    "hostname": "0.0.0.0",
    "mdns": true,
    "cors": []
  }
  "mcp": {
    "jcodemunch": {
      "type": "local",
      "command": ["jcodemunch-mcp"],
      "enabled": true
    },
    "jdocmunch": {
      "type": "local",
      "command": ["jdocmunch-mcp"],
      "enabled": true
    }
  },
  "provider": {
    "local-proxy": {
      "npm": "@ai-sdk/anthropic",
      "name": "Local Anthropic Proxy",
      "options": {
        "baseURL": "http://100.117.201.1:1234/"
      },
      "models": {
        "gemma4-26b": {
          "name": "gemma-4-26b-a4b-it-mlx"
        }
        "gemma4-31b": {
          "name": "gemma-4-31b-it-mlx"
        }
      }
    }
  },
  "model": "local-proxy/gemma4",
  "permission": {
    "*": "allow"
  }  
}
CONF_EOF
fi


# Ensure we run opencode by default, or if passing flags like -m
if [ $# -eq 0 ]; then
    ARGS=("opencode" "--prompt" "Start AGENTS.md")
elif [[ "$1" == -* ]]; then
    ARGS=("opencode" "$@")
else
    ARGS=("$@")
fi

docker run -it --rm \
  --network host \
  -p 4096:4096 \
  -v "$PROJECT_DIR:/workspace" \
  -v "$HOME/.agents:/home/${USER:-user}/.agents:ro" \
  -v "$HOME/.agents/templates/AGENTS.md:/home/${USER:-user}/.config/opencode/AGENTS.md:ro" \
  -v "$HOME/.agents/rules:/home/${USER:-user}/.config/rules:ro" \
  -v "$HOME/.config/opencode:/home/$USER/.config/opencode" \
  -v "$HOME/.local/share/opencode:/home/$USER/.local/share/opencode" \
  -e OPENCODE_SERVER_PASSWORD="$(basename "$PROJECT_DIR")" \
  -e OPENCODE_SERVER_USERNAME="${USER:-user}" \
  -e ANTHROPIC_BASE_URL \
  -e ANTHROPIC_API_KEY \
  -e JCODEMUNCH_USE_AI_SUMMARIES=false \
  opencode-sandbox "${ARGS[@]}"
EOF

chmod +x "$WRAPPER_PATH"

echo "Wrapper installed to $WRAPPER_PATH."
echo "Make sure $HOME/bin is in your PATH."
