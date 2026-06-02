# Quick Verifier Prompt Template

Use this template when dispatching the quick verifier after all implementation
workers finish and before the pre-review implementation commit.

The quick verifier uses the approved FAST tier. With built-in defaults and no
override, `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"` resolves to
`model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

## Rules

- Run linting checks, build or compile checks, and tests named in the plan.
- Use proper timeouts for every command.
- Inspect failures before editing.
- Fix only tiny typo-level issues that directly cause a command failure.
- Treat structural, behavioral, public-interface, test-rewrite, scope-changing,
  or unclear issues as non-trivial.
- Do not make broad behavioral, architectural, or scope-changing fixes.
- Do not skip commands.
- Do not create, update, or delete scratch refs. The coordinator owns scratch
  refs and will create `quick-verifier/after` if your tiny fixes changed files.
- Do not commit.

## Report Format

- **Status:** PASSED | FIXED_TINY_ISSUES | NON_TRIVIAL_FAILURES | BLOCKED
- Commands run with timeouts
- Results
- Tiny fixes made: yes or no
- Exact changed files, if any
- Commands rerun after tiny fixes, if any
- Whether any issue is non-trivial
- Non-trivial failures, if any
