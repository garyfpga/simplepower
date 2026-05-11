# Pipelined Separate Reviewer Workflow Design

## Context

Simple Power currently offers inline reviewer mode before separate reviewer
mode in the implementation handoff. In practice, separate reviewer agents catch
more useful issues because they review with fresh context instead of reviewing
their own implementation work.

The current subagent-driven execution flow is also conservative: a downstream
wave starts only after the current wave is implemented, reviewed, fixed if
needed, verified, reflected in `Task Progress`, and checkpointed. That is easy
to reason about, but it leaves the next implementation wave idle while a
separate reviewer is running. Simple Power can recover that time by allowing the
next implementation wave to start once upstream implementation is complete and
write scopes validate, while keeping downstream acceptance blocked on upstream
review, verification, and checkpointing.

## Goals

- Recommend separate reviewer mode before inline reviewer mode.
- Recommend fresh context with `/clear` when the saved spec and plan are large.
- Use a deterministic `wc -c` threshold for the fresh-context recommendation.
- Plan DAGs primarily for separate reviewer execution while keeping inline
  reviewer mode available.
- Make interface contracts mandatory in dispatch plans so pipelined downstream
  work has a clear dependency surface.
- Allow separate reviewer execution to pipeline current-wave review with
  next-wave implementation by default.
- Preserve strict acceptance gates: downstream work may start provisionally, but
  it cannot be accepted, verified, or checkpointed before upstream acceptance.
- Preserve coordinator-owned checkpoint commits and the no-worker-commit rule.

## Non-Goals

- Do not add a hook for the 35KB recommendation. The recommendation belongs in
  `simplepower:writing-plans` at handoff time.
- Do not automatically clear Codex context. The user still runs `/clear`
  manually when choosing a fresh-context path.
- Do not remove inline reviewer mode.
- Do not make inline reviewer mode the default recommendation.
- Do not let reviewers edit files.
- Do not let workers, reviewers, or fixers commit.
- Do not add non-Codex harness support.

## Handoff Recommendations

`simplepower:writing-plans` should recommend separate reviewer mode first.
Inline reviewer mode remains available as a lower-latency option, but it should
not be the first recommendation.

After plan self-review and the planning checkpoint commit, the handoff should
compute the saved spec and plan byte count with:

```bash
wc -c "$SPEC_PATH" "$PLAN_PATH"
```

If the combined byte count is greater than `35840`, the handoff recommends a
fresh context path first:

1. Run `/clear`.
2. Start `simplepower:subagent-driven-development` from the saved plan.
3. Use separate reviewer mode with `sp-impl`, then `reviewer`, then BEST-tier
   `fixer` only when needed.

If the combined byte count is `35840` or less, the handoff recommends
current-session execution first:

1. Continue in the current session.
2. Use `simplepower:subagent-driven-development`.
3. Use separate reviewer mode with `sp-impl`, then `reviewer`, then BEST-tier
   `fixer` only when needed.

The handoff should still show the other supported paths after the recommended
one:

- current-session subagent execution with inline reviewer
- fresh-context subagent execution with inline reviewer
- current-session inline implementation with inline reviewer through
  `simplepower:executing-plans`
- current-session inline implementation with separate reviewer through
  `simplepower:executing-plans`

The fresh-context recommendation uses bytes, not characters or token estimates.
The threshold is strictly greater than `35840` bytes, matching 35 KiB.

## Plan DAG Semantics

`simplepower:writing-plans` should plan primarily for separate reviewer mode.
The plan should distinguish three states instead of using vague wave-complete
language:

- implementation readiness: upstream dependencies required before `sp-impl`
  may start
- review readiness: implementation is complete and write-scope validation has
  passed
- acceptance readiness: review, required fixes, verification, `Task Progress`,
  and coordinator checkpoint commit are complete

Inline reviewer mode remains available, but it is a variant that collapses
implementation and review into `sp-impl-reviewer`. It should not drive the
default DAG wording.

Every dispatch wave should define the interface contracts it produces for
downstream work. The applicable contracts may include public functions, command
behavior, file formats, skill text rules, generated document structure, test
fixtures, or other externally consumed behavior. Downstream tasks should state
which upstream contracts they rely on.

Because pipelining is the default for separate reviewer mode, interface clarity
is mandatory. A plan that allows downstream implementation to begin from an
upstream task must make the dependency surface clear enough that a reviewer can
tell whether a finding invalidates downstream work.

## Pipelined Separate Reviewer Execution

`simplepower:subagent-driven-development` should allow wave N+1 `sp-impl`
workers to start after all wave N implementation workers finish and the
coordinator validates wave N changed files against wave N write scopes. Wave N
separate review may run at the same time as wave N+1 implementation.

This is the general default for separate reviewer mode when:

- the dependency graph allows wave N+1 to consume wave N implementation outputs
- wave N and wave N+1 write scopes do not collide
- the plan names the upstream interface contracts that wave N+1 depends on

Wave N+1 work remains provisional while wave N review is open. The coordinator
may let already-running wave N+1 workers finish if wave N review reports
issues. The coordinator must not accept wave N+1 as final progress, mark wave
N+1 as reviewed or verified, run downstream acceptance verification, or
checkpoint downstream work until wave N reaches acceptance readiness.

If wave N review or verification finds an issue that changes or invalidates an
interface used by wave N+1, the coordinator treats wave N+1 as needing
adjustment before acceptance. Already-running downstream workers are not
interrupted by default, but their result cannot be accepted as-is if it was
built on an invalidated contract.

Inline reviewer mode remains stricter. Since implementation and review are
combined in `sp-impl-reviewer`, downstream work should start after accepted
`sp-impl-reviewer` results and required validation. This design does not add
default review/implementation overlap to inline reviewer mode.

## Task Progress

The coordinator continues to own `Task Progress` edits.

For separate reviewer mode:

- `Implemented` is checked after worker results are accepted and write scopes
  validate.
- `Reviewed` is checked after the separate reviewer result is accepted.
- `Fixed` stays `N/A` unless a BEST-tier fixer applies edits.
- `Verified` is checked only after required verification passes.

For inline reviewer mode:

- `Implemented` and `Reviewed` are checked after the `sp-impl-reviewer` result
  is accepted.
- `Fixed` stays `N/A` unless a BEST-tier fixer applies edits.
- `Verified` is checked only after required verification passes.

Pipelining does not allow the coordinator to mark downstream reviewed or
verified status before upstream acceptance. It only allows downstream
implementation workers to run provisionally.

## Verification And Checkpoint Commits

Coordinator checkpoint commits should move to this rule:

> Create the wave checkpoint after wave verification passes and `Task Progress`
> is updated, even if the next wave has already started, but before accepting,
> verifying, or checkpointing downstream work.

This replaces the older requirement that downstream work must not start before
the current wave checkpoint exists. The coordinator still must not accept or
checkpoint downstream work before upstream acceptance is complete.

Workers, reviewers, and fixers must not commit. The coordinator still owns:

- the planning checkpoint after spec and plan are saved and self-reviewed
- each wave checkpoint after that wave reaches acceptance readiness
- the final checkpoint only if final verification leaves uncommitted changes

If an upstream review or verification issue requires fixes after downstream
implementation has started, the upstream fix is handled through the normal
BEST-tier fixer path and included in the upstream wave checkpoint. If downstream
files need adjustment because an upstream interface changed, those downstream
edits belong to the downstream wave before downstream acceptance unless the
approved plan explicitly assigned those files to the upstream fixer scope.

## Plan Reviewer Changes

The plan reviewer prompt should check that:

- separate reviewer mode is the first recommendation
- the context-size recommendation uses `wc -c` over the saved spec and plan
- fresh context is recommended first only when the combined byte count is
  greater than `35840`
- the DAG distinguishes implementation readiness, review readiness, and
  acceptance readiness
- every pipelined dependency has a named interface contract
- downstream work is provisional until upstream review, fixes, verification,
  progress update, and checkpoint commit are complete
- inline reviewer mode remains available but is not the default recommendation
- checkpoint commit instructions match the pipelined acceptance rule

## Skill Changes

`skills/writing-plans/SKILL.md` should update:

- execution handoff recommendation ordering
- current-session and `/clear` command ordering based on the `wc -c` threshold
- dispatch plan requirements for interface contracts
- DAG wording around implementation, review, and acceptance readiness
- self-review checks for pipelined separate reviewer planning

`skills/subagent-driven-development/SKILL.md` should update:

- process graph and wave rules to allow next-wave implementation during
  current-wave review in separate reviewer mode
- task progress rules so downstream work remains provisional
- checkpoint commit rules so wave checkpoints happen before downstream
  acceptance, not necessarily before downstream implementation starts
- red flags to forbid accepting, verifying, or checkpointing downstream work
  before upstream acceptance
- handling for reviewer findings that invalidate an interface used by running
  downstream work

`README.md` should update:

- the implementation-after-`/clear` examples so separate reviewer appears first
- the surrounding prose so separate reviewer is the recommended path
- the fresh-context recommendation rule if README documents handoff choices

## Testing

Focused static tests should verify:

- `writing-plans` recommends separate reviewer before inline reviewer.
- `writing-plans` uses `wc -c "$SPEC_PATH" "$PLAN_PATH"` or equivalent
  deterministic byte counting for the saved files.
- `writing-plans` uses a strict greater-than `35840` byte threshold.
- `writing-plans` recommends `/clear` first above the threshold and
  current-session execution first at or below the threshold.
- `writing-plans` requires interface contracts for pipelined dependencies.
- `writing-plans` distinguishes implementation readiness, review readiness, and
  acceptance readiness.
- `subagent-driven-development` allows wave N+1 implementation during wave N
  separate review after write-scope validation.
- `subagent-driven-development` says downstream work is provisional until
  upstream acceptance.
- `subagent-driven-development` forbids downstream acceptance, verification, or
  checkpointing before upstream review, fixes, verification, progress update,
  and checkpoint commit are complete.
- `subagent-driven-development` updates checkpoint commit wording to allow
  downstream implementation to have started.
- `README.md` lists separate reviewer before inline reviewer for `/clear`
  examples.

Existing Simple Power static tests and explicit skill request tests should
continue to pass.
