# Quick Verifier Prompt Template

Use this template when dispatching the quick verifier after all implementation
workers finish and before the pre-review implementation commit.

The quick verifier always uses `model="gpt-5.3-codex-spark"` and
`reasoning_effort="high"`.

## Rules

- Run linting checks, build or compile checks, and tests named in the plan.
- Use proper timeouts for every command.
- Inspect failures before editing.
- Fix only tiny typo-level issues that directly cause a command failure.
- Do not make broad behavioral, architectural, or scope-changing fixes.
- Do not skip commands.
- Do not commit.

## Report Format

- **Status:** PASSED | FIXED_TINY_ISSUES | NON_TRIVIAL_FAILURES | BLOCKED
- Commands run with timeouts
- Results
- Tiny fixes made, if any
- Non-trivial failures, if any
- Changed files
