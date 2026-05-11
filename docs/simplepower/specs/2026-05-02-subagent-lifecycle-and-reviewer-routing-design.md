# Subagent Lifecycle And Reviewer Routing Design

## Context

Simple Power now uses DAG-aware plans and wave-based subagent execution. The
current flow dispatches `sp-impl` workers and one wave reviewer/fixer per wave,
but it does not explicitly require the main agent to close finished subagents
after their results are consumed. In practice, completed subagents can remain
open even though the wave has moved on.

The current reviewer/fixer rule also defaults to the main agent's type, model,
and effort. That is conservative, but it can be wasteful for obvious, localized,
low-risk waves.

## Goals

- Add a required subagent lifecycle checkpoint after every subagent returns a
  final result.
- Make `close` the default lifecycle decision once the result has been read and
  consumed.
- Allow keeping a completed subagent open only when the main agent records a
  short, task-specific reason.
- Require kept subagents to be closed once the reason is resolved and before
  final completion.
- Move reviewer/fixer model choice into planning so the main agent recommends
  the right reviewer tier per wave.
- Allow `gpt-5.4-mini` high-effort reviewer/fixers for obvious, low-risk waves.
- Preserve main-equivalent reviewer/fixers for broad, risky, ambiguous,
  cross-cutting, or behavior-shaping waves.

## Non-Goals

- Do not change the `sp-impl` worker model. It remains `gpt-5.4-mini` with high
  effort unless the user specifies otherwise.
- Do not add an automated background process for closing agents. This is a
  workflow requirement for the coordinating main agent.
- Do not force all reviewer/fixers to use `gpt-5.4-mini`.
- Do not force all reviewer/fixers to use the main agent's model.
- Do not reintroduce per-task commits or branch-finishing automation.

## Subagent Lifecycle Checkpoint

`simplepower:subagent-driven-development` should require a lifecycle checkpoint
after every subagent final result, including implementation workers and
reviewer/fixers.

The checkpoint is:

1. Read and consume the subagent's final report.
2. Decide whether the subagent is still needed.
3. Default to closing the subagent.
4. If keeping it open, write a short reason tied to the current wave or task.
5. Close the subagent when that reason is resolved.

The main agent must not advance to final completion while finished subagents are
left open without an active written reason. The flow should also state that the
main agent must not close a subagent that is still running, blocked, or awaiting
input.

The lifecycle checkpoint should be visible in:

- the `subagent-driven-development` process graph
- the wave rules
- the red flags
- the final handoff guidance

## Reviewer/Fixer Routing

`simplepower:writing-plans` should require each dispatch wave to include a
reviewer/fixer dispatch recommendation chosen by the main agent during planning.

Each wave should state one of:

- `mini-high reviewer/fixer`: use a worker/general subagent with
  `gpt-5.4-mini` and high effort for obvious, localized, low-risk waves.
- `main-equivalent reviewer/fixer`: use the main agent's type, model, and effort
  for broad, risky, ambiguous, cross-cutting, or behavior-shaping waves.

Execution should follow the plan's reviewer/fixer recommendation unless the user
overrides it or the actual wave diff is riskier than the plan predicted. If the
diff is riskier than planned, the main agent may escalate the reviewer/fixer to
main-equivalent settings.

This keeps the reviewer/fixer choice under the main agent's planning judgment
instead of hard-coding one cost profile for every wave.

## Plan Format Changes

Every wave in the `Dispatch Plan` section should include:

- tasks in the wave
- dependencies already satisfied
- parallel safety notes
- review boundary
- reviewer/fixer dispatch recommendation
- verification required before downstream work starts

The `Write Scope Table` should gain a reviewer/fixer dispatch column or include
the reviewer/fixer tier in the wave-level dispatch plan. The plan reviewer should
verify that every wave has a reviewer/fixer recommendation and that the tier is
consistent with the stated risk.

## Execution Behavior

During wave execution, the main agent should:

1. Dispatch the wave's implementation workers.
2. Wait for each worker final result.
3. Run the lifecycle checkpoint for each returned worker.
4. Validate changed files against write scopes.
5. Dispatch the wave reviewer/fixer using the plan's recommended tier, unless
   escalation is warranted.
6. Wait for the reviewer/fixer final result.
7. Run the lifecycle checkpoint for the reviewer/fixer.
8. Run wave verification.
9. Advance only after review, lifecycle cleanup, and verification are complete.

If the lifecycle decision is `keep`, the main agent records why the subagent is
still needed and closes it before final completion unless the user explicitly
asks to preserve the session.

## Testing

Focused static checks should verify:

- `subagent-driven-development` mentions the lifecycle checkpoint.
- `subagent-driven-development` makes `close` the default after a final result is
  consumed.
- `subagent-driven-development` requires written reasons for keeping completed
  subagents open.
- `writing-plans` requires reviewer/fixer dispatch recommendations per wave.
- `writing-plans` mentions both `mini-high reviewer/fixer` and
  `main-equivalent reviewer/fixer`.
- the plan reviewer prompt checks reviewer/fixer routing consistency.

Existing brainstorming behavior, Codex-only tests, and sync script tests should
continue to pass unchanged.
