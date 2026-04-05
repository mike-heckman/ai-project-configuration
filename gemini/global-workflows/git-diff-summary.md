---
description: Create a diff sumary between the current branch and the specified origin branch (or main if not specified)
---
# /audit {{origin_branch}}
1. Execute a `git diff {{origin_branch}} > logs/git-diff.txt` substituting the provided branch or main if not specified
2. Process the diff to create a human-readable version of the changes
3. The first two lines should be the current local branch name and the date in iso-9660 format.
4. Output this summary to the project root as ./git-diff-summary.md
