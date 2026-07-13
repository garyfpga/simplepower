# Quick Verifier Prompt Template

Use this template when dispatching the quick verifier after all implementation
workers finish and before the pre-review implementation commit.

The quick verifier is a mandatory FAST-tier dispatch independent of
`use_subagent`. First validate the full six-key configuration by following
`skills/using-simplepower/references/simplepower-config.md`; every present TOML
file must validate in full, and a higher layer must not hide an invalid lower
layer. Resolve FAST from the `gpt-5.3-codex-spark-xhigh` built-in, then overlay
`/home/gary/.codex/simplepower.toml` key `fast_model`, repository
`<git-root>/simplepower.toml` key `fast_model`, a non-empty
`SIMPLEPOWER_FAST_MODEL` environment value, and explicit current-session
instructions last. Missing higher-layer keys inherit. Do not read model
assignments from `AGENTS.md`. Parse the final dash as reasoning effort; valid
suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. With the
approved built-in value, use model `gpt-5.3-codex-spark` with effort `xhigh`.
Dispatch with `fork_turns="none"`.

## Rules

- Run linting checks, build or compile checks, and tests named in the plan.
- Use proper timeouts for every command.
- Inspect failures before editing.
- Fix only tiny typo-level issues that directly cause a command failure.
- Treat structural, behavioral, public-interface, test-rewrite, scope-changing,
  or unclear issues as non-trivial.
- Do not make broad behavioral, architectural, or scope-changing fixes.
- Do not skip commands.
- Do not run Codex CLI.
- Do not spawn subagents.
- Do not invoke Simple Power skills.
- Do not restart execution or reroute the workflow.
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
