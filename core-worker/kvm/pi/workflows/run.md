---
description: Execute the project for testing
---

# /run
1. Execute the shell command: `bash ./scripts/run.sh`  The command automatically outputs STDOUT and STDERR to ./logs/run.log
2. If the script returns a non-zero exit code, analyze the output to identify formatting or syntax errors that could not be auto-fixed.
3. If the command failed, do not proceed to the next step of any calling workflow.
4. Report the status to the user.