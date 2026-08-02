---
name: writing-plans
description: Use only when the user explicitly requests simplepower:writing-plans or an authorized Simple Power chain invokes it.
---

# Writing Plans

## Overview

Write the authoritative implementation plan from the approved brainstorming
design. Planning is adaptive: choose a compact `Main agent` route for one
cohesive package, and use grouped workers only when delegation has clear
material value.

The main agent writes and self-reviews the plan. The normal workflow has no
plan-review agent, plan-review prompt, plan-review scratch refs, final-review
agent, or final-review scratch refs. The FAST quick verifier remains mandatory.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md`

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

If these inputs are missing or contradictory, ask for the missing decision
before writing the plan.

## Approved Path Enforcement

The approved brainstorming design and accepted implementation plan are
authoritative. Do not authorize backup routes, scope reduction, docs-only
substitutes, placeholder implementations, skipped verification, or route changes
unless the user gives fresh explicit approval at the moment the deviation is
needed.

Plans may describe blockers and decision points, but must not pre-approve
alternate implementation work. If the approved path is blocked during execution,
the executing agent stops, reports the exact mismatch, shows current status, and
asks the user before changing approach.

A stub substitute or execution-mode switch requires fresh explicit approval.

## Configuration And Model Terms

Before assigning FAST/NORMAL/BEST work or the FAST quick verifier, resolve and
validate Simple Power configuration by following
`skills/using-simplepower/references/simplepower-config.md`.

Active normal planning uses only:

- FAST for obvious mechanical edits, simple fixture/assertion churn, and the
  mandatory quick verifier.
- NORMAL for routine, localized implementation.
- BEST for broad, ambiguous, behavior-shaping, high-risk, or hard-to-test work.

`review_model`, `review_model2`, `final_review_model`, and
`skip_final_review` remain recognized and validated compatibility settings, but
they are deprecated no-ops in the normal brainstorming-to-implementation chain.
Do not include REVIEW allocation, plan-review routing, dual-review routing,
final-review-agent routing, or final-review-skip boilerplate in generated normal
plans.

## Route Selection Before Approval

Choose the `Implementation Route` before asking the user to approve the plan.
The route is part of the approval. Do not silently switch it later.

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
   objective route-selection reason.
5. `Exact Files`: every file that may be created, modified, deleted, or
   generated. Use exact paths.
6. `Implementation Steps`: ordered, executable steps with enough detail for the
   selected route.
7. `Risks`: concrete risks and how the plan reduces them.
8. `Quick Verification`: exact timed commands and expected results for the FAST
   quick verifier.
9. `Final Verification`: exact timed commands, expected results, and the main
   agent's final diff review requirement.
10. `Checkpoint Conditions`: exactly two coordinator checkpoints:
    - Accepted plan checkpoint after combined user approval of the plan, route,
      any grouped-worker allocation, immediate current-session execution, the
      accepted-plan checkpoint commit, and the final reviewed/verified
      implementation checkpoint commit.
    - Final reviewed/verified implementation checkpoint after implementation,
      the FAST quick verifier, main-agent final review and in-scope fixes, and
      final verification pass. When uncommitted in-scope changes remain, this
      checkpoint creates the final commit without requesting another approval;
      it does not create an empty commit.

Normal plans must not copy global configuration resolution, commit policy, or
dispatch boilerplate. Reference canonical global rules and record only values
that are specific to the plan, such as exact files, route, package contracts,
selected FAST/NORMAL/BEST allocation, and verification commands.

## Main Agent Route Requirements

For `Implementation Route: Main agent`, use the shared compact plan core only.
Do not add worker packages or implementation-worker allocation.

The implementation steps must state that, after the accepted-plan checkpoint,
the main agent directly implements the one cohesive package in the current
session, then runs the mandatory FAST quick verifier, performs the main-agent
final diff review and in-scope fixes, runs final verification, and reaches the
final checkpoint condition.

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

List grouped-worker packages and the quick verifier with resolved FAST, NORMAL,
or BEST model/effort values. Do not include REVIEW allocation. Use BEST for
broad or behavior-shaping packages, NORMAL for routine implementation packages,
and FAST only for mechanical package work or quick verification.

The quick verifier uses the FAST tier by default; its built-in value is
`gpt-5.3-codex-spark-xhigh`. Resolve all active model values through the
canonical configuration reference instead of copying environment-overlay
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
- The plan has the shared compact core, exact files, implementation steps,
  risks, timed quick verification, timed final verification, and exactly two
  coordinator checkpoint conditions.
- Grouped-worker plans, when used, include Interface Contract, File Ownership,
  cohesive Worker Packages, serialization decisions, and FAST/NORMAL/BEST
  allocation.
- Related code and tests stay in one package unless the plan explains genuine
  independence.
- Worker prompts will receive only relevant package context and exact
  `fork_turns="none"` dispatch isolation.
- The FAST quick verifier is mandatory and limited to tiny typo-level fixes.
- Non-trivial quick-verifier failures return to the main agent.
- The main agent performs final diff review and in-scope fixes; no final-review
  agent is required.
- Deprecated compatibility settings are recognized/validated but are no-ops in
  the normal chain.
- The plan does not contain placeholders, skipped checks, backup routes, or
  unapproved scope changes.

Then ask for one combined approval covering the plan, selected route, any
grouped-worker allocation, immediate current-session execution, the
accepted-plan checkpoint commit, and the
final reviewed/verified implementation checkpoint commit. State that compliant
in-scope execution creates the final commit without a second approval prompt
when uncommitted changes remain. If the user requests changes, revise the plan
and rerun the focused self-review checks. Do not create the accepted-plan
checkpoint until the user gives combined approval.

After combined approval, the coordinator creates the accepted-plan checkpoint
and immediately invokes `simplepower:subagent-driven-development` for
current-session auto-dispatch with the approved plan path and route. That
accepted combined approval remains the authorization for the final checkpoint
commit; do not ask for separate commit approval unless execution requires a
fresh approved-path decision.

## Quick Verifier And Final Review

The quick verifier runs after all implementation edits, whether those edits were
made directly by the main agent or by grouped workers. It uses FAST by default
and receives only the approved changed-file list, relevant behavior contract,
implementation summary, and exact timed commands.

The quick verifier may make only tiny typo-level fixes. Any behavior change,
structural edit, public-interface change, test rewrite, unclear failure, or
scope concern is a non-trivial failure and must return to the main agent for
diagnosis and in-scope repair. After repairs, rerun the relevant quick
verification.

The main agent performs the final implementation review: inspect the complete
diff, compare it to the accepted plan and approved path, make in-scope fixes,
and run final verification. The normal workflow has no final-review agent and
no final-review scratch phase.

Only quick-verifier scratch refs remain in the target workflow, and they are
coordinator-owned local diff anchors managed by the execution skill. The target
workflow has exactly two coordinator checkpoints: accepted plan and final
reviewed/verified implementation. The final reviewed/verified implementation
checkpoint has no intermediate quick-verified
implementation checkpoint.

The canonical scratch namespace and mechanics live in
`skills/subagent-driven-development/scratch-ref-workflow.md`, under
`refs/simplepower/scratch/<run-id>/`; generated plans
must reference that file instead of copying ref creation, diff, and cleanup
commands. Scratch refs are not accepted history commits.
Workers and quick verifiers must not commit, inspect, or manage refs.
No worker commits or per-task commits. No per-task commits includes task-local
`git commit` commands.

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
Run the mandatory FAST quick verifier after implementation edits.
Return non-trivial quick-verifier failures to the main agent.
Have the main agent perform final diff review, in-scope fixes, and final verification.
Use the combined approval as authorization for both coordinator checkpoint commits.
After compliant final verification, create the final commit without another approval when uncommitted in-scope changes remain; do not create an empty commit.
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
- Text that pre-authorizes scope reduction, skipped checks, placeholder
  implementations, docs-only substitutes, route changes, alternate execution
  modes, or user selection among execution routes after approval.

## Remember

- Route selection happens before user approval.
- Main agent is the default for one cohesive package without material
  specialization benefit.
- Grouped workers require independent non-overlapping packages or specialized
  work with clear delegation value.
- Capacity queues packages; it does not split tiny tasks.
- Compact plans need design summary, route, exact files, steps, risks, timed
  quick/final verification, and two coordinator checkpoint conditions.
- Combined approval explicitly authorizes both coordinator checkpoint commits;
  compliant in-scope execution does not request a second final-commit approval.
- Grouped plans add Interface Contract, File Ownership, cohesive Worker
  Packages, serialization decisions, and FAST/NORMAL/BEST allocation.
- Main-agent plan self-review replaces active plan-review dispatch.
- The FAST quick verifier remains mandatory and may make only tiny typo-level
  fixes.
- Main-agent final diff review and in-scope fixes replace the final-review
  agent.
- Generated plans reference canonical global rules instead of copying global
  boilerplate.
