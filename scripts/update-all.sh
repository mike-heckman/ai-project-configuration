#!/usr/bin/env bash
# Update all registered projects by re-running their initialization scripts

set -e

REGISTRY_DIR="${HOME}/.gemini/registered"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

if [ ! -d "$REGISTRY_DIR" ]; then
    echo "No registered projects found in $REGISTRY_DIR."
    exit 0
fi

update_projects() {
    local conf_file="$1"
    local init_script="$2"
    
    if [ ! -f "$conf_file" ]; then
        return
    fi
    
    echo "Updating projects from $(basename "$conf_file")..."
    local temp_conf="${conf_file}.tmp"
    > "$temp_conf"
    
    while IFS= read -r project_path || [ -n "$project_path" ]; do
        if [ -d "$project_path" ]; then
            echo "  -> Syncing $project_path..."
            # Execute the init script within the project directory
            (cd "$project_path" && bash "$init_script")
            echo "$project_path" >> "$temp_conf"
        else
            echo "  [!] Pruning stale path: $project_path"
        fi
    done < "$conf_file"
    
    mv "$temp_conf" "$conf_file"
}

update_projects "${REGISTRY_DIR}/python_locations.conf" "${SCRIPT_DIR}/init-py-project.sh"
update_projects "${REGISTRY_DIR}/ts_locations.conf" "${SCRIPT_DIR}/init-ts-project.sh"

echo ""
echo "All registered projects have been synchronized."
