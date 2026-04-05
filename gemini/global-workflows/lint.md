---
description: Run the standardized project linting and formatting script (scripts/lint.sh).
---

# /lint
1. Execute the shell command: `bash scripts/lint.sh`  The command automatically outputs STDOUT and STDERR to `./logs/lint.log`
2. If the script returns a non-zero exit code, analyze the output to identify formatting or syntax errors that could not be auto-fixed.
3. If the command failed, do not proceed to the next step of any calling workflow.
4. Report the status to the user.