# Current Session Auto-Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Streamline Simple Power planning so approved model/task allocation immediately starts current-session implementation and plan review reuses the same reviewer until the plan is approved.

**Design Summary:** The approved design removes normal `/clear`, context-window measurement, context-size fallback, and post-plan implementation handoff choices from active Simple Power workflow text and tests. After plan review passes, `simplepower:writing-plans` asks one combined approval for the reviewed plan, model/task allocation, and immediate current-session execution; on approval, the coordinator creates the accepted plan checkpoint commit and immediately invokes `simplepower:subagent-driven-development`. When the plan reviewer finds issues, the coordinator keeps the original reviewer subagent open, fixes the plan, reruns focused self-review locally, and sends the revised plan back to the same reviewer until approval.

**Architecture:** Keep `simplepower:writing-plans` as the planning and handoff owner, and keep `simplepower:subagent-driven-development` as the implementation owner. The Interface Contract below defines the exact new workflow language and stale-flow removals so docs, prompts, and tests can be updated in parallel without waiting on another worker's edits.

**Tech Stack:** Markdown skill files, Markdown docs, Bash static assertions.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

### Workflow Terms

- **Current-session-only execution:** Normal Simple Power planning no longer measures context usage, no longer reads a context measurement helper, no longer computes a plan-size fallback, and no longer offers `/clear` or fresh-context execution. Implementation always proceeds in the current session after combined approval.
- **Combined approval:** After the plan reviewer approves, `simplepower:writing-plans` asks the user to approve the reviewed plan, model/task allocation, and immediate current-session execution in one approval step.
- **Auto-dispatch after approval:** If the user gives combined approval, the coordinator creates the accepted plan checkpoint commit and immediately invokes `simplepower:subagent-driven-development` to execute the accepted plan with the approved model allocation.
- **Reusable plan reviewer loop:** The initial BEST-tier plan reviewer stays open when it reports issues. The coordinator fixes the plan, reruns focused self-review checks for changed categories, and sends the revised plan back to the same reviewer. The reviewer is closed only after approval, an unrecoverable interruption, or explicit user direction.
- **Removed stale flow:** Active docs, prompts, and static assertions must not preserve normal-workflow references to `/clear`, `Context-Size Handoff`, context usage thresholds, `55%`, saved plan-size fallback, `35840`, `wc -c "$PLAN_PATH"`, `skills/writing-plans/current-session-context.md`, "show both commands", "handoff choice", or asking which implementation handoff to use.

### Required Replacement Wording

- `skills/writing-plans/SKILL.md` must replace `Context-Size Handoff` with a current-session auto-dispatch section.
- The plan header template must keep exactly three coordinator checkpoints, with checkpoint 1 occurring after combined approval and before immediate current-session implementation starts.
- The plan review instructions must say to keep the original reviewer open for issue/fix/re-review loops.
- The plan reviewer prompt must check current-session auto-dispatch instead of context handoff.
- `README.md` and `docs/README.codex.md` must describe the simplified flow: save and review plan, ask combined approval, commit accepted plan checkpoint, immediately start `simplepower:subagent-driven-development` in the same session.
- `tests/simplepower-static/run-tests.sh` must assert the new current-session-only flow and reject stale context-handoff terms.
- `skills/writing-plans/current-session-context.md` must be deleted because the normal workflow no longer needs it.

### Verification Command Contract

- Static suite: `timeout 120s bash tests/simplepower-static/run-tests.sh`
- Focused stale-flow no-match search:

```bash
bash -lc 'timeout 30s rg -n "/clear|Context-Size Handoff|current-session-context|context usage|55%|35840|wc -c|saved plan size|show both|both commands|handoff choice|which implementation handoff|Run after /clear|Continue in current session" README.md docs/README.codex.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md; status=$?; test "$status" -eq 1'
```

Expected focused-search result: `rg` exits `1` because there are no stale normal-workflow matches, and the wrapper exits `0`. The broad no-match search intentionally does not scan `tests/simplepower-static/run-tests.sh`, because static tests may contain stale terms as assertion inputs. If legitimate historical docs outside the searched paths still mention old behavior, they are out of scope for this plan.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---:|---|---|
| `tests/simplepower-static/run-tests.sh` | Task 1 | modify | Replace stale assertions with current-session auto-dispatch assertions and stale-flow rejection checks. | Independent Bash test file. |
| `skills/writing-plans/SKILL.md` | Task 2 | modify | Update planning workflow, review loop, combined approval, auto-dispatch, commit checkpoint wording, and remember list. | Independent skill file. |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 3 | modify | Update reviewer categories and rejection calibration for current-session auto-dispatch. | Independent prompt file. |
| `skills/writing-plans/current-session-context.md` | Task 3 | delete | Remove obsolete context measurement helper. | Same owner as reviewer prompt because both remove reviewer-enforced context handoff. |
| `README.md` | Task 4 | modify | Update bilingual public workflow docs. | Independent doc file. |
| `docs/README.codex.md` | Task 5 | modify | Update Codex install guide workflow docs and current-session start instructions. | Independent doc file. |

## Implementation Tasks

### Task 1: Static Assertions For Current-Session Auto-Dispatch

**Goal:** Make the static suite enforce the new workflow and reject stale context-handoff behavior.

**Contract inputs:** Workflow Terms, Required Replacement Wording, Verification Command Contract.

**Serialization required:** No.

**Write scope:** `tests/simplepower-static/run-tests.sh`

**Parallel:** Yes, compatible with Tasks 2, 3, 4, and 5.

**Risk:** Medium, because static assertions define the executable policy checks for the rest of the change.

**Model tier:** FAST, resolved as `model="gpt-5.4-mini"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`

**Outputs and responsibilities:**
- Replace README and Codex guide assertions for `/clear`, `55%`, saved plan size, and both-command handoff with assertions for combined approval, accepted plan checkpoint, immediate current-session execution, and `simplepower:subagent-driven-development`.
- Replace `skills/writing-plans/current-session-context.md` existence assertions with absence assertions.
- Replace `skills/writing-plans/SKILL.md` context-handoff assertions with assertions for current-session auto-dispatch, reusable reviewer loop, combined approval, and immediate invocation.
- Replace plan reviewer prompt context-handoff assertions with current-session auto-dispatch assertions.
- Add `require_not_contains` checks for stale terms in active files where practical.
- Do not use broad no-match `rg` scans over `tests/simplepower-static/run-tests.sh` itself; stale strings may appear there as assertion data.

**Implementation steps:**
1. In `tests/simplepower-static/run-tests.sh`, update README assertions around the current implementation flow block.
2. Update `docs/README.codex.md` assertions around starting implementation.
3. Remove helper-file assertions for `skills/writing-plans/current-session-context.md` and add `require_file_absent "skills/writing-plans/current-session-context.md"`.
4. Update writing-plans assertions to require `Current-Session Auto-Dispatch`, `combined approval`, `immediate current-session execution`, `same reviewer`, and `simplepower:subagent-driven-development`.
5. Update reviewer prompt assertions to require `Current-Session Auto-Dispatch` and reject `/clear`/context fallback language in the target workflow files, not by scanning the static test file itself.

**Verification commands:**
- `timeout 120s bash tests/simplepower-static/run-tests.sh`
- `timeout 30s rg -n "current-session auto-dispatch|combined approval|same reviewer|immediate current-session" tests/simplepower-static/run-tests.sh`

**Completion report requirements:** Changed assertions, commands run, results, and any stale term that remains intentionally or unexpectedly.

### Task 2: Writing-Plans Workflow Policy

**Goal:** Update `simplepower:writing-plans` so it no longer offers a context handoff and instead asks combined approval before immediate current-session execution.

**Contract inputs:** Workflow Terms, Required Replacement Wording, Verification Command Contract.

**Serialization required:** No.

**Write scope:** `skills/writing-plans/SKILL.md`

**Parallel:** Yes, compatible with Tasks 1, 3, 4, and 5.

**Risk:** High, because this file controls the planning-to-implementation workflow.

**Model tier:** BEST, resolved as `model="gpt-5.5"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`

**Outputs and responsibilities:**
- Remove context-size handoff guidance from the overview and body.
- Replace the `Context-Size Handoff` section with `Current-Session Auto-Dispatch`.
- Change plan review behavior so reviewer issue loops reuse the original reviewer subagent.
- Change post-review approval behavior to combined approval for reviewed plan, model/task allocation, and immediate current-session execution.
- Require the coordinator to commit the accepted plan checkpoint after combined approval, then immediately invoke `simplepower:subagent-driven-development`.
- Update the plan header template, commit checkpoint wording, no-placeholder checks, and remember list to remove stale handoff language.

**Implementation steps:**
1. Update the overview list to replace `context-size handoff guidance` with `current-session auto-dispatch guidance`.
2. Update the plan header `Commit Policy` so checkpoint 1 is after combined approval.
3. In `Plan Review`, replace one-shot reviewer wording with the reusable reviewer loop and explicit close timing.
4. Replace separate model/allocation approval and implementation handoff choice wording with one combined approval step.
5. Replace the full `Context-Size Handoff` section with current-session auto-dispatch instructions and the exact command intent for invoking `simplepower:subagent-driven-development`.
6. Update `Commit Checkpoints`, `No Placeholders`, and `Remember` so they no longer mention context pct, `wc -c`, `/clear`, or handoff choices.

**Verification commands:**
- `timeout 30s rg -n "Current-Session Auto-Dispatch|combined approval|same reviewer|immediate current-session|simplepower:subagent-driven-development" skills/writing-plans/SKILL.md`
- `bash -lc 'timeout 30s rg -n "/clear|Context-Size Handoff|current-session-context|55%|35840|wc -c|handoff choice|which implementation handoff|Run after /clear|Continue in current session" skills/writing-plans/SKILL.md; status=$?; test "$status" -eq 1'`

**Completion report requirements:** Changed sections, commands run, results, and any unresolved workflow ambiguity.

### Task 3: Plan Reviewer Prompt And Obsolete Helper Removal

**Goal:** Update plan review expectations to validate current-session auto-dispatch and remove the obsolete context measurement helper.

**Contract inputs:** Workflow Terms, Required Replacement Wording, Verification Command Contract.

**Serialization required:** No.

**Write scope:** `skills/writing-plans/plan-document-reviewer-prompt.md`, `skills/writing-plans/current-session-context.md`

**Parallel:** Yes, compatible with Tasks 1, 2, 4, and 5.

**Risk:** High, because reviewer prompt behavior gates plan readiness.

**Model tier:** BEST, resolved as `model="gpt-5.5"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`

**Outputs and responsibilities:**
- Replace the `Context Handoff` review category with `Current-Session Auto-Dispatch`.
- Require the reviewer to confirm combined approval, accepted-plan checkpoint timing, and immediate current-session execution through `simplepower:subagent-driven-development`.
- Reject plans that include normal-workflow `/clear`, context measurement, plan-size fallback, or post-plan handoff-choice behavior.
- Add reviewer-loop awareness: when reviewing a revised plan in the same subagent, compare against previous blocking issues and report whether they are resolved.
- Delete `skills/writing-plans/current-session-context.md`.

**Implementation steps:**
1. Edit the category table in `plan-document-reviewer-prompt.md`.
2. Edit calibration/rejection paragraphs to remove stale context-handoff failures and add current-session auto-dispatch failures.
3. Add concise re-review behavior to the prompt without changing the output format.
4. Delete `skills/writing-plans/current-session-context.md`.

**Verification commands:**
- `timeout 30s rg -n "Current-Session Auto-Dispatch|combined approval|immediate current-session|same reviewer|revised plan" skills/writing-plans/plan-document-reviewer-prompt.md`
- `timeout 30s test ! -e skills/writing-plans/current-session-context.md`
- `bash -lc 'timeout 30s rg -n "/clear|current-session context pct|current-session-context|55%|35840|wc -c|handoff commands|implementation handoff" skills/writing-plans/plan-document-reviewer-prompt.md; status=$?; test "$status" -eq 1'`

**Completion report requirements:** Prompt categories changed, helper deletion status, commands run, results, and any reviewer-loop wording risk.

### Task 4: Public README Workflow Docs

**Goal:** Update the bilingual README implementation flow so users see the simplified current-session-only workflow.

**Contract inputs:** Workflow Terms, Required Replacement Wording.

**Serialization required:** No.

**Write scope:** `README.md`

**Parallel:** Yes, compatible with Tasks 1, 2, 3, and 5.

**Risk:** Low, because this is user-facing documentation only.

**Model tier:** FAST, resolved as `model="gpt-5.4-mini"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`

**Outputs and responsibilities:**
- Update the Chinese implementation flow section.
- Update the English implementation flow section.
- Remove references to choosing an implementation handoff, context usage, `55%`, saved plan size, both commands, fresh context, and `/clear`.
- Add concise language that after plan review, Simple Power asks for combined approval and then immediately starts current-session `simplepower:subagent-driven-development`.

**Implementation steps:**
1. Replace lines in the Chinese `## 实现流程` section describing context handoff.
2. Replace lines in the English `## Implementation Flow` section describing context handoff.
3. Keep existing marketplace, model allocation, visual companion, and fork attribution text intact.

**Verification commands:**
- `timeout 30s rg -n "combined approval|current session|subagent-driven-development|合并批准|当前 session" README.md`
- `bash -lc 'timeout 30s rg -n "/clear|55%|saved plan size|context usage|both commands|implementation handoff to use" README.md; status=$?; test "$status" -eq 1'`

**Completion report requirements:** Sections updated, commands run, results, and any translation concern.

### Task 5: Codex Install Guide Workflow Docs

**Goal:** Update the Codex install guide so it documents immediate current-session implementation instead of `/clear` handoff choices.

**Contract inputs:** Workflow Terms, Required Replacement Wording.

**Serialization required:** No.

**Write scope:** `docs/README.codex.md`

**Parallel:** Yes, compatible with Tasks 1, 2, 3, and 4.

**Risk:** Low, because this is user-facing documentation only.

**Model tier:** FAST, resolved as `model="gpt-5.4-mini"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`

**Outputs and responsibilities:**
- Update `Implementation Flow` to describe combined approval and immediate current-session execution.
- Replace `Starting Implementation` content with current-session-only instructions.
- Remove `/clear`, context usage, `55%`, saved plan size, both commands, and asking which handoff to use.
- Preserve setup, model allocation, and namespace guidance.

**Implementation steps:**
1. Rewrite the implementation-flow paragraph around the post-plan approval behavior.
2. Rewrite the `Starting Implementation` section with the single current-session path.
3. Keep the `simplepower:subagent-driven-development` command intent aligned with `skills/writing-plans/SKILL.md`.

**Verification commands:**
- `timeout 30s rg -n "combined approval|current-session|same session|subagent-driven-development" docs/README.codex.md`
- `bash -lc 'timeout 30s rg -n "/clear|55%|saved plan size|context usage|both commands|implementation handoff to use" docs/README.codex.md; status=$?; test "$status" -eq 1'`

**Completion report requirements:** Sections updated, commands run, results, and any doc wording mismatch.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---:|---|---|---|
| Task 1 implementation | `sp-impl` | FAST | `gpt-5.4-mini` | high | Focused Bash assertion changes. |
| Task 2 implementation | `sp-impl` | BEST | `gpt-5.5` | high | Behavior-shaping planning workflow policy. |
| Task 3 implementation | `sp-impl` | BEST | `gpt-5.5` | high | Reviewer prompt gates plan readiness and deletes obsolete helper. |
| Task 4 implementation | `sp-impl` | FAST | `gpt-5.4-mini` | high | Focused README wording update. |
| Task 5 implementation | `sp-impl` | FAST | `gpt-5.4-mini` | high | Focused Codex guide wording update. |
| Plan reviewer | reviewer | BEST | `gpt-5.5` | high | Required by `simplepower:writing-plans`; reviews plan completeness before approval. |
| Quick verifier | verifier | fixed | `gpt-5.3-codex-spark` | high | Required quick verification role after implementation workers finish. |
| Final review+fix | review+fix | BEST | `gpt-5.5` | high | Whole-diff review and fixes before final verification. |

## Plan Review

Self-review checklist:
- Design Summary captures the approved brainstorming decision: current-session-only execution, combined approval plus immediate implementation, and same-reviewer plan review loops.
- Interface Contract defines the removed stale flow, required replacement wording, and verification commands before File Ownership.
- File Ownership assigns every modified or deleted file to exactly one task.
- Task allocation maps each requirement to a task, with `Contract inputs` and `Serialization required` defined for every task.
- Aggregate parallel readiness is present: all implementation tasks have non-overlapping write scopes and may run together.
- Model allocation uses FAST for focused docs/tests and BEST for behavior-shaping skill and reviewer prompt changes.
- Review allocation includes one BEST-tier final review+fix agent after quick verification.
- Commit policy defines exactly three coordinator checkpoints and forbids worker commits.
- Verification commands use `timeout`.
- Approved path enforcement does not authorize fallback execution, skipped checks, docs-only substitutes, or placeholder implementations.

Plan reviewer dispatch:
- Dispatch one BEST-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md`.
- Provide this saved plan path and the approved brainstorming design context.
- If the reviewer reports issues, keep the same reviewer subagent open, fix this plan, rerun focused self-review checks for changed categories, and send the updated plan back to the same reviewer.
- Close the reviewer only after it approves the plan, after an unrecoverable interruption, or after explicit user direction.

After the plan reviewer approves, ask the user for combined approval of the reviewed plan, model/task allocation, and immediate current-session execution.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the coordinator creates the quick-verified implementation checkpoint. It checks that the implementation is coherent enough for final review.

The quick verifier must use `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

Commands:

```bash
timeout 120s bash tests/simplepower-static/run-tests.sh
bash -lc 'timeout 30s rg -n "/clear|Context-Size Handoff|current-session-context|context usage|55%|35840|wc -c|saved plan size|show both|both commands|handoff choice|which implementation handoff|Run after /clear|Continue in current session" README.md docs/README.codex.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md; status=$?; test "$status" -eq 1'
```

Expected result: the static suite passes, and the focused stale-flow no-match wrapper exits `0`.

The quick verifier may fix only tiny typo-level errors discovered while running the quick checks. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one BEST-tier review+fix agent. That agent reviews and fixes the whole implementation against the accepted plan, file ownership, approved path enforcement, aggregate parallel dispatch semantics, and verification requirements.

The review+fix agent may edit files within the plan's approved file ownership when fixing issues it finds. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval. It must not commit.

## Commit Checkpoints

Every plan must define exactly three future coordinator commit checkpoints:

1. Accepted plan checkpoint: after the user approves the reviewed plan, model/task allocation, and immediate current-session execution.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. Do not include worker-owned commits or per-task commits.

## Current-Session Auto-Dispatch

The normal workflow executes in the current session. Do not measure the context window, do not compute a saved-plan-size fallback, do not offer `/clear`, and do not ask the user which implementation handoff to use.

After the plan reviewer approves, ask the user one combined approval question covering:

- the reviewed plan;
- the model/task allocation;
- immediate current-session execution through `simplepower:subagent-driven-development`.

If the user approves, the coordinator creates the accepted plan checkpoint commit, then immediately invokes:

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

## Verification

Final verification commands:

```bash
timeout 120s bash tests/simplepower-static/run-tests.sh
bash -lc 'timeout 30s rg -n "/clear|Context-Size Handoff|current-session-context|context usage|55%|35840|wc -c|saved plan size|show both|both commands|handoff choice|which implementation handoff|Run after /clear|Continue in current session" README.md docs/README.codex.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md; status=$?; test "$status" -eq 1'
git status --short
```

Expected results:
- Static suite passes.
- Focused stale-flow no-match wrapper exits `0`.
- `git status --short` shows only expected plan and implementation files before checkpoint commits.

The coordinator performs the final checkpoint only after the BEST-tier review+fix agent has completed and the final commands pass.

## No Placeholders

Every step must contain the actual content an engineer needs. These are plan failures:
- `TBD`, `TODO`, `implement later`, or `fill in details`
- Vague instructions such as `add validation` without exact behavior
- Tests requested without the concrete command or test location
- References to functions, files, or commands not defined elsewhere in the plan
- Worker commit instructions, per-task commit instructions, or task-local `git commit` commands
- Text that pre-authorizes scope reduction, skipped checks, placeholder implementations, docs-only substitutes, or execution-route changes
- Retaining normal-workflow `/clear`, context measurement, plan-size fallback, or handoff-choice behavior in active workflow files

## Task Progress

- [ ] Task 1: Static Assertions For Current-Session Auto-Dispatch
- [ ] Task 2: Writing-Plans Workflow Policy
- [ ] Task 3: Plan Reviewer Prompt And Obsolete Helper Removal
- [ ] Task 4: Public README Workflow Docs
- [ ] Task 5: Codex Install Guide Workflow Docs
- [ ] Quick verification
- [ ] Quick-verified implementation checkpoint
- [ ] Final review+fix
- [ ] Final verification
- [ ] Final checkpoint
