---
name: writing-plans
description: Use only when the user explicitly requests simplepower:writing-plans or an authorized Simple Power chain invokes it.
---

# Writing Plans

## Overview

Write the authoritative implementation plan directly from the approved
brainstorming design. The plan replaces standalone specs in the normal Simple
Power workflow. It must include a compact `Design Summary`, exact file
ownership, a required `Interface Contract`, implementation task allocation
using `Contract inputs` and `Serialization required`, FAST/NORMAL/BEST/REVIEW
model allocation, conditional primary-plus-secondary review allocation,
aggregate parallel dispatch guidance, quick verification commands with timeouts,
current-session auto-dispatch guidance, combined approval, and three coordinator
commit checkpoints. Plans may include
optional inline visual aids when they reduce ambiguity.
Planning and execution also use coordinator-owned temporary scratch refs as
local review diff anchors. Scratch refs are not accepted history commits and do
not change the three-checkpoint commit policy.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md`

## Model Tiers

Simple Power uses four configurable model tiers when planning implementation,
review, and verification work. These mandatory tiers are independent of
`use_subagent`.

Before allocating models or dispatching a reviewer, validate the full six-base-key
configuration plus its optional `review_model2` and `final_review_model` keys by following
`skills/using-simplepower/references/simplepower-config.md`. Every present TOML
file must validate in full before overlays; a higher layer must not hide
malformed TOML, unknown keys, wrong types, or invalid model values in a lower
layer.

| Tier | TOML key | Environment value | Built-in default |
|------|----------|-------------------|------------------|
| REVIEW | `review_model` | `SIMPLEPOWER_REVIEW_MODEL` | `gpt-5.6-sol-high` |
| BEST | `best_model` | `SIMPLEPOWER_BEST_MODEL` | `gpt-5.6-sol-high` |
| NORMAL | `normal_model` | `SIMPLEPOWER_NORMAL_MODEL` | `gpt-5.6-luna-max` |
| FAST | `fast_model` | `SIMPLEPOWER_FAST_MODEL` | `gpt-5.3-codex-spark-xhigh` |

The six base keys are `use_subagent`, `subagent_model`, `review_model`,
`best_model`, `normal_model`, and `fast_model`. `review_model2` and
`final_review_model` are optional: neither has an independent built-in default
or environment variable, and both are resolved only through the home file,
repository file, and explicit current-session instructions. First fully resolve
the primary `review_model`; then resolve and validate a present optional value
with the same final-dash parsing. An absent `final_review_model` falls back to
the fully resolved `review_model`. An absent `review_model2`, or an exact match
with the fully resolved primary, keeps the one-primary plan-review route. Only
a distinct fully resolved `review_model2` enables the conditional read-only
plan-review route. Neither optional key changes the four mandatory tiers above.

Resolve all tier settings by starting with the built-in defaults, then
overlaying `/home/gary/.codex/simplepower.toml`, repository
`<git-root>/simplepower.toml`, the four non-empty `SIMPLEPOWER_*_MODEL` process
environment values, and explicit current-session instructions last. Each later
layer replaces only the tier values it supplies, and missing higher-layer keys
inherit. Do not read model assignments from any `AGENTS.md` file.

Interpret the final dash-delimited segment of the resolved value as
`reasoning_effort` and the preceding string as `model`. Valid effort suffixes
are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`; stop and report an
invalid resolved value rather than guessing. The built-in defaults resolve
FAST to model `gpt-5.3-codex-spark` with `xhigh`, NORMAL to model
`gpt-5.6-luna` with `max`, and BEST and REVIEW to model `gpt-5.6-sol` with
`high`.

Use REVIEW for the primary plan reviewer. Use effective `final_review_model`
for the one final review+fix agent, falling back to REVIEW when absent. A
distinct optional `review_model2` supplies only a read-only secondary
plan-review route; it never supplies review+fix authority.
Use BEST for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test implementation work. Use NORMAL for routine low-risk
implementation work, especially localized edits where the NORMAL tier is
appropriate. Use FAST for obvious repetitive work, mechanical edits across many
files, large static text sweeps, simple fixture/assertion churn, and quick
verification. The quick verifier uses the FAST tier by default, resolving to
`model="gpt-5.3-codex-spark"` and `reasoning_effort="xhigh"` unless
`SIMPLEPOWER_FAST_MODEL` is overridden by the resolution rules above. Escalate
FAST to NORMAL or BEST if the work is less mechanical or obvious, and escalate
NORMAL to BEST if the work is broad, ambiguous, behavior-shaping, or hard to
verify.

## Approved Path Enforcement

The approved brainstorming design and accepted implementation plan are
authoritative. Do not authorize backup routes, scope reduction, docs-only
substitutes, placeholder implementations, skipped verification, skipped review,
or execution-route changes unless the user gives fresh explicit approval at the
moment the deviation is needed.

A stub substitute or execution-mode switch is an approved-path deviation and
requires fresh explicit user approval before work continues.

Plans may describe blockers and decision points, but must not pre-approve
alternate implementation work. If the approved path is blocked during execution,
the agent must stop, report the exact mismatch, show current status, and ask the
user before changing approach.

## Scratch Ref Review Anchors

Temporary scratch refs are used by the coordinator to give reviewers concrete
diff anchors without adding permanent commits. Workers, primary and secondary
plan reviewers, quick verifiers, review+fix agents, and individual tasks must
not create scratch refs or commits.

All scratch refs for one Simple Power run live under
`refs/simplepower/scratch/<run-id>/`. The run id format is
`YYYYMMDD-HHMMSS-<short-head>`, such as `20260602-143012-c4ad811`. The
coordinator records the run id in working notes and final reporting when any
scratch ref is created.

Scratch refs are local review artifacts. They are not branches, accepted
checkpoint commits, pushed, merged, or rebased, and they do not count as one of
the three coordinator checkpoint commits.

Use these phase names:
- Plan review refs:
  `refs/simplepower/scratch/<run-id>/plan-review/before` and
  `refs/simplepower/scratch/<run-id>/plan-review/after-<n>`
- Quick verifier refs:
  `refs/simplepower/scratch/<run-id>/quick-verifier/before` and
  `refs/simplepower/scratch/<run-id>/quick-verifier/after`
- Review+fix refs:
  `refs/simplepower/scratch/<run-id>/review-fix/before` and
  `refs/simplepower/scratch/<run-id>/review-fix/after`

A phase may omit an `after` ref only when no file changes happened in that
phase.

Scratch refs must capture the current worktree state for the approved file list
without changing the real index or branch history. Prefer a temporary index:

```bash
SP_RUN_ID="${SP_RUN_ID:-$(date -u +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD)}"
SP_SCRATCH_PREFIX="refs/simplepower/scratch/$SP_RUN_ID"
SP_REF="$SP_SCRATCH_PREFIX/<phase>/<label>"
SP_TMP_INDEX="$(mktemp)"
GIT_INDEX_FILE="$SP_TMP_INDEX" git read-tree HEAD
GIT_INDEX_FILE="$SP_TMP_INDEX" git add -- <approved-files>
SP_TREE="$(GIT_INDEX_FILE="$SP_TMP_INDEX" git write-tree)"
SP_COMMIT="$(printf '%s\n' "simplepower scratch $SP_RUN_ID <phase>/<label>" | git commit-tree "$SP_TREE" -p HEAD)"
git update-ref "$SP_REF" "$SP_COMMIT"
rm -f "$SP_TMP_INDEX"
```

If scratch-ref creation fails, stop the review loop before relying on the
missing anchor.

Every revised-plan review prompt after a blocking issue must include either an
exact scratch-ref diff command or an explicit diff summary based on the relevant
scratch refs. Preferred command shape:

```bash
git diff refs/simplepower/scratch/<run-id>/<phase>/<before-label> refs/simplepower/scratch/<run-id>/<phase>/<after-label> -- <approved-files>
```

Quick-verifier tiny fixes and review+fix edits must be inspectable with the same
command shape before the coordinator creates the next accepted checkpoint.

After an accepted checkpoint succeeds, delete the scratch refs for that phase:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>/<phase>" | while read -r ref; do git update-ref -d "$ref"; done
```

After the accepted plan checkpoint succeeds, delete the `plan-review` refs.
After the quick-verified implementation checkpoint succeeds, delete the
`quick-verifier` refs. After the final checkpoint succeeds, delete the
`review-fix` refs. At final reporting, run a cleanup check for remaining refs
under the run id. If the workflow stops because of user direction, a blocker, or
a failed checkpoint commit, keep scratch refs as evidence and report this manual
cleanup command instead of deleting them:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>" | while read -r ref; do git update-ref -d "$ref"; done
```

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run exactly one final review+fix agent using `final_review_model` (or `review_model` when absent) before final verification and final commit.

**Goal:** [One sentence describing what this builds]

**Design Summary:** [Compact summary of the approved brainstorming design, constraints, success criteria, and key decisions]

**Architecture:** [2-3 sentences about approach, including how the Interface Contract supports aggregate parallel dispatch]

**Tech Stack:** [Key technologies/libraries]

**Model Allocation:** FAST/NORMAL/BEST/REVIEW tiers are assigned below and are independent of `use_subagent`. Resolve and validate the six base keys—`use_subagent`, `subagent_model`, `review_model`, `best_model`, `normal_model`, and `fast_model`—plus optional `review_model2` and `final_review_model` in `skills/using-simplepower/references/simplepower-config.md`: built-in defaults, then per-key overlays from `/home/gary/.codex/simplepower.toml`, repository `<git-root>/simplepower.toml`, the four non-empty `SIMPLEPOWER_*_MODEL` environment values, and explicit current-session instructions last. Missing higher-layer keys inherit, and every present TOML file is fatal if invalid even when a higher layer overrides its values. Do not read model assignments from `AGENTS.md`. The optional keys have no environment variables; `final_review_model` falls back to fully resolved `review_model` when absent, while a distinct `review_model2` enables only a read-only secondary plan reviewer. FAST defaults to `gpt-5.3-codex-spark-xhigh`, NORMAL defaults to `gpt-5.6-luna-max`, and BEST and REVIEW default to `gpt-5.6-sol-high`. Parse the final dash as reasoning effort; valid suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. The primary plan reviewer uses REVIEW, and exactly one final review+fix agent uses effective `final_review_model`. The quick verifier uses FAST. With built-in defaults, FAST resolves to model `gpt-5.3-codex-spark` with `xhigh`, NORMAL to model `gpt-5.6-luna` with `max`, and BEST/REVIEW to model `gpt-5.6-sol` with `high`.

**Commit Policy:** The coordinator commits after the reviewed plan, allocation, and immediate current-session execution receive combined approval, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, primary and secondary plan reviewers, quick verifiers, and final review+fix agents must not commit. No per-task commits. Coordinator-owned temporary scratch refs under `refs/simplepower/scratch/<run-id>/...` may be created only as local review diff anchors; they are not accepted history commits, not pushed, not merged, not rebased, and must be cleaned up after successful checkpoints or reported for manual cleanup on blockers or failed checkpoints.

---
```

The full plan body must include these required sections in order:

## Interface Contract

Define the shared contract that lets implementation and test workers proceed
together without waiting for another worker's uncommitted edits.

This section must list the public APIs, filenames, command contracts, fixtures,
data shapes, behavior guarantees, and cross-task assumptions that workers may
rely on during aggregate parallel dispatch. Use exact names and expected
behavior, not broad intent.

Rules:
- Every task must reference the relevant entries through its `Contract inputs`.
- `Contract inputs` replace routine prerequisite scheduling when the approved
  Interface Contract is sufficient for coordination.
- Tests may be planned as parallel workers against approved Interface Contract
  entries even when implementation workers are creating those APIs.
- If the Interface Contract is missing or ambiguous for a task, mark
  `Serialization required: Yes` for that task with a concrete reason, or fix the
  contract before dispatch.
- The Interface Contract does not override file ownership. Parallel workers
  still need non-overlapping write scopes.

## File Ownership

List every file that may be created or modified. This section locks the write
boundaries before task dispatch.

Required columns:
- File
- Owner task
- Change type: create, modify, delete, or generated
- Responsibility
- Parallel safety notes

Rules:
- Every implementation task must own an exact file list.
- No two parallel tasks may edit the same file.
- Shared files must be serialized to a single task or split so ownership is
  unambiguous.
- Do not leave implied files outside ownership. If a task step, command, code
  snippet, or public declaration requires a file, include that file here and in
  the task write scope.

Optional plan section: `## Visual Aids`

Plans may include `## Visual Aids` after `## File Ownership` when inline visuals
reduce implementation ambiguity. Omit this section when visual aids do not
reduce ambiguity.

Visual aids must be inline Markdown-compatible content in the plan file:
Markdown-compatible HTML blocks, SVG blocks, Markdown tables, or plain-text
diagrams. Do not generate separate linked local HTML files for plan visuals
under this design.

Suitable visual aid cases include workflow flowcharts, architecture or data-flow
maps, task ownership matrices, and state or error-path diagrams.

Written plan sections remain authoritative. Visual aids must support, not
replace or contradict, the Interface Contract, File Ownership, implementation
tasks, task allocation, model allocation, verification, commit policy, or
approved path enforcement.

## Implementation Tasks

Create small tasks that can be dispatched as non-conflicting `sp-impl` workers
in aggregate parallel where the approved Interface Contract supplies the shared
coordination. Each task must be complete enough for a worker with no surrounding
context to make the intended change without inventing scope.

Each task must include:
- Task name and goal
- Contract inputs: exact Interface Contract entries, approved design details,
  or explicit external facts the worker may rely on
- Serialization required: `No` by default; `Yes` only with a concrete reason
  such as overlapping write scopes, missing or ambiguous contract, generated
  artifact required before editing, or intentional sequential migration/runtime
  ordering
- Write scope with exact paths
- Parallel: Yes or No, with compatible task names when Yes
- Risk: Low, Medium, or High, with a concrete reason
- Model tier: FAST, NORMAL, or BEST, with the resolved model and effort. REVIEW
  is reserved for the primary plan reviewer.
- Worker role: `sp-impl`
- Outputs and file-level responsibilities
- Implementation steps with exact commands, code locations, and expected results
- Verification commands that the worker should run, each with `timeout`
- Completion report requirements: changed files, commands run, results, and
  unresolved risks

Task instructions must not include worker commits or per-task commits. Do not
serialize tasks by prerequisite order when the Interface Contract is sufficient.
Implementation tasks and test tasks with non-overlapping write scopes may be
parallel even when tests target APIs that implementation workers are creating.

## Model Allocation

List every implementation task, the primary plan reviewer, any conditional
secondary plan reviewer, the quick verifier, and the final review+fix agent.

Required columns:
- Stage
- Role
- Model tier: FAST, NORMAL, BEST, REVIEW, or `final_review_model` (fallback
  REVIEW)
- Resolved model
- Reasoning effort
- Reason

Rules:
- FAST defaults to `gpt-5.3-codex-spark-xhigh` (`fast_model` or
  `SIMPLEPOWER_FAST_MODEL` overrides it at the corresponding layer).
- NORMAL defaults to `gpt-5.6-luna-max` (`normal_model` or
  `SIMPLEPOWER_NORMAL_MODEL` overrides it at the corresponding layer).
- BEST defaults to `gpt-5.6-sol-high` (`best_model` or
  `SIMPLEPOWER_BEST_MODEL` overrides it at the corresponding layer).
- REVIEW defaults to `gpt-5.6-sol-high` (`review_model` or
  `SIMPLEPOWER_REVIEW_MODEL` overrides it at the corresponding layer).
- `final_review_model` is optional, has no independent built-in default or
  environment value, and is not a fifth tier. Resolve it after `review_model`;
  an absent value falls back to fully resolved `review_model` for exactly one
  final review+fix agent.
- `review_model2` is optional, has no built-in default or
  `SIMPLEPOWER_REVIEW_MODEL2` environment value, and is not a fifth tier.
  Resolve it after `review_model`; an absent value or exact match keeps the
  single-primary plan-review route, while a distinct fully resolved value is a
  read-only plan-review secondary only.
- Resolve all tiers from built-in defaults, then overlay
  `/home/gary/.codex/simplepower.toml`, repository
  `<git-root>/simplepower.toml`, the four non-empty `SIMPLEPOWER_*_MODEL`
  process environment values, and explicit current-session instructions last.
- Validate every present TOML file in full before overlaying values; a higher
  layer cannot hide a broken lower-precedence file. Missing higher-layer keys
  inherit.
- Do not read model assignments from any `AGENTS.md` file.
- Mandatory FAST/NORMAL/BEST/REVIEW dispatches are independent of
  `use_subagent`.
- Parse the final dash-delimited segment as reasoning effort. Accept only
  `low`, `medium`, `high`, `xhigh`, `max`, or `ultra`.
- Implementation tasks may use FAST only when the work is obvious, repetitive,
  mechanical, or simple fixture/assertion churn.
- Implementation tasks use NORMAL for routine low-risk implementation work,
  especially localized edits.
- Broad, ambiguous, cross-cutting, behavior-shaping, high-risk, or hard-to-test
  implementation tasks use BEST.
- Escalate FAST to NORMAL or BEST if the work is less mechanical or obvious.
- Escalate NORMAL to BEST if the work is broad, ambiguous, behavior-shaping, or
  hard to verify.
- The primary plan reviewer uses REVIEW. A distinct `review_model2` adds a
  concurrent read-only secondary plan reviewer; both plan reviewers must
  approve the current plan revision.
- The one final review+fix agent uses effective `final_review_model`, falling
  back to REVIEW when it is absent. It directly owns in-scope fixes.
- The quick verifier uses the FAST tier by default, resolving to
  `model="gpt-5.3-codex-spark"` and `reasoning_effort="xhigh"` unless
  `SIMPLEPOWER_FAST_MODEL` is overridden.

## Plan Review

After writing the plan, self-review it before dispatching a reviewer.

Self-review checklist:
- Design Summary: compactly captures the approved brainstorming design,
  constraints, success criteria, and key decisions.
- Interface Contract: lists concrete APIs, filenames, commands, fixtures, data
  shapes, behavior guarantees, and cross-task assumptions before File Ownership.
- File ownership: every implied file is assigned to exactly one task, and
  parallel tasks do not collide.
- Task allocation: every requirement maps to an implementation task, every task
  has `Contract inputs`, and any `Serialization required: Yes` has a concrete
  reason.
- Aggregate parallel readiness: non-overlapping workers whose coordination
  needs are satisfied by the Interface Contract are planned for aggregate
  parallel dispatch instead of prerequisite-ordered staging.
- Visual aids: if present, they are consistent with authoritative written
  sections; if absent, that is acceptable and not a review issue.
- Model allocation: FAST/NORMAL/BEST/REVIEW choices match risk and mechanics,
  all four configurable defaults and overlay layers are documented, no model
  assignments are read from `AGENTS.md`, mandatory tiers are independent of
  `use_subagent`, and optional `review_model2` and `final_review_model` have
  no environment variables. An absent `final_review_model` falls back to
  resolved `review_model`; a distinct `review_model2` is read-only and applies
  only to plan review; the quick verifier uses FAST by default.
- Review allocation: absent `review_model2` or an exact match has one primary
  plan reviewer; a distinct value has concurrent read-only plan reviewers that
  both approve. Final review always dispatches one agent using effective
  `final_review_model`.
- Commit policy: exactly three coordinator checkpoints are present and no
  non-coordinator role commits; scratch refs are local review anchors, not
  accepted checkpoint commits.
- Scratch refs: the plan includes coordinator-only scratch-ref namespace, run
  id, creation, revised-plan diff handoff, cleanup, blocker preservation, and
  final cleanup check guidance.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize unapproved route
  changes, skipped checks, or reduced deliverables.

Before first review, the coordinator creates
`refs/simplepower/scratch/<run-id>/plan-review/before` for the saved plan file
using the temporary-index pattern in `Scratch Ref Review Anchors`.

First fully resolve the primary `review_model`, then resolve any optional
`review_model2`. It has no built-in default and no
`SIMPLEPOWER_REVIEW_MODEL2` environment variable. An absent secondary or an
exact match with the fully resolved primary uses the current one-primary plan
reviewer behavior: dispatch one primary REVIEW-tier plan reviewer using
`skills/writing-plans/plan-document-reviewer-prompt.md` with
`spawn_agent(agent_type="worker", model=<REVIEW_model>, reasoning_effort=<REVIEW_effort>, fork_turns="none", message=<self-contained-review-prompt>)`.

When the fully resolved optional secondary is distinct, dispatch both plan
reviewers concurrently: the primary with the REVIEW model and the secondary
with the parsed `review_model2` model and effort. Both plan reviewers use the
same self-contained `plan-document-reviewer-prompt.md` evidence, are explicitly
read-only, and receive the saved plan path, approved brainstorming design
context, scratch run id, and the same `plan-review/before` snapshot. Every
dispatch must pass `fork_turns="none"`. If either required reviewer fails to
launch, stop the plan-review checkpoint; do not accept a partial review.

For either route, the prompt must contain the exact review task, read-only scope
and constraints, approved design and plan evidence, required review output, and
verification criteria. Keep the original required reviewer or reviewers open
through recoverable issue loops. If any reviewer reports issues, the coordinator
fixes the plan, reruns the focused self-review checks for the changed
categories, creates `refs/simplepower/scratch/<run-id>/plan-review/after-<n>`,
and sends the revised plan and the concrete diff to the same original reviewer
or both original reviewers:

```bash
git diff refs/simplepower/scratch/<run-id>/plan-review/before refs/simplepower/scratch/<run-id>/plan-review/after-<n> -- <plan-file>
```

If any original reviewer still finds issues, the next revision creates
`plan-review/after-<n+1>` and compares the last `after-<n>` ref to the new
`after-<n+1>` ref before sending that diff to every required original reviewer:

```bash
git diff refs/simplepower/scratch/<run-id>/plan-review/after-<n> refs/simplepower/scratch/<run-id>/plan-review/after-<n+1> -- <plan-file>
```

The single-primary route passes after its primary approval. The distinct route
passes only after both plan reviewers approve the same current plan revision;
an approval from one reviewer does not excuse the other review. Close the
required reviewer or reviewers only after the applicable approval condition, an
unrecoverable interruption, or explicit user direction. If a needed scratch ref
is missing, stop the review loop before relying on that missing diff anchor.

Primary and optional secondary plan reviewers must perform the assigned review
directly in the current worker. They must not edit or create files, run Codex
CLI, spawn subagents, invoke Simple Power skills, restart execution, or reroute
the workflow.

After the required plan reviewer approval condition passes, ask the user for
combined approval of the reviewed plan, model/task allocation, and immediate
current-session execution. The accepted plan checkpoint commit happens only
after that combined approval. Workers and reviewers must not create this commit.

After the user gives combined approval, the coordinator creates the accepted
plan checkpoint commit and immediately invokes
`simplepower:subagent-driven-development` to execute the accepted plan with the
approved model allocation in the current session. Every future implementation,
quick-verifier, and final review+fix `spawn_agent` dispatch must pass
`fork_turns="none"` and a self-contained prompt containing
the exact task, scope, constraints, evidence or Contract inputs, required
output, and exact verification commands and expectations. After the accepted plan
checkpoint succeeds, delete that run's `plan-review` scratch refs. If the
checkpoint fails or the workflow stops before the checkpoint, preserve the refs
and report the manual cleanup command.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the
coordinator creates the quick-verified implementation checkpoint. It checks that
the implementation is coherent enough for final review.

Before dispatching the quick verifier, the coordinator creates
`refs/simplepower/scratch/<run-id>/quick-verifier/before` for the approved
implementation file list. If the quick verifier makes tiny typo-level fixes, the
coordinator creates `refs/simplepower/scratch/<run-id>/quick-verifier/after`
after those edits and before the quick-verified implementation checkpoint, then
inspects or hands off this diff command:

```bash
git diff refs/simplepower/scratch/<run-id>/quick-verifier/before refs/simplepower/scratch/<run-id>/quick-verifier/after -- <approved-files>
```

The quick verifier must use the FAST tier by default. The built-in FAST value
`gpt-5.3-codex-spark-xhigh` resolves to `model="gpt-5.3-codex-spark"` and
`reasoning_effort="xhigh"`.
Dispatch it with
`spawn_agent(agent_type="worker", model=<FAST_model>, reasoning_effort=<FAST_effort>, fork_turns="none", message=<self-contained-verification-prompt>)`.

The plan must list exact quick verification commands with timeouts, usually:
- `timeout 30s <lint command>`
- `timeout 60s <typecheck or build command>`
- `timeout 120s <focused test command>`

Use commands that fit the repository. If no lint, build, or test command exists,
state the nearest available command and the reason it is the right quick check.

The quick verifier may fix only tiny typo-level errors discovered while running
the quick checks. Any behavior change, structural edit, test rewrite, public
interface change, or unclear issue must be reported to the coordinator instead
of fixed by the quick verifier. If no file changes happen during quick
verification, omit the `quick-verifier/after` ref. After the quick-verified
implementation checkpoint succeeds, delete that run's `quick-verifier` scratch
refs. If the checkpoint fails or the workflow stops before the checkpoint,
preserve the refs and report the manual cleanup command.

## Final Review And Fix

Before dispatching the review+fix agent, the coordinator creates
`refs/simplepower/scratch/<run-id>/review-fix/before` for the approved
implementation file list. Resolve `review_model` first, then a present optional
`final_review_model`. The latter has no environment variable and falls back to
fully resolved `review_model` when absent.

Dispatch exactly one final review+fix agent with direct in-scope fix authority.
It reviews the whole implementation against the accepted plan, file ownership,
approved path enforcement, aggregate parallel dispatch semantics, and
verification requirements:

`spawn_agent(agent_type="worker", model=<final_review_model>, reasoning_effort=<final_review_effort>, fork_turns="none", message=<self-contained-review-fix-prompt>)`.

After the final review+fix agent completes, lifecycle-close it by default,
inspect its report and the actual diff, and validate changed files. Create
`review-fix/after` only when that agent edited files.
Before final verification, inspect or hand off this diff command when the
primary made changes:

```bash
git diff refs/simplepower/scratch/<run-id>/review-fix/before refs/simplepower/scratch/<run-id>/review-fix/after -- <approved-files>
```

Only the final review+fix agent may edit files within the plan's approved file
ownership when authorized to fix issues. It must report changed files, commands
run, results, remaining risks, and any unresolved deviations that require user
approval. It must not commit. The primary and optional secondary must perform
their assigned reviews directly in the current worker. Do not run Codex CLI,
spawn subagents, invoke Simple Power skills, restart execution, or reroute the
workflow. If no final-review file changes happen during review+fix, omit the
`review-fix/after` ref. After the final checkpoint succeeds, delete that run's
`review-fix` scratch refs. If the checkpoint fails or the workflow stops before
the checkpoint, preserve the refs and report the manual cleanup command.

## Commit Checkpoints

Every plan must define exactly three future coordinator commit checkpoints:

1. Accepted plan checkpoint: after the user gives combined approval for the
   reviewed plan, model/task allocation, and immediate current-session
   execution, and before invoking `simplepower:subagent-driven-development`.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits
   complete and the quick verifier passes.
3. Final checkpoint: after the one final review+fix lifecycle completes and
   final verification passes.

Workers, primary and secondary plan reviewers, quick verifiers, and final
review+fix agents must not commit. Do not include worker-owned commits or
per-task commits.

Scratch refs are the only allowed temporary review anchors. They are
coordinator-owned, local-only, and not accepted checkpoint commits. They must be
deleted after the successful checkpoint for their phase or preserved and
reported for manual cleanup if the workflow stops or the checkpoint commit
fails.

## Current-Session Auto-Dispatch

The saved plan is the execution artifact. Do not write a project-local
implementation JSON artifact.

Normal Simple Power planning proceeds in the current session. Do not run routing
heuristics or offer alternate execution routes.

After the required plan reviewer approval condition passes, ask the user for one
combined approval that covers:
- The reviewed plan
- The model/task allocation
- Immediate current-session execution

If the user requests changes, update the plan, rerun the focused self-review
checks for the changed categories, create the next `plan-review/after-<n>`
scratch ref, and send the revised plan back to the same original reviewer or,
when the distinct secondary route is enabled, both original reviewers with the
concrete scratch-ref `git diff` command when review approval must be refreshed.
Do not create the accepted plan checkpoint until the user gives combined
approval.

After combined approval, the coordinator creates the accepted plan checkpoint
commit, deletes the successful `plan-review` scratch refs, then immediately invokes `simplepower:subagent-driven-development` in the current session with
this instruction:

```text
Execute `<PLAN_PATH>` with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST allocation for `sp-impl` workers, REVIEW for plan review, and effective `final_review_model` for final review+fix. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick FAST-tier verifier with lint/build/tests and timeouts after all workers finish, and commit the quick-verified implementation. Then resolve `final_review_model` after `review_model`, falling back to the fully resolved REVIEW value when absent, and run exactly one final review+fix agent. Run final verification and the final commit condition without adding a checkpoint or concurrent writer.
```

## Verification

List final verification commands with timeouts. Include the exact command, when
to run it, expected result, and what failure means.

Final verification should include the strongest practical checks for the change,
usually:
- `timeout 30s <lint command>`
- `timeout 60s <typecheck or build command>`
- `timeout 120s <test command>`

The final verification section must also say that the coordinator performs the
final checkpoint only after the one final review+fix lifecycle has completed
and the final commands pass.

Final reporting must include a cleanup check for any remaining scratch refs from
the run:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>"
```

If the final checkpoint succeeds, no scratch refs for that run should remain
after phase cleanup. If the workflow stopped because of user direction, a
blocker, or a failed checkpoint commit, preserve remaining scratch refs and
report the manual cleanup command from `Scratch Ref Review Anchors`.

## No Placeholders

Every step must contain the actual content an engineer needs. These are plan
failures:
- `TBD`, `TODO`, `implement later`, or `fill in details`
- Vague instructions such as `add validation` without exact behavior
- Tests requested without the concrete command or test location
- References to functions, files, or commands not defined elsewhere in the plan
- Worker commit instructions, per-task commit instructions, or task-local
  `git commit` commands
- Text that pre-authorizes scope reduction, skipped checks, placeholder
  implementations, docs-only substitutes, execution-route changes, alternate
  context execution modes, or user selection among execution routes
- Separate linked local HTML files for plan visuals unless a future approved
  design explicitly adds them

## Remember

- Exact file paths always
- Interface Contract before File Ownership
- `## Visual Aids` is optional; include it only when inline visuals reduce
  ambiguity, and check present visuals against authoritative written sections
- Exact ownership before tasks
- Contract inputs for every implementation task
- Serialization required defaults to No; Yes needs a concrete reason
- Aggregate parallel dispatch is expected when write scopes do not overlap and
  the approved Interface Contract is sufficient
- Tests may be parallel workers against approved Interface Contract APIs
- Complete task instructions, with code snippets when code shape matters
- Concrete commands with `timeout` and expected results
- FAST/NORMAL/BEST/REVIEW allocation across implementation tasks, plan review,
  and verification; optional `review_model2` is a read-only plan-review
  secondary route, and optional `final_review_model` selects final review+fix
- Model resolution order is explicit: built-in defaults, home
  `/home/gary/.codex/simplepower.toml`, repository
  `<git-root>/simplepower.toml`, the four non-empty `SIMPLEPOWER_*_MODEL`
  environment values, then explicit current-session instructions
- Every present TOML file is validated before overlays, invalid lower layers
  are fatal, and missing higher-layer keys inherit
- Model assignments are never read from `AGENTS.md`
- Mandatory tier dispatches are independent of `use_subagent`
- FAST for obvious repetitive work, mechanical edits, static text sweeps, simple
  fixture/assertion churn, and quick verification
- NORMAL for routine low-risk localized implementation work
- BEST for broad, ambiguous, behavior-shaping, high-risk, or hard-to-test work
- Resolve `final_review_model` and `review_model2` only after the primary
  REVIEW value. Neither has an environment variable; absent
  `final_review_model` falls back to REVIEW, while an absent or exact-match
  `review_model2` keeps the single-primary plan-review route
- Primary REVIEW-tier plan reviewer; when a distinct secondary exists, dispatch
  both plan reviewers concurrently and require both approvals
- Keep the initial required plan reviewer or reviewers open for issue loops;
  send revised plans and their concrete scratch diff to the same original
  reviewer or both original reviewers until the applicable approval condition,
  unrecoverable interruption, or explicit user direction
- Coordinator-owned scratch refs may live only under
  `refs/simplepower/scratch/<run-id>/`; use the
  `YYYYMMDD-HHMMSS-<short-head>` run id format and record the run id in working
  notes and final reporting
- Scratch refs are local review diff anchors, not branches, not accepted
  checkpoint commits, and not worker or task commits
- Create `plan-review/before` before first plan review; after coordinator plan
  edits, create `plan-review/after-<n>` and send the same original reviewer or,
  in the distinct-secondary route, both original reviewers a concrete `git diff`
  command
- Use the same scratch-ref diff shape for quick-verifier tiny fixes and final
  review+fix edits before the next accepted checkpoint
- Delete phase scratch refs after the accepted checkpoint for that phase
  succeeds; preserve refs and report the manual cleanup command on blockers,
  user stops, or failed checkpoint commits
- Run the final cleanup check for remaining refs under
  `refs/simplepower/scratch/<run-id>/`
- Quick verifier uses the FAST tier by default, resolving to
  `gpt-5.3-codex-spark-xhigh` when unset
- Exactly one final review+fix agent is the only final-review writer. It uses
  `final_review_model`, falling back to REVIEW when absent
- No worker commits or per-task commits
- Exactly three coordinator checkpoints
- Ask for combined approval of the reviewed plan, model/task allocation, and
  immediate current-session execution
- After combined approval, commit the accepted plan checkpoint and immediately
  invoke `simplepower:subagent-driven-development` with the approved model
  allocation
