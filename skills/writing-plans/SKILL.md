---
name: writing-plans
description: Use only when the user explicitly requests simplepower:writing-plans or an authorized Simple Power chain invokes it.
---

# Writing Plans

## Overview

Promote the authoritative evolving plan from the approved brainstorming design.
Planning is adaptive: use a compact `Main agent` route by default, and preserve
a grouped-worker route only when delegation has clear material value and the
user explicitly approved it during brainstorming.

The main agent writes and self-reviews the plan. When optional
`plan_review_model` is active, dispatch one read-only single-pass plan reviewer,
apply only accepted `Critical` and `Must Fix` findings, and do not re-review the
revised plan. The workflow has no plan-review loop, plan-review scratch refs,
final-review agent, or final-review scratch refs. Quick verification remains
mandatory; `skip_quick_verifier` selects the main agent by default or the FAST
quick-verifier subagent when `false`. The saved plan is also the
coordinator-owned execution record and receives a concise completion summary
before final handoff whenever it is a writable tracked file in the current
repository.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Plan path:** expand the existing
`docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md` in place. Brainstorming
creates this evolving plan; planning must not create a second plan artifact.

Generated plans must reference canonical global rules instead of copying
configuration, commit policy, dispatch isolation, and workflow boilerplate.
Reference the relevant source by path or section, then include only the
task-specific values needed to execute the approved work.

## Inputs From Brainstorming

Require enough approved design context to select a route objectively before user
approval:

- Goal, user-visible behavior, constraints, non-goals, and success criteria.
- Cohesion assessment: why the work is one cohesive package or which parts are
  genuinely independent.
- Specialization assessment: whether any package materially benefits from a
  delegated specialist.
- Expected file areas, public interfaces, data shapes, commands, fixtures, and
  external constraints.
- Risks, expected verification, and any decisions that would require fresh user
  approval if they change.
- The exact existing evolving plan path and its current `Grouped Workers
  Consent` state.

If these inputs are missing or contradictory, ask for the missing decision
before writing the plan.

Read the complete evolving plan before another question, tool, or edit. Verify
that the path is the active brainstorming artifact, then expand it in place.
Missing, ambiguous, unreadable, or unwritable plan state blocks planning; do not
guess, create a replacement, or copy the design into a second artifact.

## Approved Path Enforcement

The approved brainstorming design is the planning baseline, and the accepted
implementation plan is authoritative for execution. Before combined plan
approval, the main agent may incorporate an applicable Critical or Must Fix
review finding that remains within the user's stated goal, then present the
revised final plan for combined approval. This is the only pre-approval reviewer
exception. Do not authorize backup routes, scope reduction, docs-only
substitutes, placeholder implementations, skipped verification, or
execution-time route changes unless the user gives fresh explicit approval at
the moment the deviation is needed.

Plans may describe blockers and decision points, but must not pre-approve
alternate implementation work. If the approved path is blocked during execution,
the executing agent stops, reports the exact mismatch, shows current status, and
asks the user before changing approach.

A stub substitute or execution-mode switch requires fresh explicit approval.

## Configuration And Model Terms

Before assigning FAST/NORMAL/BEST work or selecting the quick-verification
executor, resolve and validate Simple Power configuration by following
`skills/using-simplepower/references/simplepower-config.md`.

Active normal planning uses only:

- FAST for obvious mechanical edits, simple fixture/assertion churn, and the
  quick-verifier subagent only when `skip_quick_verifier=false`.
- NORMAL for routine, localized implementation.
- BEST for broad, ambiguous, behavior-shaping, high-risk, or hard-to-test work.

Optional `plan_review_model` controls one read-only plan-review dispatch when
activated by a supported TOML key or non-empty
`SIMPLEPOWER_PLAN_REVIEW_MODEL`. It has no default, is independent of
`use_subagent`, and is not a FAST/NORMAL/BEST implementation tier. A
current-session value may override it only after file or environment activation.

`review_model`, `review_model2`, `final_review_model`, and
`skip_final_review` remain recognized and validated compatibility settings, but
they are deprecated no-ops in the normal brainstorming-to-implementation chain.
Do not include legacy REVIEW allocation, dual-review routing,
final-review-agent routing, final-review-skip boilerplate, or global optional
plan-review configuration in generated normal plans.

`skip_quick_verifier` is an active base Boolean and defaults to `true`.
Generated plans must record its resolved value and one executor: `Main agent`
for `true`, or `FAST subagent` for `false`. Both use the same exact timed quick
commands. Only the FAST-subagent path receives model/effort allocation,
`fork_turns="none"`, tiny-fix limits, lifecycle handling, and quick-verifier
scratch refs.

## Route Selection Before Approval

Choose the `Implementation Route` before asking the user to approve the plan.
The route is part of the approval. Do not silently switch it later.

Main agent is the default. Preserve exactly one brainstorming consent marker:
`Grouped Workers Consent: Not requested`, `Grouped Workers Consent: Declined`,
or `Grouped Workers Consent: Approved`; planning must not ask for grouped-worker consent
or promote grouped execution independently.

Select `Implementation Route: Main agent` when:

- The write scope forms one cohesive implementation package.
- Closely related code, tests, docs, fixtures, or configuration should stay
  together to preserve context.
- No specialized delegation materially improves speed, quality, or risk.

Select `Implementation Route: Grouped workers` only when:

- There are at least two independent, non-overlapping cohesive packages that can
  proceed from a shared contract, or specialized work has material delegation
  benefit.
- Every worker package can receive an exact write scope that does not overlap
  another ready worker package.
- The coordination value outweighs the extra prompt, review, and lifecycle
  overhead.
- The evolving plan contains `Grouped Workers Consent: Approved` from the
  brainstorming phase.

Objective suitability without `Approved` consent is insufficient. Silence, uncertainty, or contradictory evidence
never authorizes grouped execution:
retain `Implementation Route: Main agent` for absent or non-approved consent,
and stop for user direction when the recorded design and consent state
contradict each other.

Capacity only queues approved packages; it never justifies splitting tiny tasks.
Keep closely related production code and tests in the same package unless their
contracts and write scopes are genuinely independent. Changing the approved
route, package boundaries, or strategy requires fresh user approval.

## Shared Compact Plan Core

Every generated plan, including grouped-worker plans, must contain this compact
core with concrete content and no placeholders:

1. `# [Feature Name] Implementation Plan`
2. `Goal`: one sentence.
3. `Design Summary`: approved design, cohesion/specialization reasoning,
   constraints, decisions, risks, and success criteria.
4. `Implementation Route`: exactly `Main agent` or `Grouped workers`, with the
   objective route-selection reason and exact retained `Grouped Workers
   Consent` marker. A grouped route requires `Approved`.
5. `Exact Files`: every file that may be created, modified, deleted, or
   generated. Use exact paths and include the saved plan's own path as the
   coordinator-owned execution record.
6. `Implementation Steps`: ordered, executable steps with enough detail for the
   selected route.
7. `Risks`: concrete risks and how the plan reduces them.
8. `Quick Verification`: the resolved `skip_quick_verifier` value, selected
   `Main agent` or `FAST subagent` executor, exact timed commands, and expected
   results.
9. `Final Verification`: exact timed commands, expected results, the main
   agent's final diff review requirement, and the terminal rerun required after
   the last execution-summary edit.
10. `Execution Record`: name the saved plan path and require the coordinator to
    append or refresh `## Execution Summary` after the first final-verification
    pass. The concise summary contains current status and outcome, key changes,
    verification overview, notable findings/fixes/deviations, observed branch,
    pre-commit HEAD and worktree state, and unresolved follow-ups. Later
    findings during the active run refresh the current snapshot and append a
    phase- or date-labeled follow-up entry. Exclude raw logs, exhaustive file
    narration, and unrelated repository audits. State that the containing final
    SHA belongs in the final handoff because recording it in its own commit is
    self-referential.
11. `Checkpoint Conditions`: exactly two mandatory coordinator checkpoint
    types:
    - Accepted plan checkpoint after combined user approval of the plan, route,
      any grouped-worker allocation, immediate current-session execution, the
      accepted-plan checkpoint commit, and the final reviewed/verified
      completion checkpoint commit, plus bounded in-scope coordinator execution
      commits during the active run.
    - Final reviewed/verified completion checkpoint after implementation,
      mandatory quick verification, main-agent final review and in-scope fixes, the first
      final-verification pass, execution-summary update, and unchanged terminal
      verification pass. When uncommitted in-scope changes remain, this
      checkpoint creates the newest final commit without requesting another
      approval; it does not create an empty commit.

The checkpoint section must state that conditional execution commits do not add
checkpoint types. They are allowed only when an objective technical
prerequisite requires committed state before an approved command or work step,
or when the original plan's execution summary must be committed separately or
refreshed after later findings. Convenience and history-shaping commits do not
qualify. Combined approval covers these coordinator-owned, in-scope commits
only during the active run and expires at final handoff. Fresh approval remains
required for scope, strategy, route, or verification changes. State whether the
plan already expects an intermediate technical-prerequisite commit; a newly
discovered objective need may still use the bounded authorization without
rewriting the plan first.

Normal plans must not copy global configuration resolution, commit policy, or
dispatch boilerplate. Reference canonical global rules and record only values
that are specific to the plan, such as exact files, route, package contracts,
selected FAST/NORMAL/BEST allocation, and verification commands.

Before plan self-review, fold confirmed brainstorming facts into the permanent
design sections and remove the Brainstorming Continuity section. Add the
execution-phase continuity contract to the permanent plan text: main-agent
execution maintains at most one replaceable `## Implementation Continuity`
snapshot after a cohesive phase, on a blocker, or for final handoff preparation;
an approved grouped route maintains coordinator-written package continuity
sections only at package completion, on a blocker, or at an explicit
coordinator request. These temporary execution sections are folded into
`## Execution Summary` and removed at completion. State that built-in
compaction summaries carry transient activity while the real Simple Power hooks
restore the exact authoritative plan; do not require a Markdown update after
each test, repair, review step, answer, or internal worker milestone.

## Main Agent Route Requirements

For `Implementation Route: Main agent`, use the shared compact plan core only.
Do not add worker packages or implementation-worker allocation.

The implementation steps must state that, after the accepted-plan checkpoint,
the main agent directly implements the one cohesive package in the current
session, then runs mandatory quick verification through the approved executor,
performs the main-agent final diff review and in-scope fixes, runs final
verification, updates the original plan's execution summary, reruns terminal
verification without further file edits, and reaches the final checkpoint
condition. After a cohesive phase, on a blocker, or for final handoff
preparation it replaces the current implementation continuity snapshot with
completed work, partial results, changed files, verification, blockers, and
next action. After compaction it follows the hook-injected exact plan reread
before further action. It does not persist every test, repair, or review step.

## Grouped Workers Route Extensions

For `Implementation Route: Grouped workers`, add these sections in addition to
the shared compact plan core.

### Interface Contract

List only the shared facts worker packages may rely on before other packages
finish: public APIs, filenames, command contracts, fixtures, data shapes,
behavior guarantees, and cross-package assumptions. Use exact names and expected
behavior, not broad intent.

### File Ownership

List every file that may be created, modified, deleted, or generated. Each file
must be owned by exactly one package. No two parallel packages may edit the same
file. Shared files must be serialized into one package or split so ownership is
unambiguous.

### Worker Packages

Define cohesive worker packages, not single-file chores. Each package must
include:

- Goal and material delegation reason.
- Relevant Interface Contract entries and approved design context.
- Exact read scope and exact write scope.
- Implementation steps and expected outputs.
- Exact timed verification commands.
- Risk/model reason and FAST/NORMAL/BEST allocation.
- Completion report requirements.
- A stable package identifier, the active plan path, structured
  `PROGRESS_SNAPSHOT` reporting at package completion, blocker, or explicit
  coordinator request, and the worker's read-only package-continuity recovery
  boundary.

Label the relevant shared facts as `Contract inputs`. Every package must state
`Serialization required: No`, or `Serialization required: Yes` with the exact
approved reason and release condition.

Worker package instructions must include only relevant design, contract, scope,
and verification context. Do not paste the complete plan or repeated global
configuration, commit-policy, scratch-ref, or workflow boilerplate into worker
prompts. Worker prompts remain self-contained for their package and must retain
the canonical dispatch isolation requirement that every dispatch uses exactly
`fork_turns="none"`.

### Serialization Decisions

State which packages can run together and which must wait, with concrete
reasons. Use serialization only for overlapping write scopes, missing or
ambiguous contracts, generated artifacts required before editing, or intentional
runtime/migration ordering. Do not serialize merely because one package tests an
approved interface another package is implementing.

### FAST/NORMAL/BEST Allocation

List grouped-worker packages with resolved FAST, NORMAL, or BEST model/effort
values. When `skip_quick_verifier=false`, also list the quick-verifier subagent
with resolved FAST model/effort; with `true`, record `Main agent` and no verifier
model allocation. Do not include REVIEW allocation. Use BEST for
broad or behavior-shaping packages, NORMAL for routine implementation packages,
and FAST only for mechanical package work or a selected quick-verifier
subagent.

The quick-verifier subagent uses the FAST tier when selected; its built-in
value is `gpt-5.3-codex-spark-xhigh`. Resolve all active model values through
the canonical configuration reference instead of copying environment-overlay
boilerplate into generated plans.

## Visual Aids

Plans may include this optional section only when inline visuals reduce ambiguity.
Suitable cases include workflow flowcharts, architecture or data-flow maps,
task ownership matrices, and state or error-path diagrams.
Written plan sections remain authoritative; visual aids cannot replace or
contradict route, ownership, package, verification, or checkpoint decisions.

## Plan Self-Review And Approval

After writing the plan, the main agent self-reviews it before asking the user
for approval. Check:

- The route follows the objective `Main agent` or `Grouped workers` criteria.
- The exact `Grouped Workers Consent` marker is present; grouped execution has
  both objective value and `Approved` brainstorming consent.
- The same evolving plan was expanded in place, brainstorming continuity was
  folded into permanent content, and the applicable execution continuity
  contract is explicit.
- The plan has the shared compact core, exact files, implementation steps,
  risks, timed quick verification, timed final verification, its own path as
  the execution record, the concise summary contract, and exactly two mandatory
  coordinator checkpoint types.
- Grouped-worker plans, when used, include Interface Contract, File Ownership,
  cohesive Worker Packages, serialization decisions, and FAST/NORMAL/BEST
  allocation.
- Related code and tests stay in one package unless the plan explains genuine
  independence.
- Worker prompts will receive only relevant package context and exact
  `fork_turns="none"` dispatch isolation.
- Quick verification is mandatory and the plan records the resolved executor.
- Main-agent mode has no verifier spawn or scratch refs. FAST-subagent mode is
  limited to tiny typo-level fixes and returns non-trivial failures to the main
  agent.
- The main agent performs final diff review and in-scope fixes; no final-review
  agent is required.
- The plan runs its first final-verification pass before writing the summary and
  reruns terminal verification after the last summary edit without further file
  changes.
- Any conditional execution commit is coordinator-owned, objectively required
  for approved work or an execution-summary update, limited to the active run,
  and neither a convenience commit nor a worker/per-task commit.
- Optional plan review is either inactive or configured for one read-only pass.
- Deprecated compatibility settings are recognized/validated but are no-ops.
- The plan does not contain placeholders, skipped checks, backup routes, or
  unapproved scope changes.

If `plan_review_model` is inactive, proceed directly to combined approval after
self-review. If it is active, read
`skills/writing-plans/plan-document-reviewer-prompt.md` and dispatch exactly one
generic worker with the parsed model and effort, exact `fork_turns="none"`, the
saved plan path, approved brainstorming design context, and the selected route
and allocation. Wait for its report, then close it. The reviewer is read-only
and must not edit files, manage refs, commit, spawn agents, or invoke skills.

A usable report has `Status: PASS | ISSUES_FOUND` plus `Critical` and `Must
Fix` sections. Extra sections do not make the report unusable; ignore them.
Treat a report as unusable only when its status is missing or invalid, either
required section is missing, or its status contradicts whether those sections
contain findings. Evaluate only findings in the two required sections. Accept a
finding when it identifies applicable plan text or a concrete omission and
meets its stated Critical or Must Fix threshold. Dismiss it when it is
factually wrong, already satisfied, duplicated, outside the user's stated goal,
or below the required severity. Apply accepted fixes, record a concise reason
for each dismissal in the approval message, and ignore every other severity,
recommendation, style preference, or optional improvement. The main agent may
incorporate or dismiss design-related findings before approval; the resulting
plan remains subject to combined user approval.

After the fix pass, rerun focused self-review only for changed sections and any
directly affected route, ownership, verification, or checkpoint contract. Then
treat the plan as reviewed. Do not resend it to the reviewer, retry review,
create another reviewer, create a review loop, or create plan-review scratch
refs.

If multi-agent support, model availability, spawning, waiting, or malformed
output prevents a usable report, state the failure and reason in the combined
approval message, then continue from the completed main-agent self-review
without retrying. Do not write the failure into the plan. Do not use this
fallback for configuration validation errors; those remain fatal before
dispatch.

Then ask for one combined approval covering the final plan, selected route, any
grouped-worker allocation, immediate current-session execution, the
accepted-plan checkpoint commit, and the
final reviewed/verified completion checkpoint commit, plus bounded in-scope
coordinator execution commits during the active run. State that compliant
in-scope execution creates those commits without a second approval prompt, that
authorization expires at final handoff, and no empty commit is created. If the
user requests changes, revise the plan and rerun the focused self-review checks.
Do not create the accepted-plan checkpoint until the user gives combined
approval.

After combined approval, the coordinator creates the accepted-plan checkpoint
and immediately invokes `simplepower:subagent-driven-development` for
current-session auto-dispatch with the approved plan path and route. That
accepted combined approval remains the authorization for the final checkpoint
and bounded execution commits during the active run; do not ask for separate
commit approval unless execution requires a fresh approved-path decision. The
authorization ends when the run is handed off as complete.

## Quick Verification And Final Review

Quick verification runs after all implementation edits, whether those edits
were made directly by the main agent or by grouped workers. The plan records
one exact command set and the resolved executor.

With effective `skip_quick_verifier=true`, the main agent runs those commands
directly, diagnoses failures, applies only approved in-scope repairs, and
reruns affected commands. It creates no verifier subagent, lifecycle entry, run
id, or scratch refs.

With effective `skip_quick_verifier=false`, the FAST quick-verifier subagent
receives only the approved changed-file list, relevant behavior contract,
implementation summary, and exact timed commands.

The dispatched quick verifier may make only tiny typo-level fixes. Any behavior change,
structural edit, public-interface change, test rewrite, unclear failure, or
scope concern is a non-trivial failure and must return to the main agent for
diagnosis and in-scope repair. After repairs, rerun the relevant quick
verification.

The main agent performs the final implementation review: inspect the complete
diff from the accepted-plan checkpoint through committed and uncommitted
execution changes, compare it to the accepted plan and approved path, make
in-scope fixes, and run final verification. The normal workflow has no
final-review agent and no final-review scratch phase.

Only the FAST-subagent path uses quick-verifier scratch refs; the main-agent
path and optional single-pass plan reviewer never get them. Quick-verifier refs
are coordinator-owned local diff anchors managed by the execution skill. The
target workflow has exactly two mandatory coordinator checkpoint types:
accepted plan and final reviewed/verified completion. Objective
technical-prerequisite and execution-summary commits are bounded execution
commits, not new checkpoint types or intermediate quick-verified implementation
checkpoints.

The canonical scratch namespace and mechanics live in
`skills/subagent-driven-development/scratch-ref-workflow.md`, under
`refs/simplepower/scratch/<run-id>/`; generated plans
must reference that file instead of copying ref creation, diff, and cleanup
commands. Scratch refs are not accepted history commits.
Workers and quick verifiers must not commit, inspect, or manage refs.
No worker commits or per-task commits. No per-task commits includes task-local
`git commit` commands.

## Execution Record And Conditional Commits

After the first final-verification pass, the coordinator updates the original
plan's `## Execution Summary` with observed facts through that point. It then
inspects the summary diff and reruns the plan's terminal verification without
further file edits. A later material finding before handoff reopens completion:
apply only approved in-scope work, refresh the current summary, append a labeled
follow-up entry, and rerun affected checks plus terminal verification. The
newest verified commit becomes the final-completion checkpoint.

When the plan is writable and tracked in the current repository, an unexpected
summary write or validation failure blocks completion and preserves working
state plus any quick-verifier scratch refs that were created. When the plan is genuinely untracked,
outside the repository, or unwritable, preserve verified implementation work
and allow handoff only with the exact omission reason. The summary records the
observed pre-commit HEAD; the final handoff reports the containing SHA.

The coordinator may create a technical-prerequisite commit only when a concrete
approved command or work step objectively requires committed state. It commits
only approved in-scope changes and later records the reason and SHA in the
summary. A separate summary commit is allowed when the summary cannot join the
implementation commit or later findings require another update. Do not create
these commits for convenience, history shaping, workers, packages, or tasks.

## Current-Session Execution Handoff

The saved plan is the execution artifact. Do not write a project-local
implementation JSON artifact or ask the user to choose another route after plan
approval.

After combined approval and the accepted-plan checkpoint, invoke
`simplepower:subagent-driven-development` in the current session with a concise
handoff:

```text
Execute <PLAN_PATH> using the approved Implementation Route: <Main agent|Grouped workers>.
Preserve approved-path enforcement and exact file scope.
Use direct main-agent implementation for Main agent routes.
For Grouped workers routes, dispatch only the approved cohesive packages whose write scopes do not overlap, with exact fork_turns="none" and only package-relevant context.
Run mandatory quick verification after implementation edits through the plan-approved Main agent or FAST subagent executor.
For FAST-subagent mode, return non-trivial quick-verifier failures to the main agent and use conditional scratch refs; for main-agent mode, create neither.
Have the main agent review the full accepted-plan-to-working-state diff, apply in-scope fixes, and run the first final-verification pass.
Update the original plan's concise Execution Summary, then rerun terminal verification without further file edits.
Use the combined approval for the two mandatory checkpoint types and bounded in-scope coordinator execution commits only during the active run.
Allow an execution commit only for an objective committed-state prerequisite or a separate/later summary update, never convenience or history shaping.
After compliant terminal verification, make the newest commit the final-completion checkpoint when uncommitted in-scope changes remain; do not create an empty commit.
End commit authorization at final handoff and report the containing final SHA there.
```

## No Placeholders

Every step must contain the actual content an engineer needs. These are plan
failures:

- `TBD`, `TODO`, `implement later`, or `fill in details`.
- Vague instructions such as `add validation` without exact behavior.
- Tests requested without concrete commands, locations, and expected results.
- References to functions, files, or commands not defined elsewhere in the plan.
- Worker commit instructions, per-task commit instructions, or task-local
  `git commit` commands.
- Convenience or history-shaping commits presented as technical prerequisites,
  unconditional separate summary commits, or commit authorization extending
  beyond the active run.
- Text that pre-authorizes scope reduction, skipped checks, placeholder
  implementations, docs-only substitutes, route changes, alternate execution
  modes, or user selection among execution routes after approval.

## Remember

- Route selection happens before user approval, but grouped-worker consent is
  requested only during brainstorming.
- Main agent is the default. It remains selected whenever grouped execution was
  not both objectively suitable and explicitly approved during brainstorming.
- Grouped workers require independent non-overlapping packages or specialized
  work with clear delegation value.
- Capacity queues packages; it does not split tiny tasks.
- Compact plans need design summary, route, exact files, steps, risks, timed
  quick/final verification, their own path as the execution record, a concise
  summary contract, and two mandatory coordinator checkpoint types.
- Combined approval explicitly authorizes both mandatory checkpoint types and
  bounded in-scope coordinator execution commits during the active run;
  compliant execution does not request another commit approval, and
  authorization expires at final handoff.
- Grouped plans add Interface Contract, File Ownership, cohesive Worker
  Packages, serialization decisions, and FAST/NORMAL/BEST allocation.
- Main-agent plan self-review always runs; optional `plan_review_model` adds at
  most one read-only review and one main-agent fix pass.
- Never resend a revised plan to the optional reviewer.
- Quick verification remains mandatory. Main-agent mode has no verifier spawn
  or scratch refs; the FAST-subagent mode may make only tiny typo-level fixes.
- Main-agent final diff review and in-scope fixes replace the final-review
  agent.
- The coordinator updates the original plan after the first final-verification
  pass and reruns terminal verification after the last summary edit.
- Generated plans reference canonical global rules instead of copying global
  boilerplate.
