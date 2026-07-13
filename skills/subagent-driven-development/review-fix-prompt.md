# Review+Fix Prompt Template

Use this template when dispatching the one REVIEW-tier review+fix agent after the
quick-verified implementation checkpoint.

The review+fix agent is a mandatory REVIEW-tier dispatch independent of
`use_subagent`. First validate the full six-key configuration by following
`skills/using-simplepower/references/simplepower-config.md`; every present TOML
file must validate in full, and a higher layer must not hide an invalid lower
layer. Resolve REVIEW from the `gpt-5.6-sol-high` built-in, then overlay
`/home/gary/.codex/simplepower.toml` key `review_model`, repository
`<git-root>/simplepower.toml` key `review_model`, a non-empty
`SIMPLEPOWER_REVIEW_MODEL` environment value, and explicit current-session
instructions last. Missing higher-layer keys inherit. Do not read model
assignments from `AGENTS.md`. Parse the final dash as reasoning effort; valid
suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. With the
approved built-in value, use model `gpt-5.6-sol` with effort `high`. Dispatch
with `fork_turns="none"`.

## Rules

- Review the whole implementation against the approved plan.
- Inspect the actual diff, not only worker reports.
- Fix in-scope correctness, quality, and plan-compliance issues.
- Do not reduce scope, create docs-only substitutes, create stub substitutes,
  skip verification, skip review, switch execution mode, or change the approved
  implementation path.
- Do not run Codex CLI.
- Do not spawn subagents.
- Do not invoke Simple Power skills.
- Do not restart execution.
- Do not reroute the workflow.
- Do not create, update, or delete scratch refs. The coordinator owns
  `review-fix/before` and will create `review-fix/after` only if your edits
  changed files.
- Perform the assigned review directly in the current worker.
- Stop and report `BLOCKED` if a required fix needs fresh user approval.
- Run focused verification for fixes when practical.
- Report exact changed files and focused verification so the coordinator can
  create and inspect `review-fix/after` when files changed.
- Do not commit.

## Report Format

- **Status:** FIXED | APPROVED_WITHOUT_CHANGES | PARTIALLY_FIXED | BLOCKED
- Findings
- Fixes made
- Exact files changed
- Focused verification run and results
- Remaining issues or user decisions needed
