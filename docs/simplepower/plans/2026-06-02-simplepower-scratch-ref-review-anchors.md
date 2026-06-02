# Simple Power Scratch Ref Review Anchors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Add temporary Git scratch refs to Simple Power review loops so reviewers can diff before and after coordinator-owned revisions without adding extra accepted commits.

**Design Summary:** The approved design adds local scratch refs under `refs/simplepower/scratch/<run-id>/...` for plan-review revisions, quick-verifier tiny fixes, and final review+fix edits. Scratch refs are review aids only: they are not checkpoint commits, are never pushed, and are deleted after the relevant successful coordinator checkpoint. If the workflow stops on a blocker, user direction, or failed checkpoint, the refs remain as evidence and the coordinator reports cleanup commands. The accepted history still has exactly three normal coordinator checkpoint commits.

**Architecture:** The workflow keeps the existing coordinator-owned commit model and adds a separate scratch-ref lifecycle. Scratch refs point to temporary commit objects created from the current worktree state for approved files, preferably through a temporary index so the real index and branch history are not changed. Review prompts receive exact `git diff <before-ref> <after-ref> -- <paths>` commands when a revision loop needs concrete comparison.

**Tech Stack:** Markdown skill instructions, Simple Power prompt templates, shell/Git commands, static Bash checks.

**Model Allocation:** FAST/NORMAL/BEST/REVIEW tiers are assigned below. Resolve each tier by explicit user override, quoted assignment in project root AGENTS.md, process environment variable, then built-in default. The project root AGENTS.md lookup reads only `<repo>/AGENTS.md`, not nested AGENTS.md files or repo-wide grep. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.3-codex-spark-high` when unset), NORMAL defaults to `SIMPLEPOWER_NORMAL_MODEL` (`gpt-5.4-mini-high` when unset), BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset), and REVIEW defaults to `SIMPLEPOWER_REVIEW_MODEL` (`gpt-5.5-xhigh` when unset). The current environment resolves FAST to `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`, NORMAL to `model="gpt-5.4-mini"` and `reasoning_effort="xhigh"`, BEST to `model="gpt-5.5"` and `reasoning_effort="xhigh"`, and REVIEW to `model="gpt-5.5"` and `reasoning_effort="xhigh"`. The plan reviewer is a REVIEW-tier plan reviewer, and the final review+fix agent is a REVIEW-tier review+fix agent. The quick verifier uses the FAST tier by default.

**Commit Policy:** The coordinator commits after the reviewed plan, allocation, and immediate current-session execution receive combined approval, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits. Coordinator-owned scratch refs are allowed only as temporary review diff anchors and do not count as checkpoint commits.

---

## Interface Contract

### Scratch Ref Namespace

- All temporary refs for one Simple Power run live under `refs/simplepower/scratch/<run-id>/`.
- The run id format is `YYYYMMDD-HHMMSS-<short-head>`, for example `20260602-143012-c4ad811`.
- Scratch refs are local review artifacts. They are not branches, are not accepted checkpoints, are not pushed, and are not merged or rebased.
- The coordinator records the run id in working notes and final reporting when scratch refs are created.

### Scratch Ref Names

- Plan review refs use `refs/simplepower/scratch/<run-id>/plan-review/before` and `refs/simplepower/scratch/<run-id>/plan-review/after-<n>`.
- Quick verifier refs use `refs/simplepower/scratch/<run-id>/quick-verifier/before` and `refs/simplepower/scratch/<run-id>/quick-verifier/after`.
- Review+fix refs use `refs/simplepower/scratch/<run-id>/review-fix/before` and `refs/simplepower/scratch/<run-id>/review-fix/after`.
- A phase may omit an `after` ref only when no file changes happened in that phase.

### Scratch Ref Creation Contract

- Scratch refs must capture the current worktree state for the approved file list without changing the real branch history.
- The preferred command pattern uses a temporary index:

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

- Implementations may wrap this pattern in documentation snippets, but they must preserve these guarantees: approved files only, real index unchanged, branch history unchanged, and failure stops the review loop before relying on the missing anchor.
- If `git update-ref` or scratch commit creation fails, the coordinator stops before sending the revised artifact back to a reviewer or before moving to the next phase.

### Scratch Diff Contract

- Every revised-plan review prompt after a blocking issue must include either an exact diff command or an explicit diff summary based on the relevant scratch refs.
- The preferred command format is:

```bash
git diff refs/simplepower/scratch/<run-id>/<phase>/<before-label> refs/simplepower/scratch/<run-id>/<phase>/<after-label> -- <approved-files>
```

- Quick-verifier tiny fixes and review+fix edits must be inspectable through the same command shape before the coordinator creates the next accepted checkpoint.

### Scratch Cleanup Contract

- After the accepted plan checkpoint succeeds, delete that run's `plan-review` scratch refs.
- After the quick-verified implementation checkpoint succeeds, delete that run's `quick-verifier` scratch refs.
- After the final checkpoint succeeds, delete that run's `review-fix` scratch refs.
- At final reporting, run a cleanup check for remaining refs under `refs/simplepower/scratch/<run-id>/`.
- If the workflow stops because of user direction, blocker, or failed checkpoint commit, keep the scratch refs and report this cleanup command instead of deleting evidence:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>" |
while read -r ref; do git update-ref -d "$ref"; done
```

### Prompt And Role Contract

- Workers, plan reviewers, quick verifiers, and review+fix agents still must not commit.
- Plan reviewers and review+fix agents still perform their assigned work directly and must not run Codex CLI, spawn subagents, invoke Simple Power skills, restart execution, or reroute the workflow.
- The quick verifier may fix only tiny typo-level issues. Any structural, behavioral, public-interface, test-rewrite, or unclear issue remains coordinator/user-directed.
- The final accepted workflow still has exactly three coordinator checkpoint commits.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `docs/simplepower/plans/2026-06-02-simplepower-scratch-ref-review-anchors.md` | Coordinator planning artifact | create | Authoritative implementation plan already created by `simplepower:writing-plans` | No `sp-impl` worker edits this file |
| `AGENTS.md` | Task 1 | modify | Allow coordinator-owned temporary scratch refs while preserving the three accepted checkpoint commits and no worker/per-task commits | Do not edit in parallel with other tasks |
| `skills/writing-plans/SKILL.md` | Task 1 | modify | Add scratch-ref review anchors to plan review, commit policy, current-session auto-dispatch, cleanup, and Remember guidance | Do not edit in parallel with other tasks |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 1 | modify | Require plan reviewer checks for scratch refs and concrete revised-plan diff anchors | Do not edit in parallel with other tasks |
| `skills/subagent-driven-development/SKILL.md` | Task 2 | modify | Add scratch refs for quick-verifier tiny fixes, review+fix edits, coordinator inspection, cleanup, and final reporting | Do not edit in parallel with other tasks |
| `skills/subagent-driven-development/quick-verifier-prompt.md` | Task 2 | modify | Ensure tiny-fix reports support coordinator scratch diff inspection | Do not edit in parallel with other tasks |
| `skills/subagent-driven-development/review-fix-prompt.md` | Task 2 | modify | Ensure review+fix reports support coordinator scratch diff inspection | Do not edit in parallel with other tasks |
| `skills/using-simplepower/references/codex-tools.md` | Task 2 | modify | Document scratch-ref diff anchors in Codex tool mapping and message framing | Do not edit in parallel with other tasks |
| `README.md` | Task 3 | modify | Document scratch refs in user-facing Simple Power flow, including Chinese and English summaries | Do not edit in parallel with other tasks |
| `docs/README.codex.md` | Task 3 | modify | Document scratch refs for Codex installation/use guidance | Do not edit in parallel with other tasks |
| `.codex-plugin/plugin.json` | Task 3 | modify | Keep plugin metadata consistent with scratch-ref review anchors | Do not edit in parallel with other tasks |
| `tests/simplepower-static/run-tests.sh` | Task 4 | modify | Add static checks for scratch-ref semantics, cleanup, no extra checkpoint commits, and no non-coordinator commits | Do not edit in parallel with other tasks |

## Visual Aids

```text
Plan review:
  draft plan
    -> scratch plan-review/before
    -> REVIEW reviewer finds issue
    -> coordinator edits plan
    -> scratch plan-review/after-1
    -> same reviewer receives diff command
    -> reviewer approval
    -> user combined approval
    -> accepted plan checkpoint
    -> delete plan-review scratch refs

Implementation review:
  workers finish
    -> scratch quick-verifier/before
    -> quick verifier runs checks
    -> optional scratch quick-verifier/after for tiny fixes
    -> quick-verified implementation checkpoint
    -> delete quick-verifier scratch refs
    -> scratch review-fix/before
    -> REVIEW review+fix
    -> optional scratch review-fix/after for edits
    -> final verification
    -> final checkpoint
    -> delete review-fix scratch refs
```

The written Interface Contract, File Ownership, Implementation Tasks, and Commit Policy are authoritative if this diagram and text ever appear to conflict.

## Implementation Tasks

### Task 1: Add Planning Scratch Ref Semantics

**Goal:** Update planning policy and plan-review prompts so revised plans have concrete scratch-ref diffs without adding permanent commits.

**Contract inputs:** Scratch Ref Namespace, Scratch Ref Names, Scratch Ref Creation Contract, Scratch Diff Contract, Scratch Cleanup Contract, Prompt And Role Contract, approved design sections 1, 3, and 4.

**Serialization required:** No.

**Write scope:**
- `AGENTS.md`
- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`

**Parallel:** Yes, compatible with Tasks 2, 3, and 4 because write scopes do not overlap and the Interface Contract defines all cross-task semantics.

**Risk:** High, because this changes the planning and review loop that controls future Simple Power implementations.

**Model tier:** BEST, resolved to `model="gpt-5.5"` and `reasoning_effort="xhigh"` from `SIMPLEPOWER_BEST_MODEL`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `AGENTS.md`: Add an explicit allowance for coordinator-owned temporary scratch refs under `refs/simplepower/scratch/<run-id>/...` as review diff anchors. Preserve the rule that accepted coordinator commits happen only at the three approved checkpoints and that workers/tasks do not commit.
- `skills/writing-plans/SKILL.md`: Add a `Scratch Ref Review Anchors` section or equivalent guidance covering namespace, run id, creation with temporary index or equivalent, plan-review before/after refs, diff command handoff, cleanup after accepted plan checkpoint, preservation on blocker/failure, and final cleanup check. Update the header `Commit Policy`, `Plan Review`, `Commit Checkpoints`, `Current-Session Auto-Dispatch`, `Verification`, and `Remember` sections so they do not contradict scratch refs.
- `skills/writing-plans/plan-document-reviewer-prompt.md`: Add a review category for scratch refs. Require revised-plan review inputs to include a concrete diff command or scratch-ref-based diff summary. Reject plans that treat scratch refs as accepted checkpoint commits, allow non-coordinator scratch refs, omit cleanup, or add extra accepted commits.

**Implementation steps:**
1. In `AGENTS.md`, extend the checkpoint paragraph with a short scratch-ref exception:
   - Coordinator-owned temporary scratch refs are allowed only as local review diff anchors.
   - Scratch refs are not commits in accepted history.
   - They must be deleted after successful checkpoints or reported for manual cleanup on blockers.
2. In `skills/writing-plans/SKILL.md`, add scratch-ref terminology near the overview and commit policy so future plans can include it without violating the three-checkpoint rule.
3. In `skills/writing-plans/SKILL.md`, update `Plan Review` so the coordinator creates `plan-review/before` before first review, creates `plan-review/after-<n>` after coordinator plan edits, and sends the same reviewer a concrete `git diff` command for revised-plan loops. If the same reviewer still finds issues, the next revision compares the last `after-<n>` ref to the new `after-<n+1>` ref.
4. In `skills/writing-plans/SKILL.md`, add cleanup instructions after accepted plan checkpoint and final reporting. Include a command shape using `git for-each-ref` and `git update-ref -d`.
5. In `skills/writing-plans/plan-document-reviewer-prompt.md`, add the scratch-ref review category, calibration language, rejection rules, and output expectations.
6. Keep all new text ASCII and consistent with existing Simple Power wording.

**Verification commands:**
- `timeout 30s rg -n "refs/simplepower/scratch|scratch refs|Scratch Ref|git update-ref|git diff" AGENTS.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** Report changed files, commands run, command results, and any ambiguity in scratch-ref semantics. Do not commit.

### Task 2: Add Execution Scratch Ref Semantics

**Goal:** Update implementation execution guidance and worker prompts so quick-verifier tiny fixes and review+fix edits have concrete scratch-ref diffs.

**Contract inputs:** Scratch Ref Namespace, Scratch Ref Names, Scratch Ref Creation Contract, Scratch Diff Contract, Scratch Cleanup Contract, Prompt And Role Contract, approved design sections 1, 2, 3, and 4.

**Serialization required:** No.

**Write scope:**
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/quick-verifier-prompt.md`
- `skills/subagent-driven-development/review-fix-prompt.md`
- `skills/using-simplepower/references/codex-tools.md`

**Parallel:** Yes, compatible with Tasks 1, 3, and 4 because write scopes do not overlap and the Interface Contract defines all cross-task semantics.

**Risk:** High, because this changes runtime workflow instructions around verification, review+fix, and checkpoint commits.

**Model tier:** BEST, resolved to `model="gpt-5.5"` and `reasoning_effort="xhigh"` from `SIMPLEPOWER_BEST_MODEL`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `skills/subagent-driven-development/SKILL.md`: Add scratch refs around quick verification and review+fix. Require coordinator inspection of tiny-fix/review-fix diffs before checkpoint/final verification. Preserve no worker commits, no per-task commits, and exactly three accepted checkpoints.
- `skills/subagent-driven-development/quick-verifier-prompt.md`: Require the quick verifier to report whether tiny fixes were made, exact changed files, commands rerun, and whether any issue is non-trivial. Preserve no-commit rule.
- `skills/subagent-driven-development/review-fix-prompt.md`: Require the review+fix agent to report exact changed files and focused verification so the coordinator can create and inspect `review-fix/after`. Preserve no-commit rule and non-recursion rules.
- `skills/using-simplepower/references/codex-tools.md`: Add a short note that scratch refs are coordinator-owned local refs used to provide diff commands to reviewers and are not subagent commits.

**Implementation steps:**
1. In `skills/subagent-driven-development/SKILL.md`, add scratch-ref lifecycle checks after changed-file validation, before quick verifier dispatch, after quick verifier tiny fixes, before review+fix dispatch, after review+fix edits, and final cleanup.
2. Update quick verification language so non-trivial failures still stop for user direction before further implementation, review, or commit work.
3. Update coordinator checkpoint language so quick-verifier scratch refs are deleted only after the quick-verified implementation checkpoint succeeds.
4. Update review+fix language so `review-fix/before` is created from the quick-verified checkpoint state and `review-fix/after` is created only when review+fix changes files.
5. Update final reporting to include scratch-ref cleanup status or cleanup commands when refs are preserved.
6. Update prompt templates without allowing the quick verifier or review+fix agent to create refs or commits themselves. The coordinator owns refs.

**Verification commands:**
- `timeout 30s rg -n "refs/simplepower/scratch|quick-verifier/before|quick-verifier/after|review-fix/before|review-fix/after|scratch ref|git diff" skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/quick-verifier-prompt.md skills/subagent-driven-development/review-fix-prompt.md skills/using-simplepower/references/codex-tools.md`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** Report changed files, commands run, command results, and any remaining execution ambiguity. Do not commit.

### Task 3: Update User-Facing Docs And Metadata

**Goal:** Keep public Simple Power docs and plugin metadata consistent with the scratch-ref workflow.

**Contract inputs:** Scratch Ref Namespace, Scratch Ref Names, Scratch Cleanup Contract, Prompt And Role Contract, approved design sections 1, 3, and 4.

**Serialization required:** No.

**Write scope:**
- `README.md`
- `docs/README.codex.md`
- `.codex-plugin/plugin.json`

**Parallel:** Yes, compatible with Tasks 1, 2, and 4 because write scopes do not overlap and the Interface Contract defines all cross-task semantics.

**Risk:** Medium, because user-facing docs must stay accurate but do not directly execute the workflow.

**Model tier:** NORMAL, resolved to `model="gpt-5.4-mini"` and `reasoning_effort="xhigh"` from `SIMPLEPOWER_NORMAL_MODEL`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `README.md`: Add a concise Chinese and English explanation that Simple Power uses temporary local scratch refs to help reviewers diff revised plans and review/fix changes. Preserve current four-tier model docs and current-session auto-dispatch text.
- `docs/README.codex.md`: Add the same concept for Codex users, focused on local Git refs and unchanged accepted checkpoint history.
- `.codex-plugin/plugin.json`: Update long description to mention scratch-ref diff anchors if it can fit naturally without bloating metadata.

**Implementation steps:**
1. Add brief scratch-ref wording near the implementation flow descriptions in both Chinese and English README sections.
2. Add brief scratch-ref wording in `docs/README.codex.md` near the planning/implementation flow.
3. Update `.codex-plugin/plugin.json` long description so the advertised workflow includes scratch diff anchors and still mentions quick verification, REVIEW-tier review+fix, and final verification.
4. Avoid adding install or model override guidance not already present.

**Verification commands:**
- `timeout 30s rg -n "scratch ref|scratch refs|refs/simplepower/scratch|diff anchors" README.md docs/README.codex.md .codex-plugin/plugin.json`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** Report changed files, commands run, command results, and any user-facing wording concerns. Do not commit.

### Task 4: Add Static Regression Checks

**Goal:** Add static checks that enforce scratch-ref documentation, cleanup, and unchanged accepted checkpoint semantics.

**Contract inputs:** Scratch Ref Namespace, Scratch Ref Names, Scratch Diff Contract, Scratch Cleanup Contract, Prompt And Role Contract, approved design section 4.

**Serialization required:** No.

**Write scope:**
- `tests/simplepower-static/run-tests.sh`

**Parallel:** Yes, compatible with Tasks 1, 2, and 3 because the test file can be updated against the approved Interface Contract before implementation workers finish.

**Risk:** Medium, because static tests need to be specific enough to catch regressions without becoming brittle about harmless phrasing.

**Model tier:** NORMAL, resolved to `model="gpt-5.4-mini"` and `reasoning_effort="xhigh"` from `SIMPLEPOWER_NORMAL_MODEL`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `tests/simplepower-static/run-tests.sh`: Add `require_contains` checks for `refs/simplepower/scratch`, scratch refs being review aids rather than checkpoint commits, `git update-ref`, `git diff`, cleanup with `git update-ref -d`, plan-review before/after refs, quick-verifier before/after refs, review-fix before/after refs, and preservation of no worker/per-task commits and exactly three accepted coordinator checkpoint commits.

**Implementation steps:**
1. Add tests near existing writing-plans and plan-reviewer checks for scratch refs and revised-plan diff commands.
2. Add tests near SDD checks for quick-verifier and review+fix scratch anchors.
3. Add tests near README/Codex/plugin metadata checks for user-facing scratch-ref documentation.
4. Add tests for cleanup wording and failure/blocker preservation.
5. Keep checks as substring assertions unless a regex is clearly needed.

**Verification commands:**
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** Report changed files, commands run, command results, and any brittle-test risk. Do not commit.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Implementation Task 1 | `sp-impl` | BEST | `gpt-5.5` | `xhigh` | Planning/review policy is behavior-shaping and high-risk |
| Implementation Task 2 | `sp-impl` | BEST | `gpt-5.5` | `xhigh` | Runtime workflow and review+fix semantics are behavior-shaping and high-risk |
| Implementation Task 3 | `sp-impl` | NORMAL | `gpt-5.4-mini` | `xhigh` | User-facing docs are routine localized updates against a clear contract |
| Implementation Task 4 | `sp-impl` | NORMAL | `gpt-5.4-mini` | `xhigh` | Static test additions are localized but require precise assertions |
| Plan review | Plan document reviewer | REVIEW | `gpt-5.5` | `xhigh` | REVIEW is reserved for the plan reviewer |
| Quick verification | Quick verifier | FAST | `gpt-5.3-codex-spark` | `high` | FAST is the approved default quick-verification tier |
| Final review+fix | Review+fix agent | REVIEW | `gpt-5.5` | `xhigh` | REVIEW is reserved for the final review+fix agent |

## Plan Review

After writing this plan, self-review it against:
- Design Summary: The plan captures temporary scratch refs, no extra accepted commits, cleanup, preservation on blockers, and exact success criteria.
- Interface Contract: Scratch ref namespace, names, creation, diff, cleanup, and prompt/role behavior are concrete.
- File Ownership: Every implementation file is assigned exactly once, and parallel tasks do not collide.
- Task allocation: Every task has `Contract inputs` and `Serialization required`.
- Aggregate parallel readiness: All implementation tasks have non-overlapping write scopes and can run together from the Interface Contract.
- Visual aids: The diagram supports the written contract and does not override it.
- Model allocation: FAST/NORMAL/BEST/REVIEW choices match current environment resolution and risk.
- Review allocation: One REVIEW-tier review+fix agent is present after quick verification.
- Commit policy: Exactly three accepted coordinator checkpoints remain, and scratch refs are not accepted commits.
- Verification: Quick and final commands are concrete and use `timeout`.
- Approved path enforcement: No backup route, reduced deliverable, skipped verification, skipped review, or execution-mode switch is authorized.

Then dispatch a REVIEW-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md`, with this plan path and the approved brainstorming context. Keep the same reviewer open through recoverable issue loops. If the reviewer reports issues, fix this plan, rerun focused self-review for changed categories, and send the revised plan back to the same reviewer. Close the reviewer only after approval, unrecoverable interruption, or explicit user direction.

## Quick Verification

After implementation workers complete and changed files pass scope validation, dispatch the quick verifier using the FAST tier. The quick verifier runs:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 30s rg -n "refs/simplepower/scratch|scratch refs|Scratch Ref|git update-ref|git diff|git update-ref -d" AGENTS.md README.md docs/README.codex.md .codex-plugin/plugin.json skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/quick-verifier-prompt.md skills/subagent-driven-development/review-fix-prompt.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
```

This is a docs, prompt, metadata, and static-test workflow change. There is no native source build for these files, so quick verification uses the static test runner as the repository-specific lint/test signal and the focused `rg` command as the nearest build-contract check for required workflow text.

Expected result: the static test runner passes, and the focused search shows scratch-ref coverage across policy, docs, prompts, tool mapping, and static tests.

The quick verifier may fix only tiny typo-level issues that directly cause command failure. Any behavior change, structural edit, public-interface change, test rewrite, or unclear issue must be reported to the coordinator instead of fixed.

## Review+Fix

After the quick-verified implementation checkpoint, dispatch one REVIEW-tier review+fix agent. The review+fix agent reviews the complete implementation diff against this plan, the Scratch Ref Interface Contract, File Ownership, approved path enforcement, static tests, and verification results. It may fix in-scope correctness, quality, and plan-compliance issues within approved file ownership. It must not commit, reduce scope, create docs-only substitutes, create stub substitutes, skip verification, skip review, switch execution mode, spawn subagents, invoke Simple Power skills, run Codex CLI, restart execution, or reroute the workflow.

## Commit Checkpoints

This plan defines exactly three accepted coordinator checkpoint commits:

1. Accepted plan checkpoint: after the user gives combined approval for this reviewed plan, model/task allocation, and immediate current-session execution, and before invoking `simplepower:subagent-driven-development`.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete, quick verification passes, and quick-verifier scratch refs have been inspected as applicable.
3. Final checkpoint: after the REVIEW-tier review+fix agent completes, final verification passes, and review-fix scratch refs have been inspected as applicable.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. Do not include worker-owned commits or per-task commits. Scratch refs under `refs/simplepower/scratch/<run-id>/...` are temporary coordinator-owned review aids and do not count as checkpoint commits.

## Current-Session Auto-Dispatch

After the plan reviewer approves, ask the user for one combined approval covering:
- The reviewed plan.
- The model/task allocation.
- Immediate current-session execution.

If the user requests changes, update this plan, rerun focused self-review checks for the changed categories, and send the revised plan back to the same reviewer when review approval must be refreshed. Do not create the accepted plan checkpoint until the user gives combined approval.

After combined approval, the coordinator creates the accepted plan checkpoint commit, then immediately invokes `simplepower:subagent-driven-development` in the current session with this instruction:

```text
Execute `docs/simplepower/plans/2026-06-02-simplepower-scratch-ref-review-anchors.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST/REVIEW model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick FAST-tier verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent, final verification, and final commit.
```

## Verification

Final verification commands:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s rg -n "refs/simplepower/scratch|scratch refs|Scratch Ref|git update-ref|git diff|git update-ref -d" AGENTS.md README.md docs/README.codex.md .codex-plugin/plugin.json skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/quick-verifier-prompt.md skills/subagent-driven-development/review-fix-prompt.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
```

Expected result:
- Static checks pass and enforce scratch-ref semantics.
- Brainstorm server tests still pass, proving unrelated active checks were not broken.
- Codex plugin sync smoke test passes, proving metadata remains packageable.
- Focused `rg` output confirms scratch-ref guidance appears in all approved workflow surfaces.

The coordinator performs the final checkpoint only after the REVIEW-tier review+fix agent has completed and all final commands pass.
