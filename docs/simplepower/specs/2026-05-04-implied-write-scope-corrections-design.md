# Implied Write-Scope Corrections Design

## Goal

Tighten Simple Power planning and execution so obvious plan/write-scope
contradictions are caught before implementation, and so execution can correct
the narrow class of write-scope omissions already implied by the approved plan
without asking the user for routine approval.

The motivating failure is a task whose steps required adding host declarations
to a header, while that header was missing from the task's write scope. The
worker correctly stopped instead of editing out of scope, but the workflow
should have caught the contradiction during plan writing or corrected it as a
plan typo during coordination.

## Problem

Simple Power currently treats the approved plan and write scopes as
authoritative. That is correct, but the plan review contract focuses on broad
coverage, dependency graph validity, parallel write collisions, placeholders,
and approved-path enforcement. It does not explicitly require a per-task audit
that compares the task write scope against every file implied by:

- task steps;
- task `Files:` lists;
- code snippets;
- public declaration requirements;
- verification setup;
- the plan's file-structure responsibility map;
- requirements inherited from the approved spec.

As a result, a plan can be internally contradictory: the task tells a worker to
edit a file, while the task write scope omits that file. Execution then stops
for user approval even when the correct answer is already implied by the
approved plan.

## Classification

Simple Power should classify write-scope mismatches into two categories.

### Implied-Scope Omission

An implied-scope omission exists when a missing file is already named or
structurally required by the approved spec or plan. Examples:

- A task step says to add declarations to `include/foo.h`, but the write scope
  lists only `src/foo.cc`.
- The task `Files:` block lists `tests/foo_test.py`, but the write-scope line
  omits it.
- A file-structure section says a header owns public helper declarations, and a
  later task requires adding those public declarations.

This is a plan correction, not a product-scope expansion and not an alternate
implementation path.

### True Scope Expansion

A true scope expansion exists when the missing file or implementation strategy
is not already implied by the approved spec or plan. Examples:

- A worker discovers a new module must be refactored to make the task possible.
- A task requires a new dependency or generated artifact not named in the plan.
- A verification failure suggests changing a different subsystem that was not
  part of the approved design.

True scope expansion still requires fresh explicit user approval before any
implementation work proceeds.

## Planning Changes

`simplepower:writing-plans` must add an implied write-scope audit to plan
authoring and self-review.

For every task, the planner must:

1. Extract files named in the write-scope line, write-scope table row, and
   task `Files:` block.
2. Check the task steps, prose, code snippets, verification instructions,
   public declaration requirements, file-structure responsibilities, and
   relevant spec requirements for files the task is expected to modify.
3. Ensure every implied file is present in the task write scope.
4. Explain any deliberate shared-file overlap as serialized, review-gated, or
   safe for parallelism.

The plan reviewer prompt must treat a mismatch between implied files and task
write scope as a blocking issue. This should be separate from the existing
parallel-safety check, because a serialized task can still have an incomplete
write scope.

## Execution Changes

`simplepower:subagent-driven-development` and `simplepower:executing-plans`
must classify write-scope mismatches before asking the user.

When a worker reports that a required file is outside its assigned scope, or
when the coordinator detects that a task step needs a file missing from the
task write scope, the coordinator must:

1. Compare the missing file against the approved spec, plan file-structure
   section, task `Files:` block, task prose, snippets, and verification
   instructions.
2. If the file is already implied, update the plan's write-scope line and
   write-scope table for that task, record a short wave note describing the
   correction, and continue with the same approved task.
3. If the file is not already implied, stop and ask the user for fresh explicit
   approval before changing scope, strategy, verification, or review mode.

Workers, reviewers, and fixers must not self-expand their assigned write scope.
They should continue to report `BLOCKED` or `NEEDS_CONTEXT` when the task
requires an out-of-scope path. The coordinator owns the classification and any
plan correction.

## Approved Path Enforcement

This change must not weaken approved-path enforcement. An implied write-scope
correction is allowed only when the approved plan or spec already requires the
missing file. It must not authorize:

- backup plans;
- escape plans;
- fallback implementations;
- reduced scope;
- docs-only substitutes;
- stub substitutes;
- skipped verification;
- skipped review;
- execution-mode switches;
- easier alternate paths.

If the coordinator cannot point to approved text that implies the missing file,
the situation is a blocker requiring fresh explicit user approval.

## User Experience

For implied-scope omissions, the coordinator should not ask the user to approve
routine corrections. The coordinator should make the plan correction, continue
the wave, and report the correction in the wave summary.

For true scope expansions, the coordinator should ask a concise question that
states:

1. the approved task and write scope;
2. the missing file or new strategy;
3. why the approved plan does not already imply it;
4. the exact approval needed to proceed.

This keeps obvious plan typos from interrupting implementation while preserving
human approval for real design or scope changes.

## Files To Change

- `skills/writing-plans/SKILL.md`: add the implied write-scope audit to plan
  authoring requirements and self-review.
- `skills/writing-plans/plan-document-reviewer-prompt.md`: add a blocking
  review category for implied write-scope mismatches.
- `skills/subagent-driven-development/SKILL.md`: add coordinator
  classification and plan-correction rules for execution.
- `skills/executing-plans/SKILL.md`: add the same classification rule for
  inline execution.
- `skills/subagent-driven-development/implementer-prompt.md`: keep worker
  behavior strict, and tell workers to report suspected implied omissions rather
  than edit out of scope.
- `skills/subagent-driven-development/impl-reviewer-prompt.md`: apply the same
  worker-side reporting rule for inline reviewer workers.
- `skills/subagent-driven-development/fixer-prompt.md`: keep fixers inside
  assigned scope and tell them to report suspected implied omissions.
- `tests/simplepower-static/run-tests.sh`: add static assertions for the new
  planning, reviewer, execution, and worker-prompt language.

## Testing

Static tests should verify that:

- writing-plans requires an implied write-scope audit;
- writing-plans self-review checks task steps, snippets, file lists, and
  file-structure responsibilities against each task write scope;
- the plan reviewer treats implied write-scope mismatches as blocking issues;
- subagent-driven development and inline execution classify mismatches as
  implied-scope omissions or true scope expansions;
- execution guidance allows coordinator-owned plan correction only for
  implied-scope omissions;
- worker prompts still forbid out-of-scope edits and require reporting instead
  of self-expanding scope;
- approved-path enforcement language still blocks fallback work and easier
  alternate paths without fresh explicit approval.

Run:

```bash
bash tests/simplepower-static/run-tests.sh
```

Expected result: all Simple Power static checks pass.

## Non-Goals

- Do not let workers, reviewers, or fixers modify their own assigned write
  scope.
- Do not allow implementation of files or strategies not implied by the
  approved spec or plan.
- Do not add a backup plan, fallback implementation, reduced-scope path, or
  docs-only substitute.
- Do not weaken review, verification, model allocation, task progress, or
  checkpoint commit requirements.
