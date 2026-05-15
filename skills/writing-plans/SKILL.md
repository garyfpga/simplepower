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
using `Contract inputs` and `Serialization required`, FAST/BEST model
allocation, aggregate parallel dispatch guidance, review allocation, quick
verification commands with timeouts, current-session auto-dispatch guidance,
combined approval, and three coordinator commit checkpoints. Plans may include
optional inline visual aids when they reduce ambiguity.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md`

## Model Tiers

Simple Power uses two configurable model tiers when planning implementation and
review work:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"
```

If either environment variable is unset, use the default shown above. Interpret
the final dash-delimited segment as `reasoning_effort` and the preceding string
as `model`. For example, `gpt-5.4-mini-high` resolves to
`model="gpt-5.4-mini"` and `reasoning_effort="high"`.

Use FAST for narrow, low-risk, localized implementation work. Use BEST for
broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or hard-to-test
implementation and review work. If the allocation is unclear, choose BEST. The
plan reviewer and final review+fix agent use BEST. The quick verifier uses
`model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

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

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** [One sentence describing what this builds]

**Design Summary:** [Compact summary of the approved brainstorming design, constraints, success criteria, and key decisions]

**Architecture:** [2-3 sentences about approach, including how the Interface Contract supports aggregate parallel dispatch]

**Tech Stack:** [Key technologies/libraries]

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan, allocation, and immediate current-session execution receive combined approval, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

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
- Model tier: FAST or BEST, with the resolved default model and effort
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

List every implementation task, the plan reviewer, the quick verifier, and the
final review+fix agent.

Required columns:
- Stage
- Role
- Model tier
- Resolved model
- Reasoning effort
- Reason

Rules:
- FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset).
- BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset).
- Implementation tasks may use FAST only when the work is narrow, localized,
  low-risk, and easy to verify.
- Broad, ambiguous, cross-cutting, behavior-shaping, high-risk, or hard-to-test
  implementation tasks use BEST.
- The plan reviewer uses BEST.
- The final review+fix agent uses BEST.
- The quick verifier uses `model="gpt-5.3-codex-spark"` and
  `reasoning_effort="high"`.

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
- Model allocation: FAST/BEST choices match risk, and reviewer/verifier roles
  use the required models.
- Review allocation: the plan has one BEST-tier review+fix agent after quick
  verification.
- Commit policy: exactly three coordinator checkpoints are present and no
  non-coordinator role commits.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize unapproved route
  changes, skipped checks, or reduced deliverables.

Then dispatch a BEST-tier plan reviewer using
`skills/writing-plans/plan-document-reviewer-prompt.md`. Provide the saved plan
path and the approved brainstorming design context. Keep the initial reviewer
subagent open while it reports recoverable issues. If the reviewer reports
issues, fix the plan, rerun the focused self-review checks for the changed
categories, and send the revised plan back to the same reviewer. Close the
reviewer only after approval, an unrecoverable interruption, or explicit user
direction.

After the plan reviewer approves, ask the user for combined approval of the
reviewed plan, model/task allocation, and immediate current-session execution.
The accepted plan checkpoint commit happens only after that combined approval.
Workers and reviewers must not create this commit.

After the user gives combined approval, the coordinator creates the accepted
plan checkpoint commit and immediately invokes
`simplepower:subagent-driven-development` to execute the accepted plan with the
approved model allocation in the current session.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the
coordinator creates the quick-verified implementation checkpoint. It checks that
the implementation is coherent enough for final review.

The quick verifier must use `model="gpt-5.3-codex-spark"` and
`reasoning_effort="high"`.

The plan must list exact quick verification commands with timeouts, usually:
- `timeout 30s <lint command>`
- `timeout 60s <typecheck or build command>`
- `timeout 120s <focused test command>`

Use commands that fit the repository. If no lint, build, or test command exists,
state the nearest available command and the reason it is the right quick check.

The quick verifier may fix only tiny typo-level errors discovered while running
the quick checks. Any behavior change, structural edit, test rewrite, public
interface change, or unclear issue must be reported to the coordinator instead
of fixed by the quick verifier.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch
one BEST-tier review+fix agent. That agent reviews and fixes the whole
implementation against the accepted plan, file ownership, approved path
enforcement, aggregate parallel dispatch semantics, and verification
requirements.

The review+fix agent may edit files within the plan's approved file ownership
when fixing issues it finds. It must report changed files, commands run, results,
remaining risks, and any unresolved deviations that require user approval. It
must not commit.

## Commit Checkpoints

Every plan must define exactly three future coordinator commit checkpoints:

1. Accepted plan checkpoint: after the user gives combined approval for the
   reviewed plan, model/task allocation, and immediate current-session
   execution, and before invoking `simplepower:subagent-driven-development`.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits
   complete and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final
   verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit.
Do not include worker-owned commits or per-task commits.

## Current-Session Auto-Dispatch

The saved plan is the execution artifact. Do not write a project-local
implementation JSON artifact.

Normal Simple Power planning proceeds in the current session. Do not measure
context measurement helper and context-based routing
heuristics, or offer alternate execution routes.

After the plan reviewer approves, ask the user for one combined approval that
covers:
- The reviewed plan
- The model/task allocation
- Immediate current-session execution

If the user requests changes, update the plan, rerun the focused self-review
checks for the changed categories, and send the revised plan back to the same
reviewer when review approval must be refreshed. Do not create the accepted
plan checkpoint until the user gives combined approval.

After combined approval, the coordinator creates the accepted plan checkpoint
commit, then immediately invokes `simplepower:subagent-driven-development` in
the current session with this instruction:

```text
Execute `<PLAN_PATH>` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
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
final checkpoint only after the BEST-tier review+fix agent has completed and the
final commands pass.

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
- FAST/BEST allocation per task
- BEST-tier plan reviewer
- Keep the initial plan reviewer open for issue loops; send revised plans back
  to the same reviewer until approval, unrecoverable interruption, or explicit
  user direction
- Quick `gpt-5.3-codex-spark` high-effort verifier
- One BEST-tier review+fix agent
- No worker commits or per-task commits
- Exactly three coordinator checkpoints
- Ask for combined approval of the reviewed plan, model/task allocation, and
  immediate current-session execution
- After combined approval, commit the accepted plan checkpoint and immediately
  invoke `simplepower:subagent-driven-development` with the approved model
  allocation
