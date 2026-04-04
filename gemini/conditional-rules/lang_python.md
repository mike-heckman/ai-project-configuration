# 🐍 Python Engineering Standards
**Activation:** Glob Match (`**/*.py`, `**/pyproject.toml`)

## 🔍 Pre-flight Requirement
- **Index Check:** Before proposing or implementing code changes, you MUST call `jCodeMunch.resolve_repo` to ensure your symbol map is current.

## 📦 Environment & Dependency Management
- **Primary Tool:** Always use `uv`.
- **Operations:** Never use `pip install`. Use `uv add` for dependencies or `uv pip install` for ephemeral needs.
- **Execution:** Never run `python` directly. Always wrap commands: `uv run <command>`.
- **Context:** Strictly honor constraints defined in `pyproject.toml`.

## 🏗 Coding Standards & Architecture
- **SOLID & Patterns:** Strictly adhere to SOLID principles. Every new class docstring MUST explicitly document the design pattern employed.
- **Paths:** **Strict Path requirement.** Use `pathlib` or `Path` for all path construction.
  - *Prohibited:* `os.path`, `os.getcwd()`, and string-based path concatenation.
- **Formatting:** PEP8 compliant via **Ruff**. Strict **120 character** line limit.
- **Strict Typing:** **MANDATORY.** Every function signature must have full type hints for all arguments and return values. 
  - *Constraint:* Use `Any` only as a last resort and provide a comment explaining why.
  - *Validation:* Use `X | None` for nullable types.
  - *Native Types:* Use native collection types (`dict`, `list`, `tuple`).  
  - *Union Types:* Use `X | Y` or `X | None` instead of `Union` or `Optional`.
  - *Constants:* Use `Final` for all constants. Never hardcode string literals inline.  
- **Modern Syntax:**
  - **Timestamps:** Use `datetime.now(tz=timezone.utc)`. `datetime.utcnow()` is strictly prohibited.
- **Robustness:**
  - **Exceptions:** Use explicit chaining: `raise NewError(...) from e`.
  - **Logging:** Define `logger = logging.getLogger(__name__)` at the module level.
  - **Secrets:** Use `field(repr=False)` on dataclass fields holding keys or tokens.

## Linting Strategy: 
The ./.ruff-master-config.toml file is an externally managed file. Do not edit ruff.toml directly. 
If you need to change a rule, suggest an update to the user.

## 🧪 Testing & CLI
- **Framework:** Use `pytest` and `pytest-mock`.
- **CLI:** Prefer `argparse` for standard library consistency.
- **Coverage:** Ensure tests exist for all new logic to satisfy the `/ready` workflow.

## 📝 Documentation
- **Style:** Mandatory **Google-style multi-line** docstrings for ALL functions and classes.
- **Constraint:** Single-line docstrings are prohibited.
- **Custom Standards:** Always query `docs/coding-standards.md` via **jDocMunch** for project-specific overrides.