---
name: lang_python
description: "Strict Python guidelines for uv workspaces, typing, and pathlib."
activation: "glob_match(**/*.py, **/pyproject.toml)"
---

# 🐍 Python Engineering Standards

## 🏁 Pre-flight & Context
- **Sync:** Call `jCodeMunch.resolve_repo` before any code proposal to verify symbol maps.
- **Local Standards:** Query `docs/coding-standards.md` via `jDocMunch` for project-specific overrides.

## 📦 Env & Dependencies (uv Only)
- **Authority:** Use `uv` exclusively. `pip install` is **PROHIBITED**.
- **Commands:** Use `uv add` for persistent deps; `uv run <cmd>` for all execution.
- **Python Version:** Always use `uv`-managed Python versions (`uv python install`). Avoid relying on the system Python.
- **Venv Creation:** To avoid broken symlinks in containerized environments, create self-contained virtual environments using `python3 -m venv --copies .venv`. Use the path from `uv python find` as the base interpreter to ensure you are using the correct managed version.
- **Constraint:** Strictly honor `pyproject.toml` version/dependency locks.

## 🏗 Architecture & Syntax
- **Patterns:** Document the design pattern in every new class docstring (SOLID required).
- **Paths:** Use `pathlib.Path` for all operations. **PROHIBITED:** `os.path`, `os.getcwd()`, and string concatenation.
- **Formatting:** Ruff/PEP8 compliant. **120 char** limit. Do not edit `.ruff-master-config.toml`.
- **Modernity:** Use `datetime.now(tz=timezone.utc)`. **PROHIBITED:** `datetime.utcnow()`.
- **Errors:** Use explicit chaining: `raise NewError(...) from e`.
- **Logging:** Define `logger = logging.getLogger(__name__)` at module level.

## 🧬 Type Hygiene (Mandatory)
- **Signatures:** Full type hints for all args/returns. Use `Any` only with a `# Reason:` comment.
- **Modern Syntax:** Use `X | Y` (not `Union`) and `X | None` (not `Optional`). 
- **Collections:** Use native `dict`, `list`, `tuple`.
- **Constants:** Use `Final` for constants. No hardcoded inline string literals.

## 🧪 Testing & Docs
- **Frameworks:** `pytest`, `pytest-mock`, and `click` (for CLI).
- **Coverage:** New logic MUST have tests to satisfy the `/ready` workflow.
- **Docstrings:** **Mandatory Google-style multi-line** for ALL symbols. **PROHIBITED:** Single-line docstrings.
- **Security:** Use `field(repr=False)` for secrets in dataclasses.