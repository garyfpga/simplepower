# Simple Power Approved Path Enforcement Design

## Goal

Tighten the Simple Power workflow so agents cannot use backup plans, escape
plans, easier substitute implementations, reduced scope, or workflow shortcuts
unless the user gives fresh explicit approval at the moment the deviation is
needed.

The approved spec and approved plan are authoritative. If the approved path is
blocked, impossible, unsafe, underspecified, unexpectedly expensive, or no
longer matches the codebase, the agent must stop, report the mismatch, and ask
the user before changing approach.

## Context

Simple Power already has strong gates around brainstorming, implementation
planning, model allocation, wave execution, review, verification, and
coordinator checkpoint commits. Those gates prevent many common workflow
failures, but they do not yet name a cross-cutting rule against substituting
easier work for approved work.

The failure mode to block is not only explicit fallback language. It also
includes partial delivery, stubs presented as implementation, documentation-only
substitutes, skipped review or verification, execution-mode switches, deferred
scope, or any easier alternate path that changes what the user approved.

## Scope

This change applies to active Simple Power workflow skills, active subagent
prompt templates, and static tests.

Update:

- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/impl-reviewer-prompt.md`
- `skills/subagent-driven-development/reviewer-prompt.md`
- `skills/subagent-driven-development/fixer-prompt.md`
- `skills/executing-plans/SKILL.md`
- `tests/simplepower-static/run-tests.sh`

Historical specs and plans do not need to be rewritten.

## Non-Goals

- Do not add runtime hooks, external enforcement services, or generated
  handoff artifacts.
- Do not remove the user's ability to approve a different path.
- Do not prohibit diagnostic investigation after a blocker is discovered.
- Do not reintroduce non-Codex harness support in active docs.
- Do not change the existing coordinator checkpoint commit policy.

## Approved Path Enforcement Contract

Add a named contract, `Approved Path Enforcement`, to the active workflow. The
contract must say:

- The approved spec and approved plan are authoritative.
- No backup plan, escape plan, fallback implementation, reduced scope,
  docs-only substitute, stub substitute, skipped verification, skipped review,
  execution-mode switch, or easier alternate path may be used unless the user
  gives fresh explicit approval at the moment the deviation is needed.
- If the approved path is blocked, impossible, unsafe, underspecified,
  unexpectedly expensive, or mismatched with the codebase, the agent must stop
  work, explain the exact mismatch, show the current status, and ask the user
  before changing approach.
- Pre-approved alternates in specs or plans do not count as execution approval.
  Execution still requires fresh user approval before using any alternate path.
- The only autonomous action after a blocker is diagnosis and reporting. No
  implementation work may proceed on an alternate path.

This contract must be repeated at the points where drift can enter: design
authoring, plan authoring, plan self-review, plan document review, execution
coordination, worker prompts, reviewer prompts, and fixer prompts.

## Brainstorming Changes

`skills/brainstorming/SKILL.md` must add the contract to the design and spec
rules.

Brainstorming must produce a complete intended design, not a design with escape
hatches. If the design has risks or uncertainty, the spec may describe blockers
and decision points, but it must not authorize fallback work. Any alternate path
requires fresh user approval during execution.

The spec self-review must check for language that would authorize backup
plans, reduced scope, deferred implementation, stubs, docs-only substitutes, or
other alternate work. If that language is present, the spec must rewrite it as a
blocker-reporting rule or remove it.

## Planning Changes

`skills/writing-plans/SKILL.md` must add the contract to the plan header,
required plan guidance, no-placeholder rules, and self-review checklist.

Plans must directly map every spec requirement to concrete implementation,
review, and verification tasks. The plan must not include fallback
implementations, scope reductions, optional shortcuts, docs-only substitutes,
stub substitutes, skipped verification, skipped review, or execution-mode
switching as authorized paths.

The plan may describe blocker handling, but blocker handling must stop for user
approval. It must not instruct agents to continue with a different
implementation.

Plan self-review must scan for substitution language such as:

- backup
- escape
- fallback
- if this is too hard
- skip
- stub for now
- document instead
- defer implementation
- later
- optional shortcut

The scan must distinguish legitimate blocker-reporting text from unauthorized
alternate work. Unauthorized alternate work must be removed or rewritten before
handoff.

## Plan Reviewer Changes

`skills/writing-plans/plan-document-reviewer-prompt.md` must require the plan
reviewer to check for approved path enforcement.

The reviewer must reject plans that:

- miss a spec requirement
- authorize fallback implementations
- allow reduced scope or partial delivery
- allow skipped review or verification
- allow execution-mode switching without fresh user approval
- describe stubs or docs-only work as an acceptable substitute for
  implementation

Advisory recommendations can still be non-blocking, but any approved path
enforcement violation must be a blocking issue.

## Subagent Execution Changes

`skills/subagent-driven-development/SKILL.md` must add enforcement gates:

- before dispatching a wave
- after worker results are received
- after review or fixer results are received
- before marking `Task Progress`
- before wave verification
- before checkpoint commits

The coordinator must compare actual worker output against the approved plan and
write scope. If output is incomplete, out of scope, substituted, stubbed,
docs-only, missing verification, missing review, or based on a different
execution mode, the coordinator cannot accept it as progress.

When the approved path cannot proceed, the coordinator must stop, report the
blocker, and ask the user before dispatching alternate work or changing the
plan. The coordinator may gather diagnostic information needed to explain the
blocker, but must not implement an alternate path without approval.

## Inline Execution Changes

`skills/executing-plans/SKILL.md` must mirror the same enforcement for inline
execution.

The main agent must follow the approved plan exactly. It must not switch review
mode, skip review, skip verification, reduce scope, implement stubs, document
instead of implementing, or choose an easier alternate path without fresh user
approval.

If an inline task is blocked, the main agent must stop and ask. It may explain
diagnostic findings, but it must not continue by changing the implementation
strategy on its own.

## Worker Prompt Changes

`skills/subagent-driven-development/implementer-prompt.md` and
`skills/subagent-driven-development/impl-reviewer-prompt.md` must require
workers to report `BLOCKED` or `NEEDS_CONTEXT` instead of implementing
substitutes.

Workers must not:

- broaden or shrink assigned scope
- replace implementation with docs, comments, stubs, or placeholders
- skip required checks because they are inconvenient
- use a different implementation strategy that changes approved behavior
- switch review mode or take on roles not assigned by the coordinator

If completing the task requires any of those actions, the worker must stop and
report the exact issue.

## Reviewer And Fixer Prompt Changes

`skills/subagent-driven-development/reviewer-prompt.md` must make approved
path enforcement part of review. Reviewers must flag scope shrink, missing spec
coverage, fallback work, stubs, docs-only substitutes, skipped verification,
skipped review, and unapproved execution-mode switches as blocking issues.

`skills/subagent-driven-development/fixer-prompt.md` must require fixers to
apply only requested fixes inside the assigned scope. If a fix requires an
alternate path, broader rewrite, scope change, skipped verification, or changed
behavior, the fixer must stop and report `BLOCKED` or `NEEDS_CONTEXT`.

## Testing

Add static tests in `tests/simplepower-static/run-tests.sh` to verify that the
approved path enforcement contract appears in:

- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/impl-reviewer-prompt.md`
- `skills/subagent-driven-development/reviewer-prompt.md`
- `skills/subagent-driven-development/fixer-prompt.md`
- `skills/executing-plans/SKILL.md`

Static tests must also assert key phrases that make the rule hard to miss:

- `Approved Path Enforcement`
- `fresh explicit approval`
- `backup plan`
- `escape plan`
- `docs-only substitute`
- `stub substitute`
- `execution-mode switch`
- `BLOCKED`

## Acceptance Criteria

- Brainstorming specs do not authorize backup plans, escape plans, fallback
  implementations, or substitute work.
- Implementation plans directly cover approved spec requirements and reject
  substitution language during self-review.
- Plan review treats approved path enforcement violations as blocking issues.
- Subagent execution stops for fresh user approval before any alternate path.
- Inline execution follows the same stop-and-ask behavior.
- Worker prompts require blocked reporting instead of substitute
  implementation.
- Reviewer prompts flag scope shrink, skipped work, fallback work, and easier
  alternates.
- Fixer prompts stop when requested fixes require a changed path.
- Static tests pass.

## Error Handling

If the approved path is blocked, the agent must report:

1. The approved spec or plan requirement that cannot be followed.
2. The concrete reason it cannot be followed.
3. The files, commands, or observations that show the blocker.
4. The current implementation status.
5. The decision needed from the user.

The agent must not present alternate implementation work as already started
or completed. Alternate options may be described only as choices awaiting user
approval.
