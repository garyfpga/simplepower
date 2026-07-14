# On-Demand Explorer Fan-Out and Dual Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one primary REVIEW-tier review+fix agent before final verification and final commit. After Task 2 is installed, pair that primary with a simultaneous read-only secondary reviewer only when a distinct effective `review_model2` exists.

**Goal:** Make optional exploration coordinator-led and on-demand, and add an optional cheap second review model that provides a parallel independent review at both plan-review and final-review checkpoints without allowing concurrent file edits.

**Design Summary:** Preserve `use_subagent` as the hard gate, but require coordinator-owned read-only triage before optional exploration in brainstorming and RO. Escalate only for a large, cross-cutting, complex, or stalled investigation; dispatch any useful number of distinct read-only explorers within runtime capacity, never automatically at workflow start. Add optional `review_model2` with no built-in default and no environment variable. When it is absent or exactly equal to the resolved `review_model`, retain the current single-reviewer behavior. When it is present and differs, run two read-only plan reviewers concurrently, and run a read-only primary/secondary final-review phase from one verified snapshot before authorizing only the primary reviewer to fix in scope. Add a root `simplepower.toml.example` showing `gpt-5.6-luna-max` as an optional inexpensive secondary reviewer; do not track an active `simplepower.toml`.

**Architecture:** This repository is instruction-driven: the canonical configuration reference defines the contract, workflow skills consume it, prompt templates constrain agents, and the static harness enforces stable behavior anchors. The Interface Contract below permits four non-overlapping workers to update shared policy, review orchestration, user-facing documentation, and static tests in aggregate; the workers must use the listed contract instead of waiting for one another's uncommitted edits.

**Tech Stack:** Markdown workflow contracts and prompts, TOML examples validated with Python `tomllib`, Bash static checks, repository skill-trigger tests, and coordinator-owned Git scratch refs.

**Model Allocation:** The current six-key configuration was validated before planning. Home configuration supplies `use_subagent=true`, `subagent_model=gpt-5.6-luna-max`, REVIEW `gpt-5.6-sol-xhigh`, BEST `gpt-5.6-terra-max`, NORMAL `gpt-5.6-luna-max`, and FAST `gpt-5.3-codex-spark-xhigh`; no repository `simplepower.toml` exists. The user explicitly instructed this current session to ignore the four non-empty `SIMPLEPOWER_*` model-tier environment overrides, so every allocation in this plan uses those validated home-file values after the repository layer. The normal resolution contract remains built-in defaults, home file, repository file, environment variables, then explicit current-session instructions; this plan records that last-layer instruction rather than changing the environment or repository. Task 1 changes the target schema from six base keys to those six plus optional `review_model2`; it does not add `SIMPLEPOWER_REVIEW_MODEL2` or change the four mandatory tiers. Because `review_model2` is not currently configured, this plan's own plan-review dispatch uses the existing single REVIEW reviewer.

**Commit Policy:** The coordinator creates exactly three checkpoints: the accepted reviewed plan after combined user approval, the quick-verified implementation before final review, and the final verified implementation. Workers, plan reviewers, quick verifiers, and review agents never commit. Coordinator-owned scratch refs under `refs/simplepower/scratch/20260713-155017-f6e737a/...` are local review diff anchors only, are not accepted history, and are deleted after successful checkpoints or preserved and reported for manual cleanup on a blocker or failed checkpoint.

---

## Interface Contract

### OD-IC-1: Branch, scope, and configuration vocabulary

- Work occurs on `feature/on-demand-explorer-fanout-and-dual-review`, whose HEAD is `f6e737a`, the current tip of `optimize/skill-compaction`.
- The target supported TOML vocabulary is the existing six base keys—`use_subagent`, `subagent_model`, `review_model`, `best_model`, `normal_model`, and `fast_model`—plus optional `review_model2`.
- `review_model2` has no built-in default. If present in home, repository, or explicit current-session configuration, it is a nonempty model/effort string validated by the same final-dash parsing and allowed suffixes as the other model values.
- The four environment variables remain exactly `SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`, `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL`. There is no `SIMPLEPOWER_REVIEW_MODEL2`.
- Compare `review_model2` and `review_model` as fully resolved strings. An absent value or an exact match disables the secondary route; any distinct valid value enables it.
- No implementation task tracks an active repository `simplepower.toml`. The only new configuration artifact is root `simplepower.toml.example`.

### OD-IC-2: Coordinator-led optional explorer fan-out

- `use_subagent=false` prohibits every optional explorer in brainstorming and RO. `true` is permission, not an instruction to spawn.
- Both workflows begin with coordinator-owned read-only triage and must not dispatch explorers automatically when activated.
- Only after triage identifies a large, cross-cutting, complex, or stalled investigation may the coordinator dispatch one or more explorers. There is no policy-defined numeric cap: runtime capacity and useful, distinct investigation angles are the practical limits.
- Every explorer uses the parsed `subagent_model`, exact `fork_turns="none"`, and a self-contained brief with task, assigned distinct angle, repository scope, read-only restrictions, evidence, expected report, and verification.
- Explorers may inspect files and run read-only commands only. They may not edit or create files, create RO artifacts, answer user design questions, choose approaches, approve designs, or transfer coordinator ownership.
- The coordinator synthesizes all reports. If any explorer in a selected batch cannot dispatch because multi-agent support, the configured model, or spawning is unavailable, stop the affected workflow and report the blocker; do not treat a partial batch as a substitute.

### OD-IC-3: Optional secondary reviewer routing

- `review_model` remains the primary REVIEW route and the only review+fix route. `review_model2` is a conditional, read-only secondary route, not a fifth mandatory model tier.
- With a distinct effective `review_model2`, planning dispatches primary and secondary plan reviewers concurrently. Both receive the same self-contained plan evidence, are read-only, and must approve before the plan passes. If either finds blocking issues, the coordinator revises the plan, creates the next plan-review scratch ref, and sends the concrete diff to both original reviewers for the next loop.
- With a distinct effective `review_model2`, final review starts after the quick-verified implementation checkpoint and the shared `review-fix/before` scratch anchor exists. The coordinator dispatches the primary review+fix agent and secondary reviewer concurrently against that same snapshot. Both initial briefs prohibit edits.
- The coordinator collects both reports, closes the secondary by default, synthesizes findings against the accepted plan, and sends the primary a self-contained follow-up authorizing only in-scope fixes. Keeping the primary open while it awaits this synthesis is the sole permitted lifecycle exception.
- Only the primary may edit after that follow-up. The secondary never edits, commits, manages refs, or starts new work. The existing `review-fix/after` anchor records only primary edits.
- If either configured reviewer cannot dispatch, stop the review checkpoint and report the precise blocker. Do not silently continue with one reviewer or allow a primary to edit before both reports are available.
- When no distinct secondary is configured, retain the existing one primary REVIEW-tier plan-review and review+fix behavior.

### OD-IC-4: Preserved safety and review boundaries

- Every Simple Power spawn remains isolated with exact `fork_turns="none"` and a self-contained prompt. Plan reviewers and secondary reviewers are read-only; the primary review+fix agent may only edit approved ownership after authorization.
- Mandatory FAST/NORMAL/BEST/REVIEW allocation, quick-verifier restrictions, the three coordinator checkpoints, scratch-ref ownership, final verification, and no-worker-commit policy remain intact.
- Review disagreement is evidence for coordinator synthesis, not a vote or an authorization to broaden scope. A required scope expansion, changed strategy, or other approved-path deviation still stops for user direction.

### OD-IC-5: Documentation, metadata, example, and static coverage

- `simplepower.toml.example` presents all base keys plus a documented optional `review_model2 = "gpt-5.6-luna-max"`; copying it is a user action, and no tracked active config is created.
- Chinese and English README sections, Codex installation documentation, testing guidance, plugin metadata, source skills, prompt templates, and the tool mapping must agree on the same fan-out and dual-review behavior.
- Static tests must enforce behavior anchors without matching historical plans or requiring a retired exact-one explorer phrase. They must retain the invariant that exactly one primary review+fix agent owns edits.

### OD-IC-6: Verification contract

- The repository's focused signal is `tests/simplepower-static/run-tests.sh`; the plan also runs syntax, skill-triggering, explicit-skill, brainstorm-server, plugin-sync, TOML-example, whitespace, and focused negative-search checks.
- No native source changes are in scope, so `xmake b` is not required.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---|---|---|
| `docs/simplepower/plans/2026-07-13-on-demand-explorer-fanout-and-dual-review.md` | Coordinator (planning) | create | Authoritative approved implementation plan and review record | Created before worker dispatch; no worker edits it. |
| `skills/using-simplepower/references/simplepower-config.md` | Task 1 | modify | Seven-key configuration and canonical on-demand fan-out policy | Exclusive to Task 1. |
| `skills/brainstorming/SKILL.md` | Task 1 | modify | Brainstorming triage and later fan-out rules | Exclusive to Task 1. |
| `skills/ro/SKILL.md` | Task 1 | modify | RO triage, later fan-out, and RO explorer constraints | Exclusive to Task 1. |
| `skills/writing-plans/SKILL.md` | Task 2 | modify | Future plan-review and plan-document dual-review routing | Exclusive to Task 2. |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 2 | modify | Review criteria for the optional secondary plan reviewer | Exclusive to Task 2. |
| `skills/subagent-driven-development/SKILL.md` | Task 2 | modify | Conditional parallel final-review lifecycle and primary-only fixes | Exclusive to Task 2. |
| `skills/subagent-driven-development/review-fix-prompt.md` | Task 2 | modify | Primary review+fix two-phase prompt behavior | Exclusive to Task 2. |
| `skills/subagent-driven-development/secondary-review-prompt.md` | Task 2 | create | Self-contained read-only secondary final-review prompt | Exclusive to Task 2. |
| `skills/using-simplepower/references/codex-tools.md` | Task 2 | modify | Codex dispatch mapping for the conditional secondary reviewer | Exclusive to Task 2. |
| `README.md` | Task 3 | modify | Chinese and English configuration and workflow documentation | Exclusive to Task 3. |
| `docs/README.codex.md` | Task 3 | modify | Codex configuration, review, and on-demand fan-out documentation | Exclusive to Task 3. |
| `docs/testing.md` | Task 3 | modify | Manual configuration and workflow smoke-test guidance | Exclusive to Task 3. |
| `.codex-plugin/plugin.json` | Task 3 | modify | User-facing plugin description of primary plus optional secondary review | Exclusive to Task 3. |
| `simplepower.toml.example` | Task 3 | create | Copyable documented model configuration example | Exclusive to Task 3. |
| `tests/simplepower-static/run-tests.sh` | Task 4 | modify | Static behavioral regression coverage for all approved changes | Exclusive to Task 4. |

No `## Visual Aids` section is needed: the key correctness issue is a temporal permission boundary, which the written Interface Contract states more precisely than a diagram.

## Implementation Tasks

### Task 1: Define the canonical configuration and on-demand explorer policy

**Goal:** Extend the shared configuration contract with optional `review_model2` and replace startup-oriented one-explorer wording with coordinator-led, on-demand fan-out in brainstorming and RO.

**Contract inputs:** OD-IC-1, OD-IC-2, OD-IC-4, OD-IC-5, and OD-IC-6.

**Serialization required:** No. Task 1 owns only the shared reference and optional-explorer workflow skills; Tasks 2–4 consume its exact contract without editing these files.

**Write scope:**

- `skills/using-simplepower/references/simplepower-config.md`
- `skills/brainstorming/SKILL.md`
- `skills/ro/SKILL.md`

**Parallel:** Yes, with Tasks 2, 3, and 4.

**Risk:** High — these instructions directly decide whether agents launch, how many may launch, which model they use, and when a workflow must stop.

**Model tier:** BEST — resolved `gpt-5.6-terra` with `max` reasoning.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

1. Change the config reference from an exclusively six-key schema to six base keys plus optional `review_model2`. State its lack of default, home/repository/current-session overlay behavior, validation, exact resolved-string comparison, and the absence of a model-2 environment variable; preserve the existing four environment-tier variables and all validation guarantees.
2. Replace the shared optional-explorer policy with initial coordinator triage, later qualified escalation, one-or-more distinct angles, no policy count cap, runtime-capacity practical limit, self-contained read-only briefs, coordinator synthesis, and stop-on-selected-batch failure.
3. Update brainstorming's first procedure item so it never dispatches automatically at activation and may later fan out only after coordinator triage proves the investigation merits it. Preserve visual-companion, design-approval, and coordinator-responsibility rules.
4. Update RO's Initial Analysis similarly, retaining the prohibition on edits, file creation, and `.codex-ro` artifacts by explorers, along with all RO temp-artifact and cleanup boundaries.
5. Do not alter systematic-debugging's bounded six-angle policy; it remains a separate, explicitly bounded workflow.

**Verification:**

```bash
timeout 30s rg -n 'review_model2|no built-in default|four mandatory model tiers|initial.*triage|one or more|distinct.*angle|runtime capacity|fork_turns="none"|partial' skills/using-simplepower/references/simplepower-config.md skills/brainstorming/SKILL.md skills/ro/SKILL.md
timeout 30s rg -n 'optionally dispatch one read-only|select one read-only explorer|spawn exactly one read-only|initial explorer necessary' skills/using-simplepower/references/simplepower-config.md skills/brainstorming/SKILL.md skills/ro/SKILL.md
timeout 30s git diff --check -- skills/using-simplepower/references/simplepower-config.md skills/brainstorming/SKILL.md skills/ro/SKILL.md
```

The first command must show all replacement anchors. The second must exit 1 because it searches only active changed policy files for retired exact-one wording. The third must exit 0 with no output.

**Completion report:** List changed files; quote the configuration, fan-out, and failure-boundary anchors added; report each command and exit status; confirm no systematic-debugging file was changed.

### Task 2: Add conditional dual-review orchestration and prompts

**Goal:** Teach planning and implementation workflows to use a distinct optional `review_model2` as a concurrent read-only second pair of eyes while preserving exactly one primary review+fix writer.

**Contract inputs:** OD-IC-1, OD-IC-3, OD-IC-4, OD-IC-5, and OD-IC-6.

**Serialization required:** No. Task 2 owns every planning/review lifecycle and prompt path; Tasks 1, 3, and 4 rely on the approved contract rather than these uncommitted files.

**Write scope:**

- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/review-fix-prompt.md`
- `skills/subagent-driven-development/secondary-review-prompt.md`
- `skills/using-simplepower/references/codex-tools.md`

**Parallel:** Yes, with Tasks 1, 3, and 4.

**Risk:** High — it changes mandatory review sequencing, lifecycle exceptions, and authority to edit the shared worktree.

**Model tier:** BEST — resolved `gpt-5.6-terra` with `max` reasoning.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

1. In writing-plans, describe the six base keys plus optional `review_model2`, retain the four mandatory tiers, and make future plan review conditional: absent/equal stays one reviewer; distinct values spawn both reviewers concurrently, require both approvals, and route each revised plan diff to both original reviewers.
2. Update the plan-document reviewer template so it validates optional-secondary routing, no `SIMPLEPOWER_REVIEW_MODEL2`, two read-only plan reviewers when enabled, and one primary fixer plus a read-only secondary in final review. Preserve direct-review and non-recursion restrictions.
3. In SDD, resolve `review_model2` only after the primary model is resolved. For a distinct secondary, create the normal `review-fix/before` snapshot, dispatch both read-only initial reviews concurrently with `fork_turns="none"`, stop the checkpoint if either dispatch fails, synthesize both reports, close the secondary, then send the retained primary a self-contained fix authorization. Preserve direct single-primary behavior when the secondary is absent or equal.
4. Update `review-fix-prompt.md` so the primary explicitly receives a dual-review mode field. In dual mode it reports initial findings without edits and waits for coordinator synthesis; in single mode it retains its existing direct review+fix permission. In both modes it may never commit or manage refs.
5. Create `secondary-review-prompt.md` with the same plan/diff/ownership evidence fields but strict read-only, no-file-creation, no-ref, no-commit, no-subagent, no-skill, and no-rerouting restrictions. Its report must give findings, evidence, exact commands, risks, and explicit no-edit confirmation.
6. Update the Codex tool mapping to name the conditional secondary reviewer, require the same snapshot and self-contained brief, and distinguish its read-only role from the primary REVIEW-tier review+fix agent.
7. Preserve the existing scratch-ref namespace and use one `review-fix/before` and, only for primary edits, one `review-fix/after`; do not add a second accepted checkpoint or concurrent writer.

**Verification:**

```bash
timeout 30s rg -n 'review_model2|exact match|read-only|both.*plan reviewer|both.*reports|primary.*fix|SIMPLEPOWER_REVIEW_MODEL2|fork_turns="none"' skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/review-fix-prompt.md skills/subagent-driven-development/secondary-review-prompt.md skills/using-simplepower/references/codex-tools.md
timeout 30s rg -n 'secondary-review-prompt.md|primary.*only|no.*edit' skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/review-fix-prompt.md skills/subagent-driven-development/secondary-review-prompt.md
timeout 30s git diff --check -- skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/review-fix-prompt.md skills/subagent-driven-development/secondary-review-prompt.md skills/using-simplepower/references/codex-tools.md
```

The searches must demonstrate the conditional route and primary-only edit boundary; the whitespace check must exit 0 with no output.

**Completion report:** List changed and created paths; state the single-review, dual-plan-review, and dual-final-review state transitions; report commands and results; identify any ambiguity instead of broadening the workflow.

### Task 3: Publish configuration, model, and review guidance with an example

**Goal:** Give users a copyable configuration example and align public documentation and plugin metadata with on-demand fan-out and the optional second reviewer.

**Contract inputs:** OD-IC-1, OD-IC-2, OD-IC-3, OD-IC-4, OD-IC-5, and OD-IC-6.

**Serialization required:** No. Task 3 owns documentation, metadata, and the example file only; it can document the approved interface while Tasks 1, 2, and 4 edit their disjoint paths.

**Write scope:**

- `README.md`
- `docs/README.codex.md`
- `docs/testing.md`
- `.codex-plugin/plugin.json`
- `simplepower.toml.example`

**Parallel:** Yes, with Tasks 1, 2, and 4.

**Risk:** Medium — unclear instructions could make users enable unwanted agents or misunderstand the no-concurrent-writers safety boundary.

**Model tier:** NORMAL — resolved `gpt-5.6-luna` with `max` reasoning.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

1. Update both Chinese and English README model/configuration sections: retain four mandatory tiers and four environment overrides, introduce optional `review_model2` with no environment override, explain absent/equal versus distinct behavior, and describe coordinator-first on-demand explorer fan-out rather than one startup explorer.
2. Update `docs/README.codex.md` with the same resolution, fan-out, plan-review, and final-review behavior. Explain that only the primary fixes after the two reports and that the secondary is a read-only pair of eyes.
3. Update `docs/testing.md` manual checks for seven-key validation, `review_model2` absence/equality/distinctness, no `SIMPLEPOWER_REVIEW_MODEL2`, initial coordinator triage, qualified fan-out, dual plan review, and primary-only final fixes.
4. Add root `simplepower.toml.example` with comments identifying it as a copyable example rather than active repository configuration. Include the base keys and `review_model2 = "gpt-5.6-luna-max"`, explaining that removing it or setting it equal to `review_model` leaves one reviewer.
5. Update plugin long description from a single-review claim to a primary REVIEW-tier review+fix pass that can be paired with an optional distinct read-only reviewer. Do not change the manifest version, skills path, or plugin packaging layout.

**Verification:**

```bash
timeout 30s python3 -c 'import pathlib, tomllib; tomllib.loads(pathlib.Path("simplepower.toml.example").read_text()); print("example TOML valid")'
timeout 30s rg -n 'review_model2|gpt-5.6-luna-max|initial triage|fan-out|primary|read-only|four mandatory model tiers' README.md docs/README.codex.md docs/testing.md .codex-plugin/plugin.json simplepower.toml.example
timeout 30s bash -c '! git ls-files --error-unmatch simplepower.toml >/dev/null 2>&1'
timeout 30s git diff --check -- README.md docs/README.codex.md docs/testing.md .codex-plugin/plugin.json simplepower.toml.example
```

The TOML parser must succeed, the documentation search must show aligned terms, the third command must confirm that active `simplepower.toml` is not tracked, and the whitespace check must be clean.

**Completion report:** List changed and created files; identify the Chinese and English README sections; report all command results; confirm no active `simplepower.toml` was created or tracked.

### Task 4: Replace retired static assumptions with contract coverage

**Goal:** Make the static harness enforce the new configuration, on-demand fan-out, and primary-only dual-review contract without coupling it to obsolete exact-one wording.

**Contract inputs:** OD-IC-1, OD-IC-2, OD-IC-3, OD-IC-4, OD-IC-5, and OD-IC-6.

**Serialization required:** No. Task 4 owns only the static harness and may assert the Interface Contract while the other workers create the source text it checks.

**Write scope:**

- `tests/simplepower-static/run-tests.sh`

**Parallel:** Yes, with Tasks 1, 2, and 3.

**Risk:** Medium — brittle assertions could reject correct future wording, while weak assertions could permit unsafe dispatch regression.

**Model tier:** FAST — resolved `gpt-5.3-codex-spark` with `xhigh` reasoning.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**

1. Preserve the assertion that active `simplepower.toml` is untracked, add an existence/content check for `simplepower.toml.example`, and change configuration assertions from a six-key-only schema to six base keys plus optional `review_model2`, including no default and no secondary environment override.
2. Replace exact-one explorer assertions with stable anchors for initial coordinator triage, later qualified escalation, one-or-more distinct angles, no automatic startup dispatch, read-only/self-contained isolation, runtime capacity, synthesis, and stop-on-batch failure. Add negative searches restricted to active policy/documentation paths so historical plans are not rewritten or tested as live contract.
3. Add coverage that a distinct secondary model enables two concurrent read-only plan reviewers and two concurrent initial final reviewers, both reports precede primary fixes, the secondary never edits, absent/equal values preserve one primary path, and dispatch failure does not downgrade to a partial review.
4. Add prompt/template checks for `secondary-review-prompt.md`, dual-mode primary instructions, and retained non-recursion/no-commit/scratch-ref restrictions. Preserve the invariant that exactly one primary REVIEW-tier review+fix agent is the only writer.
5. Update README, Codex-doc, plugin-metadata, and testing-guide expectations so they no longer assert a single unqualified review pass or a single optional explorer.

**Verification:**

```bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 30s rg -n 'review_model2|initial triage|one or more|primary.*fix|secondary.*read-only' tests/simplepower-static/run-tests.sh
```

Both commands must exit 0. Do not run the full static suite in this parallel worker: it reads the Task 1–3 source files and therefore runs only in Quick Verification after all four workers have completed. The harness search must show the new behavioral anchors rather than retired exact-one requirements.

**Completion report:** List changed assertions; report each command and status; explain how the checks distinguish a single primary fixer from an optional second read-only reviewer.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---|---|---|---|
| Task 1 | `sp-impl` | BEST | `gpt-5.6-terra` | `max` | Cross-skill policy that governs optional agent launches and configuration validation. |
| Task 2 | `sp-impl` | BEST | `gpt-5.6-terra` | `max` | Mandatory review lifecycle, prompt authority, and worktree safety are behavior-shaping. |
| Task 3 | `sp-impl` | NORMAL | `gpt-5.6-luna` | `max` | Localized but policy-sensitive documentation, metadata, and example configuration. |
| Task 4 | `sp-impl` | FAST | `gpt-5.3-codex-spark` | `xhigh` | Focused assertion updates against a detailed approved contract. |
| Plan review | plan document reviewer | REVIEW | `gpt-5.6-sol` | `xhigh` | Current planning configuration has no `review_model2`; use the existing REVIEW plan-review route. |
| Quick verification | verifier | FAST | `gpt-5.3-codex-spark` | `xhigh` | Repository-specific syntax and static validation after all edits. |
| Final review+fix | primary reviewer/fixer | REVIEW | `gpt-5.6-sol` | `xhigh` | One primary REVIEW agent retains the only final-edit authority. |

After Task 2 is implemented, any future workflow with a distinct effective `review_model2` uses that parsed model and effort as a conditional read-only secondary review route. It is not a FAST/NORMAL/BEST/REVIEW tier and is absent from this plan's current configuration.

## Plan Review

Self-review before reviewer dispatch confirms:

- OD-IC-1 through OD-IC-6 provide exact configuration, dispatch, safety, documentation, and verification contracts for every task.
- The four implementation tasks have disjoint write scopes and may dispatch in aggregate from the Interface Contract.
- Task 2 preserves one primary REVIEW-tier review+fix writer while adding only a conditional read-only second reviewer, so the target workflow does not create concurrent writers or extra checkpoints.
- The plan lists a concrete example path, all prompt/template files, unchanged four environment overrides, and no active tracked `simplepower.toml`.
- No visual aid is needed; no worker or reviewer is authorized to commit; all verification commands have timeouts.

Before first review, create `refs/simplepower/scratch/20260713-155017-f6e737a/plan-review/before` with a temporary index containing only `docs/simplepower/plans/2026-07-13-on-demand-explorer-fanout-and-dual-review.md`.

Dispatch one current REVIEW plan reviewer with `model="gpt-5.6-sol"`, `reasoning_effort="xhigh"`, and `fork_turns="none"`, using `skills/writing-plans/plan-document-reviewer-prompt.md`. Its self-contained brief must name the plan path, the complete approved design in this plan, the fact that this plan intentionally evolves the six-base-key schema by adding optional `review_model2`, the scratch run id, exact review criteria, and read-only/no-recursion restrictions. The reviewer must evaluate the target dual-review design while recognizing that the current planning dispatch itself has only one configured reviewer.

If the reviewer reports recoverable issues, the coordinator changes only this plan, reruns the affected self-review checks, creates `refs/simplepower/scratch/20260713-155017-f6e737a/plan-review/after-<n>`, and sends the same reviewer a concrete diff:

```bash
git diff refs/simplepower/scratch/20260713-155017-f6e737a/plan-review/before refs/simplepower/scratch/20260713-155017-f6e737a/plan-review/after-1 -- docs/simplepower/plans/2026-07-13-on-demand-explorer-fanout-and-dual-review.md
```

For later revisions, compare the immediately preceding `after-<n>` ref to the next one. Keep the reviewer open through recoverable issue loops; close it only after approval, an unrecoverable interruption, or explicit user direction.

After reviewer approval, request one combined user approval of the reviewed plan, this model allocation, and immediate current-session execution. Do not create the accepted-plan checkpoint before that approval.

## Quick Verification

After all four workers finish and the coordinator validates actual diffs against File Ownership, create `refs/simplepower/scratch/20260713-155017-f6e737a/quick-verifier/before` over every Task 1–4 file. Dispatch the FAST quick verifier with `model="gpt-5.3-codex-spark"`, `reasoning_effort="xhigh"`, `fork_turns="none"`, and a self-contained prompt based on `skills/subagent-driven-development/quick-verifier-prompt.md`.

The quick verifier runs:

```bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 30s python3 -c 'import pathlib, tomllib; tomllib.loads(pathlib.Path("simplepower.toml.example").read_text()); print("example TOML valid")'
timeout 30s git diff --check
```

All commands must exit 0. The verifier may fix only tiny typo-level errors that directly cause a command failure and only in its approved ownership. If it changes a file, create `refs/simplepower/scratch/20260713-155017-f6e737a/quick-verifier/after` and inspect the corresponding scratch diff before the quick-verified implementation checkpoint.

## Final Review And Fix

After the quick-verified implementation checkpoint, create `refs/simplepower/scratch/20260713-155017-f6e737a/review-fix/before` over the same Task 1–4 files.

Dispatch the primary REVIEW review+fix agent with `model="gpt-5.6-sol"`, `reasoning_effort="xhigh"`, `fork_turns="none"`, `skills/subagent-driven-development/review-fix-prompt.md`, and the accepted plan, Interface Contract, ownership, worker reports, quick-verification evidence, and scratch context. Because Task 2 changes the target lifecycle, it must apply the new optional-secondary contract during this execution: if a distinct `review_model2` is then configured, dispatch the secondary read-only reviewer concurrently from `secondary-review-prompt.md`, collect both reports, and authorize only the primary to fix after synthesis. If none is configured or it equals the primary, preserve direct one-primary review+fix.

If the primary edits, create `refs/simplepower/scratch/20260713-155017-f6e737a/review-fix/after` and inspect:

```bash
git diff refs/simplepower/scratch/20260713-155017-f6e737a/review-fix/before refs/simplepower/scratch/20260713-155017-f6e737a/review-fix/after -- skills/using-simplepower/references/simplepower-config.md skills/brainstorming/SKILL.md skills/ro/SKILL.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/review-fix-prompt.md skills/subagent-driven-development/secondary-review-prompt.md skills/using-simplepower/references/codex-tools.md README.md docs/README.codex.md docs/testing.md .codex-plugin/plugin.json simplepower.toml.example tests/simplepower-static/run-tests.sh
```

The primary and secondary may not create refs or commits. A distinct configured secondary that cannot launch stops final review; it does not authorize a single-review downgrade.

## Commit Checkpoints

1. **Accepted plan checkpoint:** After the current REVIEW plan reviewer approves and the user gives combined approval for this reviewed plan, allocation, and immediate execution, commit only `docs/simplepower/plans/2026-07-13-on-demand-explorer-fanout-and-dual-review.md`. Then delete successful `plan-review` scratch refs.
2. **Quick-verified implementation checkpoint:** After Tasks 1–4 complete and all quick-verification commands pass, commit the approved implementation files. Then delete successful `quick-verifier` scratch refs.
3. **Final checkpoint:** After the primary review+fix lifecycle and final verification pass, commit any remaining approved implementation changes. Do not create an empty commit. Then delete successful `review-fix` scratch refs.

If scratch-ref creation or a checkpoint fails, stop the affected phase, preserve evidence, and report this manual cleanup command rather than deleting refs:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/20260713-155017-f6e737a" | while read -r ref; do git update-ref -d "$ref"; done
```

## Current-Session Auto-Dispatch

After combined approval and the accepted-plan checkpoint, immediately invoke `simplepower:subagent-driven-development` in this session with:

```text
Execute `docs/simplepower/plans/2026-07-13-on-demand-explorer-fanout-and-dual-review.md` with aggregate parallel implementation from OD-IC-1 through OD-IC-6. Dispatch Tasks 1, 2, 3, and 4 together because their write scopes do not overlap. Use the approved BEST, BEST, NORMAL, and FAST allocations with `fork_turns="none"` and self-contained prompts. Run the FAST quick verifier after all workers, create the quick-verified implementation checkpoint, then apply the Task 2 conditional review lifecycle: one primary REVIEW review+fix agent and, only for a distinct effective `review_model2`, a concurrent read-only secondary reviewer before primary-only fixes. Run final verification and create the final checkpoint only if changes remain.
```

## Final Verification

After final review completes, the coordinator runs:

```bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s python3 -c 'import pathlib, tomllib; tomllib.loads(pathlib.Path("simplepower.toml.example").read_text()); print("example TOML valid")'
timeout 30s rg -n 'optionally dispatch one read-only|select one read-only explorer|spawn exactly one read-only|initial explorer necessary' README.md docs/README.codex.md docs/testing.md skills/brainstorming/SKILL.md skills/ro/SKILL.md skills/using-simplepower/references/simplepower-config.md
timeout 30s git diff --check
timeout 30s git status --short
timeout 30s git for-each-ref --format='%(refname)' "refs/simplepower/scratch/20260713-155017-f6e737a"
```

The first seven commands must exit 0. The focused negative search must exit 1, proving active policy and documentation contain no retired exact-one optional-explorer contract. The remaining timed checks must exit 0. Before the final checkpoint, status may contain only approved implementation files; after it, it must be clean. The final scratch-ref check must produce no output after successful phase cleanup.
