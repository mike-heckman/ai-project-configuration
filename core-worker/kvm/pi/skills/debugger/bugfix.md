---
description: Entrypoint workflow for tracking, intaking, and closing bug reports
---
# Bugfix Lifecycle Workflow

This workflow defines the standard operating procedure for the lifecycle of a bug. This workflow ONLY handles creating the report and managing indexes. It offloads resolution to the `/bug-iteration` workflow.

## 1. Intake and Documentation
When a new bug is reported, follow these steps:

1. **Check Existing Reports:** Review `./docs/backlog/bugs-active.md` and `./docs/backlog/bugs-resolved.md` to see if this is a known issue.
2. **Determine Bug ID:** Find the highest existing `bug-XXXX.md` file in `./docs/backlog/` and increment for the new bug.
3. **Create the Bug Report:** Create the `./docs/backlog/bug-XXXX.md` file using the template in `{{SKILLS_DIR}}/debugger/resources/bug-XXXX.md`. 
4. **Track the Bug:** Add a row for the newly created bug to the table in `./docs/backlog/bugs-active.md`.

## 2. Hand off to Iteration Loop
Transition to the `/bug-iteration` workflow to begin resolution.

## 3. Closure
Once the `/bug-iteration` loop returns a successful outcome:

1. **Update Report Status:** Update the Status at the top of the `./docs/backlog/bug-XXXX.md` file to: `- **Status:** Resolved (YYYY-MM-DD)`.
2. **Untrack from Active:** Remove the row for the bug from `./docs/backlog/bugs-active.md`.
3. **Add to Resolved:** Append a summary row for the bug, including its root cause, to `./docs/backlog/bugs-resolved.md`.
4. **DOD:** Invoke the `/submit` workflow to hand off to the Reviewer.
