---
name: subagent-driven-development
description: Use only when the user explicitly requests simplepower:subagent-driven-development or an authorized Simple Power chain invokes it.
---

# Subagent-Driven Development

## Overview

Execute an approved Simple Power plan through plan-first parallel
implementation with aggregate parallel dispatch. Read the plan, validate file
ownership, the Interface Contract, task Contract inputs, and
`Serialization required` fields, then dispatch the full set of
contract-compatible `sp-impl` file-edit workers before waiting. Execute any
explicitly serialized implementation tasks only when their approved concrete
reason is satisfied. After all implementation workers finish, run the quick
verifier using the approved FAST tier with lint/build/tests and timeouts. By
default that resolves to `model="gpt-5.3-codex-spark"` and
`reasoning_effort="high"`. Commit the quick-verified implementation, then
dispatch one BEST-tier review+fix agent before final verification and final
commit.

This workflow uses aggregate parallel dispatch: the accepted plan's Interface
Contract satisfies cross-task coordination for non-overlapping workers,
including test workers targeting plan-defined APIs. The coordinator owns
approved-scope validation, lifecycle decisions, checkpoint commits, final
verification, and final reporting while implementation workers edit only their
assigned files.

## Approved Path Enforcement

The approved plan is authoritative. Do not use a backup plan, escape plan,
fallback implementation, reduced scope, docs-only substitute, stub substitute,
skipped verification, skipped review, execution-mode switch, or alternate
implementation strategy unless the user gives fresh explicit approval at the
moment the deviation is needed.

Before dispatch, after worker results, before quick verification, before the
coordinator checkpoint commit, before the review+fix pass, before final
verification, and before the final commit, compare actual work against the
approved plan, File Ownership entries, and write scopes. If work is incomplete,
substituted, stubbed, docs-only, out of scope, missing required verification,
or based on a different execution mode, do not accept it as progress.

If the approved path is blocked, stop, report the exact mismatch and current
status, and ask the user before changing approach. Diagnostic investigation is
allowed; alternate implementation work is not.

## Implied Write-Scope Corrections

When a worker reports that a required file is outside its assigned write scope,
or the coordinator detects that a task step needs a file missing from the task
write scope, classify the mismatch before asking the user.

An `implied-scope omission` exists only when the missing file is already named
or structurally required by the approved spec, plan file-structure section,
task `Files:` block, task prose, task snippets, verification instructions, or
public declaration requirements. For an implied-scope omission, the coordinator
may update the plan's File Ownership entry for that task, update the task write
scope, record a short note describing the correction, and continue with the
same approved task.

A `true scope expansion` exists when the missing file or strategy is not
already implied by approved text. If the missing file or strategy is not
already implied, stop and ask the user for fresh explicit approval before
changing scope, strategy, verification, review approach, or implementation
work.

If the missing file or strategy is not already implied, treat it as a true
scope expansion.

Workers and review+fix agents must not self-expand write scope. They report
`BLOCKED` or `NEEDS_CONTEXT`; the coordinator owns classification and any plan
correction.

## When to Use

Use this workflow when:

- The Simple Power plan is approved and ready for execution.
- The plan defines an Interface Contract, file ownership, task Contract inputs,
  `Serialization required` fields, verification, and model allocation.
- Multiple implementation tasks can run concurrently without overlapping write
  scopes, with coordination satisfied by the accepted Interface Contract.
- Test workers may target plan-defined APIs before implementation workers have
  finished those APIs, because the approved Interface Contract is the shared
  contract for the aggregate worker set.
- The coordinator can dispatch subagents directly from the current session.

Do not use this workflow for unstable plans, broad design work, or work that
requires serialization because of overlapping writes, missing or ambiguous
contracts, generated artifacts that must exist first, or intentional sequential
runtime or migration ordering.

## The Process

1. Read the approved plan and model allocation.
2. Validate the Interface Contract, file ownership, task Contract inputs, and
   `Serialization required` fields.
3. Identify the aggregate worker set and any explicitly serialized tasks. The
   aggregate set is all `sp-impl` tasks whose approved write scopes do not
   overlap, whose Contract inputs are satisfied by the accepted Interface
   Contract, and whose `Serialization required` field is `No`.
4. Dispatch the full aggregate worker set before waiting.
5. Wait for the aggregate workers to finish.
6. Execute serialized `sp-impl` tasks only at the required point named by their
   concrete reason. If the point is unclear, stop for user direction before
   quick verification.
7. Run a lifecycle checkpoint and close finished workers by default.
8. Validate changed files against approved write scopes.
9. Dispatch the quick verifier using the approved FAST tier. By default,
   `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"` resolves to
   `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.
10. Let the quick verifier fix only tiny typo-level issues.
11. Stop for user direction if quick verification finds non-trivial failures.
12. Commit the quick-verified implementation before final review.
13. Dispatch one BEST-tier review+fix agent with the whole diff and approved
    plan.
14. Run final verification.
15. Commit final changes.
16. Report verification results, commit SHAs, changed files, aggregate
    dispatch decisions, any serialized tasks with reasons, and subagent
    lifecycle status.

## Dispatch Rules

1. Read the approved plan before dispatching any subagent.
2. Validate the plan's Interface Contract before dispatch. Confirm each task's
   Contract inputs reference accepted Interface Contract entries, approved
   design details, explicit external facts, or an approved serialized artifact
   condition.
3. Validate every task's `Serialization required` field before dispatch.
   `Serialization required: No` is the default aggregate-parallel path. If the
   value is `Yes`, the task must name a concrete reason and the point when it
   may run.
4. Dispatch all `sp-impl` tasks with `Serialization required: No`,
   non-overlapping approved write scopes, and Contract inputs satisfied by the
   accepted Interface Contract before waiting for any worker result.
5. Do not block a task merely because it relies on another worker's
   uncommitted implementation when the accepted Interface Contract defines the
   public API, filename, command contract, fixture, data shape, behavior
   guarantee, or cross-task assumption it needs.
6. Serialize only for concrete reasons: overlapping write scopes, missing or
   ambiguous contracts, generated artifacts that must exist before editing, or
   intentional sequential runtime or migration work. A serialized task may run
   after its approved condition is satisfied; do not require a commit between
   implementation tasks unless the accepted plan explicitly requires a
   committed checkpoint.
7. Paste the full task text, exact write scope, Contract inputs,
   `Serialization required` value and reason if any, model tier, and relevant
   context into each `sp-impl` prompt.
8. Do not require a worker to read the plan file to discover its own task.
9. Use `fork_context=false` by default for all Simple Power subagents.
10. Record any model escalation, context exception, serialization exception, or
    lifecycle exception with a written reason.
11. No worker commits or per-task commits. No per-task commits.

## Quick Verification

After all implementation workers finish and their changed files pass scope
validation, dispatch the quick verifier from `quick-verifier-prompt.md`.

The quick verifier uses the approved FAST tier by default. Unless
`SIMPLEPOWER_FAST_MODEL` is overridden, that resolves to
`model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

The quick verifier must run the linting checks, build or compile checks, and
tests named in the plan with proper timeouts. It may fix only tiny typo-level
issues that directly cause a command failure. If it finds non-trivial failures,
stop for user direction before further implementation, review, or commit work.

## Coordinator Checkpoint Commits

After quick verification passes, or after it fixes only tiny typo-level issues
and the relevant checks pass, create a coordinator checkpoint commit for the
quick-verified implementation before dispatching the review+fix agent.

Workers and verification agents must not commit. The coordinator owns the
checkpoint once accepted implementation changes and any tiny verification fixes
are ready.

Use commands like:

```bash
git status --short
git add $APPROVED_CHANGED_FILES
git commit -m "feat: checkpoint ${FEATURE_NAME} implementation"
git rev-parse --short HEAD
```

If there are no implementation file changes beyond already committed work, do
not create an empty commit. Record that no coordinator checkpoint commit was
needed before final review.

If the checkpoint commit fails, stop before final review. Inspect
`git status --short`, resolve the failure within the coordinator's approved
scope, rerun required verification if committed content changes, then retry the
checkpoint commit.

## Review+Fix

After the coordinator checkpoint commit, dispatch one BEST-tier review+fix
agent from `review-fix-prompt.md` with the whole diff, approved plan, task
requirements, file ownership, verification results, and any worker reports that
matter.

The review+fix agent reviews the actual diff, fixes in-scope correctness,
quality, and plan-compliance issues, runs focused verification when practical,
and reports any remaining issue that needs user approval. It must not reduce
scope, create docs-only substitutes, create stub substitutes, skip
verification, skip review, switch execution mode, or change the approved
implementation path.

Stop for user direction if the review+fix agent reports `BLOCKED` or if a
required fix needs fresh explicit approval.

## Final Verification And Final Commit

Run final verification after the review+fix pass is complete. Use the final
verification commands named in the approved plan and any repo-required checks
that apply to the changed files.

Inspect `git status --short` after final verification. Create a final commit
only if uncommitted changes remain. Do not create an empty final commit.

Rule: final commit only if uncommitted changes remain after final verification.

Use commands like:

```bash
git status --short
git add $FINAL_CHANGED_FILES
git commit -m "feat: finalize ${FEATURE_NAME}"
git rev-parse --short HEAD
```

Report the final verification results, coordinator checkpoint commit SHA, final
commit SHA when one was created, changed files, and confirmation that all
finished subagents were closed or have an active written reason to remain open.

## Subagent Lifecycle Checkpoint

Run a subagent lifecycle checkpoint after every subagent returns a final result,
including `sp-impl`, quick verifier, and review+fix results.

**Default lifecycle decision: close.**

At each checkpoint:

1. Read and consume the subagent's final report.
2. Decide whether the subagent is still needed.
3. Close the subagent by default.
4. If keeping it open, record a short written reason tied to the current plan
   execution.
5. Close the subagent as soon as that reason is resolved.

Do not close a subagent that is still running, blocked, or awaiting input. Do
not reach final completion while finished subagents remain open without an
active written reason.

## Model Selection

Use the plan's approved FAST, NORMAL, or BEST allocation unless the user
explicitly overrides it. These settings are an explicit Simple Power override
to generic same-model defaults from AGENTS.md or other ambient instructions.

Defaults:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"
```

If any variable is unset, use the default above. Resolve each env value by
taking the final dash-delimited segment as `reasoning_effort` and the
preceding string as `model`.

Tier routing:

- BEST: broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
  hard-to-test work; plan reviewer; final review+fix.
- NORMAL: routine low-risk implementation work that used the old FAST tier,
  especially localized edits where `gpt-5.4-mini-high` is appropriate.
- FAST: obvious repetitive work, mechanical edits across many files, large
  static text sweeps, simple fixture or assertion churn, and quick
  verification.

Role routing:

- `sp-impl`: use the plan's approved FAST, NORMAL, or BEST tier,
  `agent_type="worker"`, `fork_context=false`.
- Quick verifier: use the approved FAST tier, `agent_type="worker"`,
  `fork_context=false`.
- Review+fix agent: always use BEST, `agent_type="worker"`,
  `fork_context=false`.

If a planned FAST implementation task is less mechanical or obvious than the
plan predicted, escalate that task to NORMAL or BEST and record the reason
before dispatch. If a planned NORMAL task is broader, riskier, more ambiguous,
more behavior-shaping, or harder to verify than the plan predicted, escalate
that task to BEST and record the reason before dispatch.

## Context Selection

Default all Simple Power subagent dispatches to `fork_context=false`.
Subagents should receive the exact task text, write scope, relevant context,
verification instructions, and diff information in their prompt instead of
inheriting the parent conversation.

Use `fork_context=true` only when the subagent genuinely needs the live
conversation history and that context cannot be summarized safely in the
prompt. Record the reason when making that exception.

## Prompt Templates

- `./implementer-prompt.md` - Template for `sp-impl` file-edit workers
- `./quick-verifier-prompt.md` - Template for quick verification before the
  coordinator checkpoint commit
- `./review-fix-prompt.md` - Template for the one BEST-tier review+fix agent

## Red Flags

**Never:**

- Dispatch aggregate parallel implementation when write scopes overlap,
  Contract inputs are not satisfied by the accepted Interface Contract, or
  contract ambiguity is unresolved.
- Stage non-overlapping implementation or test tasks behind another worker's
  uncommitted result when the accepted Interface Contract already satisfies
  cross-task coordination.
- Ignore a concrete `Serialization required: Yes` reason for overlapping
  writes, missing or ambiguous contracts, required generated artifacts, or
  intentional sequential work.
- Skip explicitly serialized implementation tasks before quick verification.
- Trust worker status reports instead of inspecting the actual diff.
- Accept out-of-scope edits.
- Accept substituted, incomplete, stubbed, docs-only, or reduced-scope work as
  progress against the approved plan.
- Use a backup plan, escape plan, fallback implementation, execution-mode
  switch, or alternate implementation strategy without fresh explicit user
  approval.
- Continue implementation on an alternate path after a blocker before asking
  the user.
- Require worker commits or per-task commits.
- Let a worker, quick verifier, or review+fix agent update the approved plan
  unless that edit is explicitly assigned.
- Let a worker read the plan file instead of receiving the task text and
  context.
- Skip quick verification.
- Skip the coordinator checkpoint commit after quick verification unless there
  are no uncommitted implementation changes.
- Skip the one BEST-tier review+fix agent.
- Skip final verification.
- Skip the subagent lifecycle checkpoint after a final subagent result.
- Leave a finished subagent open without a written reason tied to the current
  plan execution.
- Move on while review+fix or verification issues are still open.
- Merge, push, or create a PR without a separate user request.
- Use stale upstream plugin skill prefixes in this scope.

**If a worker asks questions:**

- Answer clearly before letting the worker continue.
- Provide the missing task context or write-scope details.

**If a worker reports a blocker:**

- Treat it as real.
- Gather only the diagnostic context needed to explain the blocker.
- If the blocker is a missing write-scope file, classify it as an
  `implied-scope omission` or `true scope expansion` using the approved spec
  and plan.
- For an `implied-scope omission`, update the plan's File Ownership entry for
  that task, update the task write scope, record a written reason, and continue
  with the same approved task.
- For a `true scope expansion`, stop before alternate implementation work.
- Ask the user for fresh explicit approval before changing scope, plan,
  verification, implementation strategy, or any file not implied by approved
  text.

**If quick verification finds issues:**

- Allow only tiny typo-level fixes that directly cause a command failure.
- Stop for user direction when failures are non-trivial.
- Re-run the failed command after any tiny fix.

**If review+fix finds issues:**

- Fix only within approved write scopes.
- Stop if a fix needs fresh explicit approval, a true scope expansion, reduced
  scope, docs-only substitute, stub substitute, skipped verification, changed
  implementation strategy, or broader rewrite.
- Run focused verification for fixes when practical.
- Re-run final verification before final completion.

## Integration

**Required workflow skills:**

- **simplepower:writing-plans** - Creates the plan this skill executes.

**Subagents should use:**

- **simplepower:test-driven-development** - Follow TDD when it fits the task.

**Final completion:**

- Run the final verification commands from the plan and any repo-required
  checks.
- Inspect `git status --short` and summarize any remaining diff.
- Create a final commit only if uncommitted changes remain after final
  verification.
- Report the final verification results, aggregate dispatch decisions, any
  serialized tasks and reasons, coordinator checkpoint commit SHA, any final
  commit SHA, changed files, and confirmation that all finished subagents were
  closed or have an active written reason to remain open.
- Do not merge, push, or create a PR unless the user separately asks.

No worker commits or per-task commits. No per-task commits. Workers,
verification agents, and review+fix agents must not commit. Coordinator
checkpoint commits are required after quick-verified implementation. Create a
final commit only if uncommitted changes remain after final verification.
