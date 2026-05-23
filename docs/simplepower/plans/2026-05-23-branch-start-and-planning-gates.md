# Branch Start And Planning Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Update Simple Power so brainstorming and systematic debugging start on in-place branches by default, planning handoffs require explicit user approval, and the finished change is pushed and propagated to the local Codex config.

**Design Summary:** The approved design adds an in-place branch setup step to `simplepower:brainstorming` and `simplepower:systematic-debugging`, using `feature/<slug>` for brainstorming and `debug/<slug>` for debugging. It also adds two explicit user gates: brainstorming asks before invoking `simplepower:writing-plans`, and writing-plans asks before dispatching its REVIEW-tier plan document reviewer. Existing combined approval before implementation remains. The post-final coordinator flow commits and pushes this Simple Power repo branch, runs the existing Codex plugin sync script when tooling allows it, then updates `/home/gary/.codex/simplepower` to the pushed commit and commits/pushes the `/home/gary/.codex` submodule pointer.

**Architecture:** This is a workflow-contract change implemented in skill Markdown, docs, prompt fixtures, and static tests. The Interface Contract below gives workers exact future behavior for branch setup, planning gates, and release/update operations so non-overlapping edits can proceed in aggregate parallel.

**Tech Stack:** Markdown skill files, Bash static test harness, Git, GitHub CLI for optional plugin sync, Codex config git submodule update.

**Model Allocation:** FAST/NORMAL/BEST/REVIEW tiers are assigned below. Resolve each tier by explicit user override, quoted assignment in project root AGENTS.md, process environment variable, then built-in default. The project root AGENTS.md lookup reads only `<repo>/AGENTS.md`, not nested AGENTS.md files or repo-wide grep. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.3-codex-spark-high` when unset), NORMAL defaults to `SIMPLEPOWER_NORMAL_MODEL` (`gpt-5.4-mini-high` when unset), BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset), and REVIEW defaults to `SIMPLEPOWER_REVIEW_MODEL` (`gpt-5.5-xhigh` when unset). The plan reviewer is a REVIEW-tier plan reviewer, and the final review+fix agent is a REVIEW-tier review+fix agent. The quick verifier uses the FAST tier by default, resolving to `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"` unless `SIMPLEPOWER_FAST_MODEL` is overridden.

**Commit Policy:** The coordinator commits after the reviewed plan, allocation, and immediate current-session execution receive combined approval, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

### IC-1: In-Place Branch Start

- `In-place branch` means creating or switching to a normal branch in the current checkout with `git checkout -b`, not creating a Git worktree.
- `simplepower:brainstorming` defaults to a branch named `feature/<slug>`.
- `simplepower:systematic-debugging` defaults to a branch named `debug/<slug>`.
- `<slug>` is derived from the user's request or the agent's short task summary, lowercased, dash-separated, and kept short. Avoid sensitive names in branch slugs.
- If the current branch already starts with the required prefix, the skill reports the existing branch and continues without creating a new one.
- If the current branch does not start with the required prefix, the skill creates a new in-place branch before substantive skill work: before context exploration for brainstorming, and before Phase 1 investigation for systematic debugging.
- If the working tree has uncommitted changes, branch creation is still allowed because the changes move with the working tree; the skill must report that existing changes were carried onto the new branch.
- If the chosen branch name already exists, the skill should use a short unique suffix such as `-2` and report the final branch name.
- If git branching is unavailable, blocked, or unsafe, the skill must ask the user whether to continue in the current checkout before doing substantive skill work.
- The default branch start must not invoke `simplepower:using-git-worktrees`. Worktrees remain available only when explicitly requested or when another approved flow calls that skill.

### IC-2: Brainstorming Planning Handoff Gate

- Brainstorming still requires conversational design approval before planning.
- After the user approves the design, `simplepower:brainstorming` asks before invoking `simplepower:writing-plans`.
- The skill must not invoke `simplepower:writing-plans` until the user explicitly approves that planning handoff.
- If the user declines or pauses, brainstorming stops with the approved design summary and current status instead of invoking another skill.

### IC-3: Writing-Plans Reviewer Dispatch Gate

- `simplepower:writing-plans` still writes and self-reviews the saved Markdown plan first.
- After self-review and before dispatching the REVIEW-tier plan document reviewer, writing-plans asks the user whether to start the plan reviewer.
- The skill must not dispatch the REVIEW-tier plan document reviewer until the user explicitly approves that reviewer dispatch.
- If the user declines or pauses, writing-plans reports the saved plan path, self-review status, and that reviewer dispatch is pending.
- The existing combined approval gate after reviewer approval remains unchanged: the user approves the reviewed plan, model/task allocation, and immediate current-session execution before the accepted-plan checkpoint commit and `simplepower:subagent-driven-development` dispatch.

### IC-4: User-Requested Release And Local Codex Update

- This user explicitly requested commit and push of the Simple Power repo after implementation, then updating `/home/gary/.codex` to point at the new Simple Power commit, then committing and pushing `/home/gary/.codex`.
- This approved plan therefore includes coordinator push/update operations after final verification and final commit. It does not create a general default that Simple Power pushes without an explicit user request.
- The existing plugin sync script is `scripts/sync-to-codex-plugin.sh`. It syncs tracked Simple Power plugin content into `garyfpga/codex-plugins`, pushes a sync branch, and opens a PR when `gh`, `rsync`, `git`, and authentication are available.
- After pushing this repo branch, the coordinator should run `./scripts/sync-to-codex-plugin.sh -y` from the Simple Power repo. If the script reports no changes, record that. If tooling or authentication blocks it, report the exact blocker instead of inventing a substitute.
- `/home/gary/.codex/simplepower` is a git submodule currently pointing at the Simple Power repo. Updating `/home/gary/.codex` means fetching the pushed Simple Power commit in that submodule, checking out the final Simple Power commit, committing the changed submodule pointer in `/home/gary/.codex`, and pushing `/home/gary/.codex` to `origin master`.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---|---|---|
| `docs/simplepower/plans/2026-05-23-branch-start-and-planning-gates.md` | Coordinator plan | create | Authoritative implementation plan and reviewed allocation | Coordinator-owned before implementation; workers must not edit unless assigned by review+fix |
| `skills/brainstorming/SKILL.md` | Task 1 | modify | Add default in-place `feature/<slug>` branch start and planning handoff gate | No other task edits this file |
| `skills/systematic-debugging/SKILL.md` | Task 1 | modify | Add default in-place `debug/<slug>` branch start before Phase 1 | No other task edits this file |
| `skills/using-git-worktrees/SKILL.md` | Task 1 | modify | Remove conflicting implication that brainstorming defaults to worktrees | No other task edits this file |
| `skills/writing-plans/SKILL.md` | Task 2 | modify | Add user gate before REVIEW-tier plan reviewer dispatch and preserve combined approval | No other task edits this file |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 2 | modify | Make plan review check the reviewer dispatch gate and preserved implementation gate | No other task edits this file |
| `README.md` | Task 3 | modify | Document branch defaults, planning gates, and release/update path in user-facing docs | No other task edits this file |
| `docs/README.codex.md` | Task 3 | modify | Document branch defaults, planning gates, and Codex local update expectations | No other task edits this file |
| `.codex/INSTALL.md` | Task 3 | modify | Mention update command and local skill rescan expectations consistent with new flow | No other task edits this file |
| `docs/testing.md` | Task 3 | modify | Document smoke-test expectations for branch defaults and planning gates | No other task edits this file |
| `.codex-plugin/plugin.json` | Task 3 | modify | Update plugin metadata if needed to mention explicit branch/planning workflow behavior | No other task edits this file |
| `tests/simplepower-static/run-tests.sh` | Task 4 | modify | Add static assertions for branch defaults, planning gates, docs, and fixture wording | No other task edits this file |
| `tests/skill-triggering/prompts/approved-brainstorming-handoff.txt` | Task 4 | modify | Update fixture to represent explicit user approval of the planning handoff | No other task edits this file |
| `tests/skill-triggering/prompts/approved-planning-handoff.txt` | Task 4 | modify | Update fixture only if needed to preserve combined approval wording after reviewer gate changes | No other task edits this file |

## Implementation Tasks

### Task 1: Add branch-start behavior to process skills

**Goal:** Make brainstorming and systematic debugging start on in-place branches by default and clarify that worktrees are not the default branch mechanism.

**Contract inputs:** IC-1 and IC-2.

**Serialization required:** No.

**Write scope:** `skills/brainstorming/SKILL.md`, `skills/systematic-debugging/SKILL.md`, `skills/using-git-worktrees/SKILL.md`.

**Parallel:** Yes, compatible with Tasks 2, 3, and 4.

**Risk:** High, because this changes the first step of two process skills and must not weaken the brainstorming design gate or systematic debugging root-cause discipline.

**Model tier:** BEST, resolved to `model="gpt-5.5"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- In `skills/brainstorming/SKILL.md`, add a start-branch checklist item before context exploration and a section specifying `feature/<slug>` in-place branch behavior.
- In `skills/brainstorming/SKILL.md`, add the planning handoff gate so the skill asks before invoking `simplepower:writing-plans` after design approval.
- In `skills/brainstorming/SKILL.md`, update the process flow text and graph so branch start happens before context exploration.
- In `skills/systematic-debugging/SKILL.md`, add a start-branch section before Phase 1 that uses `debug/<slug>` and states this setup is allowed before root-cause investigation because it does not implement a fix.
- In `skills/using-git-worktrees/SKILL.md`, update the Integration section so it no longer says brainstorming defaults to or requires worktrees.

**Implementation steps:**
1. Edit `skills/brainstorming/SKILL.md` near the checklist to add `Start in-place feature branch` before `Explore project context`.
2. Add a `## Start In-Place Feature Branch` section that uses IC-1 wording and states that this branch step is setup, not implementation.
3. Update the brainstorming DOT graph to include branch start before context exploration and to route design approval to the IC-2 planning handoff gate before `simplepower:writing-plans`.
4. Edit `skills/systematic-debugging/SKILL.md` after the Iron Law or before Phase 1 to add `## Start In-Place Debug Branch`, using IC-1 with the `debug/` prefix.
5. Ensure systematic debugging still says no fixes before root-cause investigation and that branch creation is not a fix.
6. Edit `skills/using-git-worktrees/SKILL.md` Integration to say brainstorming and systematic debugging use in-place branches by default; this skill is used only when explicitly requested or by another approved workflow.

**Verification commands:**
- `timeout 30s rg -n "Start In-Place Feature Branch|feature/<slug>|git checkout -b|Planning Handoff Gate|before invoking .+writing-plans|must not invoke .+writing-plans|Start In-Place Debug Branch|debug/<slug>|not invoke simplepower:using-git-worktrees|worktrees are not the default" skills/brainstorming/SKILL.md skills/systematic-debugging/SKILL.md skills/using-git-worktrees/SKILL.md`

**Completion report requirements:** changed files, commands run and results, confirmation that branch creation is before substantive skill work, confirmation that brainstorming asks before invoking writing-plans, confirmation that existing design/root-cause gates remain, unresolved risks.

### Task 2: Add planning and reviewer dispatch gates

**Goal:** Require explicit user approval before brainstorming invokes writing-plans and before writing-plans dispatches the REVIEW-tier plan document reviewer.

**Contract inputs:** IC-3 and the existing combined approval behavior described in IC-3.

**Serialization required:** No.

**Write scope:** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.

**Parallel:** Yes, compatible with Tasks 1, 3, and 4.

**Risk:** High, because this changes the planning lifecycle and plan reviewer contract while preserving the existing combined approval before implementation.

**Model tier:** BEST, resolved to `model="gpt-5.5"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- In `skills/writing-plans/SKILL.md`, add a reviewer dispatch gate after self-review and before reviewer dispatch.
- In `skills/writing-plans/SKILL.md`, update overview/current-session guidance so combined approval before implementation remains unchanged.
- In `skills/writing-plans/plan-document-reviewer-prompt.md`, add review checks for the reviewer dispatch gate and preserved combined approval.

**Implementation steps:**
1. Edit the writing-plans overview to mention explicit reviewer-dispatch approval before the REVIEW-tier plan reviewer.
2. In `## Plan Review`, after the self-review checklist and before "Then dispatch", replace immediate reviewer dispatch with "ask the user before dispatching".
3. State that if the user does not approve reviewer dispatch, the coordinator reports the saved plan path and pending reviewer status and stops.
4. Keep the existing same-reviewer loop after dispatch and keep the current combined approval after reviewer approval.
5. Update `## Current-Session Auto-Dispatch` and `## Remember` with the reviewer dispatch gate while preserving accepted-plan checkpoint behavior.
6. Edit `skills/writing-plans/plan-document-reviewer-prompt.md` so reviewers check that generated plans preserve the reviewer dispatch gate, combined approval, accepted-plan checkpoint timing, and immediate SDD execution only after combined approval.

**Verification commands:**
- `timeout 30s rg -n "reviewer dispatch|before dispatching the REVIEW-tier plan reviewer|Do not dispatch|combined approval|accepted-plan checkpoint|same reviewer" skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md`

**Completion report requirements:** changed files, commands run and results, confirmation that there is a gate before plan reviewer dispatch, confirmation that combined approval before implementation remains intact, unresolved risks.

### Task 3: Update user-facing docs and plugin metadata

**Goal:** Document the new default branch behavior, planning gates, and requested repo/plugin/local Codex update path.

**Contract inputs:** IC-1, IC-2, IC-3, and IC-4.

**Serialization required:** No.

**Write scope:** `README.md`, `docs/README.codex.md`, `.codex/INSTALL.md`, `docs/testing.md`, `.codex-plugin/plugin.json`.

**Parallel:** Yes, compatible with Tasks 1, 2, and 4.

**Risk:** Medium, because docs must match active workflow contracts and avoid implying automatic pushes without explicit user request.

**Model tier:** NORMAL, resolved to `model="gpt-5.4-mini"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `README.md` documents in both main language sections where appropriate that brainstorming starts `feature/<slug>`, systematic debugging starts `debug/<slug>`, brainstorming asks before writing-plans, and writing-plans asks before the REVIEW-tier plan reviewer.
- `docs/README.codex.md` documents the same behavior for Codex users.
- `.codex/INSTALL.md` keeps marketplace update instructions and mentions restart/rescan expectations.
- `docs/testing.md` updates manual smoke-test expectations.
- `.codex-plugin/plugin.json` long description is updated only if the current metadata would otherwise become misleading.

**Implementation steps:**
1. Edit `README.md` Implementation Flow sections to document branch defaults and planning gates while preserving existing model tier and combined approval language.
2. Edit `docs/README.codex.md` Implementation Flow and Starting Implementation sections to document branch defaults and reviewer dispatch approval.
3. Edit `.codex/INSTALL.md` only if needed to mention update/rescan expectations after marketplace upgrades.
4. Edit `docs/testing.md` manual smoke-test expectations to include branch creation and planning gates.
5. Edit `.codex-plugin/plugin.json` longDescription only if needed to mention explicit branch/planning workflow behavior without overpromising automatic pushes.

**Verification commands:**
- `timeout 30s rg -n "feature/<slug>|debug/<slug>|before invoking .*writing-plans|before dispatching the REVIEW-tier plan reviewer|codex plugin marketplace upgrade|simplepower:subagent-driven-development" README.md docs/README.codex.md .codex/INSTALL.md docs/testing.md .codex-plugin/plugin.json`

**Completion report requirements:** changed files, commands run and results, confirmation that docs do not imply automatic pushing without explicit user request, unresolved risks.

### Task 4: Add static coverage and update fixtures

**Goal:** Lock the new branch-start and planning-gate contracts into the static test harness and prompt fixtures.

**Contract inputs:** IC-1, IC-2, IC-3, and IC-4.

**Serialization required:** No.

**Write scope:** `tests/simplepower-static/run-tests.sh`, `tests/skill-triggering/prompts/approved-brainstorming-handoff.txt`, `tests/skill-triggering/prompts/approved-planning-handoff.txt`.

**Parallel:** Yes, compatible with Tasks 1, 2, and 3 because the Interface Contract defines the expected strings before the implementation files are edited.

**Risk:** Medium, because brittle string assertions can make future workflow edits painful if they are too specific.

**Model tier:** NORMAL, resolved to `model="gpt-5.4-mini"`, `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- Add `require_contains` checks for branch defaults in `skills/brainstorming/SKILL.md` and `skills/systematic-debugging/SKILL.md`.
- Add checks that branching failures require user approval before continuing.
- Add checks for the brainstorming planning handoff gate and writing-plans reviewer dispatch gate.
- Add checks that combined approval before SDD remains.
- Update prompt fixtures so the approved brainstorming handoff represents explicit user approval to invoke `simplepower:writing-plans`.

**Implementation steps:**
1. Add static assertions near existing brainstorming checks in `tests/simplepower-static/run-tests.sh`.
2. Add static assertions near existing writing-plans checks for the reviewer dispatch gate and preserved combined approval.
3. Add static assertions near docs checks for `README.md`, `docs/README.codex.md`, and `docs/testing.md`.
4. Update `tests/skill-triggering/prompts/approved-brainstorming-handoff.txt` from direct design approval to explicit planning-handoff approval.
5. Update `tests/skill-triggering/prompts/approved-planning-handoff.txt` only if needed to keep wording consistent with the preserved combined approval gate.
6. Keep assertions phrase-based and stable; do not check whole paragraphs.

**Verification commands:**
- `timeout 30s bash tests/simplepower-static/run-tests.sh`
- `timeout 30s bash tests/skill-triggering/run-test.sh approved-brainstorming-handoff tests/skill-triggering/prompts/approved-brainstorming-handoff.txt`
- `timeout 30s bash tests/skill-triggering/run-test.sh approved-planning-handoff tests/skill-triggering/prompts/approved-planning-handoff.txt`

**Completion report requirements:** changed files, commands run and results, confirmation that static coverage checks both branch defaults and planning gates, unresolved risks.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---|---|---|---|
| Task 1 | `sp-impl` | BEST | `gpt-5.5` | high | Behavior-shaping edits to two process skills and worktree integration language |
| Task 2 | `sp-impl` | BEST | `gpt-5.5` | high | Planning lifecycle and reviewer dispatch semantics are central workflow behavior |
| Task 3 | `sp-impl` | NORMAL | `gpt-5.4-mini` | high | User-facing docs and metadata updates are localized and lower risk |
| Task 4 | `sp-impl` | NORMAL | `gpt-5.4-mini` | high | Static checks and fixtures require care but are localized |
| Plan review | Plan reviewer | REVIEW | `gpt-5.5` | xhigh | Must validate authoritative workflow plan, gates, model allocation, and release/update operations |
| Quick verification | Quick verifier | FAST | `gpt-5.3-codex-spark` | high | Runs static checks and focused tests after implementation workers finish |
| Final review+fix | Review+fix agent | REVIEW | `gpt-5.5` | xhigh | Reviews whole diff against accepted workflow contract before final verification |

## Plan Review

After writing this plan, self-review it before asking to dispatch a reviewer.

Self-review checklist:
- Design Summary: compactly captures the approved brainstorming design, constraints, success criteria, and key decisions.
- Interface Contract: lists concrete workflow contracts for branch start, planning gates, reviewer dispatch, and release/update operations before File Ownership.
- File ownership: every implied file is assigned to exactly one task, and parallel tasks do not collide.
- Task allocation: every requirement maps to an implementation task, every task has `Contract inputs`, and any `Serialization required: Yes` has a concrete reason.
- Aggregate parallel readiness: non-overlapping workers whose coordination needs are satisfied by the Interface Contract are planned for aggregate parallel dispatch instead of prerequisite-ordered staging.
- Visual aids: absent, which is acceptable because this workflow change is text-contract driven.
- Model allocation: FAST/NORMAL/BEST/REVIEW choices match risk and mechanics, all four configurable defaults are documented, model resolution precedence is explicit, the project root AGENTS.md lookup is limited to `<repo>/AGENTS.md`, the plan reviewer and final review+fix agent use REVIEW, and the quick verifier uses the FAST tier by default.
- Review allocation: the plan has one REVIEW-tier review+fix agent after quick verification.
- Commit policy: exactly three coordinator checkpoints are present and no non-coordinator role commits.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize unapproved route changes, skipped checks, or reduced deliverables.
- User-requested push/update operations: post-final operations are clearly scoped to this user's explicit request and do not change Simple Power's default push behavior.

After this self-review, ask the user before dispatching a REVIEW-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md`. Provide the saved plan path and the approved brainstorming design context. Do not dispatch the plan reviewer until the user approves starting that reviewer.

If the reviewer reports issues, fix the plan, rerun the focused self-review checks for the changed categories, and send the revised plan back to the same reviewer. Close the reviewer only after approval, an unrecoverable interruption, or explicit user direction.

The REVIEW-tier plan reviewer must perform the assigned review directly in the current worker. Do not run Codex CLI. Do not spawn subagents. Do not invoke Simple Power skills. Do not restart execution. Do not reroute the workflow.

After the plan reviewer approves, ask the user for combined approval of the reviewed plan, model/task allocation, and immediate current-session execution. The accepted plan checkpoint commit happens only after that combined approval. Workers and reviewers must not create this commit.

After the user gives combined approval, the coordinator creates the accepted plan checkpoint commit and immediately invokes `simplepower:subagent-driven-development` to execute the accepted plan with the approved model allocation in the current session.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the coordinator creates the quick-verified implementation checkpoint. It checks that the implementation is coherent enough for final review.

The quick verifier must use the FAST tier by default. With the default `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`, this resolves to `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

Quick verification commands:
- `timeout 30s bash tests/simplepower-static/run-tests.sh`
- `timeout 120s npm --prefix tests/brainstorm-server test`

The quick verifier may fix only tiny typo-level errors discovered while running the quick checks. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one REVIEW-tier review+fix agent. That agent reviews and fixes the whole implementation against the accepted plan, file ownership, approved path enforcement, aggregate parallel dispatch semantics, planning gates, branch-start semantics, and verification requirements.

The review+fix agent may edit files within the plan's approved file ownership when fixing issues it finds. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval. It must not commit.

The REVIEW-tier review+fix agent must perform the assigned review and fixes directly in the current worker. Do not run Codex CLI. Do not spawn subagents. Do not invoke Simple Power skills. Do not restart execution. Do not reroute the workflow.

## Commit Checkpoints

Every plan must define exactly three future coordinator commit checkpoints:

1. Accepted plan checkpoint: after the user gives combined approval for the reviewed plan, model/task allocation, and immediate current-session execution, and before invoking `simplepower:subagent-driven-development`.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete and the quick verifier passes.
3. Final checkpoint: after the REVIEW-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. Do not include worker-owned commits or per-task commits.

The user also explicitly requested post-final pushes and local Codex config update. Those operations happen after the third checkpoint, not as worker-owned commits.

## Current-Session Auto-Dispatch

The saved plan is the execution artifact. Do not write a project-local implementation JSON artifact.

Normal Simple Power planning proceeds in the current session. Do not run routing heuristics or offer alternate execution routes.

Before dispatching the plan reviewer, ask the user to approve starting the REVIEW-tier plan document reviewer. Do not dispatch that reviewer until the user approves.

After the plan reviewer approves, ask the user for one combined approval that covers:
- The reviewed plan
- The model/task allocation
- Immediate current-session execution

If the user requests changes, update the plan, rerun the focused self-review checks for the changed categories, and send the revised plan back to the same reviewer when review approval must be refreshed. Do not create the accepted plan checkpoint until the user gives combined approval.

After combined approval, the coordinator creates the accepted plan checkpoint commit, then immediately invokes `simplepower:subagent-driven-development` in the current session with this instruction:

```text
Execute `docs/simplepower/plans/2026-05-23-branch-start-and-planning-gates.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST/REVIEW model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick FAST-tier verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent, final verification, and final commit.
```

## Verification

Final verification commands:
- `timeout 30s bash tests/simplepower-static/run-tests.sh`
  - Run after review+fix completes.
  - Expected result: all static workflow checks pass.
  - Failure means the active skill/docs/test contracts are inconsistent.
- `timeout 120s npm --prefix tests/brainstorm-server test`
  - Run after review+fix completes.
  - Expected result: brainstorm server tests pass.
  - Failure means the visual companion or brainstorm server behavior regressed.
- `timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh`
  - Run after review+fix completes.
  - Expected result: plugin sync smoke tests pass.
  - Failure means the existing sync script path is not verified enough to use for post-final sync.

The coordinator performs the final checkpoint only after the REVIEW-tier review+fix agent has completed and the final commands pass.

## Post-Final Push, Plugin Sync, And Local Codex Update

These operations are approved by the user's direct request for this task. They are not a general default for future Simple Power work.

After the final checkpoint commit:

1. Push this Simple Power repo branch:

   ```bash
   git push -u origin feature/simplepower-branch-planning-gates
   ```

2. Run the existing plugin sync script:

   ```bash
   ./scripts/sync-to-codex-plugin.sh -y
   ```

   Expected result: the script either reports no changes or opens a PR against `garyfpga/codex-plugins`. If `gh`, `rsync`, network, or authentication blocks the script, report the exact blocker.

3. Update `/home/gary/.codex/simplepower` to the final Simple Power commit:

   ```bash
   SIMPLEPOWER_SHA="$(git rev-parse HEAD)"
   git -C /home/gary/.codex/simplepower fetch origin
   git -C /home/gary/.codex/simplepower checkout "$SIMPLEPOWER_SHA"
   git -C /home/gary/.codex status --short
   ```

4. Commit and push `/home/gary/.codex`:

   ```bash
   git -C /home/gary/.codex add simplepower
   git -C /home/gary/.codex commit -m "chore: update simplepower submodule"
   git -C /home/gary/.codex push origin master
   ```

Report the pushed Simple Power commit SHA, plugin sync result or blocker, `/home/gary/.codex` commit SHA, and push results.

## No Placeholders

Every step above contains concrete files, commands, and expected behavior. Workers must not add `TBD`, `TODO`, placeholder implementations, docs-only substitutes, skipped verification, skipped review, alternate context execution modes, worker commit commands, or per-task commit commands.

## Remember

- Exact file paths always.
- Interface Contract before File Ownership.
- No visual aids are needed for this plan.
- Branch defaults are in-place `feature/<slug>` and `debug/<slug>`, not worktrees.
- Branch failures require user approval before continuing in the current checkout.
- Brainstorming asks before invoking `simplepower:writing-plans`.
- Writing-plans asks before dispatching the REVIEW-tier plan reviewer.
- Existing combined approval before implementation remains.
- Contract inputs for every implementation task.
- Serialization required defaults to No; Yes needs a concrete reason.
- Aggregate parallel dispatch is expected when write scopes do not overlap and the approved Interface Contract is sufficient.
- Concrete commands with `timeout` and expected results.
- FAST/NORMAL/BEST/REVIEW allocation across implementation tasks, review, and verification.
- Model resolution precedence is explicit: user override, quoted assignment in project root AGENTS.md, process environment variable, built-in default.
- The project root AGENTS.md lookup reads only `<repo>/AGENTS.md`; never scan nested AGENTS.md files or use repo-wide grep for model assignments.
- REVIEW-tier plan reviewer.
- Keep the initial plan reviewer open for issue loops; send revised plans back to the same reviewer until approval, unrecoverable interruption, or explicit user direction.
- Quick verifier uses the FAST tier by default, resolving to `gpt-5.3-codex-spark-high` when unset.
- One REVIEW-tier review+fix agent.
- No worker commits or per-task commits.
- Exactly three coordinator checkpoints.
- Ask before dispatching the REVIEW-tier plan reviewer.
- Ask for combined approval of the reviewed plan, model/task allocation, and immediate current-session execution.
- After combined approval, commit the accepted plan checkpoint and immediately invoke `simplepower:subagent-driven-development` with the approved model allocation.
- After final verification and final commit, push this repo branch, run `scripts/sync-to-codex-plugin.sh -y`, then update, commit, and push `/home/gary/.codex`.
