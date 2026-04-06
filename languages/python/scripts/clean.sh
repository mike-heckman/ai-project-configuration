#!/bin/bash
#
# NOTE: This script is hard-linked via the ai-project-configuration/_setup.sh script. 
# Edits to this file should be made in that location to ensure that edits are 
# intentionally applied to the project template and not just the test script.
# Last edit: 2026-04-02 by Mike
#

set -e

if [ -d "temp" ]; then
    echo "Removing temp directory contents..."
    rm -rf temp/*
else
    echo "Temp directory does not exist. Creating temp directory..."
    mkdir temp
fi

if [ "$(ls -A ./temp/ | wc -l)" -eq 0 ]; then
    echo "Temp folder is now empty."
else
    echo "Failed to clean temp folder. Current contents:"
    ls -la ./temp/
fi
