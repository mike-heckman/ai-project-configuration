---
description: Run the standardized unit test and coverage script (scripts/test.sh).
---

# /test
1. Execute the shell command: `bash scripts/test.sh [test/specific_test1] [test/specific_test2]`
   If you don't specify, all tests are run and coverage data is produced.
   The command automatically outputs STDOUT and STDERR to ./logs/test.log
2. If the script returns a non-zero exit code, analyze the output to identify broken unit tests or syntax errors that must be fixed to continue
3. If the command failed, do not proceed to the next step of any calling workflow.
4. Report the status to the user.