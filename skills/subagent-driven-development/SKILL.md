---
name: subagent-driven-development
description: Use only when the user explicitly requests simplepower:subagent-driven-development or an authorized Simple Power chain invokes it.
---

# Subagent-Driven Development

## Purpose

Execute an accepted `simplepower:writing-plans` implementation plan in the
current Codex session. The skill name is retained for compatibility, but the
workflow is now an adaptive coordinator for the approved `Implementation Route`:

- `Implementation Route: Main agent` means the coordinator implements the one
  cohesive package directly and dispatches no `sp-impl` implementation worker.
- `Implementation Route: Grouped workers` means the coordinator dispatches
  cohesive, non-overlapping worker packages only when at least two independent
  packages or specialized work materially benefits from delegation.

Both routes preserve the mandatory FAST quick verifier, coordinator-owned final
diff review, final verification, `approved-path`, `no-worker-commit`, and
`final commit condition` safeguards.

The accepted plan's combined approval authorizes both coordinator checkpoint
commits. When execution remains on the approved path and final verification
passes, create the final reviewed/verified implementation commit for remaining
uncommitted in-scope changes without requesting another approval. Fresh user
approval is still required for the deviations defined below, not for the
already-approved final checkpoint commit.

Capacity is only a scheduling constraint. Queue whole cohesive packages when
capacity is full; never split a small package into artificial tiny tasks and
never mark capacity queuing as serialization.

## Approved Path

The accepted plan is authoritative. Do not use a backup plan, escape plan,
fallback implementation, reduced-scope substitute, docs-only substitute, stub
substitute, skipped verification, skipped review, execution-mode switch,
execution-route switch, or alternate implementation strategy unless the user
gives fresh explicit approval at the moment the deviation is needed.

At each lifecycle boundary, compare actual work against the approved plan,
`Implementation Route`, exact changed-file list, implementation steps, risks,
verification commands, checkpoint conditions, `File Ownership` when present,
worker package scopes when present, and relevant contract inputs:

- before edits or dispatch;
- after each grouped worker result;
- before quick verification;
- after the quick verifier result;
- after any coordinator repair;
- before coordinator final diff review;
- before final verification;
- before the final commit condition.

If work is incomplete, substituted, stubbed, docs-only, out of scope, missing
required verification, or based on a different route or strategy, do not accept
it as progress. Stop, report the exact mismatch and current status, and ask the
user before changing approach. Diagnostic investigation is allowed; alternate
implementation work is not.

## Required Plan Validation

Before any edit or dispatch, validate that the plan is accepted and contains
the compact core required for both routes:

- `Design Summary`;
- exactly one `Implementation Route`, either `Main agent` or `Grouped workers`;
- exact changed files and ownership of every file to be edited or deleted;
- complete implementation steps;
- risks;
- timed quick-verification commands with expected results;
- timed final-verification commands with expected results;
- exactly two coordinator checkpoint conditions: approved plan and final
  reviewed/verified implementation.

Also confirm that the accepted plan records combined user approval for both
coordinator checkpoint commits. If that authorization is absent or ambiguous,
stop before edits and request it; do not reinterpret implementation-only
approval as commit authorization.

For `Implementation Route: Main agent`, also validate that the work is one
cohesive package and that the plan states there is no material specialization
benefit from delegation.

For `Implementation Route: Grouped workers`, also validate:

- `Interface Contract`;
- `File Ownership`;
- cohesive `Worker Packages`;
- exact read scopes and write scopes;
- relevant contract inputs for every package;
- serialization decisions with concrete reasons and release conditions;
- FAST/NORMAL/BEST allocation and reasons.

Stop for user direction when the route is missing, ambiguous, contradicted by
the package structure, or would require changing from one approved route to the
other.

## Implied Write-Scope Corrections

When a package report says a required file is outside its assigned write scope,
or the coordinator detects that a file is missing from the approved write scope,
classify the mismatch before asking the user.

An `implied-scope omission` exists only when the missing file is already named
or structurally required by the approved design summary, exact file list,
implementation steps, task prose, snippets, verification instructions, public
declarations, `Interface Contract`, or `File Ownership`. For an implied-scope
omission, the coordinator may update the in-session ownership record for that
package, record the correction, and continue on the same approved route.

A `true scope expansion` exists when the missing file or strategy is not
already implied by approved text. Stop and ask the user for fresh explicit
approval before changing scope, strategy, verification, review approach, or
implementation work.

Grouped workers and the quick verifier must not self-expand write scope. They
report `BLOCKED` or `NEEDS_CONTEXT`; the coordinator owns classification and
any approved correction.

## Required Read Points

Before route execution, read the accepted plan and validate the sections named
above.

Before creating, diffing, deleting, or reporting scratch refs, read
`./scratch-ref-workflow.md` and use its command shapes. Scratch refs live only
under `refs/simplepower/scratch/<run-id>/` and are coordinator-owned local
quick-verifier anchors, not branches, accepted commits, pushed refs, merged
refs, rebased refs, worker commits, or task commits.

## Model And Config Routing

Before any model-controlled dispatch, validate model configuration by following
`skills/using-simplepower/references/simplepower-config.md`. Validate every
present TOML file in full before overlays; a higher layer must not hide
malformed TOML, unknown keys, wrong types, or invalid model values in a lower
layer.

Resolution order is: built-in defaults, `~/.codex/simplepower.toml`,
repository `<git-root>/simplepower.toml`, the supported non-empty environment
overrides, then explicit current-session instructions. Missing higher-layer
keys inherit. Do not read model assignments from any `AGENTS.md` file. Parse
the final dash-delimited segment as `reasoning_effort`; valid suffixes are
`low`, `medium`, `high`, `xhigh`, `max`, and `ultra`.

The seven base keys are `use_subagent`, `skip_final_review`, `subagent_model`,
`review_model`, `best_model`, `normal_model`, and `fast_model`; `review_model2`
and `final_review_model` are optional compatibility keys. `review_model`,
`review_model2`, `final_review_model`, and `skip_final_review` remain
recognized and validated so existing configuration files continue to parse, but
they are deprecated no-ops in the normal execution chain described here.

Active dispatch routing:

- Grouped `sp-impl` workers use the plan-approved FAST, NORMAL, or BEST tier.
  Escalate FAST to NORMAL/BEST when work is less mechanical than planned;
  escalate NORMAL to BEST when work is broad, ambiguous, behavior-shaping,
  high risk, or hard to verify. Record the reason.
- The quick verifier always uses FAST. With built-in defaults this resolves to
  `model="gpt-5.3-codex-spark"` and `reasoning_effort="xhigh"`.
- `Implementation Route: Main agent` dispatches no `sp-impl` worker and uses no
  implementation model routing.

Quick verifier: use FAST. Grouped-worker `Contract inputs` contain only the
relevant approved Interface Contract entries and package facts.

Every retained Simple Power dispatch uses exact `fork_turns="none"` and a
self-contained prompt. There are no conversation-history inheritance
exceptions.

## Authoritative Lifecycle

1. Read the accepted plan. Confirm it is the approved plan for the current
   execution, not a backup or substitute.
2. Validate route, exact files, implementation steps, risks, timed quick and
   final verification, and the two checkpoint conditions.
3. Validate model configuration before any grouped-worker or quick-verifier
   dispatch. Treat deprecated review settings as validation-only compatibility
   keys.
4. If `Implementation Route: Main agent`, implement the approved cohesive
   package directly in the coordinator session. Do not dispatch an `sp-impl`
   worker for the package.
5. If `Implementation Route: Grouped workers`, classify every package:
   - ready grouped packages: non-overlapping approved write scopes, relevant
     contract inputs satisfied by the accepted `Interface Contract`, and no
     unsatisfied serialization condition;
   - true serialized packages: approved serialization with a concrete reason
     and the exact condition or point when the package may run;
   - blocked packages: missing ownership, ambiguous contract, invalid model
     allocation, unclear route, or unclear serialization condition.
6. Stop for user direction if any package is blocked in a way that is not an
   implied-scope omission.
7. Build the complete ready set of non-conflicting contract-ready grouped
   packages. Put ready packages that do not fit current child-agent capacity
   into a queued ready list; do not split them and do not mark them serialized merely
   because capacity is full.
8. Dispatch ready grouped packages with `fork_turns="none"` until all
   child-agent slots are full or no ready package remains. Never leave an
   available slot idle while queued ready work remains.
9. Whenever a grouped worker finishes, run the lifecycle checkpoint
   immediately: consume its report, inspect the actual diff, validate changed
   files against approved ownership, decide close-by-default or record a
   written reason to keep it open, then dispatch the next queued ready package
   into the freed slot.
10. Continue rolling dispatch until every ready grouped package is complete.
    Dispatch true serialized packages only after their approved condition is
    satisfied; once ready, they use the same whole-package slot-filling queue.
    A required generated artifact is a valid serialization reason when named in
    the approved plan.
11. Before quick verification, ensure all implementation work is complete, no
    finished worker remains open without a written reason, and every changed
    file is in approved ownership.
12. Create `refs/simplepower/scratch/<run-id>/quick-verifier/before` for the
    approved changed-file list. If this fails, stop before relying on the
    missing anchor.
13. Dispatch the quick verifier from `quick-verifier-prompt.md` with the
    approved FAST model, `fork_turns="none"`, and a self-contained prompt
    containing the design summary, approved file list, relevant contract
    entries, implementation result summaries, exact commands, timeouts, and
    expected results.
14. The quick verifier runs the named lint/build/test commands. It may fix only
    tiny typo-level issues that directly cause a command failure. It reports
    `NON_TRIVIAL_FAILURES` for structural, behavioral, interface,
    scope-changing, or unclear failures.
15. If the quick verifier reports non-trivial failures, the coordinator
    diagnoses them, makes only approved in-scope repairs, and reruns the
    required verification. Do not launch another implementation worker or
    reviewer to handle those failures. If repair needs true scope expansion or
    changed strategy, stop for user approval.
16. After quick verifier returns, lifecycle-close it by default, inspect the
    report and actual diff, validate any changed files, and if tiny fixes
    changed files create `quick-verifier/after` and inspect the scratch diff.
    Omit the `after` ref when no files changed.
17. After quick verification, the coordinator inspects the complete actual diff,
    performs coordinator review for plan compliance, ownership, behavior,
    quality, and verification adequacy, then makes any necessary in-scope
    fixes directly. This is the main agent final review authority.
18. Run final verification from the approved plan and any repository-required
    checks for the changed files.
19. Apply the final reviewed/verified implementation checkpoint condition.
    The accepted combined approval already authorizes this checkpoint. The
    coordinator must create a final commit when uncommitted in-scope changes
    remain, without requesting another approval; do not create an empty commit.
    There is no intermediate quick-verified implementation checkpoint.
20. Delete quick-verifier scratch refs only after the final checkpoint condition
    succeeds, then run the final cleanup check for
    `refs/simplepower/scratch/<run-id>/`.
21. Report verification results, final checkpoint SHA or no-empty outcome when
    applicable, changed files, route decision, grouped dispatch decisions,
    capacity queue behavior, any serialized packages and reasons, lifecycle
    status, quick-verifier scratch run id when refs were created, scratch-ref
    cleanup status or cleanup commands for preserved refs, and coordinator
    review findings/fixes.

## Dispatch Rules

- Use only accepted plans with a valid `Implementation Route`.
- For `Main agent`, do not dispatch an implementation worker.
- For `Grouped workers`, dispatch only cohesive package units. Closely related
  code and tests stay in one package unless their write scopes and contracts
  are genuinely independent.
- Validate each grouped package's contract inputs against the accepted
  `Interface Contract`, approved design details, explicit external facts, or
  approved serialized artifact condition.
- `Serialization required: No` is the default grouped-worker path.
  `Serialization required: Yes` must name an approved concrete reason and the
  point when the package may run.
- Do not block a package merely because it relies on another worker's
  uncommitted implementation when the accepted `Interface Contract` defines the
  public API, filename, command contract, fixture, data shape, behavior
  guarantee, or cross-package assumption it needs.
- Do not treat capacity limits as serialization. Record capacity-limited
  packages as queued ready packages and dispatch them as soon as a slot opens.
- Serialize only for approved overlap, missing or ambiguous contracts, required
  generated artifacts, or intentional sequential runtime/migration ordering.
- Make every grouped `sp-impl` prompt self-contained using
  `implementer-prompt.md`: package-specific design summary, relevant contract
  entries, exact read scope, exact write scope, package steps, verification,
  timeouts, expected results, and completion report requirements.
- Do not paste the complete plan or repeated global boilerplate into grouped
  worker prompts. Do not require a worker to read the plan file to discover its
  own package.
- Every dispatch is:
  `spawn_agent(agent_type="worker", model=<resolved_model>, reasoning_effort=<resolved_effort>, fork_turns="none", message=<self-contained-prompt>)`.
- Record any model escalation, serialization exception, capacity scheduling
  decision, route concern, or lifecycle exception with a written reason.
- No worker commits. No per-package commits. Workers and quick verifiers must
  not create, update, delete, inspect, or manage refs.
- No per-task commits.

## Scratch Refs

Scratch refs are coordinator-owned evidence for quick-verifier diffs. They do
not change the two accepted coordinator checkpoints: approved plan and final
reviewed/verified implementation.

All temporary refs for one run live under
`refs/simplepower/scratch/<run-id>/`, where the run id is
`YYYYMMDD-HHMMSS-<short-head>`. Record the run id in working notes and final
reporting whenever scratch refs are created.

Use `./scratch-ref-workflow.md` for exact commands, including temporary-index
creation, diffing, phase cleanup, final cleanup checks, and preserved-ref
cleanup commands.

Phase ownership and timing:

- Quick-verifier `before` is created after all implementation edits are
  complete and before the quick verifier dispatch.
- Quick-verifier `after` is created only when tiny fixes changed files.
- Delete quick-verifier refs only after the final reviewed/verified
  implementation checkpoint succeeds or the no-empty-final-commit outcome is
  recorded as successful.
- On user direction, a blocker, scratch-ref creation failure, or failed
  checkpoint, preserve scratch refs as evidence and report the manual cleanup
  command from `scratch-ref-workflow.md`.

If scratch-ref creation fails, stop the verification loop before relying on the
missing anchor. For quick-verifier tiny fixes, inspect the scratch diff before
final verification.

## Subagent Lifecycle

Run a lifecycle checkpoint after every retained subagent final result,
including grouped `sp-impl` workers and the quick verifier.

Default lifecycle decision: close.

At each checkpoint:

1. Read and consume the final report.
2. Inspect the actual diff and validate approved ownership.
3. Decide whether the subagent is still needed.
4. Close it by default.
5. If keeping it open, record a written reason tied to current plan execution.
6. Close it as soon as that reason is resolved.
7. If queued ready grouped work remains and capacity is available, dispatch the next queued ready package into the freed slot.
   Do so immediately after closure.

Do not close a subagent that is still running, blocked, or awaiting input. Do
not reach final completion while finished subagents remain open without an
active written reason.

## Prompt Templates

- `./implementer-prompt.md` - self-contained grouped `sp-impl` package prompt.
- `./quick-verifier-prompt.md` - self-contained FAST quick-verifier prompt.

## Red Flags

Never:

- Start edits or dispatch before validating `Implementation Route`, exact
  files, implementation steps, risks, timed checks, and two checkpoint
  conditions.
- Dispatch an `sp-impl` worker for `Implementation Route: Main agent`.
- Use `Implementation Route: Grouped workers` for fewer than two independent
  non-overlapping packages unless specialized delegation has a documented
  material benefit.
- Split cohesive package work into tiny tasks because of capacity.
- Dispatch grouped packages with overlapping write scopes.
- Dispatch a grouped package with missing or ambiguous contract inputs.
- Mark capacity queueing as `Serialization required: Yes`.
- Leave an available child-agent slot idle while queued ready work remains.
- Stage non-overlapping work behind another worker's uncommitted result when
  the accepted `Interface Contract` already supplies the needed contract.
- Ignore an approved `Serialization required: Yes` reason.
- Skip explicitly serialized grouped packages before quick verification.
- Trust worker status reports instead of inspecting the actual diff.
- Accept out-of-scope edits.
- Accept substituted, incomplete, stubbed, docs-only, or reduced-scope work as
  progress.
- Use a backup plan, escape plan, fallback implementation, execution-route
  switch, or alternate strategy without fresh explicit user approval.
- Continue implementation on an alternate path after a blocker before asking
  the user.
- Require or allow worker commits, per-package commits, or ref management.
- Let a worker or quick verifier update the approved plan unless that edit is
  explicitly assigned.
- Let a worker read the plan file instead of receiving package-specific
  context.
- Skip quick verification, coordinator final diff review, final verification,
  or the final commit condition.
- Skip required quick-verifier scratch-ref creation, scratch diff inspection,
  phase cleanup, preserved-ref reporting, or final cleanup checks.
- Leave a finished subagent open without a written reason tied to the current
  plan execution.
- Merge, push, or create a PR without a separate user request.
- Use stale upstream plugin skill prefixes in this scope.

If a grouped worker asks questions, provide the missing package context or
write-scope details before letting it continue.

If a grouped worker reports a blocker, treat it as real. Gather only the
diagnostic context needed to explain it, classify missing write-scope files as
`implied-scope omission` or `true scope expansion`, and stop for user approval
before true scope expansion or alternate implementation work.

If the quick verifier finds issues, allow only tiny typo-level fixes that
directly cause a command failure. Non-trivial failures return to the
coordinator for diagnosis, approved in-scope repair, and verification rerun.

If coordinator review finds issues, fix only within approved write scopes, run
focused verification when practical, and stop if a required fix needs fresh
approval, true scope expansion, reduced scope, docs-only substitute, stub
substitute, skipped verification, changed implementation strategy, or broader
rewrite.

## Integration

Required upstream workflow skill:

- `simplepower:writing-plans` creates the accepted adaptive plan this skill
  executes.

Grouped workers may use `simplepower:test-driven-development` only when the
assigned prompt explicitly authorizes it and the work fits the package. They
must not recursively invoke Simple Power workflow skills unless their prompt
explicitly requires it.

## Final Completion

Run final verification commands from the approved plan and any repo-required
checks for the changed files. Inspect the final diff and working tree state
within the approved scope. Apply the final commit condition only after
coordinator review and final verification pass.

The accepted combined approval authorizes the final checkpoint commit. Create
it whenever uncommitted in-scope changes remain, without requesting another
approval; do not create an empty commit. No worker commits. No per-task commits.

Final reporting must include:

- status and final verification results;
- selected route: `Main agent` or `Grouped workers`;
- for `Main agent`, confirmation that no `sp-impl` implementation worker was
  dispatched;
- for `Grouped workers`, aggregate dispatch and rolling capacity decisions,
  including queued packages and slot-filling behavior;
- true serialized packages and reasons;
- coordinator review findings and in-scope fixes;
- final checkpoint SHA or no-empty outcome when applicable;
- changed files;
- quick-verifier scratch run id when refs were created;
- scratch-ref cleanup status or cleanup commands for preserved refs; and
- confirmation that all finished subagents were closed or have an active
  written reason to remain open.
