# HTML Plan Visual Aids Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Add optional inline visual aids to new Markdown implementation plans while preserving the existing localhost visual companion for brainstorming.

**Design Summary:** The approved design keeps new implementation plans as Markdown files under `docs/simplepower/plans/` and does not convert historical plans. `simplepower:writing-plans` should optionally include inline Markdown-compatible visual aids when they reduce ambiguity, especially workflow flowcharts, architecture or data-flow maps, task ownership matrices, and state or error-path diagrams. Visual aids are optional, must not contradict authoritative text sections, and should be omitted when text is clearer. Separately, `simplepower:brainstorming` should continue to offer the browser visual companion before visual design questions; if the user accepts, it starts the localhost page and then uses it only for questions that benefit from seeing mockups, diagrams, or comparisons.

**Architecture:** `skills/writing-plans/SKILL.md` remains the source of truth for generated plan shape and gains optional `Visual Aids` guidance without changing the `.md` artifact contract. `skills/writing-plans/plan-document-reviewer-prompt.md` validates any present visuals for consistency while treating absence as acceptable. `skills/brainstorming/SKILL.md` and `skills/brainstorming/visual-companion.md` clarify that the interactive localhost companion is a brainstorming aid, distinct from inline visuals in saved Markdown plans.

**Tech Stack:** Markdown skill instructions, optional embedded Markdown-compatible HTML/SVG/table snippets, Bash static checks, existing Simple Power test harness.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

The implementation must preserve and enforce these workflow contracts:

- `Plan artifact format`: New Simple Power implementation plans continue to be saved as `.md` files under `docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md`. The implementation must not require `.html` plan files and must not convert historical plan files.
- `Optional Visual Aids`: `simplepower:writing-plans` may include a `## Visual Aids` section only when visual treatment reduces ambiguity. If no visual aid is useful, the section should be omitted rather than filled with "not needed" boilerplate.
- `Inline visual format`: Plan visuals live inside the Markdown plan as Markdown-compatible content, such as HTML blocks, SVG blocks, Markdown tables, or plain-text diagrams. The workflow must not generate or require separate linked local HTML files for plan visuals.
- `Suitable visual aid cases`: The writing-plan guidance should explicitly name workflow flowcharts, architecture or data-flow maps, task ownership matrices, and state or error-path diagrams as suitable optional cases.
- `Visual authority`: Written plan sections remain authoritative. If a visual aid contradicts the Interface Contract, File Ownership, task allocation, model allocation, verification, commit policy, or approved design, the reviewer must flag the contradiction before approval.
- `Brainstorming visual companion`: `simplepower:brainstorming` continues to offer the browser visual companion when upcoming design questions would benefit from visuals. If the user accepts, the agent should start the localhost companion using `skills/brainstorming/visual-companion.md`, provide the local URL, and use the browser only for visual questions.
- `Distinct visual modes`: Brainstorming visual companion pages are temporary interactive localhost aids. Writing-plan visuals are optional inline content in the saved Markdown plan. The implementation must make that distinction clear.
- `Deployment requirement`: After final verification and final Simple Power commit, the coordinator updates `/home/gary/.codex/simplepower` to the new `html-plan-visual-aids` branch, updates the parent `/home/gary/.codex` submodule pointer, commits the parent pointer change, and pushes both `garyfpga/simplepower` and `garyfpga/codex-config`. Existing unrelated `/home/gary/.codex/config.toml` changes must be preserved and not staged unless the user explicitly asks to include them.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `docs/simplepower/plans/2026-05-09-html-plan-visual-aids.md` | Coordinator plan | create | Authoritative implementation plan and reviewed allocation | Coordinator-owned before implementation; workers must not edit unless assigned by review+fix |
| `skills/writing-plans/SKILL.md` | Task 1 | modify | Add optional inline visual-aid guidance to generated Markdown plan requirements | No other task edits this file |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 2 | modify | Teach reviewer to validate present visual aids without requiring them | No other task edits this file |
| `skills/brainstorming/SKILL.md` | Task 3 | modify | Clarify that accepted visual companion use starts a localhost page for visual brainstorming questions | No other task edits this file |
| `skills/brainstorming/visual-companion.md` | Task 3 | modify | Clarify temporary brainstorming companion pages are distinct from saved plan visuals | Same owner as brainstorming guidance |
| `README.md` | Task 4 | modify | Document optional inline plan visuals and the separate brainstorming visual companion at user-facing workflow level | Same owner as docs/static checks |
| `docs/README.codex.md` | Task 4 | modify | Document optional inline plan visuals and localhost brainstorming companion in Codex guide | Same owner as docs/static checks |
| `docs/testing.md` | Task 4 | modify | Mention static coverage for optional plan visuals and brainstorming companion behavior | Same owner as docs/static checks |
| `tests/simplepower-static/run-tests.sh` | Task 4 | modify | Add assertions for Markdown plan format, optional visual aids, suitable cases, reviewer behavior, and brainstorming companion guidance | Test-only file; can be updated in parallel with skill files |

## Implementation Tasks

### Task 1: Add optional visual-aid guidance to writing-plans

**Goal:** Make `simplepower:writing-plans` support optional inline visuals in new Markdown implementation plans without changing the plan artifact format.

**Contract inputs:** `Plan artifact format`, `Optional Visual Aids`, `Inline visual format`, `Suitable visual aid cases`, `Visual authority`, and approved design decision to keep plans as `.md` files with optional inline visual blocks.

**Serialization required:** No. This task owns only `skills/writing-plans/SKILL.md`.

**Write scope:** `skills/writing-plans/SKILL.md`

**Parallel:** Yes, compatible with Task 2, Task 3, and Task 4.

**Risk:** Medium. This changes the plan-generation contract, but the change is limited to instructions and preserves existing required sections.

**Model tier:** BEST, using default `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"` when unset, resolved for dispatch as `model="gpt-5.5"` and `reasoning_effort="high"`, because this is behavior-shaping workflow text.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- Keep `**Save plans to:** docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md`.
- Add `Visual Aids` as an optional plan section, not a required section in the required-section list.
- State that visual aids are omitted when they do not reduce ambiguity.
- Permit inline Markdown-compatible HTML, SVG, Markdown tables, and plain-text diagrams.
- Explicitly name workflow flowcharts, architecture or data-flow maps, task ownership matrices, and state or error-path diagrams as suitable cases.
- State that plan visuals must support, not replace or contradict, the Interface Contract, File Ownership, implementation tasks, model allocation, verification, and approved path enforcement.
- State that writing-plans must not generate separate linked local HTML files for plan visuals under this design.
- Update self-review and "Remember" guidance so present visual aids are checked for consistency while absence is acceptable.

**Implementation steps:**

1. Edit `skills/writing-plans/SKILL.md` Overview to mention optional inline visual aids after aggregate parallel dispatch guidance.
2. In the plan body requirements area, add an optional `## Visual Aids` section description after `## Interface Contract` or after `## File Ownership`, without adding it to "must include these required sections".
3. Add examples of suitable visual cases using the exact terms from the Interface Contract.
4. Update Plan Review self-review to include: if visual aids are present, they are consistent with authoritative written sections; if absent, no issue.
5. Update No Placeholders or Remember sections to forbid separate linked local HTML plan artifacts unless a future approved design adds them.

**Verification commands for worker:**

- `timeout 30s rg -n "Visual Aids|workflow flowchart|architecture or data-flow|task ownership matrix|state or error-path|Markdown-compatible|separate linked local HTML" skills/writing-plans/SKILL.md`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, confirmation that `.md` remains the generated plan format, unresolved risks if any.

### Task 2: Update plan reviewer visual checks

**Goal:** Ensure the plan reviewer catches contradictory visual aids without requiring visuals on every plan.

**Contract inputs:** `Optional Visual Aids`, `Inline visual format`, `Visual authority`, and approved design decision that absent visual aids are acceptable.

**Serialization required:** No. This task owns only `skills/writing-plans/plan-document-reviewer-prompt.md`.

**Write scope:** `skills/writing-plans/plan-document-reviewer-prompt.md`

**Parallel:** Yes, compatible with Task 1, Task 3, and Task 4.

**Risk:** Low. This is a localized reviewer checklist update.

**Model tier:** FAST, using default `SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"` when unset, resolved for dispatch as `model="gpt-5.4-mini"` and `reasoning_effort="high"`, because the change is narrow and easy to verify.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- Add a `Visual Aids` reviewer category.
- State that visual aids are optional and absence is not a blocking issue.
- If a plan includes visual aids, require consistency with the approved design, Interface Contract, File Ownership, Implementation Tasks, Model Allocation, Quick Verification, Review+Fix, Commit Policy, Context Handoff, and Approved Path Enforcement.
- Reject visual aids that imply `.html` plan artifacts, separate linked local HTML files, converted historical plans, skipped checks, or alternate implementation routes.
- Keep calibration focused on implementation-impacting issues.

**Implementation steps:**

1. Edit the What to Check table in `skills/writing-plans/plan-document-reviewer-prompt.md` to add a `Visual Aids` row.
2. Update the Calibration section so missing visual aids are not a reason to reject a plan.
3. Add rejection language for visuals that contradict authoritative plan sections or imply separate linked local HTML plan files.
4. Preserve all existing aggregate-parallel, model-allocation, context-handoff, and commit-policy checks.

**Verification commands for worker:**

- `timeout 30s rg -n "Visual Aids|optional|absence|contradict|separate linked local HTML|\\.html" skills/writing-plans/plan-document-reviewer-prompt.md`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, confirmation that visuals are optional and checked only when present, unresolved risks if any.

### Task 3: Clarify brainstorming visual companion behavior

**Goal:** Make the brainstorming skill explicit that accepted visual companion use starts the localhost page for visual brainstorming questions and is separate from saved plan visuals.

**Contract inputs:** `Brainstorming visual companion`, `Distinct visual modes`, and approved design decision to preserve the existing companion mechanism.

**Serialization required:** No. This task owns only brainstorming guidance files.

**Write scope:** `skills/brainstorming/SKILL.md`, `skills/brainstorming/visual-companion.md`

**Parallel:** Yes, compatible with Task 1, Task 2, and Task 4.

**Risk:** Low. Existing server scripts and companion behavior already exist; this clarifies guidance.

**Model tier:** FAST, using default `SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"` when unset, resolved for dispatch as `model="gpt-5.4-mini"` and `reasoning_effort="high"`, because this is localized documentation in existing guidance.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- In `skills/brainstorming/SKILL.md`, after the user accepts the visual companion, require reading `skills/brainstorming/visual-companion.md`, starting the localhost server, giving the local URL, and using it per visual question.
- Preserve the existing one-message offer requirement.
- Preserve the rule that accepting the companion does not mean every question uses the browser.
- Add a short distinction between temporary brainstorming companion pages and optional inline visuals in saved Markdown plans.
- In `skills/brainstorming/visual-companion.md`, add the same distinction in the overview or How It Works section.

**Implementation steps:**

1. Edit `skills/brainstorming/SKILL.md` Visual Companion section to say accepted companion use starts the localhost page using the detailed guide.
2. Add language that browser pages are temporary brainstorming aids, not generated implementation plan artifacts.
3. Edit `skills/brainstorming/visual-companion.md` Overview or How It Works to distinguish the temporary localhost companion from optional inline saved-plan visuals.
4. Keep the existing per-question browser-versus-terminal decision rule unchanged.

**Verification commands for worker:**

- `timeout 30s rg -n "localhost|local URL|temporary|saved Markdown plan|inline visuals|per-question" skills/brainstorming/SKILL.md skills/brainstorming/visual-companion.md`
- `timeout 30s bash tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, confirmation that the existing one-message offer and per-question decision rules remain, unresolved risks if any.

### Task 4: Update docs and static checks

**Goal:** Lock the new optional visual-aid behavior in user-facing docs and the static test harness.

**Contract inputs:** All Interface Contract entries, especially `Plan artifact format`, `Optional Visual Aids`, `Suitable visual aid cases`, `Brainstorming visual companion`, and `Distinct visual modes`.

**Serialization required:** No. This task owns docs and static tests only. The static test may fail until Tasks 1-3 land; that is expected under aggregate parallel execution.

**Write scope:** `README.md`, `docs/README.codex.md`, `docs/testing.md`, `tests/simplepower-static/run-tests.sh`

**Parallel:** Yes, compatible with Task 1, Task 2, and Task 3.

**Risk:** Medium. Static assertions can overmatch if they are too broad, so they must be targeted to active workflow files.

**Model tier:** BEST, using default `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"` when unset, resolved for dispatch as `model="gpt-5.5"` and `reasoning_effort="high"`, because this task codifies the workflow contract and guards against regressions.

**Worker role:** `sp-impl`

**Outputs and file-level responsibilities:**

- In `README.md`, mention that writing-plans creates Markdown plans and may include optional inline visual aids when useful.
- In `docs/README.codex.md`, document the same behavior for Codex users and distinguish it from the brainstorming localhost companion.
- In `docs/testing.md`, add one concise bullet to the static test coverage list saying it checks optional plan visual guidance and brainstorming visual companion behavior.
- In `tests/simplepower-static/run-tests.sh`, add `require_contains` checks for:
  - plans remain under `docs/simplepower/plans`
  - `.md` plan format remains in `skills/writing-plans/SKILL.md`
  - optional `Visual Aids` guidance exists in writing-plans
  - the four suitable visual aid cases are named
  - reviewer prompt checks visual aids without requiring them
  - brainstorming guidance mentions localhost/local URL behavior and distinguishes temporary companion pages from saved Markdown plan visuals
- Add `require_not_contains` checks that active workflow docs do not say new plans are saved as `.html` files or that historical plans must be converted.

**Implementation steps:**

1. Edit `README.md` Core Workflow or Starting Implementation area with one concise mention of optional inline visual aids in Markdown plans.
2. Edit `docs/README.codex.md` Implementation Flow or Usage with the same guidance and companion distinction.
3. Edit `docs/testing.md` to add one concise bullet under the static checks coverage list for optional plan visual guidance and brainstorming visual companion behavior.
4. Add targeted static assertions near existing writing-plans, plan reviewer, and brainstorming blocks in `tests/simplepower-static/run-tests.sh`.
5. Keep negative regex checks scoped to active files so archived historical docs do not fail tests.

**Verification commands for worker:**

- `timeout 30s bash tests/simplepower-static/run-tests.sh`
- `timeout 30s rg -n "Visual Aids|workflow flowchart|architecture or data-flow|task ownership matrix|state or error-path|\\.html|Markdown" README.md docs/README.codex.md docs/testing.md tests/simplepower-static/run-tests.sh`

**Completion report requirements:** changed files, commands run and results, note any expected temporary static-test failures while parallel tasks are not yet integrated, unresolved risks if any.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Task 1 | `sp-impl` | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | Planner guidance changes the authoritative generated plan contract. |
| Task 2 | `sp-impl` | FAST | `gpt-5.4-mini` from default `gpt-5.4-mini-high` | high | Reviewer update is narrow and localized to one prompt. |
| Task 3 | `sp-impl` | FAST | `gpt-5.4-mini` from default `gpt-5.4-mini-high` | high | Brainstorming companion clarification is localized guidance for existing behavior. |
| Task 4 | `sp-impl` | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | Static tests and user-facing docs encode the workflow contract and regression boundaries. |
| Plan review | plan document reviewer | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | The reviewer must catch workflow contradictions before implementation. |
| Quick verification | quick verifier | fixed | `gpt-5.3-codex-spark` | high | Required quick verifier model for lint/build/tests before review. |
| Final review+fix | review+fix agent | BEST | `gpt-5.5` from default `gpt-5.5-high` | high | The reviewer must inspect and fix the whole workflow diff. |

## Plan Review

Self-review checklist:

- Design Summary: captures Markdown plan preservation, optional inline visuals, four suitable visual cases, brainstorming localhost companion behavior, no historical conversion, and post-finish deployment.
- Interface Contract: lists concrete artifact format, optional visual behavior, inline format, visual authority, brainstorming companion behavior, distinct visual modes, and deployment requirements before File Ownership.
- File ownership: every implied file is assigned to exactly one task; parallel tasks do not collide.
- Task allocation: every requirement maps to an implementation task, every task has `Contract inputs`, and every task has `Serialization required: No` with non-overlapping write scopes.
- Aggregate parallel readiness: Tasks 1-4 can run in aggregate parallel because their coordination needs are satisfied by the Interface Contract and write scopes do not overlap.
- Model allocation: BEST/FAST choices match risk; reviewer, verifier, and review+fix roles use the required models.
- Review allocation: the plan has one BEST-tier review+fix agent after quick verification.
- Commit policy: exactly three coordinator checkpoints are present and no non-coordinator role commits.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize `.html` plan conversion, separate linked local plan artifacts, skipped checks, reduced deliverables, docs-only substitutes, stub substitutes, or execution-route changes.
- Deployment: post-final steps update `/home/gary/.codex/simplepower`, commit only the parent submodule pointer unless the user explicitly authorizes unrelated changes, and push both repositories.

Then dispatch a BEST-tier plan reviewer using
`skills/writing-plans/plan-document-reviewer-prompt.md`. Provide the saved plan
path and the approved brainstorming design context. If the reviewer reports
issues, fix the plan and rerun the focused self-review checks for the changed
categories before asking the user.

After the plan reviewer approves, ask the user to approve both the reviewed
plan and model/task allocation. The accepted plan checkpoint commit happens
only after that approval. Workers and reviewers must not create this commit.

After the user approves the reviewed plan and model/task allocation, the
coordinator creates the accepted plan checkpoint commit before presenting the
implementation handoff choice.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the
coordinator creates the quick-verified implementation checkpoint. It checks that
the implementation is coherent enough for final review.

The quick verifier must use `model="gpt-5.3-codex-spark"` and
`reasoning_effort="high"`.

Quick verification commands:

- `timeout 30s bash tests/simplepower-static/run-tests.sh`
- `timeout 60s bash tests/skill-triggering/run-all.sh`
- `timeout 60s bash tests/explicit-skill-requests/run-all.sh`

Expected result: all commands pass. If the quick verifier finds only tiny typo-level issues directly causing command failure, it may fix them and rerun the failed command. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

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

1. Accepted plan checkpoint: after the user approves the reviewed plan and
   model/task allocation.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits
   complete and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final
   verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit.
Do not include worker-owned commits or per-task commits.

## Context-Size Handoff

The saved plan is the handoff artifact. Do not write a project-local
implementation handoff JSON artifact.

After the user approves the reviewed plan and model/task allocation and the
coordinator creates the accepted plan checkpoint commit, read
`skills/writing-plans/current-session-context.md`. Measure the current
coordinator session context pct in the main agent; do not spawn a subagent for
this measurement. Use `CODEX_THREAD_ID` and the Codex JSONL file through the
helper.

If the current session context measurement succeeds, use `>= 55%` for the
fresh-context `/clear` recommendation and `< 55%` for continuing in the
current session. If measurement fails, fall back to the saved plan size:

```bash
wc -c "$PLAN_PATH"
```

For fallback only, use bytes from the saved plan file, not characters, lines,
combined artifacts, or token estimates. The fallback comparison is strict
greater-than `35840`: a byte count greater than 35840 bytes selects the
fresh-context `/clear` recommendation, and `35840` or less selects the current
session recommendation.

Always show both implementation handoff commands, state whether the
recommendation came from current context pct or the plan-size fallback, and
ask the user which implementation handoff to use. Use Codex's user-question
tool, such as `request_user_input`, when available; otherwise ask in plain
text.

If the recommendation is fresh context, put this option first and label it
`Run after /clear (Recommended)`. If the recommendation is continuing in the
current session, put this option first and label it
`Continue in current session (Recommended)`.

For current-session handoff, show this exact command text:

```text
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-09-html-plan-visual-aids.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

For fresh-context handoff, show this exact command text:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-09-html-plan-visual-aids.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

If the user chooses current-session execution, that choice is an authorized
handoff to `simplepower:subagent-driven-development`. If the user chooses fresh
context, stop after showing the fresh-context command and tell the user to run
`/clear` manually before sending the command.

## Verification

Final verification commands:

- `timeout 30s bash tests/simplepower-static/run-tests.sh`
  - Run after the BEST-tier review+fix agent completes.
  - Expected result: all Simple Power static checks pass.
  - Failure means the workflow contract is missing, contradictory, or stale.
- `timeout 60s bash tests/skill-triggering/run-all.sh`
  - Run after static checks pass.
  - Expected result: skill-triggering smoke tests pass.
  - Failure means the active Simple Power handoff language may have regressed.
- `timeout 60s bash tests/explicit-skill-requests/run-all.sh`
  - Run after skill-triggering tests pass.
  - Expected result: explicit skill request tests pass.
  - Failure means the explicit invocation contract may have regressed.

The coordinator performs the final checkpoint only after the BEST-tier review+fix agent has completed and all final commands pass.

## Post-Final Deployment

After the final checkpoint commit in this repository:

1. Push the Simple Power feature branch and updated `main`:
   - `git push origin main`
   - `git push -u origin html-plan-visual-aids`
2. Update the installed submodule checkout:
   - `git -C /home/gary/.codex/simplepower fetch origin`
   - `git -C /home/gary/.codex/simplepower switch html-plan-visual-aids`
   - `git -C /home/gary/.codex/simplepower pull --ff-only`
3. In `/home/gary/.codex`, verify the parent repo still has the pre-existing `config.toml` changes and the updated `simplepower` submodule pointer:
   - `git -C /home/gary/.codex status --short`
   - `git -C /home/gary/.codex diff -- simplepower`
4. Commit only the submodule pointer unless the user separately asks to include unrelated config changes:
   - `git -C /home/gary/.codex add simplepower`
   - `git -C /home/gary/.codex commit -m "Update Simple Power visual aids workflow"`
5. Push the Codex config repo:
   - `git -C /home/gary/.codex push origin master`

If `/home/gary/.codex/simplepower` cannot switch to `html-plan-visual-aids`, or if the parent repo cannot commit only the submodule pointer because of unrelated conflicts, stop and ask the user before changing the approved deployment path.

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
  implementations, docs-only substitutes, or execution-route changes
- Text that changes new implementation plans from Markdown files to required
  `.html` files
- Text that requires converting existing historical plan files
- Text that requires separate linked local HTML files for plan visuals under
  this design
