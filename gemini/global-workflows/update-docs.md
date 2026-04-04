---
description: Synchronize README, Architecture docs, and .agent_context.md with the latest code changes.
---

# /update-docs
1. **Analyze:** Use `jCodeMunch.get_repo_outline` to identify modified modules or new public APIs.
2. **README:** Update the "Features" or "Usage" section of `README.md` if the user-facing interface has changed.
3. **Internal Docs:** Update relevant files in `docs/` (e.g., `api_reference.md` or `setup.md`).
4. **Context Check:** Review `./agent_context.md`.
    - Add any "Tribal Knowledge" discovered during this task (e.g., "The `uv` cache needs to be cleared if X happens").
    - Remove completed items from the "Current Focus" section.
5. **Sync:** Call `jDocMunch.index_documentation` to ensure these changes are immediately available for the next prompt.