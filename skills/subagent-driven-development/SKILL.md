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

Both routes preserve mandatory quick verification, coordinator-owned final
diff review, final verification, `approved-path`, `no-worker-commit`, and
`final commit condition` safeguards. Effective `skip_quick_verifier=true`
selects the main agent; `false` selects the isolated FAST verifier subagent.

The accepted plan's combined approval authorizes two mandatory coordinator
checkpoint types: accepted plan and final reviewed/verified completion. During
the active run it may also authorize a coordinator-owned execution commit when
an objective technical prerequisite requires committed state before approved
testing or work, or when the original plan's execution summary must be created
or refreshed separately. These bounded commits are not worker, package, task,
or convenience checkpoints. When execution remains on the approved path and
terminal verification passes, the newest verified commit is the final
completion checkpoint. Fresh user approval is still required for the deviations
defined below, and commit authorization ends at final handoff.

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
- after the quick-verification result;
- after any coordinator repair;
- before any technical-prerequisite or summary-update commit;
- before coordinator final diff review;
- before final verification;
- before and after updating the original plan's execution summary;
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
- exactly one `Grouped Workers Consent` marker: `Not requested`, `Declined`, or
  `Approved`;
- exact changed files and ownership of every file to be edited or deleted;
- complete implementation steps;
- risks;
- timed quick-verification commands with expected results;
- timed final-verification commands with expected results;
- its own saved path as the coordinator-owned execution record, with the
  concise summary and follow-up-update contract; and
- exactly two mandatory coordinator checkpoint types: approved plan and final
  reviewed/verified completion, plus bounded active-run execution-commit
  conditions.

Also confirm that the accepted plan records combined user approval for both
mandatory checkpoint types and bounded in-scope coordinator execution commits
during the active run. If that authorization is absent or ambiguous, stop
before edits and request it; do not reinterpret implementation-only approval as
commit authorization. The authorization does not survive final handoff.

For `Implementation Route: Main agent`, also validate that the work is one
cohesive package and that the plan states there is no material specialization
benefit from delegation.

For `Implementation Route: Grouped workers`, also validate:

- `Grouped Workers Consent: Approved` recorded during brainstorming; objective
  suitability, silence, uncertainty, or a planning-time suggestion is not
  consent;
- `Interface Contract`;
- `File Ownership`;
- cohesive `Worker Packages`;
- exact read scopes and write scopes;
- relevant contract inputs for every package;
- serialization decisions with concrete reasons and release conditions;
- FAST/NORMAL/BEST allocation and reasons.

Stop for user direction when the route or consent is missing, ambiguous,
contradictory, when grouped execution lacks `Approved` brainstorming consent,
when the route is contradicted by the package structure, or when execution would
require changing from one approved route to the other.

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

Grouped workers and a dispatched quick-verifier subagent must not self-expand
write scope. They report `BLOCKED` or `NEEDS_CONTEXT`; the coordinator owns
classification and any approved correction.

## Required Read Points

Before route execution, read the accepted plan and validate the sections named
above.

If the main-agent context was compacted or reconstructed, reread the active plan
before another question, tool, edit, dispatch, verification command, or
checkpoint decision. Revalidate route, exact scope, the current continuity
snapshot, and `Next action`. Missing, ambiguous, unreadable, or unwritable plan
state blocks execution; preserve current work and report recovery details
instead of guessing.

When effective `skip_quick_verifier=false`, read
`./scratch-ref-workflow.md` before creating, diffing, deleting, or reporting
scratch refs and use its command shapes. These refs live only under
`refs/simplepower/scratch/<run-id>/` and are coordinator-owned local
quick-verifier anchors, not branches, accepted commits, pushed refs, merged
refs, rebased refs, worker commits, or task commits. Effective `true` creates
no verifier run id or scratch refs.

## Plan-Based Compaction Continuity

Continuity is an instruction-level protocol stored in the authoritative plan,
not an executable lifecycle helper, helper agent, parser, extra state artifact,
or configuration key. The coordinator is the only writer to the plan.

For `Implementation Route: Main agent`, maintain one replaceable
`## Implementation Continuity` snapshot. After every meaningful implementation,
verification, repair, or review milestone, replace the current snapshot in
place with:

- `Completed work`
- `Partial results`
- `Changed files`
- `Verification`
- `Blockers`
- `Next action`

The write must succeed before moving beyond the milestone. This proactive
snapshot is the pre-compaction behavior; the required reread above is the
post-compaction behavior.

For `Implementation Route: Grouped workers`, assign every worker package a
stable `Package identifier` and a coordinator-owned package continuity section.
Each worker sends a structured `PROGRESS_SNAPSHOT` after every meaningful
milestone with the package identifier, completed work, partial results, changed
files, verification, blockers, and next action. It must successfully deliver
that report before proceeding beyond the milestone. The coordinator consumes
the report, validates actual ownership and progress, and replaces that
package's current snapshot; workers never edit the plan.

After worker-context compaction, a worker may read only its package continuity
section from the supplied plan path, then revalidate its package boundary and
next action before resuming. This narrow recovery read does not authorize
full-plan discovery or replace the self-contained dispatch prompt. If the
section cannot be read or does not identify a safe next action, report
`BLOCKED` or `NEEDS_CONTEXT` and stop.

At phase completion, fold durable snapshot facts into approved permanent plan
content or `## Execution Summary`, then remove temporary continuity sections.
Snapshots are current replaceable state, not append-only logs.

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

The eight base keys are `use_subagent`, `skip_quick_verifier`,
`skip_final_review`, `subagent_model`, `review_model`, `best_model`,
`normal_model`, and `fast_model`;
`plan_review_model`, `review_model2`, and `final_review_model` are optional.
`plan_review_model` controls only the completed planning phase and is
validation-only during execution. `review_model`,
`review_model2`, `final_review_model`, and `skip_final_review` remain
recognized and validated so existing configuration files continue to parse, but
they are deprecated no-ops in the normal execution chain described here.

Active dispatch routing:

- Grouped `sp-impl` workers use the plan-approved FAST, NORMAL, or BEST tier.
  Escalate FAST to NORMAL/BEST when work is less mechanical than planned;
  escalate NORMAL to BEST when work is broad, ambiguous, behavior-shaping,
  high risk, or hard to verify. Record the reason.
- Effective `skip_quick_verifier=true` runs quick verification in the main
  agent with no verifier model routing, spawn, lifecycle, or scratch refs.
- Effective `skip_quick_verifier=false` dispatches the quick verifier with
  FAST. With built-in defaults this resolves to
  `model="gpt-5.3-codex-spark"` and `reasoning_effort="xhigh"`.
- `Implementation Route: Main agent` dispatches no `sp-impl` worker and uses no
  implementation model routing.

Quick verification: use the approved executor resolved from
`skip_quick_verifier`; use FAST only for the subagent path. Grouped-worker
`Contract inputs` contain only the relevant approved Interface Contract
entries and package facts.

Every retained Simple Power dispatch uses exact `fork_turns="none"` and a
self-contained prompt. There are no conversation-history inheritance
exceptions.

## Coordinator Execution Commits

The two mandatory checkpoint types remain accepted plan and final completion.
Additional commits are coordinator-owned execution commits and are allowed only
during the active run under the accepted combined approval:

- A `technical-prerequisite commit` requires a concrete approved command or
  work step that objectively cannot proceed without committed state. The need
  may be discovered during execution and does not require a plan rewrite when
  scope, strategy, route, and verification remain unchanged.
- An `execution-summary commit` is allowed when the original plan's summary
  cannot join the implementation commit or when a later in-run finding requires
  the summary to be refreshed again.

Before either commit, compare all staged content with the accepted exact file
scope and approved path. Commit only approved in-scope changes, never create an
empty commit, and record each reason. Record a technical-prerequisite SHA in a
later summary; report the SHA of a commit containing the summary in the final
handoff or a later follow-up. Convenience, history shaping, clean-history
preference, workers, packages, and tasks never justify a commit. A prerequisite
commit does not mark verification or the run complete, and the coordinator's
final diff review must include the range from the accepted-plan checkpoint
through every committed and uncommitted execution change. Merge, push, and PR
operations still require separate user authorization.

If an authorized commit fails, preserve the working tree and any scratch refs,
report the exact failure and recovery state, and do not claim completion.

## Original Plan Execution Summary

The coordinator owns summary updates. Workers and a dispatched quick verifier
report facts but must not edit the plan. After the first final-verification pass,
append or refresh `## Execution Summary` in the original plan with:

- current status and outcome;
- key changes;
- verification overview;
- notable review findings, fixes, and plan deviations;
- observed branch, pre-commit HEAD, and worktree state; and
- unresolved issues and follow-ups.

Keep it concise: do not paste raw logs, narrate every file, or audit unrelated
repository subsystems. A later material finding before final handoff reopens
completion. Refresh the current snapshot, append a phase- or date-labeled
follow-up entry with the new finding, action, and affected verification, then
rerun affected checks and terminal verification. The newest verified commit is
the final-completion checkpoint.

When the plan is writable and tracked in the current repository, an unexpected
write or validation failure blocks completion; preserve work and scratch refs
and report recovery details. When the original plan is genuinely untracked,
outside the repository, or unwritable, preserve verified implementation work
and allow handoff only with the exact omission reason. After the last summary
edit, inspect its diff and rerun the plan's terminal verification without
further file edits. Record observed pre-commit state in the summary and report
the containing final SHA in the handoff; a file cannot record its own containing
SHA without changing it.

## Authoritative Lifecycle

1. Read the accepted plan. Confirm it is the approved plan for the current
   execution, not a backup or substitute. Apply the post-compaction reread rule
   whenever context was reconstructed.
2. Validate route, exact files including the plan's own execution-record path,
   implementation steps, risks, timed quick and final verification, summary
   requirements, and the two mandatory checkpoint conditions plus bounded
   execution-commit conditions.
3. Validate configuration before selecting the quick-verification executor and
   before any grouped-worker or quick-verifier dispatch. Treat
   `plan_review_model` and deprecated review settings as
   validation-only keys during execution. Throughout the remaining lifecycle,
   apply `Coordinator Execution Commits` only at an objective committed-state
   prerequisite or a required separate/later summary update.
4. If `Implementation Route: Main agent`, implement the approved cohesive
   package directly in the coordinator session. Do not dispatch an `sp-impl`
   worker for the package. Refresh `## Implementation Continuity` after each
   meaningful milestone before proceeding.
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
   files against approved ownership, refresh its package continuity from the
   final `PROGRESS_SNAPSHOT`, decide close-by-default or record a
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
12. With effective `skip_quick_verifier=true`, run the plan's exact timed quick
    commands directly in the coordinator. Inspect failures, make only approved
    in-scope repairs, rerun affected commands, and stop for fresh approval if
    repair requires scope or strategy changes. Create no verifier subagent,
    lifecycle entry, run id, or scratch refs.
13. With effective `skip_quick_verifier=false`, create
    `refs/simplepower/scratch/<run-id>/quick-verifier/before` for the approved
    changed-file list. If this fails, stop before relying on the missing anchor.
14. In that subagent mode, dispatch the quick verifier from
    `quick-verifier-prompt.md` with the approved FAST model, exact
    `fork_turns="none"`, and a self-contained prompt containing the design
    summary, approved file list, relevant contract entries, implementation
    result summaries, exact commands, timeouts, and expected results.
15. The dispatched quick verifier runs the named lint/build/test commands. It
    may fix only tiny typo-level issues that directly cause a command failure.
    It reports `NON_TRIVIAL_FAILURES` for structural, behavioral, interface,
    scope-changing, or unclear failures. The coordinator diagnoses those
    failures, makes only approved in-scope repairs, and reruns required
    verification. Do not launch another implementation worker or reviewer to
    handle them. Stop for user approval if repair needs true scope expansion or
    changed strategy.
16. After a dispatched quick verifier returns, lifecycle-close it by default,
    inspect the report and actual diff, validate any changed files, and if tiny
    fixes changed files create `quick-verifier/after` and inspect the scratch
    diff. Omit the `after` ref when no files changed. Both executor paths then
    continue to coordinator review.
17. After quick verification, the coordinator inspects the complete diff from
    the accepted-plan checkpoint through committed and uncommitted execution
    changes, performs coordinator review for plan compliance, ownership,
    behavior, quality, and verification adequacy, then makes any necessary
    in-scope fixes directly. This is the main agent final review authority.
18. Run the first final-verification pass from the approved plan and any
    repository-required checks for the changed files.
19. Update the original plan's execution summary with observed facts and the
    first verification results. If this is genuinely impossible, apply the
    narrow omission handling above; otherwise a write or validation failure is
    a blocker.
20. Inspect the summary diff, then rerun the plan's terminal verification with
    no further file edits. If a material finding appears before handoff, reopen
    completion, make only approved in-scope repairs, refresh the current summary
    and append a labeled follow-up entry, then repeat affected and terminal
    verification.
21. Apply the final reviewed/verified completion checkpoint condition. The
    accepted combined approval already authorizes this checkpoint. The
    coordinator must create the newest final commit when uncommitted in-scope
    changes remain, without requesting another approval; do not create an empty
    commit. A prior technical-prerequisite or summary commit does not replace
    this condition.
22. When subagent mode created quick-verifier scratch refs, delete them only
    after the newest final checkpoint condition succeeds, then run the final
    cleanup check for `refs/simplepower/scratch/<run-id>/`. Main-agent mode has
    no verifier-ref cleanup.
23. Report verification results, final checkpoint SHA or no-empty outcome when
    applicable, execution-summary status, any execution-commit reasons and
    SHAs, changed files, route decision, grouped dispatch decisions, capacity
    queue behavior, any serialized packages and reasons, lifecycle status,
    quick-verification executor, quick-verifier scratch run id when refs were
    created, scratch-ref cleanup
    status or cleanup commands for preserved refs, and coordinator review
    findings/fixes. Commit authorization ends with this final handoff.

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
  timeouts, expected results, stable package identifier, plan path, milestone
  snapshot gate, recovery-read boundary, and completion report requirements.
- Do not paste the complete plan or repeated global boilerplate into grouped
  worker prompts. Do not require a worker to read the plan file to discover its
  own package.
- Every dispatch is:
  `spawn_agent(agent_type="worker", model=<resolved_model>, reasoning_effort=<resolved_effort>, fork_turns="none", message=<self-contained-prompt>)`.
- Record any model escalation, serialization exception, capacity scheduling
  decision, route concern, or lifecycle exception with a written reason.
- No worker commits. No per-package commits. Workers and quick verifiers must
  not create, update, delete, inspect, or manage refs.
- Workers must not edit the plan. Only the coordinator converts delivered
  `PROGRESS_SNAPSHOT` reports into package continuity updates.
- No per-task commits.

## Scratch Refs

Scratch refs are coordinator-owned evidence for FAST quick-verifier subagent
diffs and exist only when effective `skip_quick_verifier=false`. Main-agent
quick verification creates none. Scratch refs do not change the two mandatory
coordinator checkpoint types: approved plan and final reviewed/verified
completion. Bounded technical-prerequisite and summary commits are execution
history, not scratch-ref phases.

All temporary refs for one run live under
`refs/simplepower/scratch/<run-id>/`, where the run id is
`YYYYMMDD-HHMMSS-<short-head>`. Record the run id in working notes and final
reporting whenever scratch refs are created.

Use `./scratch-ref-workflow.md` for exact commands, including temporary-index
creation, diffing, phase cleanup, final cleanup checks, and preserved-ref
cleanup commands.

Subagent-mode phase ownership and timing:

- Quick-verifier `before` is created after all implementation edits are
  complete and before the quick verifier dispatch.
- Quick-verifier `after` is created only when tiny fixes changed files.
- Delete quick-verifier refs only after the newest final reviewed/verified
  completion checkpoint succeeds or the no-empty-final-commit outcome is
  recorded as successful.
- On user direction, a blocker, scratch-ref creation failure, or failed
  checkpoint, preserve scratch refs as evidence and report the manual cleanup
  command from `scratch-ref-workflow.md`.

If scratch-ref creation fails, stop the verification loop before relying on the
missing anchor. For quick-verifier tiny fixes, inspect the scratch diff before
final verification.

## Subagent Lifecycle

Run a lifecycle checkpoint after every retained subagent final result,
including grouped `sp-impl` workers and the quick verifier when dispatched.

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
  files including the original plan's execution-record path, implementation
  steps, risks, timed checks, summary contract, and two mandatory checkpoint
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
- Create coordinator execution commits for convenience, history shaping, clean
  history, or anything other than an objective committed-state prerequisite or
  a required separate/later execution-summary update.
- Let a worker or quick verifier update the approved plan; execution-summary
  edits are coordinator-owned.
- Let a worker read the plan file instead of receiving package-specific
  context.
- Skip quick verification, coordinator final diff review, final verification,
  original-plan summary handling, terminal post-summary verification, or the
  final commit condition.
- Skip required quick-verifier scratch-ref creation, scratch diff inspection,
  phase cleanup, preserved-ref reporting, or final cleanup checks in
  FAST-subagent mode, or create any verifier scratch ref in main-agent mode.
- Leave a finished subagent open without a written reason tied to the current
  plan execution.
- Merge, push, or create a PR without a separate user request.
- Treat active-run commit authorization as valid after final handoff.
- Use stale upstream plugin skill prefixes in this scope.

If a grouped worker asks questions, provide the missing package context or
write-scope details before letting it continue.

If a grouped worker reports a blocker, treat it as real. Gather only the
diagnostic context needed to explain it, classify missing write-scope files as
`implied-scope omission` or `true scope expansion`, and stop for user approval
before true scope expansion or alternate implementation work.

If a dispatched quick verifier finds issues, allow only tiny typo-level fixes
that directly cause a command failure. Non-trivial failures return to the
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
checks for the changed files. Inspect the accepted-plan-to-working-state diff
within the approved scope, run the first final-verification pass, update the
original plan's concise execution summary, and rerun terminal verification
without further file edits. Apply the final commit condition only after that
coordinator review and terminal verification pass.

The accepted combined approval authorizes the two mandatory checkpoint types
and bounded coordinator execution commits during the active run. Create the
newest final checkpoint commit whenever uncommitted in-scope changes remain,
without requesting another approval; do not create an empty commit. No worker
commits. No per-task commits. Authorization ends at final handoff.

Final reporting must include:

- status and final verification results;
- selected route: `Main agent` or `Grouped workers`;
- for `Main agent`, confirmation that no `sp-impl` implementation worker was
  dispatched;
- for `Grouped workers`, aggregate dispatch and rolling capacity decisions,
  including queued packages and slot-filling behavior;
- true serialized packages and reasons;
- coordinator review findings and in-scope fixes;
- execution-summary status and any labeled follow-up updates;
- every technical-prerequisite or separate summary commit with its reason and
  SHA;
- final checkpoint SHA or no-empty outcome when applicable;
- changed files;
- quick-verification executor and resolved `skip_quick_verifier` value;
- quick-verifier scratch run id when refs were created;
- scratch-ref cleanup status or cleanup commands for preserved refs; and
- confirmation that all finished subagents were closed or have an active
  written reason to remain open.
