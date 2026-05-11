# Aggregate Parallel Planning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for plan-first parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers according to the approved file ownership, run the quick verifier, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Make Simple Power plan and execution guidance default to aggregate parallel dispatch when the plan defines the shared interface contract up front.

**Design Summary:** The approved design changes Simple Power from dependency-shaped parallelism to interface-contract-shaped aggregate parallelism. Plans must define an explicit interface contract before task allocation, then implementation and test workers with non-overlapping write scopes may run together even when tests rely on APIs that implementation workers are creating. Serialization remains allowed only for concrete reasons: overlapping write scopes, missing or ambiguous contracts, generated artifacts that must exist first, or intentionally sequential runtime work. Static tests should lock the new planning vocabulary and prevent a return to routine wave or dependency staging.

**Architecture:** `skills/writing-plans/SKILL.md` becomes the source of truth for interface-first plan shape. `skills/subagent-driven-development/SKILL.md` becomes the source of truth for dispatch semantics: approved interface contracts satisfy cross-task coordination, and the coordinator dispatches the full aggregate-parallel set before quick verification. Static checks assert the new contract language and reject old active-flow staging language.

**Tech Stack:** Markdown skill instructions, Bash static checks, existing Simple Power test harness.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

The implementation must define and enforce these planning/execution terms:

- `Interface Contract`: a required plan section that lists public APIs, filenames, command contracts, fixtures, data shapes, behavior guarantees, and cross-task assumptions that workers can rely on before any other worker finishes.
- `Contract inputs`: the task-local references to entries in the Interface Contract. These replace routine `Depends on` scheduling for implementation and test tasks.
- `Serialization required`: a task-local field that defaults to `No`. `Yes` is valid only with a concrete reason such as overlapping write scopes, missing or ambiguous contract, generated artifact required before editing, or intentional sequential migration/runtime ordering.
- Aggregate parallel dispatch: after the reviewed plan is accepted, the coordinator dispatches all `sp-impl` tasks whose write scopes do not overlap and whose coordination needs are satisfied by the approved Interface Contract, including implementation and tests.
- Test-worker expectation: a test worker may write tests against the approved Interface Contract while implementation is still in progress. Its focused tests may fail before aggregate integration; the quick verifier owns integrated lint/build/test verification after all workers complete.
- Existing guardrails remain unchanged: no overlapping parallel write scopes, no worker self-expansion, no approved-path deviations, no skipped quick verifier, no skipped review+fix, no skipped final verification, no worker commits, and no per-task commits.

## Approved Path Enforcement

The accepted implementation plan is authoritative. Do not use backup routes,
scope reduction, docs-only substitutes, stub substitutes, placeholder
implementations, skipped verification, skipped review, or execution-route
changes unless the user gives fresh explicit approval at the moment the
deviation is needed.

If the approved aggregate-parallel path is blocked, the coordinator must stop,
report the exact mismatch and current status, and ask the user before changing
scope, implementation strategy, verification, review routing, or dispatch
semantics.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `docs/simplepower/plans/2026-05-08-aggregate-parallel-planning.md` | Coordinator plan | create | Authoritative implementation plan and reviewed allocation | Coordinator-owned before implementation; workers must not edit unless assigned by review+fix |
| `skills/writing-plans/SKILL.md` | Task 1 | modify | Add Interface Contract section requirement, replace routine dependency planning with Contract inputs and Serialization required defaults, update handoff language | No other task edits this file |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 1 | modify | Make plan reviewer enforce Interface Contract and aggregate parallel readiness | Same owner as writing-plan behavior to keep planning contract consistent |
| `skills/subagent-driven-development/SKILL.md` | Task 2 | modify | Update dispatch semantics from dependency-staged execution to aggregate-parallel dispatch from approved Interface Contract | No other task edits this file |
| `skills/subagent-driven-development/implementer-prompt.md` | Task 2 | modify | Tell workers to rely on Contract inputs and report contract mismatches instead of waiting for other workers | Same owner as SDD dispatch behavior to keep worker contract consistent |
| `tests/simplepower-static/run-tests.sh` | Task 3 | modify | Add static assertions for Interface Contract, Contract inputs, Serialization required defaults, aggregate parallel dispatch, and old staging rejection | Test-only file; can run in parallel with docs edits because write scope is isolated |

## Implementation Tasks

### Task 1: Update planning contract

**Goal:** Make `simplepower:writing-plans` generate interface-first aggregate-parallel plans.

**Contract inputs:** Use the approved Interface Contract in this plan. The exact terms to introduce are `Interface Contract`, `Contract inputs`, `Serialization required`, and aggregate parallel dispatch. The user approved replacing routine task dependency scheduling with plan-defined interfaces/contracts.

**Serialization required:** No. This task owns only planning-skill files.

**Write scope:** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`

**Parallel:** Yes, compatible with Task 2 and Task 3.

**Risk:** Medium. This changes the main plan-generation contract and reviewer criteria but stays in two Markdown files.

**Model tier:** BEST, using default `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"` when unset, resolved for dispatch as `model="gpt-5.5"` and `reasoning_effort="high"`, because this is behavior-shaping workflow text.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- In `skills/writing-plans/SKILL.md`, add `Interface Contract` as a required section before File Ownership.
- Change the implementation-task required fields from routine `Depends on` to `Contract inputs` and `Serialization required`.
- State that `Serialization required` defaults to `No` and must include a concrete reason when `Yes`.
- State that tests may be planned as parallel workers against approved Interface Contract entries even when implementation workers are creating those APIs.
- Update self-review and handoff language so aggregate parallel dispatch is expected, not exceptional.
- In `skills/writing-plans/plan-document-reviewer-prompt.md`, add review categories for Interface Contract and aggregate parallel readiness.
- Make the reviewer reject plans that use dependency staging where the contract is sufficient, omit contract inputs, or omit a concrete serialization reason.

**Implementation steps:**

1. Edit `skills/writing-plans/SKILL.md` header template to mention Interface Contract and aggregate parallel dispatch.
2. Insert a required `## Interface Contract` section before `## File Ownership`.
3. Update `## Implementation Tasks` required fields:
   - remove routine `Depends on`
   - add `Contract inputs`
   - add `Serialization required: No by default; Yes only with concrete reason`
   - preserve write scope, risk, model tier, worker role, verification, and report requirements
4. Update `## Plan Review`, `## Context-Size Handoff`, and `## Remember` wording to use aggregate parallel dispatch.
5. Edit `skills/writing-plans/plan-document-reviewer-prompt.md` to enforce the same contract.

**Verification commands for worker:**

- `timeout 30s rg -n "Interface Contract|Contract inputs|Serialization required|aggregate parallel" skills/writing-plans`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, confirmation that planning guidance no longer encourages routine dependency staging, unresolved risks if any.

### Task 2: Update execution dispatch semantics

**Goal:** Make `simplepower:subagent-driven-development` dispatch all contract-compatible workers together instead of staging tasks by uncommitted implementation dependencies.

**Contract inputs:** Use the approved Interface Contract in this plan. SDD must treat the accepted plan's Interface Contract as satisfying cross-task coordination for non-overlapping workers, including test workers that target plan-defined APIs.

**Serialization required:** No. This task owns only SDD skill files.

**Write scope:** `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/implementer-prompt.md`

**Parallel:** Yes, compatible with Task 1 and Task 3.

**Risk:** Medium. This changes workflow execution semantics but keeps approved-path and write-scope guardrails intact.

**Model tier:** BEST, using default `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"` when unset, resolved for dispatch as `model="gpt-5.5"` and `reasoning_effort="high"`, because this controls multi-agent dispatch behavior.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- In `skills/subagent-driven-development/SKILL.md`, update Overview, When to Use, Process, Dispatch Rules, Red Flags, and final completion language from plan-first parallel to aggregate parallel where appropriate.
- Replace the rule that blocks tasks depending on another uncommitted result with a rule that approved Interface Contract entries satisfy cross-task coordination.
- Keep serialization for overlapping writes, missing/ambiguous contracts, required generated artifacts, and intentional sequential work.
- In `skills/subagent-driven-development/implementer-prompt.md`, add Contract inputs to the worker prompt and tell workers to report contract mismatches or suspected implied-scope omissions instead of waiting for another worker's implementation.

**Implementation steps:**

1. Edit `skills/subagent-driven-development/SKILL.md` to define aggregate parallel dispatch.
2. Update dispatch validation so the coordinator reads the Interface Contract and Serialization required fields before dispatch.
3. Change dispatch rules to send all tasks with non-overlapping write scopes and `Serialization required: No` before waiting.
4. Preserve quick verifier, checkpoint commit, review+fix, lifecycle, model routing, context selection, and approved-path enforcement.
5. Edit `skills/subagent-driven-development/implementer-prompt.md` to include Contract inputs and contract mismatch reporting.

**Verification commands for worker:**

- `timeout 30s rg -n "Interface Contract|Contract inputs|Serialization required|aggregate parallel" skills/subagent-driven-development`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, confirmation that SDD still blocks overlapping writes and unresolved contract ambiguity, unresolved risks if any.

### Task 3: Lock the contract with static tests

**Goal:** Update the static harness so active Simple Power guidance must preserve the aggregate-parallel interface-contract workflow.

**Contract inputs:** The static harness should assert the terms from this plan's Interface Contract in active planning and SDD files.

**Serialization required:** No. This task owns only the static test runner.

**Write scope:** `tests/simplepower-static/run-tests.sh`

**Parallel:** Yes, compatible with Task 1 and Task 2. The test may initially fail until Tasks 1 and 2 finish; that is expected under aggregate parallel execution.

**Risk:** Low. The task updates string and regex assertions only.

**Model tier:** FAST, using default `SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"` when unset, resolved for dispatch as `model="gpt-5.4-mini"` and `reasoning_effort="high"`, because it is localized test-harness work.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- Add `require_contains` checks for `Interface Contract`, `Contract inputs`, `Serialization required`, and aggregate parallel dispatch in `skills/writing-plans/SKILL.md`.
- Add equivalent checks in `skills/subagent-driven-development/SKILL.md`.
- Add checks for plan reviewer and implementer prompt updates.
- Extend retired active-flow regex checks so active plan-first files reject routine dependency-staged dispatch wording. Do not overmatch neutral words from historical archives or unrelated writing-skills references.

**Implementation steps:**

1. Edit `tests/simplepower-static/run-tests.sh` near existing writing-plans assertions to add planning contract checks.
2. Edit the SDD assertion block to add execution contract checks.
3. Add targeted assertions for `skills/writing-plans/plan-document-reviewer-prompt.md` and `skills/subagent-driven-development/implementer-prompt.md`.
4. Update the old active-flow language regex only if needed to catch dependency-staged dispatch guidance without blocking valid serialization guardrails.

**Verification commands for worker:**

- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, note whether failures are expected because implementation tasks have not landed yet, unresolved risks if any.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Task 1 | `sp-impl` | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | Planning contract changes shape all future generated plans. |
| Task 2 | `sp-impl` | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | SDD dispatch rules control multi-agent execution safety. |
| Task 3 | `sp-impl` | FAST | `gpt-5.4-mini` from default `gpt-5.4-mini-high` | high | Static-test changes are narrow and localized. |
| Plan review | plan document reviewer | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | The reviewer must catch workflow contradictions before implementation. |
| Quick verification | quick verifier | fixed | `gpt-5.3-codex-spark` | high | Required quick verifier model for lint/build/tests before review. |
| Final review+fix | review+fix agent | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | The reviewer must inspect and fix the whole workflow diff. |

## Plan Review

Self-review checklist:

- Design Summary: captures interface-first aggregate parallelism, test-worker concurrency, guardrails, and success criteria.
- Interface Contract: defines shared terms and cross-task coordination assumptions before File Ownership.
- File ownership: every modified file is assigned to exactly one implementation task; no parallel write collisions exist.
- Task allocation: every requirement maps to an implementation task.
- Model allocation: Task 1 and Task 2 use BEST because they shape behavior; Task 3 uses FAST because it is localized; reviewer/verifier roles use required models.
- Review allocation: one BEST-tier review+fix agent runs after quick verification.
- Commit policy: exactly three coordinator checkpoints are present and no non-coordinator role commits.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize unapproved route changes, skipped checks, reduced deliverables, docs-only substitutes, or stub substitutes.

After this self-review, dispatch a BEST-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md`. Provide this saved plan path and the approved brainstorming design context. If the reviewer reports issues, fix the plan and rerun focused self-review checks before asking the user.

After the plan reviewer approves, ask the user to approve both this reviewed plan and the model/task allocation. The accepted plan checkpoint commit happens only after that approval.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the coordinator creates the quick-verified implementation checkpoint. It must use `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

Quick verification commands:

- `timeout 30s bash tests/simplepower-static/run-tests.sh`
- `timeout 60s bash tests/skill-triggering/run-all.sh`
- `timeout 60s bash tests/explicit-skill-requests/run-all.sh`

Expected result: all commands pass. If the quick verifier finds only tiny typo-level issues directly causing command failure, it may fix them and rerun the failed command. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one BEST-tier review+fix agent. That agent reviews and fixes the whole implementation against this accepted plan, file ownership, approved path enforcement, aggregate parallel dispatch semantics, and verification requirements.

The review+fix agent may edit files within this plan's approved file ownership when fixing issues it finds. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval. It must not commit.

## Commit Checkpoints

1. Accepted plan checkpoint: after the user approves the reviewed plan and model/task allocation.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. Do not include worker-owned commits or per-task commits.

## Context-Size Handoff

After the user approves the reviewed plan and model/task allocation and the coordinator creates the accepted plan checkpoint commit, compute the saved plan size:

```bash
PLAN_PATH="docs/simplepower/plans/2026-05-08-aggregate-parallel-planning.md"
wc -c "$PLAN_PATH"
```

Use bytes from the saved plan file. The comparison is strict greater-than `35840`. A byte count greater than `35840` selects the fresh-context recommendation; `35840` or less selects current-session execution.

Always show both implementation handoff commands, mark the size-based recommendation, put the recommended option first, and ask the user which implementation handoff to use.

For current-session handoff:

```text
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-08-aggregate-parallel-planning.md` with plan-first aggregate parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

For fresh-context handoff:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-08-aggregate-parallel-planning.md` with plan-first aggregate parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

## Verification

Final verification commands:

- `timeout 30s bash tests/simplepower-static/run-tests.sh`
  - Run after review+fix completes.
  - Expected result: all static Simple Power checks pass.
  - Failure means active workflow guidance or repository constraints are inconsistent.
- `timeout 60s bash tests/skill-triggering/run-all.sh`
  - Run after review+fix completes.
  - Expected result: all skill-triggering fixtures pass.
  - Failure means the active invocation contract changed unintentionally.
- `timeout 60s bash tests/explicit-skill-requests/run-all.sh`
  - Run after review+fix completes.
  - Expected result: all explicit skill request fixtures pass.
  - Failure means Simple Power explicit invocation behavior changed unintentionally.

The coordinator performs the final checkpoint only after the BEST-tier review+fix agent has completed and all final commands pass.
