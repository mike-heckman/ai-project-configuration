---
description: Iteration loop for investigating, fixing, and validating a known bug
---
# Bug Iteration Workflow

This workflow handles the technical resolution of a known bug. It is usually called from the `/bugfix` workflow once a `bug-XXXX.md` file exists.

## 1. Read the bug-XXXX document and any bug documents listed in its "Related bug tickets" section

## 2. Start a New Iteration
**If there isn't an active Iteration header**
In the `./docs/backlog/bug-XXXX.md` file, append a new iteration header:

```
## Iteration Y

(Where Y is the current attempt number, starting at 1).
```

## 3. Investigate & Propose
Fill out the following sections under your `## Iteration Y` header:

```
### Investigation
[Detail the steps taken to investigate the issue. Include file paths, logs, or metrics reviewed.]

### Root Cause
[Explain *why* the bug occurs based on the investigation.]

### Proposed Fix
[Describe the proposed solution, including specific files to modify and the nature of the changes.]

### Regression Prevention & Additional Testing
[Detail how the fix will be validated locally via tests or scripts, and what needs to be added to the codebase to prevent this bug from reoccurring.]
```

## 4. Seek Approval
**STOP AND ASK THE USER FOR APPROVAL**. Do not proceed with code changes until the proposed fix and validation strategy are approved.

## 5. Execute Local Validation & Fix
Once approved:
1. Write the validation test/script first and run it to prove that it fails on the current broken state.
2. Implement the proposed code fix.
3. Run the validation test again to prove the fix works locally.
4. Have the reviewer evaluate the code

## 6. Halt for Deployment & Manual Verification
**STOP AND YIELD TO THE USER.** 
Instruct the user to deploy the changes to the necessary environment and perform manual verification. 

*Agent Note: This is an expected interruption point. If you are starting a fresh session and see an iteration in `bug-XXXX.md` that has a proposed fix but no outcome, assume you are waiting on the user for deployment verification results. Ask the user for the results before proceeding.*

## 7. Document Outcome
Once the user returns with the manual verification results, append them to the bottom of the current Iteration section.

**If SUCCESSFUL:**

```
### Outcome
The fix successfully resolved the issue.
- [X] Automated validation correctly identifies the issue.
- [X] Automated validation passes after the fix was applied.
- [X] Manual verification confirms the reported behavior is resolved.
```

*Transition back to the `/bugfix` workflow for closure.*

**If UNSUCCESSFUL:**

```
### Outcome
The fix did not resolve the issue as expected. 
[Detail what failed during testing, new error messages, or observations.]

*Restart this `/bug-iteration` workflow at Step 1 for the next attempt.*
```
