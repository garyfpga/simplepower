# Simple Power Implementation Routing And Model Allocation Design

## Context

Simple Power currently writes an implementation plan, then asks the user whether
to start subagent implementation, start inline implementation, or stop after the
plan. Subagent execution uses `sp-impl` workers followed by a combined wave
reviewer/fixer. That keeps the workflow compact, but the combined role makes the
review and fix responsibilities harder to audit and makes model routing less
explicit.

The workflow also has fixed model names in skill text. `sp-impl` workers use
`gpt-5.4-mini` with high effort, while reviewer/fixer routing can use either a
mini-high or main-equivalent tier. The next version should let users configure
the fast and best model tiers through environment variables, let the plan choose
between those tiers by risk, and show that allocation before implementation
starts.

## Goals

- Add a post-plan implementation choice that covers current-session subagent and
  inline execution with either inline or separate review.
- Show copyable `/clear` restart commands for subagent implementation in a new
  session, with inline-reviewer and separate-reviewer variants.
- Split execution prompts into explicit worker roles:
  `sp-impl`, `reviewer`, `sp-impl-reviewer`, and `fixer`.
- Use risk-based model allocation between FAST and BEST tiers for
  implementation and review roles.
- Make every `fixer` use the BEST tier.
- Ask the user to approve or adjust model allocation before choosing the
  implementation path.
- Document `SIMPLEPOWER_BEST_MODEL` and `SIMPLEPOWER_FAST_MODEL` in skills and
  README.
- Update README authorship and thanks to the upstream Superpowers author.

## Non-Goals

- Do not add a project-local implementation handoff JSON artifact.
- Do not add or depend on Codex hooks for context restart.
- Do not make Simple Power clear Codex context automatically. The user runs
  `/clear` manually when choosing a new-session command.
- Do not reintroduce Claude, Gemini, OpenCode, Cursor, Copilot, or other
  non-Codex harness support in active workflow docs.
- Do not require per-task commits.

## User Flow

After `simplepower:writing-plans` saves and self-reviews the implementation
plan, it first asks the user to approve the model allocation. The question should
summarize the FAST/BEST choices from the plan for implementation workers,
reviewers, and any fixer paths. The recommended option accepts the allocation.
The alternate option lets the user request allocation changes before execution
mode is selected.

The model allocation question should be shaped like:

1. Accept model allocation (Recommended).
2. Adjust model allocation before implementation.

After model allocation is accepted, `simplepower:writing-plans` asks which
implementation path to use. Use Codex's `askUserQuestion` or
`request_user_input` style tool when available; otherwise ask in plain text.
Offer these current-session options:

1. Subagent implementation in this session with inline reviewer.
2. Subagent implementation in this session with separate reviewer.
3. Inline implementation in this session with inline reviewer.
4. Inline implementation in this session with separate reviewer.

The same handoff text must also show two copyable new-session commands and tell
the user to run `/clear` first:

1. Subagent implementation in a new session with inline reviewer.
2. Subagent implementation in a new session with separate reviewer.

The new-session commands should name the plan path, selected review mode, model
allocation policy, and the required Simple Power skill. They should be
self-contained enough for a fresh session to execute from the saved plan without
needing the previous conversation.

The new-session command templates should be shaped like:

```text
/clear
Use `simplepower:subagent-driven-development` to execute
`docs/simplepower/plans/<plan-file>.md` wave-by-wave with subagent
implementation and inline reviewer mode. Use the plan's approved FAST/BEST
model allocation. Use `sp-impl-reviewer` for implementation plus self-review and
BEST-tier `fixer` for any required fix pass.
```

```text
/clear
Use `simplepower:subagent-driven-development` to execute
`docs/simplepower/plans/<plan-file>.md` wave-by-wave with subagent
implementation and separate reviewer mode. Use the plan's approved FAST/BEST
model allocation. Use `sp-impl` for implementation, `reviewer` for spec and
quality review, and BEST-tier `fixer` for any required fix pass.
```

## Execution Roles

Simple Power should use four explicit execution roles instead of one worker plus
a combined reviewer/fixer:

| Role | Responsibility | Model tier |
|------|----------------|------------|
| `sp-impl` | Implement the assigned task or wave scope only. | FAST or BEST by planned risk |
| `reviewer` | Review spec compliance and code quality only. Do not fix. | FAST or BEST by planned risk |
| `sp-impl-reviewer` | Implement, then perform inline spec compliance and code quality self-review before reporting. | FAST or BEST by planned risk |
| `fixer` | Fix reviewer-found issues inside the assigned write scope. | Always BEST |

Inline reviewer means the implementation unit performs both spec compliance
review and code quality review before reporting completion. Separate reviewer
means implementation and review are distinct stages, and fixes are a distinct
BEST-tier stage when review finds issues.

### Subagent Implementation With Inline Reviewer

For each wave, dispatch one `sp-impl-reviewer` worker per independent task. The
worker implements, self-reviews against the task requirements and code quality,
runs focused verification when practical, and reports changed files and review
findings. No separate reviewer subagent is dispatched for that wave. If later
verification exposes issues that require edits, dispatch a BEST-tier `fixer`.

### Subagent Implementation With Separate Reviewer

For each wave, dispatch one `sp-impl` worker per independent task. After workers
finish and the coordinator validates changed files against write scopes,
dispatch a `reviewer` for the wave or for the reviewed task group described by
the plan. The `reviewer` reports findings only. If review finds issues requiring
edits, dispatch a BEST-tier `fixer` with the reviewer report, actual diff, write
scope, and verification requirements.

### Inline Implementation With Inline Reviewer

The main agent implements each task and performs the same spec compliance and
quality review checklist required from `sp-impl-reviewer`. No reviewer subagent
is dispatched. If a later verification failure requires a focused fix pass, the
main agent may fix directly as coordinator, but any subagent fixer dispatch must
use the BEST tier.

### Inline Implementation With Separate Reviewer

The main agent implements each task or wave, then dispatches a `reviewer`
subagent for spec compliance and code quality review. If the reviewer reports
issues that need edits, dispatch a BEST-tier `fixer` or apply the fix inline
when the plan explicitly keeps fixes in the coordinator. The default subagent
fixer tier is always BEST.

## Model Environment Variables

Simple Power should read two environment variables:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"
```

If an environment variable is unset, Simple Power uses the default shown above.
The value format is `<model>-<reasoning_effort>`, where the final dash suffix is
the reasoning effort. For example:

- `gpt-5.5-high` resolves to `model="gpt-5.5"` and
  `reasoning_effort="high"`.
- `gpt-5.4-mini-high` resolves to `model="gpt-5.4-mini"` and
  `reasoning_effort="high"`.

Skill text should tell agents to resolve the final dash-delimited segment as
the effort and keep the preceding string as the model name. If parsing fails or
the model allocation is unclear, choose BEST.

## Model Allocation Rules

The implementation plan must allocate FAST or BEST per task and per review or
fix stage. The allocation should appear in the dispatch plan, task list, and
write scope table so the user and a fresh session can audit it.

Use FAST for narrow, low-risk, localized implementation or review work where the
write scope is small and the expected behavior is obvious.

Use BEST for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test implementation or review work.

Use BEST for every `fixer`, regardless of risk.

If a planned FAST task becomes broader or riskier once the actual diff is known,
execution should escalate that stage to BEST and record the reason in the wave
notes.

## Plan Format Changes

`simplepower:writing-plans` should add model allocation to the required plan
format:

- The dispatch plan should state the execution role and model tier for each
  wave stage.
- The write scope table should include `Execution role`, `Model tier`, and
  `Review mode` columns.
- Each task should state its planned implementation role, reviewer role if any,
  fixer policy, model tier, and the reason for the tier.
- The self-review checklist should verify that every implementation and review
  stage has a role and tier, and every fixer path is BEST.

The plan should continue to include dependency graph, task progress table, write
scope table, concrete verification commands, no placeholders, no per-task commit
instructions, and one final coordinator commit after final verification.

## Skill And Prompt Changes

`skills/writing-plans/SKILL.md` should own the model allocation approval gate and
the expanded execution-path question. It should document the two environment
variables, risk-based routing, plan fields, and `/clear` restart commands.

`skills/subagent-driven-development/SKILL.md` should replace the combined
`wave reviewer/fixer` flow with role-based dispatch using `sp-impl`,
`reviewer`, `sp-impl-reviewer`, and `fixer`. It should preserve wave dependency
checks, non-overlapping write scopes, `fork_context=false` defaults, lifecycle
checkpoints, `Task Progress` updates, verification before downstream waves, and
one final coordinator commit.

`skills/executing-plans/SKILL.md` should document the two inline modes. Inline
reviewer mode uses the main agent's self-review checklist. Separate reviewer
mode dispatches a `reviewer` subagent after inline implementation and dispatches
a BEST-tier `fixer` only when a subagent fix pass is needed.

Prompt templates under `skills/subagent-driven-development/` should become:

- `implementer-prompt.md` for `sp-impl`.
- `reviewer-prompt.md` for `reviewer`.
- `impl-reviewer-prompt.md` for `sp-impl-reviewer`.
- `fixer-prompt.md` for `fixer`.

The current `wave-reviewer-fixer-prompt.md` should be retired or replaced so
active docs no longer teach the combined reviewer/fixer role.

## README Changes

`README.md` should document:

- The `SIMPLEPOWER_BEST_MODEL` and `SIMPLEPOWER_FAST_MODEL` environment
  variables and their defaults.
- The final `/clear` implementation flow for starting subagent implementation in
  a fresh session.
- The author line:
  no personal author line.
- A short thanks to Jesse Vincent / Prime Radiant, author of Superpowers, for
  the upstream project this fork is based on.

## Testing

Update `tests/simplepower-static/run-tests.sh` so static checks verify:

- `writing-plans` names `SIMPLEPOWER_BEST_MODEL` and
  `SIMPLEPOWER_FAST_MODEL`.
- `writing-plans` asks the user to approve model allocation before choosing
  implementation mode.
- `writing-plans` includes the four current-session implementation options.
- `writing-plans` shows the two `/clear` new-session subagent commands.
- `writing-plans` requires role and model tier fields in plans.
- `subagent-driven-development` documents `sp-impl`, `reviewer`,
  `sp-impl-reviewer`, and `fixer`.
- `subagent-driven-development` says `fixer` always uses BEST.
- `executing-plans` documents inline implementation with separate reviewer.
- The old combined `wave reviewer/fixer` prompt is absent from active workflow
  checks.
- README documents the two environment variables, the `/clear` flow, Gary
  Chow's author line, and thanks to the upstream Superpowers author.

Existing static checks for Simple Power namespace, Codex-only active docs,
generated docs under `docs/simplepower`, lifecycle checkpoints, narrow subagent
context, task progress states, no per-task commits, and final verification
should continue to pass.
