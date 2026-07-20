---
name: subagent-driven-development
description: Use only when the user explicitly requests simplepower:subagent-driven-development or an authorized Simple Power chain invokes it.
---

# Subagent-Driven Development

## Purpose

Execute an accepted `simplepower:writing-plans` implementation plan in the
current Codex session. The plan is authoritative and must contain an
`Interface Contract`, `File Ownership`, task `Contract inputs`,
`Serialization required`, verification commands, and model allocation.

This skill is the coordinator workflow for `sp-impl` workers, the FAST quick
verifier, and a configuration-controlled final review+fix phase. `review_model2`
can add a read-only second plan reviewer during planning, but never affects
final review or adds a writer or checkpoint. This skill uses capacity-aware rolling aggregate
scheduling: build the complete ready set, fill every available child agent slot
with ready non-conflicting work, and immediately dispatch the next queued ready
task whenever a worker finishes and is lifecycle-closed.

Capacity queuing is not `Serialization required: Yes`. A task is truly
serialized only for an approved concrete reason: overlapping write scopes,
missing or ambiguous contract/dependency, a required generated artifact that
must exist first, or intentional sequential runtime/migration ordering.

Stable report terms: `approved-path`, `no-worker-commit`, and
`final commit condition`.

## Approved Path

The approved plan is authoritative. Do not use a backup plan, escape plan,
fallback implementation, reduced scope, docs-only substitute, stub substitute,
skipped verification, skipped review, execution-mode switch, or alternate
implementation strategy unless the user gives fresh explicit approval at the
moment the deviation is needed.

At each lifecycle boundary, compare actual work against the approved plan,
`File Ownership`, task write scopes, `Contract inputs`, and required
verification:

- before any dispatch;
- after each worker, quick-verifier, or final review+fix result;
- before quick verification;
- before the quick-verified implementation checkpoint;
- before review+fix;
- before final verification;
- before the final commit.

If work is incomplete, substituted, stubbed, docs-only, out of scope, missing
required verification, or based on a different execution mode, do not accept it
as progress. Stop, report the exact mismatch and current status, and ask the
user before changing approach. Diagnostic investigation is allowed; alternate
implementation work is not.

## Implied Write-Scope Corrections

When a worker reports that a required file is outside its assigned write scope,
or the coordinator detects that a task needs a file missing from its write
scope, classify the mismatch before asking the user.

An `implied-scope omission` exists only when the missing file is already named
or structurally required by the approved spec, plan file-structure section,
task `Files:` block, task prose, task snippets, verification instructions, or
public declaration requirements. For an implied-scope omission, the coordinator
may update the plan's `File Ownership` entry for that task, update the task
write scope, record the correction, and continue with the same approved task.

A `true scope expansion` exists when the missing file or strategy is not
already implied by approved text. Stop and ask the user for fresh explicit
approval before changing scope, strategy, verification, review approach, or
implementation work.

Workers and the final review+fix agent must not self-expand write scope. They
report `BLOCKED` or `NEEDS_CONTEXT`; the coordinator owns classification and
any plan correction.

## Required Read Points

Before dispatching any subagent, read the approved plan and validate the
sections named above.

Before creating, diffing, deleting, or reporting scratch refs, read
`./scratch-ref-workflow.md` and use its command shapes. Scratch refs live only
under `refs/simplepower/scratch/<run-id>/` and are coordinator-owned local
review anchors, not branches, accepted commits, pushed refs, merged refs,
rebased refs, worker commits, or task commits.

## Model And Config Routing

Before any model-controlled dispatch, validate model configuration by following
`skills/using-simplepower/references/simplepower-config.md`. Validate every
present TOML file in full before overlays; a higher layer must not hide
malformed TOML, unknown keys, wrong types, or invalid model values in a lower
layer.

Resolution order is: built-in defaults, `~/.codex/simplepower.toml`,
repository `<git-root>/simplepower.toml`, the supported non-empty
`SIMPLEPOWER_*` environment overrides, then explicit current-session
instructions. Missing higher-layer keys inherit. Do not read model assignments
from any `AGENTS.md` file. Parse the final dash-delimited segment as
`reasoning_effort`; valid suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`.

The seven base keys are `use_subagent`, `skip_final_review`, `subagent_model`,
`review_model`, `best_model`, `normal_model`, and `fast_model`; `review_model2`
and `final_review_model` are optional keys, not mandatory tiers. Resolve the
primary `review_model` first. Then resolve a present `final_review_model` from
the home file, repository file, `SIMPLEPOWER_FINAL_REVIEW_MODEL`, and explicit
current-session instructions; an absent value falls back to fully resolved
`review_model`. Validate and parse it with the same rules even when final review
is skipped. Resolve
`review_model2` the same way: it has no environment variable, and an absent
value or exact match with fully resolved `review_model` disables the optional
read-only plan-review secondary.

Routing decisions:

- `sp-impl`: use the plan-approved FAST, NORMAL, or BEST tier. Escalate FAST
  to NORMAL/BEST when the work is less mechanical than planned; escalate NORMAL
  to BEST when the task is broad, ambiguous, behavior-shaping, high risk, or
  hard to verify. Record the reason.
- Quick verifier: use FAST. With built-in defaults this resolves to
  `model="gpt-5.3-codex-spark"` and `reasoning_effort="xhigh"`.
- Final review+fix: when `skip_final_review=false`, use the effective
  `final_review_model`. Exactly one final review+fix agent is the only
  final-review agent and writer after the quick-verified implementation
  checkpoint. When `skip_final_review=true`, do not create final-review scratch
  refs or dispatch that agent; continue with final verification and the final
  checkpoint condition.
- Plan-review secondary: a distinct parsed optional `review_model2` is
  read-only and applies only to plan review; it does not affect this final
  review flow.

Every Simple Power dispatch uses `fork_turns="none"` and a self-contained
prompt. There are no conversation-history inheritance exceptions.

## Authoritative Lifecycle

1. Read the accepted plan and model allocation. Confirm it is a reviewed,
   approved `simplepower:writing-plans` plan, not a backup or substitute.
2. Validate the `Interface Contract`, `File Ownership`, every task's
   `Contract inputs`, `Serialization required`, write scope, model tier,
   verification commands, and output requirements.
3. Classify all `sp-impl` tasks:
   - ready aggregate tasks: `Serialization required: No`, non-overlapping
     approved write scopes, and `Contract inputs` satisfied by the accepted
     `Interface Contract`;
   - true serialized tasks: approved `Serialization required: Yes` with a
     concrete reason and the exact condition or point when it may run;
   - blocked tasks: missing ownership, ambiguous contract, invalid model
     allocation, or unclear serialization condition.
4. Stop for user direction if any task is blocked in a way that is not an
   implied-scope omission.
5. Build the complete set of non-conflicting contract-ready `sp-impl` tasks.
   Put ready tasks that do not fit current child-agent capacity into a queued
   ready list; do not mark them serialized merely because capacity is full.
6. Dispatch ready `sp-impl` tasks with `fork_turns="none"` until all child-agent
   slots are full or no ready task remains. Never leave an available slot idle
   while queued ready work remains.
7. Whenever a worker finishes, run the lifecycle checkpoint immediately:
   consume its report, inspect the actual diff, validate changed files against
   approved ownership, decide close-by-default or record a written reason to
   keep it open, then dispatch the next queued ready task into the freed slot.
8. Continue rolling dispatch until every ready aggregate task is complete.
   Dispatch true serialized tasks only after their approved condition is
   satisfied; once ready, they also use the same slot-filling queue.
9. Before quick verification, ensure all required `sp-impl` work is complete,
   no finished worker remains open without a written reason, and every changed
   file is in approved ownership.
10. Create `refs/simplepower/scratch/<run-id>/quick-verifier/before` for the
    approved file list. If this fails, stop before relying on the missing
    anchor.
11. Dispatch the quick verifier from `quick-verifier-prompt.md` with the
    approved FAST model, `fork_turns="none"`, and a self-contained prompt
    containing the plan, approved file list, worker results, exact commands,
    timeouts, and expected results.
12. The quick verifier runs lint/build/tests named in the plan. It may fix only
    tiny typo-level issues that directly cause a command failure. Non-trivial
    failures stop the workflow for user direction before further
    implementation, review, or commit work.
13. After quick verifier returns, lifecycle-close it by default, inspect the
    report and actual diff, validate any changed files, and if tiny fixes
    changed files create `quick-verifier/after` and inspect the scratch diff.
    Omit the `after` ref when no files changed.
14. Create the coordinator quick-verified implementation checkpoint commit.
    If no uncommitted implementation changes remain, record the no-empty-commit
    outcome as the successful checkpoint. No worker commits. Delete
    quick-verifier scratch refs only after this checkpoint succeeds.
15. Resolve and validate `skip_final_review`, `review_model`, and the optional
    `final_review_model`.
16. When `skip_final_review=false`, create
    `refs/simplepower/scratch/<run-id>/review-fix/before` from the quick-verified
    checkpoint state for the approved file list. If this fails, stop before
    review+fix. Dispatch exactly one final review+fix agent from
    `review-fix-prompt.md` with the effective final model, whole diff, approved
    plan, ownership, worker reports, verification evidence, scratch context,
    and `fork_turns="none"`. It has direct in-scope review+fix authority.
17. When that agent runs, lifecycle-close it by default, inspect its report and
    actual diff, validate changed files, create `review-fix/after` only if it
    changed files, and inspect the scratch diff before final verification. When
    `skip_final_review=true`, skip steps 16-17 without creating review+fix refs.
18. Run final verification from the approved plan and any repo-required checks
    for the changed files.
19. Inspect `git status --short`. Create a final commit only if uncommitted
    changes remain after final verification; do not create an empty final
    commit. Delete review+fix scratch refs after the final checkpoint succeeds,
    then run the final cleanup check for `refs/simplepower/scratch/<run-id>/`.
20. Report verification results, coordinator checkpoint SHA, final commit SHA
    when created, changed files, dispatch decisions, capacity queue behavior,
    any serialized tasks and reasons, lifecycle status, scratch run id when
    refs were created, scratch-ref cleanup status or cleanup commands for
    preserved refs, whether final review ran or was skipped, and, when it ran,
    whether `final_review_model` was explicitly selected or fell back to
    `review_model`.

## Dispatch Rules

- Use only accepted plans with `Interface Contract`, `File Ownership`,
  `Contract inputs`, and `Serialization required`.
- Validate each task's `Contract inputs` against the accepted `Interface
  Contract`, approved design details, explicit external facts, or approved
  serialized artifact condition.
- `Serialization required: No` is the default aggregate path. `Serialization
  required: Yes` must name an approved concrete reason and the point when the
  task may run.
- Do not block a task merely because it relies on another worker's uncommitted
  implementation when the accepted `Interface Contract` defines the public API,
  filename, command contract, fixture, data shape, behavior guarantee, or
  cross-task assumption it needs.
- Do not treat capacity limits as serialization. Record capacity-limited tasks
  as queued ready tasks and dispatch them as soon as a slot opens.
- Serialize only for approved overlap, missing or ambiguous contracts, required
  generated artifacts, or intentional sequential runtime/migration ordering.
- Make every `sp-impl` prompt self-contained using
  `implementer-prompt.md`: full task text, read scope, write scope,
  constraints, `Contract inputs`, `Serialization required`, model tier,
  required output, exact verification commands, timeouts, and expected results.
- Do not require a worker to read the plan file to discover its own task.
- Every dispatch is:
  `spawn_agent(agent_type="worker", model=<resolved_model>, reasoning_effort=<resolved_effort>, fork_turns="none", message=<self-contained-prompt>)`.
- Record any model escalation, serialization exception, capacity scheduling
  decision, or lifecycle exception with a written reason.
- No worker commits. No per-task commits. Workers, quick verifiers, and final
  review+fix agents must not create, update, delete, inspect, or manage refs.

## Scratch Refs

Scratch refs are coordinator-owned evidence for review diffs. They do not
change the three accepted coordinator checkpoints: accepted plan,
quick-verified implementation, and final verification/final commit condition.

All temporary refs for one run live under
`refs/simplepower/scratch/<run-id>/`, where the run id is
`YYYYMMDD-HHMMSS-<short-head>`. Record the run id in working notes and final
reporting whenever scratch refs are created.

Use `./scratch-ref-workflow.md` for exact commands, including temporary-index
creation, diffing, phase cleanup, final cleanup checks, and preserved-ref
cleanup commands.

Phase ownership and timing:

- Plan review refs are created and deleted by the planning coordinator, not by
  `sp-impl`, quick verifier, or final review+fix agents.
- Quick-verifier `before` is created after all workers complete and before the
  quick verifier dispatch. Quick-verifier `after` is created only when tiny
  fixes changed files. Delete quick-verifier refs only after the
  quick-verified implementation checkpoint succeeds or the no-empty-commit
  outcome is recorded as successful.
- Review+fix `before` is created only when `skip_final_review=false`, after the
  quick-verified implementation checkpoint and before the one final review+fix
  dispatch. Review+fix `after`
  is created only when that agent changes files. Delete review+fix refs only
  after the final checkpoint succeeds or the no-empty-final-commit outcome is
  recorded as successful.
- On user direction, a blocker, scratch-ref creation failure, or failed
  checkpoint commit, preserve scratch refs as evidence and report the manual
  cleanup command from `scratch-ref-workflow.md`.

If scratch-ref creation fails, stop the review loop before relying on the
missing anchor. For quick-verifier tiny fixes and primary review+fix edits,
inspect the scratch diff before creating the next accepted checkpoint.

## Subagent Lifecycle

Run a lifecycle checkpoint after every subagent final result, including
`sp-impl`, quick verifier, and final review+fix.

Default lifecycle decision: close.

At each checkpoint:

1. Read and consume the final report.
2. Inspect the actual diff and validate approved ownership.
3. Decide whether the subagent is still needed.
4. Close it by default.
5. If keeping it open, record a written reason tied to current plan execution.
6. Close it as soon as that reason is resolved.
7. If queued ready work remains and capacity is available, dispatch the next
   ready worker immediately after closure.

Do not close a subagent that is still running, blocked, or awaiting input. Do
not reach final completion while finished subagents remain open without an
active written reason.

## Prompt Templates

- `./implementer-prompt.md` - self-contained `sp-impl` worker prompt.
- `./quick-verifier-prompt.md` - self-contained FAST quick-verifier prompt.
- `./review-fix-prompt.md` - self-contained final review+fix prompt.

## Red Flags

Never:

- Dispatch implementation before validating `Interface Contract`, `File
  Ownership`, `Contract inputs`, and `Serialization required`.
- Dispatch parallel tasks with overlapping write scopes.
- Dispatch a task with missing or ambiguous contract inputs.
- Mark capacity queueing as `Serialization required: Yes`.
- Leave an available child-agent slot idle while queued ready work remains.
- Stage non-overlapping work behind another worker's uncommitted result when
  the accepted `Interface Contract` already supplies the needed contract.
- Ignore an approved `Serialization required: Yes` reason.
- Skip explicitly serialized implementation tasks before quick verification.
- Trust worker status reports instead of inspecting the actual diff.
- Accept out-of-scope edits.
- Accept substituted, incomplete, stubbed, docs-only, or reduced-scope work as
  progress.
- Use a backup plan, escape plan, fallback implementation, execution-mode
  switch, or alternate strategy without fresh explicit user approval.
- Continue implementation on an alternate path after a blocker before asking
  the user.
- Require or allow worker commits, per-task commits, or ref management.
- Let a worker, quick verifier, or final review+fix agent update the approved
  plan unless that edit is explicitly assigned.
- Let a worker read the plan file instead of receiving the task text and
  context.
- Skip quick verification, the quick-verified implementation checkpoint, final
  verification, or the final commit condition. Skip the final review+fix pass
  only when effective `skip_final_review=true`.
- Skip required scratch-ref creation, scratch diff inspection, phase cleanup,
  preserved-ref reporting, or final cleanup checks.
- Leave a finished subagent open without a written reason tied to the current
  plan execution.
- Merge, push, or create a PR without a separate user request.
- Use stale upstream plugin skill prefixes in this scope.

If a worker asks questions, provide the missing task context or write-scope
details before letting it continue.

If a worker reports a blocker, treat it as real. Gather only the diagnostic
context needed to explain it, classify missing write-scope files as
`implied-scope omission` or `true scope expansion`, and stop for user approval
before true scope expansion or alternate implementation work.

If quick verification finds issues, allow only tiny typo-level fixes that
directly cause a command failure, require reruns of failed commands after tiny
fixes, and stop for user direction on non-trivial failures.

If the final review+fix agent finds issues, fix only within approved write
scopes, run focused verification when practical, and stop if a required fix
needs fresh approval, true scope expansion, reduced scope, docs-only substitute,
stub substitute, skipped verification, changed implementation strategy, or
broader rewrite.

## Integration

Required upstream workflow skill:

- `simplepower:writing-plans` creates the accepted plan this skill executes.

Subagents may use `simplepower:test-driven-development` only when the assigned
prompt explicitly authorizes it and the work fits the task. They must not
recursively invoke Simple Power workflow skills unless their prompt explicitly
requires it.

## Final Completion

Run final verification commands from the approved plan and any repo-required
checks. Inspect `git status --short`. Create a final commit only if
uncommitted changes remain after final verification; do not create an empty
final commit.

Final reporting must include:

- final verification results;
- aggregate dispatch and rolling capacity decisions, including queued tasks and
  slot-filling behavior;
- true serialized tasks and reasons;
- coordinator quick-verified checkpoint SHA;
- final commit SHA when created;
- changed files;
- scratch run id when refs were created;
- scratch-ref cleanup status or cleanup commands for preserved refs;
- final-review outcome: skipped by effective `skip_final_review=true`, or run
  with explicit `final_review_model` or fallback to `review_model`; and
- confirmation that all finished subagents were closed or have an active
  written reason to remain open.
