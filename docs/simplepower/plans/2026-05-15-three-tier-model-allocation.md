# Three-Tier Model Allocation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation after the coordinator completes the approved branch preparation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Change Simple Power from BEST/FAST model allocation to BEST/NORMAL/FAST allocation, where NORMAL is the current `gpt-5.4-mini-high` tier and FAST defaults to Spark.

**Design Summary:** The approved design keeps BEST for risky and behavior-shaping work, renames the current FAST tier to NORMAL with `SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"`, adds Spark as the new FAST tier with `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`, and makes the quick verifier use the FAST tier by default. The work must first merge `workflow/current-session-auto-dispatch` back to `main`, create a new feature branch from the updated `main`, then implement and verify the tier changes. After the Simple Power repo is committed and pushed, update `/home/gary/.codex` so its Simple Power submodule follows the new branch, commit that config repo update, and push it.

**Architecture:** The model allocation contract is instruction-driven Markdown, so the change updates the active skills, user docs, Codex tool mapping, and static test contract together. The Interface Contract below gives every worker the same tier names, defaults, escalation rules, and quick-verifier semantics so non-overlapping documentation and test edits can proceed in aggregate parallel.

**Tech Stack:** Markdown skills and docs, Bash static tests, npm-based brainstorm server tests, git submodule metadata in `/home/gary/.codex`.

**Model Allocation:** FAST/NORMAL/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.3-codex-spark-high` when unset). NORMAL defaults to `SIMPLEPOWER_NORMAL_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses the FAST tier by default.

**Commit Policy:** The coordinator commits after the reviewed plan, allocation, and immediate current-session execution receive combined approval and branch preparation has placed the work on `feat/three-tier-model-allocation`; after all Simple Power file edits and quick verification complete before final review; and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits. The user-requested `/home/gary/.codex` submodule update is a separate post-implementation repository commit after the Simple Power branch is pushed.

---

## Interface Contract

The implementation must consistently use these public workflow terms:

- Tier names: `FAST`, `NORMAL`, and `BEST`.
- Environment variables and defaults:
  - `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"`
  - `SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"`
  - `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`
- Parsing rule: parse each value as `<model>-<reasoning_effort>` by taking the final dash-delimited segment as `reasoning_effort` and the preceding string as `model`.
- BEST use: broad, cross-cutting, ambiguous, behavior-shaping, high-risk, hard-to-test work, the plan reviewer, and the final review+fix agent.
- NORMAL use: routine low-risk implementation work that used the old FAST tier, especially localized edits where `gpt-5.4-mini-high` is appropriate.
- FAST use: obvious repetitive work, mechanical edits across many files, large static text sweeps, simple fixture or assertion churn, and quick verification.
- Quick verifier: uses the approved FAST tier by default, which resolves to `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"` unless `SIMPLEPOWER_FAST_MODEL` is overridden.
- Escalation rule: if planned FAST work becomes less mechanical or less obvious, escalate to NORMAL or BEST and record the reason; if planned NORMAL work becomes broad, ambiguous, behavior-shaping, or hard to verify, escalate to BEST and record the reason.
- Active docs and tests must stop describing Simple Power as having only two configurable model tiers.

Branch and repository contract:

- The execution branch for implementation is `feat/three-tier-model-allocation`.
- Before the accepted plan checkpoint commit, the coordinator must fast-forward `main` from `workflow/current-session-auto-dispatch`, push `main`, create `feat/three-tier-model-allocation` from updated `main`, and keep the reviewed plan file as an uncommitted carry-over until committing it on the new branch.
- `/home/gary/.codex` currently has pre-existing uncommitted `config.toml` edits. Preserve them. Do not include those edits in the Simple Power submodule update commit unless the user gives fresh explicit approval.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `docs/simplepower/plans/2026-05-15-three-tier-model-allocation.md` | Coordinator | create | Authoritative reviewed plan and accepted plan checkpoint content | Coordinator-owned only; workers must not edit unless explicitly assigned by coordinator for review fixes before approval |
| `skills/writing-plans/SKILL.md` | Task 1 | modify | Plan format, tier docs, allocation rules, self-review, approval, and current-session handoff language | Independent from Task 2 and docs files |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 1 | modify | Plan reviewer checks for FAST/NORMAL/BEST, NORMAL default, and quick verifier FAST default | Same owner as `skills/writing-plans/SKILL.md` so plan authoring and plan review stay consistent |
| `skills/subagent-driven-development/SKILL.md` | Task 2 | modify | Runtime model selection, quick verifier tier, dispatch rules, and red flags | Independent from Task 1 and docs files |
| `skills/using-simplepower/references/codex-tools.md` | Task 3 | modify | Codex spawn mappings and tier resolution guidance | Independent from Tasks 1, 2, 4, and 5 |
| `README.md` | Task 4 | modify | Chinese and English user-facing model allocation docs | Independent from skill files |
| `docs/README.codex.md` | Task 4 | modify | Codex install guide model allocation docs and quick verifier summary | Shared with `README.md` in same task to keep user-facing docs consistent |
| `tests/simplepower-static/run-tests.sh` | Task 5 | modify | Static assertions for three env vars, FAST/NORMAL/BEST language, and quick verifier using FAST | Serialized after Tasks 1-4 so assertions match final wording |
| `/home/gary/.codex/.gitmodules` | Post-implementation deployment | modify | Change the `simplepower` submodule branch to `feat/three-tier-model-allocation` | External repo update after Simple Power branch is pushed |
| `/home/gary/.codex/simplepower` | Post-implementation deployment | generated | Update the submodule checkout and gitlink to the pushed feature branch commit | External repo update after Simple Power branch is pushed |

## Implementation Tasks

### Task 0: Prepare Branches And Preserve Plan

**Goal:** Move from the completed workflow branch to a new feature branch before implementation edits begin.

**Contract inputs:** Branch contract from the Interface Contract; current branch `workflow/current-session-auto-dispatch`; target branch `feat/three-tier-model-allocation`; plan path `docs/simplepower/plans/2026-05-15-three-tier-model-allocation.md`.

**Serialization required:** Yes, because all implementation tasks must happen on the new branch from updated `main`.

**Write scope:** Git refs only plus the uncommitted plan file carry-over.

**Parallel:** No.

**Risk:** Medium, because branch state controls where all later commits land.

**Model tier:** BEST, resolved default `model="gpt-5.5"`, `reasoning_effort="high"`, because this is workflow-shaping repository setup.

**Worker role:** Coordinator only.

**Outputs and file-level responsibilities:** Updated local `main`, pushed `origin/main`, new local branch `feat/three-tier-model-allocation`, and the plan file still present as an uncommitted file ready for the accepted plan checkpoint commit.

**Implementation steps:**

1. Confirm the current branch is `workflow/current-session-auto-dispatch`.
2. Confirm there are no uncommitted changes except `docs/simplepower/plans/2026-05-15-three-tier-model-allocation.md`.
3. Run `git fetch origin`.
4. Run `git branch --list feat/three-tier-model-allocation`; if it exists, stop for user direction before changing branches.
5. Run `git switch main`.
6. Run `git merge --ff-only workflow/current-session-auto-dispatch`.
7. Run `git push origin main`.
8. Run `git switch -c feat/three-tier-model-allocation`.
9. Confirm `docs/simplepower/plans/2026-05-15-three-tier-model-allocation.md` is still uncommitted on the new branch.

**Verification commands:**

```bash
timeout 30s git status --short --branch
timeout 30s git log --oneline --decorate -5
```

Expected result: branch is `feat/three-tier-model-allocation`, the plan file is uncommitted, and `main` contains the former `workflow/current-session-auto-dispatch` tip.

**Completion report requirements:** Report branch name, pushed `main` SHA, and any uncommitted files.

### Task 1: Update Plan-Writing Tier Contract

**Goal:** Make `simplepower:writing-plans` author plans with FAST/NORMAL/BEST allocation.

**Contract inputs:** Tier names, environment variables, parsing rule, allocation rules, quick verifier FAST default, and escalation rule from the Interface Contract.

**Serialization required:** No.

**Write scope:** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.

**Parallel:** Yes, with Tasks 2, 3, and 4 after Task 0.

**Risk:** High, because this skill defines the authoritative plan format and execution handoff.

**Model tier:** BEST, resolved default `model="gpt-5.5"`, `reasoning_effort="high"`, because plan authoring controls downstream behavior.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

- Replace two-tier `FAST/BEST` language in active plan-writing instructions with `FAST/NORMAL/BEST`.
- Add `SIMPLEPOWER_NORMAL_MODEL`.
- Change `SIMPLEPOWER_FAST_MODEL` default to `gpt-5.3-codex-spark-high`.
- Describe quick verifier as using the FAST tier by default.
- Update required plan header, implementation task fields, model allocation section, plan review checklist, current-session auto-dispatch text, and reminder bullets.
- Update the plan document reviewer prompt so future plan review checks FAST/NORMAL/BEST allocation instead of the old FAST/BEST contract.

**Implementation steps:**

1. Update `## Model Tiers` to list all three variables and their defaults.
2. Change the required plan header `**Model Allocation:**` line to describe FAST/NORMAL/BEST and quick verifier FAST default.
3. In `## Implementation Tasks`, change model-tier requirements from `FAST or BEST` to `FAST, NORMAL, or BEST`.
4. In `## Model Allocation`, require stages to list FAST/NORMAL/BEST, resolved model, effort, and reason.
5. In `## Plan Review`, update model allocation self-review to check all three tiers and quick verifier FAST default.
6. In `## Quick Verification` and `## Current-Session Auto-Dispatch`, replace hard-coded Spark wording with FAST-tier wording while preserving the default resolved Spark example where useful.
7. In `## Remember`, replace two-tier reminders with FAST/NORMAL/BEST reminders.
8. In `skills/writing-plans/plan-document-reviewer-prompt.md`, update the Model Allocation review category so it requires FAST/NORMAL/BEST, the three env defaults, plan reviewer BEST, final review+fix BEST, and quick verifier FAST.

**Verification commands:**

```bash
timeout 30s rg -n 'SIMPLEPOWER_NORMAL_MODEL|FAST/NORMAL/BEST|quick verifier uses the FAST tier|gpt-5.3-codex-spark-high' skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
! timeout 30s rg -n 'two configurable model tiers|FAST/BEST allocation|Quick .*gpt-5.3-codex-spark.* high-effort verifier' skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
```

Expected result: first command shows the new contract; second command has no active stale hits.

**Completion report requirements:** Changed file, commands run, results, and any unresolved wording risks.

### Task 2: Update Subagent Execution Tier Contract

**Goal:** Make `simplepower:subagent-driven-development` execute approved FAST/NORMAL/BEST allocations and use FAST for the quick verifier.

**Contract inputs:** Tier names, defaults, quick verifier FAST default, and escalation rule from the Interface Contract.

**Serialization required:** No.

**Write scope:** `skills/subagent-driven-development/SKILL.md`.

**Parallel:** Yes, with Tasks 1, 3, and 4 after Task 0.

**Risk:** High, because this skill controls runtime subagent routing.

**Model tier:** BEST, resolved default `model="gpt-5.5"`, `reasoning_effort="high"`, because dispatch semantics are behavior-shaping.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

- Change the overview and process text so the quick verifier uses the FAST tier by default.
- Add `SIMPLEPOWER_NORMAL_MODEL`.
- Change `SIMPLEPOWER_FAST_MODEL` default to `gpt-5.3-codex-spark-high`.
- Let `sp-impl` use FAST, NORMAL, or BEST from the plan.
- Keep review+fix always BEST.
- Update escalation language for FAST and NORMAL.

**Implementation steps:**

1. In overview/process text, replace hard-coded quick verifier model wording with FAST-tier wording and default resolved Spark details.
2. In `## Quick Verification`, state that the quick verifier uses the approved FAST tier and defaults to `model="gpt-5.3-codex-spark"`, `reasoning_effort="high"`.
3. In `## Model Selection`, list all three env vars and parse rules.
4. Update role routing so `sp-impl` uses the plan's FAST, NORMAL, or BEST tier.
5. Update escalation rules to cover FAST-to-NORMAL-or-BEST and NORMAL-to-BEST.
6. Update red flags if they reference old two-tier wording.

**Verification commands:**

```bash
timeout 30s rg -n 'SIMPLEPOWER_NORMAL_MODEL|FAST, NORMAL, or BEST|FAST tier|gpt-5.3-codex-spark-high' skills/subagent-driven-development/SKILL.md
! timeout 30s rg -n "FAST/BEST allocation|plan's FAST or BEST|Quick verifier: use model=\"gpt-5.3-codex-spark\"" skills/subagent-driven-development/SKILL.md
```

Expected result: first command shows the new contract; second command has no active stale hits.

**Completion report requirements:** Changed file, commands run, results, and any unresolved dispatch risks.

### Task 3: Update Codex Tool Mapping

**Goal:** Align Codex spawn-agent mapping with FAST/NORMAL/BEST tier resolution.

**Contract inputs:** Tier names, defaults, quick verifier FAST default, parsing rule, and external `/home/gary/.codex` preservation rule from the Interface Contract.

**Serialization required:** No.

**Write scope:** `skills/using-simplepower/references/codex-tools.md`.

**Parallel:** Yes, with Tasks 1, 2, and 4 after Task 0.

**Risk:** Medium, because this file teaches the concrete Codex tool calls used by skills.

**Model tier:** NORMAL, resolved default `model="gpt-5.4-mini"`, `reasoning_effort="high"`, because the edit is localized and straightforward.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

- Update the mapping table to show `<FAST_or_NORMAL_or_BEST_model>`.
- Describe the quick verifier as FAST-tier dispatch rather than an unrelated hard-coded Spark call.
- Add `SIMPLEPOWER_NORMAL_MODEL` and change FAST default to Spark.
- Keep review+fix mapped to BEST.

**Implementation steps:**

1. Update the `sp-impl file-edit worker` row.
2. Update the `quick verifier` row to use `<FAST_model>` and `<FAST_effort>`, with text saying the default resolves to Spark high.
3. Update the environment-variable paragraph to list BEST, NORMAL, and FAST.
4. Update follow-up text to say implementation workers use the approved FAST/NORMAL/BEST allocation and review+fix always uses BEST.

**Verification commands:**

```bash
timeout 30s rg -n 'FAST_or_NORMAL_or_BEST|SIMPLEPOWER_NORMAL_MODEL|gpt-5.3-codex-spark-high|quick verifier.*FAST' skills/using-simplepower/references/codex-tools.md
! timeout 30s rg -n 'FAST_or_BEST|SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"|approved FAST/BEST' skills/using-simplepower/references/codex-tools.md
```

Expected result: first command shows new mapping; second command has no stale hits.

**Completion report requirements:** Changed file, commands run, results, and any unresolved mapping risks.

### Task 4: Update User-Facing Docs

**Goal:** Document the three model tiers for users in the README and Codex install guide.

**Contract inputs:** Tier names, env defaults, parsing rule, and allocation rules from the Interface Contract.

**Serialization required:** No.

**Write scope:** `README.md`, `docs/README.codex.md`.

**Parallel:** Yes, with Tasks 1, 2, and 3 after Task 0.

**Risk:** Low, because this is user-facing documentation text with direct static-test coverage.

**Model tier:** NORMAL, resolved default `model="gpt-5.4-mini"`, `reasoning_effort="high"`, because the edit is localized documentation.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

- Update Chinese and English README model allocation sections to three tiers.
- Update `docs/README.codex.md` model allocation section to three tiers.
- Describe FAST as Spark and quick verifier default.
- Preserve existing marketplace install, current-session auto-dispatch, and upstream attribution wording.

**Implementation steps:**

1. In the Chinese README model allocation section, change "two configurable model tiers" to three tiers, add NORMAL, update FAST default, and explain NORMAL versus FAST.
2. In the English README model allocation section, make the same changes.
3. In `docs/README.codex.md`, update env vars, parsing example, allocation rules, and implementation flow summary.
4. Avoid reintroducing retired `/clear`, saved-plan-size, or manual clone install flow references.

**Verification commands:**

```bash
timeout 30s rg -n 'SIMPLEPOWER_NORMAL_MODEL|SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"|FAST.*Spark|NORMAL' README.md docs/README.codex.md
! timeout 30s rg -n 'two configurable model tiers|SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"|/clear|saved plan size' README.md docs/README.codex.md
```

Expected result: first command shows the new user docs; second command has no stale active hits.

**Completion report requirements:** Changed files, commands run, results, and any unresolved user-doc risks.

### Task 5: Update Static Tests

**Goal:** Make static tests enforce the new three-tier contract and catch stale two-tier wording in active files.

**Contract inputs:** Tier names, env defaults, active file list, and success criteria from the Interface Contract.

**Serialization required:** Yes, because assertions should be edited after Tasks 1-4 establish final wording.

**Write scope:** `tests/simplepower-static/run-tests.sh`.

**Parallel:** No.

**Risk:** Medium, because over-broad assertions can fail on historical docs or miss active contract regressions.

**Model tier:** FAST, resolved default `model="gpt-5.3-codex-spark"`, `reasoning_effort="high"`, because this is obvious repetitive assertion churn over known strings.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

- Replace README and Codex guide assertions for old FAST default with NORMAL and new FAST defaults.
- Add assertions for `SIMPLEPOWER_NORMAL_MODEL`.
- Add assertions that writing-plans, SDD, and Codex tool mapping describe FAST/NORMAL/BEST.
- Add no-active-match assertions against old active two-tier phrases in active files.
- Keep historical specs/plans out of broad stale-wording checks unless a path is already in active test scope.

**Implementation steps:**

1. Update README checks for `SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"` and `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`.
2. Update `docs/README.codex.md` checks the same way.
3. Add checks for `skills/writing-plans/SKILL.md`, `skills/subagent-driven-development/SKILL.md`, and `skills/using-simplepower/references/codex-tools.md` that require FAST/NORMAL/BEST language.
4. Replace stale old-default checks with new-default checks.
5. Add focused stale checks for active files only.

**Verification commands:**

```bash
timeout 60s bash tests/simplepower-static/run-tests.sh
```

Expected result: static tests pass.

**Completion report requirements:** Changed file, command run, result, and any assertion risk.

### Task 6: Post-Implementation Deployment Update

**Goal:** Push the completed Simple Power feature branch, then update `/home/gary/.codex` to use that branch and push the config repo update.

**Contract inputs:** Branch contract, external repo preservation rule, final Simple Power branch `feat/three-tier-model-allocation`, and remote `git@github.com:garyfpga/simplepower.git`.

**Serialization required:** Yes, because this runs only after final Simple Power verification and final checkpoint commit.

**Write scope:** `/home/gary/.codex/.gitmodules`, `/home/gary/.codex/simplepower` gitlink.

**Parallel:** No.

**Risk:** Medium, because `/home/gary/.codex` has pre-existing user edits in `config.toml` that must not be accidentally committed.

**Model tier:** BEST, resolved default `model="gpt-5.5"`, `reasoning_effort="high"`, because this updates the live Codex configuration repository and pushes remote state.

**Worker role:** Coordinator only.

**Outputs and file-level responsibilities:**

- Push `feat/three-tier-model-allocation` in `/home/gary/git/simplepower`.
- In `/home/gary/.codex`, update `.gitmodules` submodule branch from `workflow/current-session-auto-dispatch` to `feat/three-tier-model-allocation`.
- In `/home/gary/.codex/simplepower`, fetch and check out `feat/three-tier-model-allocation` at the pushed final commit.
- Commit only `.gitmodules` and the `simplepower` gitlink in `/home/gary/.codex` unless the user gives fresh explicit approval to include the pre-existing `config.toml` edits.
- Push `/home/gary/.codex` `master`.

**Implementation steps:**

1. In `/home/gary/git/simplepower`, run `git status --short --branch` and confirm the final branch is clean on `feat/three-tier-model-allocation`.
2. Run `git push -u origin feat/three-tier-model-allocation`.
3. In `/home/gary/.codex`, run `git status --short --branch` and confirm `config.toml` is the pre-existing dirty file.
4. Edit `.gitmodules` so `submodule "simplepower"` has `branch = feat/three-tier-model-allocation`.
5. Run `git submodule sync simplepower`.
6. In `/home/gary/.codex/simplepower`, run `git fetch origin` and `git checkout feat/three-tier-model-allocation`.
7. Confirm the submodule HEAD equals the pushed final Simple Power commit.
8. In `/home/gary/.codex`, run `git add .gitmodules simplepower`.
9. Run `git diff --cached --name-only` and confirm only `.gitmodules` and `simplepower` are staged.
10. Run `git commit -m "chore: point simplepower to three-tier model branch"`.
11. Run `git push origin master`.

**Verification commands:**

```bash
timeout 30s git -C /home/gary/git/simplepower status --short --branch
timeout 30s git -C /home/gary/.codex diff --cached --name-only
timeout 30s git -C /home/gary/.codex submodule status simplepower
timeout 30s git -C /home/gary/.codex status --short --branch
```

Expected result: Simple Power feature branch is pushed and clean; `/home/gary/.codex` has the submodule update committed and pushed; any remaining `config.toml` dirt is explicitly reported as pre-existing and intentionally not committed.

**Completion report requirements:** Simple Power pushed branch, `/home/gary/.codex` commit SHA, pushed remote, staged-file check, and remaining dirty files if any.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Plan reviewer | reviewer | BEST | `gpt-5.5` | high | The plan changes core workflow instructions and branch/deployment sequencing. |
| Task 0 branch preparation | Coordinator | BEST | `gpt-5.5` | high | Branch setup determines where all commits land. |
| Task 1 implementation | `sp-impl` | BEST | `gpt-5.5` | high | `writing-plans` controls future plan schema and allocation semantics. |
| Task 2 implementation | `sp-impl` | BEST | `gpt-5.5` | high | `subagent-driven-development` controls runtime dispatch and verifier routing. |
| Task 3 implementation | `sp-impl` | NORMAL | `gpt-5.4-mini` | high | Codex tool mapping is localized text with clear replacements. |
| Task 4 implementation | `sp-impl` | NORMAL | `gpt-5.4-mini` | high | User docs are localized and directly verified by static tests. |
| Task 5 implementation | `sp-impl` | FAST | `gpt-5.3-codex-spark` | high | Static assertion updates are obvious repetitive string churn. |
| Quick verifier | quick verifier | FAST | `gpt-5.3-codex-spark` | high | Quick verification should use the FAST/Spark tier by default. |
| Final review+fix | review+fix agent | BEST | `gpt-5.5` | high | Final review must assess cross-file consistency and fix issues. |
| Task 6 deployment update | Coordinator | BEST | `gpt-5.5` | high | Live Codex config repo update and push require careful staging. |

## Plan Review

Self-review checklist:

- Design Summary: captures the approved three-tier model allocation design, branch flow, push requirement, and `/home/gary/.codex` update.
- Interface Contract: defines concrete tier names, env vars, defaults, parsing, quick verifier semantics, escalation, branch setup, and external repo preservation.
- File ownership: every active file expected to change is assigned to exactly one task, and `/home/gary/.codex/config.toml` is explicitly out of write scope unless the user re-approves it.
- Task allocation: every requirement maps to Task 0 through Task 6, every implementation task has Contract inputs, and serialized tasks have concrete reasons.
- Aggregate parallel readiness: Tasks 1-4 are non-overlapping and can run together after Task 0; Task 5 waits for final wording; Task 6 waits for final verification and push.
- Model allocation: FAST/NORMAL/BEST choices match risk, the quick verifier uses FAST, and final review+fix uses BEST.
- Review allocation: one BEST-tier review+fix agent runs after quick verification.
- Commit policy: exactly three Simple Power coordinator checkpoints are present and no worker commits are allowed; the `/home/gary/.codex` commit is an explicit user-requested external repo update after the Simple Power branch is pushed.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize skipped checks, docs-only substitutes, scope reduction, or alternate branch/deployment behavior.

## Quick Verification

Run quick verification after Tasks 1-5 complete and changed files pass scope validation. The quick verifier uses the approved FAST tier, defaulting to `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

Quick verifier authority is intentionally narrow. It may fix only tiny typo-level errors that directly cause a quick-check command failure. It must report behavior changes, structural edits, test rewrites, public interface changes, unclear issues, or anything outside typo-level repair to the coordinator instead of fixing them.

Commands:

```bash
timeout 60s bash tests/simplepower-static/run-tests.sh
timeout 60s rg -n 'SIMPLEPOWER_NORMAL_MODEL|SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"|FAST/NORMAL/BEST|quick verifier uses the FAST tier' README.md docs/README.codex.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
! timeout 60s rg -n "two configurable model tiers|SIMPLEPOWER_FAST_MODEL=\"gpt-5.4-mini-high\"|FAST/BEST allocation|plan's FAST or BEST|Quick .*gpt-5.3-codex-spark.* high-effort verifier" README.md docs/README.codex.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
```

Expected result: static tests pass; the positive scan finds the new contract; the stale scan returns no matches. If the stale scan finds historical archived plans or specs outside the listed active files, do not treat that as part of this quick check because the command intentionally scopes only active files.

## Final Verification

Run final verification after the BEST-tier review+fix agent completes.

Commands:

```bash
timeout 60s bash tests/simplepower-static/run-tests.sh
timeout 60s bash tests/skill-triggering/run-all.sh
timeout 60s bash tests/explicit-skill-requests/run-all.sh
timeout 60s npm --prefix tests/brainstorm-server test
timeout 60s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s git status --short --branch
```

Expected result: all test commands pass and the working tree contains only approved changes ready for the final Simple Power checkpoint. The coordinator performs the final Simple Power checkpoint only after the review+fix agent has completed and these commands pass.

After the Simple Power final checkpoint and push, run the Task 6 deployment verification commands in `/home/gary/.codex` before committing and pushing that external repo update.

## Coordinator Checkpoints

1. Accepted plan checkpoint: after the user gives combined approval for the reviewed plan, model/task allocation, immediate current-session execution, and branch preparation; after Task 0 creates `feat/three-tier-model-allocation`; before invoking `simplepower:subagent-driven-development`.
2. Quick-verified implementation checkpoint: after Tasks 1-5 complete and quick verification passes.
3. Final Simple Power checkpoint: after the BEST-tier review+fix agent completes and final verification passes.

Task 6 then performs the separate user-requested `/home/gary/.codex` commit and push for the submodule branch update. That external repo commit must stage only `.gitmodules` and `simplepower` unless the user gives fresh explicit approval to include the pre-existing `config.toml` edits.
