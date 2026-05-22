# Four-Tier Review Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Add a dedicated `SIMPLEPOWER_REVIEW_MODEL` tier for Simple Power review roles and harden reviewer prompts against recursive Codex or subagent launches.

**Design Summary:** The approved design changes Simple Power from three tiers to four tiers: `FAST`, `NORMAL`, `BEST`, and `REVIEW`. `SIMPLEPOWER_REVIEW_MODEL` defaults to `gpt-5.5-xhigh` and is used for both the plan reviewer and final review+fix agent. `BEST` remains for broad or risky implementation work. Model resolution uses explicit user override first, then a quoted assignment in project root `AGENTS.md` if that file exists, then the process environment, then the built-in default. The lookup reads only `<repo>/AGENTS.md`; it does not scan nested AGENTS files and does not repo-wide grep. The plan reviewer and review+fix prompts must explicitly forbid running Codex CLI, spawning subagents, invoking Simple Power skills, restarting execution, or rerouting the workflow.

**Architecture:** This is a prompt/docs/static-test update. The Interface Contract below defines the four-tier model vocabulary, root-AGENTS precedence, and reviewer non-recursion rules so independent workers can update skills, runtime docs, prompt fixtures, and static tests without waiting for each other's edits.

**Tech Stack:** Markdown skills and docs, Bash static tests, Codex multi-agent prompt templates, JSON plugin metadata.

**Model Allocation:** FAST/NORMAL/BEST/REVIEW tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.3-codex-spark-high` when unset), NORMAL defaults to `SIMPLEPOWER_NORMAL_MODEL` (`gpt-5.4-mini-high` when unset), BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset), and REVIEW defaults to `SIMPLEPOWER_REVIEW_MODEL` (`gpt-5.5-xhigh` when unset). The plan reviewer and final review+fix agent use REVIEW. The quick verifier uses the FAST tier by default, resolving to `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"` unless overridden by the resolution order.

**Commit Policy:** The coordinator commits after the reviewed plan, allocation, and immediate current-session execution receive combined approval, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

### Model Tiers

- Simple Power has exactly four configurable tiers in active workflow text: `FAST`, `NORMAL`, `BEST`, and `REVIEW`.
- Built-in defaults:
  - `SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"`
  - `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"`
  - `SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"`
  - `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`
- Values parse as `<model>-<reasoning_effort>` by taking the final dash-delimited segment as `reasoning_effort` and the preceding string as `model`.
- `gpt-5.5-xhigh` resolves to `model="gpt-5.5"` and `reasoning_effort="xhigh"`.

### Model Resolution Precedence

When a Simple Power skill resolves any `SIMPLEPOWER_*_MODEL` value, it uses this order:

1. Explicit user override in the current request or approved plan.
2. Quoted assignment in project root `AGENTS.md`, if `<repo>/AGENTS.md` exists.
3. Process environment variable.
4. Built-in default.

The AGENTS lookup reads only the project root `AGENTS.md`. It must not scan nested `AGENTS.md` files, inherited parent directories, historical docs, or the whole repo. Accepted AGENTS assignment forms are:

```bash
SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"
SIMPLEPOWER_REVIEW_MODEL = "gpt-5.5-xhigh"
```

The same quoted-assignment rule applies to `SIMPLEPOWER_BEST_MODEL`, `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL`.

### Tier Routing

- `REVIEW`: plan reviewer and final review+fix agent.
- `BEST`: broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or hard-to-test implementation work.
- `NORMAL`: routine low-risk localized implementation work.
- `FAST`: obvious repetitive work, mechanical edits across many files, large static text sweeps, simple fixture or assertion churn, and quick verification.
- `sp-impl` workers use the task's approved `FAST`, `NORMAL`, or `BEST` tier.
- The quick verifier uses the approved `FAST` tier by default.
- The final review+fix agent always uses `REVIEW`, not `BEST`.

### Reviewer Non-Recursion

The plan document reviewer prompt and the final review+fix prompt must include these hard negative instructions:

- Do not run Codex CLI.
- Do not spawn subagents.
- Do not invoke Simple Power skills.
- Do not restart execution.
- Do not reroute the workflow.
- Perform the assigned review directly in the current worker.

Reviewer hardening applies to `skills/writing-plans/plan-document-reviewer-prompt.md` and `skills/subagent-driven-development/review-fix-prompt.md`. The review+fix agent may still edit approved files when fixing issues because that is its assigned role, but it must not launch another agent or new Codex process to do that work.

### Active Text Scope

Active workflow files should no longer describe the plan reviewer or final review+fix agent as `BEST-tier`. Active docs should describe a `REVIEW-tier` plan reviewer and `REVIEW-tier` review+fix pass. Historical plans and archived design docs under `docs/simplepower/plans/` or `docs/simplepower/specs/` may keep old text.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `tests/simplepower-static/run-tests.sh` | Task 1 | modify | Add/update assertions for four-tier model allocation, root AGENTS precedence, REVIEW routing, and reviewer non-recursion. | Independent test file; should be edited before or in parallel with implementation tasks because Interface Contract defines expected strings. |
| `tests/skill-triggering/prompts/approved-planning-handoff.txt` | Task 1 | modify | Update planning handoff fixture to mention FAST/NORMAL/BEST/REVIEW allocation when needed. | Same owner as static test updates to keep fixtures aligned. |
| `tests/explicit-skill-requests/prompts/action-oriented.txt` | Task 1 | modify | Replace BEST-tier review+fix fixture wording with REVIEW-tier wording. | Same owner as related prompt fixture updates. |
| `tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt` | Task 1 | modify | Replace BEST-tier review+fix fixture wording with REVIEW-tier wording. | Same owner as related prompt fixture updates. |
| `skills/writing-plans/SKILL.md` | Task 2 | modify | Change plan-writing contract to four tiers, root AGENTS precedence, REVIEW-tier plan review, and REVIEW-tier final review+fix language. | Isolated from SDD runtime file edits. |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 2 | modify | Update reviewer checks for four-tier allocation, REVIEW roles, root AGENTS precedence, and no recursive Codex/subagent behavior. | Same owner as writing-plans skill because both define plan review contract. |
| `skills/subagent-driven-development/SKILL.md` | Task 3 | modify | Change SDD model selection, role routing, process steps, and red flags to use REVIEW for review+fix. | Isolated from writing-plans edits. |
| `skills/subagent-driven-development/implementer-prompt.md` | Task 3 | modify | Update stale task-model placeholder text from FAST/BEST to FAST/NORMAL/BEST. | Same owner as SDD prompt language. |
| `skills/subagent-driven-development/quick-verifier-prompt.md` | Task 3 | modify | Align quick verifier wording with approved FAST tier and resolution order without changing its FAST role. | Same owner as SDD prompt language. |
| `skills/subagent-driven-development/review-fix-prompt.md` | Task 3 | modify | Update to REVIEW-tier and add hard negative non-recursion instructions. | Same owner as SDD runtime review+fix contract. |
| `skills/using-simplepower/references/codex-tools.md` | Task 4 | modify | Update Codex tool mapping to four-tier resolution, root AGENTS precedence, and REVIEW routing for plan review/review+fix. | Isolated docs/reference file. |
| `README.md` | Task 4 | modify | Update Simplified Chinese and English user docs for four tiers, root AGENTS precedence, and REVIEW routing. | Same owner as public docs to keep wording consistent. |
| `docs/README.codex.md` | Task 4 | modify | Update Codex install guide for four tiers, root AGENTS precedence, and REVIEW routing. | Same owner as public docs to keep wording consistent. |
| `.codex-plugin/plugin.json` | Task 4 | modify | Update plugin long description from BEST-tier review+fix to REVIEW-tier review+fix. | Metadata-only change. |
| `AGENTS.md` | Task 4 | modify | Add contributor guidance that model default docs must preserve root `AGENTS.md` precedence and avoid setting local overrides unless intentional. | Root contributor doc; same owner as public docs and tool mapping. |
| `docs/simplepower/plans/2026-05-22-four-tier-review-model.md` | Coordinator | create | Authoritative implementation plan. | Coordinator-owned before implementation; implementation workers should not edit unless explicitly assigned by review+fix. |

## Implementation Tasks

### Task 1: Update Static Tests And Prompt Fixtures

**Goal:** Make the static contract fail on stale three-tier review routing and pass only when active files document the four-tier REVIEW model and reviewer non-recursion rules.

**Contract inputs:** Model Tiers, Model Resolution Precedence, Tier Routing, Reviewer Non-Recursion, and Active Text Scope from the Interface Contract.

**Serialization required:** No.

**Write scope:** `tests/simplepower-static/run-tests.sh`, `tests/skill-triggering/prompts/approved-planning-handoff.txt`, `tests/explicit-skill-requests/prompts/action-oriented.txt`, `tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt`.

**Parallel:** Yes, compatible with Tasks 2, 3, and 4.

**Risk:** Medium, because static tests define the acceptance contract and can become either too weak or too brittle.

**Model tier:** NORMAL, resolved default `model="gpt-5.4-mini"`, `reasoning_effort="high"`, because this is localized test and fixture maintenance but requires careful expected-string choices.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `tests/simplepower-static/run-tests.sh` requires `SIMPLEPOWER_REVIEW_MODEL`, `FAST/NORMAL/BEST/REVIEW`, `gpt-5.5-xhigh`, root `AGENTS.md` precedence, no nested AGENTS scanning, REVIEW-tier plan reviewer, REVIEW-tier review+fix, and non-recursion hard negatives.
- `tests/simplepower-static/run-tests.sh` rejects stale active text such as `three configurable model tiers`, `FAST/NORMAL/BEST model allocation`, `BEST-tier plan reviewer`, `one BEST-tier review+fix agent`, `plan reviewer and final review+fix agent use BEST`, and `Always dispatch the review+fix agent with BEST` in active files.
- Prompt fixtures replace BEST-tier review+fix wording with REVIEW-tier wording where present.

**Implementation steps:**
1. In `tests/simplepower-static/run-tests.sh`, update README and Codex guide assertions to include `SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"` and four-tier language.
2. Update writing-plans assertions to require `SIMPLEPOWER_REVIEW_MODEL`, `FAST/NORMAL/BEST/REVIEW`, `REVIEW-tier plan reviewer`, root `AGENTS.md`, and reviewer non-recursion instructions.
3. Update plan reviewer prompt assertions to require `SIMPLEPOWER_REVIEW_MODEL`, `REVIEW`, root `AGENTS.md`, and the hard negative instructions.
4. Update SDD assertions to require review+fix uses REVIEW, root `AGENTS.md` precedence, and non-recursion instructions in `review-fix-prompt.md`.
5. Update Codex tool mapping assertions to require `SIMPLEPOWER_REVIEW_MODEL`, `REVIEW_model`, root `AGENTS.md` precedence, and four-tier worker dispatch wording.
6. Update stale-model regexes so active files fail if they still route review roles through BEST. Scope those checks to active workflow files, not historical plans/specs.
7. Update the prompt fixture files listed in write scope to use REVIEW-tier wording for review+fix.

**Verification commands:**
- `timeout 60s bash tests/simplepower-static/run-tests.sh`
- `timeout 30s rg -n 'SIMPLEPOWER_REVIEW_MODEL|FAST/NORMAL/BEST/REVIEW|REVIEW-tier|project root AGENTS.md|Do not run Codex CLI|Do not spawn subagents' tests/simplepower-static/run-tests.sh tests/skill-triggering/prompts/approved-planning-handoff.txt tests/explicit-skill-requests/prompts/action-oriented.txt tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt`

**Expected results:** Static tests may fail until Tasks 2-4 update active files, but Task 1's own diff should clearly encode the new expected contract and fixture wording.

**Completion report requirements:** Changed files, assertions added/updated, commands run, results, and any assertion that intentionally waits for implementation tasks.

### Task 2: Update Plan Writing And Plan Reviewer Contract

**Goal:** Make plan writing produce and review four-tier plans with REVIEW-tier plan review and final review+fix allocation.

**Contract inputs:** Model Tiers, Model Resolution Precedence, Tier Routing, Reviewer Non-Recursion, and Active Text Scope from the Interface Contract.

**Serialization required:** No.

**Write scope:** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.

**Parallel:** Yes, compatible with Tasks 1, 3, and 4.

**Risk:** High, because these files define the authoritative planning contract and reviewer gate.

**Model tier:** BEST, resolved default `model="gpt-5.5"`, `reasoning_effort="high"`, because this is broad workflow-prompt behavior.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `skills/writing-plans/SKILL.md` describes four configurable tiers and the model resolution precedence.
- `skills/writing-plans/SKILL.md` uses REVIEW-tier for plan reviewer and final review+fix agent in overview, model allocation template, checklist, current-session handoff, commit checkpoints, and remember section.
- `skills/writing-plans/plan-document-reviewer-prompt.md` checks four-tier model allocation, root `AGENTS.md` precedence, REVIEW role routing, and reviewer non-recursion.

**Implementation steps:**
1. Replace three-tier overview language with four-tier language in `skills/writing-plans/SKILL.md`.
2. Add `SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"` to defaults and parsing examples.
3. Add the resolution precedence: user override, project root `AGENTS.md`, environment, built-in default.
4. State explicitly that the root AGENTS lookup reads only `<repo>/AGENTS.md`, not nested AGENTS files and not a repo-wide grep.
5. Replace plan reviewer and final review+fix routing from BEST to REVIEW throughout the planning skill.
6. Update the plan header template and `Model Allocation` section to require FAST/NORMAL/BEST/REVIEW.
7. Update the plan review dispatch text to say REVIEW-tier plan reviewer.
8. Update `plan-document-reviewer-prompt.md` with four-tier model checks, REVIEW role checks, root AGENTS precedence checks, and hard negative non-recursion rules.
9. Ensure no active text in these two files still says plan reviewer or final review+fix use BEST.

**Verification commands:**
- `timeout 30s rg -n 'SIMPLEPOWER_REVIEW_MODEL|FAST/NORMAL/BEST/REVIEW|REVIEW-tier plan reviewer|REVIEW-tier review\\+fix|project root AGENTS.md|Do not run Codex CLI|Do not spawn subagents' skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md`
- `bash -lc 'timeout 30s rg -n "BEST-tier plan reviewer|one BEST-tier review\\+fix agent|plan reviewer and final review\\+fix agent use BEST|final review\\+fix agent uses BEST" skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md; test "$?" -eq 1'`

**Expected results:** Positive search finds the new four-tier and non-recursion language. Negative search finds no stale BEST-for-review active wording in these files.

**Completion report requirements:** Changed files, commands run, results, and any wording risk that needs coordinator review.

### Task 3: Update Subagent-Driven Development Runtime And Prompts

**Goal:** Make SDD dispatch final review+fix through the REVIEW tier and prevent review+fix workers from recursively launching Codex or new subagents.

**Contract inputs:** Model Tiers, Model Resolution Precedence, Tier Routing, Reviewer Non-Recursion, and Active Text Scope from the Interface Contract.

**Serialization required:** No.

**Write scope:** `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/implementer-prompt.md`, `skills/subagent-driven-development/quick-verifier-prompt.md`, `skills/subagent-driven-development/review-fix-prompt.md`.

**Parallel:** Yes, compatible with Tasks 1, 2, and 4.

**Risk:** High, because this file controls actual subagent routing and lifecycle expectations.

**Model tier:** BEST, resolved default `model="gpt-5.5"`, `reasoning_effort="high"`, because this is broad workflow-prompt behavior.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `skills/subagent-driven-development/SKILL.md` documents four-tier model resolution and uses REVIEW for review+fix.
- `skills/subagent-driven-development/SKILL.md` role routing maps review+fix to `SIMPLEPOWER_REVIEW_MODEL`.
- `skills/subagent-driven-development/review-fix-prompt.md` is REVIEW-tier and contains the hard negative non-recursion instructions.
- `skills/subagent-driven-development/quick-verifier-prompt.md` says the quick verifier uses the approved FAST tier, not an unconditional hard-coded model.
- `skills/subagent-driven-development/implementer-prompt.md` no longer says only FAST or BEST for implementation tasks.

**Implementation steps:**
1. Add `SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"` to the SDD model defaults.
2. Add root `AGENTS.md` precedence to the SDD model selection section.
3. Replace final review+fix role routing from BEST to REVIEW throughout process, review+fix, final verification, prompt templates, and red flag text.
4. Keep `sp-impl` routing limited to FAST/NORMAL/BEST unless a future design explicitly adds REVIEW for implementation.
5. Keep quick verifier routing through FAST and update `quick-verifier-prompt.md` to avoid hard-coding the default as unconditional.
6. Update `review-fix-prompt.md` to say REVIEW-tier and add the hard negative instructions from the Interface Contract.
7. Update `implementer-prompt.md` model placeholder text to mention FAST, NORMAL, or BEST.

**Verification commands:**
- `timeout 30s rg -n 'SIMPLEPOWER_REVIEW_MODEL|REVIEW-tier review\\+fix|Review\\+fix agent: always use REVIEW|project root AGENTS.md|Do not run Codex CLI|Do not spawn subagents|FAST, NORMAL, or BEST' skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/quick-verifier-prompt.md skills/subagent-driven-development/review-fix-prompt.md`
- `bash -lc 'timeout 30s rg -n "one BEST-tier review\\+fix agent|Review\\+fix agent: always use BEST|final review\\+fix[^\n]*BEST|Use this template when dispatching the one BEST-tier" skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/review-fix-prompt.md; test "$?" -eq 1'`

**Expected results:** Positive search finds REVIEW-tier routing and non-recursion language. Negative search finds no stale BEST-for-review active wording in SDD files.

**Completion report requirements:** Changed files, commands run, results, and any unresolved role-routing ambiguity.

### Task 4: Update Tool Mapping, Active Docs, Metadata, And Contributor Notes

**Goal:** Make user-facing docs and Codex tool mapping describe the four-tier workflow, root `AGENTS.md` precedence, and REVIEW-tier review roles.

**Contract inputs:** Model Tiers, Model Resolution Precedence, Tier Routing, Reviewer Non-Recursion, and Active Text Scope from the Interface Contract.

**Serialization required:** No.

**Write scope:** `skills/using-simplepower/references/codex-tools.md`, `README.md`, `docs/README.codex.md`, `.codex-plugin/plugin.json`, `AGENTS.md`.

**Parallel:** Yes, compatible with Tasks 1, 2, and 3.

**Risk:** Medium, because docs must stay aligned across English, Simplified Chinese, plugin metadata, and tool mapping.

**Model tier:** NORMAL, resolved default `model="gpt-5.4-mini"`, `reasoning_effort="high"`, because this is localized documentation and reference updating.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `skills/using-simplepower/references/codex-tools.md` includes REVIEW model mapping for plan reviewer and review+fix.
- `README.md` and `docs/README.codex.md` document four tiers and root `AGENTS.md` precedence.
- `.codex-plugin/plugin.json` long description says REVIEW-tier review+fix.
- `AGENTS.md` contributor notes preserve the root AGENTS precedence rule without setting local model overrides.

**Implementation steps:**
1. In `skills/using-simplepower/references/codex-tools.md`, add `SIMPLEPOWER_REVIEW_MODEL`, `REVIEW_model`, and `REVIEW_effort` mappings.
2. State that the resolution order is user override, project root `AGENTS.md`, environment variable, built-in default.
3. State that only `<repo>/AGENTS.md` is read for model assignments; nested AGENTS files and repo-wide grep are not part of this feature.
4. Update README Simplified Chinese and English model allocation sections to four tiers, including REVIEW.
5. Update `docs/README.codex.md` model allocation, implementation flow, and starting command to use FAST/NORMAL/BEST/REVIEW and REVIEW-tier review+fix.
6. Update `.codex-plugin/plugin.json` long description to say REVIEW-tier review+fix.
7. Add a short contributor note to `AGENTS.md` that active model docs must preserve root AGENTS precedence and not set local model override values unless intentionally changing this repo's defaults.

**Verification commands:**
- `timeout 30s rg -n 'SIMPLEPOWER_REVIEW_MODEL|FAST/NORMAL/BEST/REVIEW|REVIEW-tier|project root AGENTS.md|gpt-5.5-xhigh' skills/using-simplepower/references/codex-tools.md README.md docs/README.codex.md .codex-plugin/plugin.json AGENTS.md`
- `bash -lc 'timeout 30s rg -n "three configurable model tiers|FAST/NORMAL/BEST model allocation|one BEST-tier review\\+fix|review\\+fix stage uses BEST|Always dispatch the review\\+fix agent with BEST" skills/using-simplepower/references/codex-tools.md README.md docs/README.codex.md .codex-plugin/plugin.json AGENTS.md; test "$?" -eq 1'`

**Expected results:** Positive search finds four-tier docs and root AGENTS precedence. Negative search finds no stale three-tier or BEST-for-review active wording in docs/reference files.

**Completion report requirements:** Changed files, commands run, results, and any user-facing wording choices worth coordinator review.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Task 1 implementation | `sp-impl` | NORMAL | `gpt-5.4-mini` | high | Static test and fixture edits are localized but need careful contract coverage. |
| Task 2 implementation | `sp-impl` | BEST | `gpt-5.5` | high | Planning and reviewer prompts define broad workflow behavior. |
| Task 3 implementation | `sp-impl` | BEST | `gpt-5.5` | high | SDD runtime routing and review+fix prompts define broad workflow behavior. |
| Task 4 implementation | `sp-impl` | NORMAL | `gpt-5.4-mini` | high | User docs and tool mapping are localized text/reference updates. |
| Plan review | plan reviewer | REVIEW | `gpt-5.5` | xhigh | The reviewer is validating the authoritative plan and review-routing contract. |
| Quick verifier | quick verifier | FAST | `gpt-5.3-codex-spark` | high | Quick verification is static checks and focused scans. |
| Final review+fix | review+fix agent | REVIEW | `gpt-5.5` | xhigh | The final reviewer must inspect and fix the whole implementation without recursive launches. |

Resolution note: the table shows built-in defaults. If the user provides explicit overrides, or if project root `AGENTS.md` contains quoted `SIMPLEPOWER_*_MODEL` assignments, or if environment variables are set, resolve each tier using the Model Resolution Precedence section.

## Plan Review

Self-review checklist:
- Design Summary: captures the approved four-tier REVIEW model, root AGENTS precedence, and reviewer non-recursion hardening.
- Interface Contract: defines model tiers, resolution order, accepted AGENTS assignment syntax, tier routing, non-recursion rules, and active text scope before File Ownership.
- File ownership: every active file expected to change is assigned to exactly one task, with no parallel write collisions.
- Task allocation: every requirement maps to an implementation task, every task has `Contract inputs`, and every task has `Serialization required: No`.
- Aggregate parallel readiness: Tasks 1-4 can run in parallel because their write scopes do not overlap and the Interface Contract supplies shared wording.
- Visual aids: omitted because this workflow/text change does not need a visual aid.
- Model allocation: FAST/NORMAL/BEST/REVIEW choices match task risk; plan reviewer and final review+fix use REVIEW; quick verifier uses FAST.
- Review allocation: the plan has one REVIEW-tier review+fix agent after quick verification.
- Commit policy: exactly three coordinator checkpoints are present and no non-coordinator role commits.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize unapproved route changes, skipped checks, reduced deliverables, docs-only substitutes, or recursive execution.

Then dispatch a REVIEW-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md` as the base reviewer scope, with the approved design context that this plan intentionally updates the active standard from three tiers to four tiers. The reviewer must evaluate against the approved four-tier design in this plan, not against stale current active text that this plan is changing. Keep the initial reviewer subagent open while it reports recoverable issues. If the reviewer reports issues, fix the plan, rerun focused self-review checks for the changed categories, and send the revised plan back to the same reviewer. Close the reviewer only after approval, unrecoverable interruption, or explicit user direction.

After the plan reviewer approves, ask the user for combined approval of the reviewed plan, model/task allocation, and immediate current-session execution. The accepted plan checkpoint commit happens only after that combined approval. Workers and reviewers must not create this commit.

After the user gives combined approval, the coordinator creates the accepted plan checkpoint commit and immediately invokes `simplepower:subagent-driven-development` to execute the accepted plan with the approved model allocation in the current session.

## Quick Verification

Run quick verification after Tasks 1-4 complete and changed files pass scope validation. The quick verifier uses the approved FAST tier by default.

Quick verification commands:
- `timeout 60s bash tests/simplepower-static/run-tests.sh`
- `timeout 30s rg -n 'SIMPLEPOWER_REVIEW_MODEL|FAST/NORMAL/BEST/REVIEW|REVIEW-tier|project root AGENTS.md|gpt-5.5-xhigh' README.md docs/README.codex.md AGENTS.md .codex-plugin/plugin.json skills tests`
- `bash -lc 'timeout 30s rg -n "three configurable model tiers|FAST/NORMAL/BEST model allocation|BEST-tier plan reviewer|one BEST-tier review\\+fix agent|plan reviewer and final review\\+fix agent use BEST|Always dispatch the review\\+fix agent with BEST" README.md docs/README.codex.md AGENTS.md .codex-plugin/plugin.json skills tests/skill-triggering tests/explicit-skill-requests; test "$?" -eq 1'`

Expected result: static tests pass, positive searches find the four-tier contract, and negative searches find no stale active three-tier or BEST-for-review text. If any failure is a tiny typo-level mismatch, the quick verifier may fix it and rerun the failed command. Any behavior, scope, or contract ambiguity must be reported to the coordinator instead of fixed by the quick verifier.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one REVIEW-tier review+fix agent. That agent reviews and fixes the whole implementation against the accepted plan, file ownership, approved path enforcement, aggregate parallel dispatch semantics, model-resolution precedence, REVIEW role routing, reviewer non-recursion rules, and verification requirements.

The review+fix agent may edit files within the plan's approved file ownership when fixing issues it finds. It must not run Codex CLI, spawn subagents, invoke Simple Power skills, restart execution, reroute the workflow, or commit. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval.

## Commit Checkpoints

1. Accepted plan checkpoint: after the user gives combined approval for the reviewed plan, model/task allocation, and immediate current-session execution, and before invoking `simplepower:subagent-driven-development`.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete and the quick verifier passes.
3. Final checkpoint: after the REVIEW-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. Do not include worker-owned commits or per-task commits.

## Current-Session Auto-Dispatch

The saved plan is the execution artifact. Do not write a project-local implementation JSON artifact.

Normal Simple Power planning proceeds in the current session. Do not run routing heuristics or offer alternate execution routes.

After the plan reviewer approves, ask the user for one combined approval that covers:
- The reviewed plan
- The model/task allocation
- Immediate current-session execution

If the user requests changes, update the plan, rerun the focused self-review checks for the changed categories, and send the revised plan back to the same reviewer when review approval must be refreshed. Do not create the accepted plan checkpoint until the user gives combined approval.

After combined approval, the coordinator creates the accepted plan checkpoint commit, then immediately invokes `simplepower:subagent-driven-development` in the current session with this instruction:

```text
Execute `docs/simplepower/plans/2026-05-22-four-tier-review-model.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST/REVIEW model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick FAST-tier verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent, final verification, and final commit.
```

## Verification

Final verification commands:

- `timeout 60s bash tests/simplepower-static/run-tests.sh`
- `timeout 60s bash tests/skill-triggering/run-test.sh`
- `timeout 60s bash tests/explicit-skill-requests/run-test.sh`
- `timeout 30s rg -n 'SIMPLEPOWER_REVIEW_MODEL|FAST/NORMAL/BEST/REVIEW|REVIEW-tier|project root AGENTS.md|gpt-5.5-xhigh|Do not run Codex CLI|Do not spawn subagents|Do not invoke Simple Power skills|Do not restart execution|Do not reroute the workflow|Perform the assigned review directly' README.md docs/README.codex.md AGENTS.md .codex-plugin/plugin.json skills tests`
- `bash -lc 'timeout 30s rg -n "three configurable model tiers|FAST/NORMAL/BEST model allocation|BEST-tier plan reviewer|one BEST-tier review\\+fix agent|plan reviewer and final review\\+fix agent use BEST|final review\\+fix agent uses BEST|Always dispatch the review\\+fix agent with BEST" README.md docs/README.codex.md AGENTS.md .codex-plugin/plugin.json skills tests/skill-triggering tests/explicit-skill-requests; test "$?" -eq 1'`

Expected result: all static and skill-triggering checks pass, positive scans find four-tier and non-recursion language, and negative scans find no stale active review-routing text. Historical plans/specs are intentionally excluded from the negative scan.

The coordinator performs the final checkpoint only after the REVIEW-tier review+fix agent has completed and all final commands pass.

## No Placeholders

Every step above contains exact files, model roles, resolution rules, expected strings, and verification commands. This plan does not authorize scope reduction, docs-only substitutes, placeholder implementations, skipped verification, skipped review, recursive review launches, execution-route changes, or user selection among alternate execution routes.
