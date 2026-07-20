# Token-Efficient Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run exactly one final review+fix agent using `final_review_model` (or `review_model` when absent) before final verification and final commit.

**Goal:** Reduce normal Simple Power token use while preserving brainstorming, a cheap quick-verifier subagent, and parallel implementation when it has clear value.

**Design Summary:** Keep brainstorming through explicit design approval. Planning becomes adaptive: a compact plan routes one cohesive implementation package to the main agent, while a full plan routes at least two independent or specialized packages to grouped `sp-impl` workers. The main agent self-reviews plans and performs final implementation review and in-scope fixes. The FAST quick-verifier subagent remains. The resulting workflow uses two coordinator checkpoints, removes plan-review and final-review subagent machinery, keeps closely related code and tests together, and accepts the old review settings as deprecated compatibility keys without using or repeating them in normal plans. This implementation run itself follows the currently installed three-checkpoint and reviewer rules until the new workflow is committed.

**Architecture:** `simplepower:writing-plans` selects and records either `Main agent` or `Grouped workers` from explicit cohesion and specialization criteria. `simplepower:subagent-driven-development` remains the compatible execution entry point but becomes an adaptive coordinator: it implements a single package directly or dispatches grouped, non-overlapping worker packages, then always dispatches the FAST quick verifier and finishes with coordinator-owned review, fixes, verification, and the final checkpoint. Canonical policy stays in skills and references; generated plans and worker prompts contain only route-specific and package-specific context.

**Tech Stack:** Markdown Codex skills and prompt templates, Bash static checks, JSON plugin metadata, TOML configuration documentation.

**Model Allocation:** For this transition run, validate the seven base keys `use_subagent`, `skip_final_review`, `subagent_model`, `review_model`, `best_model`, `normal_model`, and `fast_model`, plus optional `review_model2` and `final_review_model`. Resolve per key from built-in defaults, `/home/gary/.codex/simplepower.toml`, the absent repository `simplepower.toml`, supported non-empty `SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SKIP_FINAL_REVIEW`, `SIMPLEPOWER_SUBAGENT_MODEL`, `SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_FINAL_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`, `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL` environment overrides, then current-session instructions. Missing higher-layer keys inherit; every present TOML file and non-empty override must validate even if a higher layer replaces its value. `review_model2` has no environment override. An absent `final_review_model` falls back to fully resolved `review_model`; an absent or equal `review_model2` keeps one plan reviewer. Parse model values at the final dash and accept only `low`, `medium`, `high`, `xhigh`, `max`, or `ultra`. Effective values are FAST `gpt-5.3-codex-spark-xhigh`, NORMAL `gpt-5.5-high`, BEST `gpt-5.5-xhigh`, REVIEW `gpt-5.5-xhigh`, and final review `gpt-5.5-xhigh`; `review_model2` is absent, so this run uses one plan reviewer. The target workflow keeps FAST/NORMAL/BEST for implementation allocation and quick verification, while recognizing the review-related settings as deprecated no-ops in the normal chain.

**Commit Policy:** This transition run uses the currently required three coordinator checkpoints: accepted reviewed plan after combined approval, quick-verified implementation, and final review/fix plus final verification. Workers, the plan reviewer, quick verifier, and final review+fix agent do not commit. The resulting workflow documented and implemented by this plan uses two coordinator checkpoints—approved plan and final reviewed/verified implementation—and keeps only quick-verifier scratch refs. Scratch refs are coordinator-owned local diff anchors under `refs/simplepower/scratch/<run-id>/`, are not accepted history, and are cleaned after successful checkpoints. On user stops, blockers, or failed checkpoint commits, preserve them as evidence and report `git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>" | while read -r ref; do git update-ref -d "$ref"; done` for manual cleanup.

---

## Interface Contract

### Adaptive planning contract

- Every new plan contains `Design Summary`, `Implementation Route`, exact changed files, implementation steps, risks, quick verification commands, final verification commands, and two checkpoint conditions.
- `Implementation Route: Main agent` is selected when all edits form one cohesive write package and no specialized delegation materially improves execution.
- `Implementation Route: Grouped workers` is selected only when there are at least two independent, non-overlapping write packages or specialized work that materially benefits from delegation.
- Grouped-worker plans additionally contain `Interface Contract`, `File Ownership`, `Worker Packages`, serialization decisions, and FAST/NORMAL/BEST model allocation.
- The main agent performs a concise plan self-review before user approval. No plan-review agent, `plan-review/*` scratch ref, secondary reviewer, or plan-review prompt participates in the target workflow.
- User approval covers the plan, selected route, any worker/model allocation, and immediate current-session execution.

### Cohesive package contract

- A worker package owns a coherent subsystem or documentation/testing responsibility, not an individual file or tiny task.
- Closely related production changes and tests stay in the same package unless their write scopes and contracts are genuinely independent.
- Capacity changes scheduling only; it never causes artificial package splitting or marks work serialized.
- A grouped-worker prompt contains the design summary, only the relevant shared contract entries, exact read/write scope, complete package instructions, exact verification commands, and completion report requirements. It does not paste the complete plan or global configuration/commit-policy boilerplate.

### Adaptive execution contract

- `simplepower:subagent-driven-development` remains the execution skill name for compatibility.
- On `Main agent`, the coordinator edits the approved files directly and does not dispatch an `sp-impl` worker.
- On `Grouped workers`, the coordinator dispatches all ready, non-conflicting cohesive packages with exact `fork_turns="none"`, then lifecycle-closes them after inspecting reports and diffs.
- Switching the approved implementation route requires fresh user approval.
- Implied file-scope omissions may be corrected by the coordinator; true scope or strategy expansion requires fresh user approval.

### Verification and review contract

- The FAST quick verifier remains mandatory after all implementation edits. It receives only the approved changed-file list, relevant behavior contract, worker/main-agent result summary, and exact timed commands.
- Quick-verifier edits remain limited to tiny typo-level fixes and are bracketed by coordinator-owned `quick-verifier/before` and optional `quick-verifier/after` scratch refs.
- Non-trivial quick-verifier failures return to the main agent for diagnosis and in-scope repair, followed by rerunning verification. They do not trigger another implementation or review subagent.
- After quick verification, the main agent inspects the complete implementation diff, checks plan compliance and quality, makes in-scope fixes directly, and runs final verification.
- The target flow has no final review+fix agent, no `review-fix/*` scratch refs, and no intermediate quick-verified implementation commit.
- The target flow commits the approved plan once and commits the final reviewed/verified implementation once. It does not create empty commits.

### Compatibility configuration contract

- `review_model`, `review_model2`, `final_review_model`, and `skip_final_review` remain recognized and validated so existing home and repository TOML files do not fail.
- These settings are documented as deprecated compatibility keys and do not control normal brainstorming-to-implementation execution.
- Active model routing uses `best_model`, `normal_model`, and `fast_model`; optional explorer routing continues to use `use_subagent` and `subagent_model`.
- Normal generated plans omit review-model resolution, review allocation, and final-review-skip boilerplate.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---|---|---|
| `skills/brainstorming/SKILL.md` | Task 1 | modify | Hand off approved design to adaptive planning | Planning package only |
| `skills/writing-plans/SKILL.md` | Task 1 | modify | Define compact/full plans, route selection, self-review, and two checkpoints | Planning package only |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 1 | delete | Remove retired plan-review agent prompt | Planning package only |
| `skills/subagent-driven-development/SKILL.md` | Task 2 | modify | Implement direct/grouped execution, quick verification, main review, and two-checkpoint lifecycle | Execution package only |
| `skills/subagent-driven-development/implementer-prompt.md` | Task 2 | modify | Replace tiny-task/full-plan repetition with cohesive package context | Execution package only |
| `skills/subagent-driven-development/quick-verifier-prompt.md` | Task 2 | modify | Preserve limited FAST verification and return non-trivial failures to coordinator | Execution package only |
| `skills/subagent-driven-development/review-fix-prompt.md` | Task 2 | delete | Remove retired final review+fix agent prompt | Execution package only |
| `skills/subagent-driven-development/scratch-ref-workflow.md` | Task 2 | modify | Retain only quick-verifier scratch phases and cleanup mechanics | Execution package only |
| `AGENTS.md` | Task 3 | modify | Replace three-checkpoint/reviewer contributor rules with approved adaptive policy | Documentation package only |
| `README.md` | Task 3 | modify | Document adaptive route, main-agent reviews, quick verifier, compatibility keys, and two checkpoints in both languages | Documentation package only |
| `docs/README.codex.md` | Task 3 | modify | Update Codex installation/use guide for the target workflow | Documentation package only |
| `.codex-plugin/plugin.json` | Task 3 | modify | Update user-facing capability description | Documentation package only |
| `simplepower.toml.example` | Task 3 | modify | Mark review settings as deprecated compatibility keys | Documentation package only |
| `skills/using-simplepower/SKILL.md` | Task 3 | modify | Describe the adaptive approved chain without mandatory reviewers | Documentation package only |
| `skills/using-simplepower/references/simplepower-config.md` | Task 3 | modify | Preserve validation compatibility while removing active review routing | Documentation package only |
| `skills/using-simplepower/references/codex-tools.md` | Task 3 | modify | Remove plan/final reviewer dispatch mappings and add direct/grouped execution mapping | Documentation package only |
| `docs/testing.md` | Task 4 | modify | Document tests and manual expectations for both routes | Test package only |
| `tests/simplepower-static/run-tests.sh` | Task 4 | modify | Assert the adaptive flow and reject retired review machinery | Test package only |
| `tests/skill-triggering/prompts/approved-planning-handoff.txt` | Task 4 | modify | Exercise adaptive execution handoff | Test package only |
| `tests/explicit-skill-requests/prompts/action-oriented.txt` | Task 4 | modify | Request route-aware execution, quick verification, and main review | Test package only |
| `tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt` | Task 4 | modify | Define expected direct/grouped behavior | Test package only |
| `tests/explicit-skill-requests/prompts/subagent-driven-development-please.txt` | Task 4 | modify | Remove unconditional parallel-worker wording | Test package only |
| `tests/explicit-skill-requests/prompts/skip-formalities.txt` | Task 4 | modify | Preserve explicit invocation with adaptive routing | Test package only |
| `tests/explicit-skill-requests/prompts/mid-conversation-execute-plan.txt` | Task 4 | modify | Preserve mid-conversation adaptive execution | Test package only |
| `tests/explicit-skill-requests/prompts/codex-suggested-it.txt` | Task 4 | modify | Describe adaptive execution recommendation | Test package only |
| `tests/explicit-skill-requests/prompts/after-planning-flow.txt` | Task 4 | modify | Update post-planning route expectations | Test package only |

## Implementation Tasks

### Task 1: Rewrite adaptive planning policy

**Goal:** Make planning compact for direct implementation and full only for grouped workers, with main-agent self-review and no plan-review dispatch.

**Contract inputs:** Adaptive planning contract; cohesive package contract; approved design sections 1–3.

**Serialization required:** No.

**Write scope:** `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`, and deletion of `skills/writing-plans/plan-document-reviewer-prompt.md`.

**Parallel:** Yes, with Tasks 2–4.

**Risk:** High because this changes the authoritative design-to-execution handoff and plan schema.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:** Preserve brainstorming approval and approved-path gates. Define exact route-selection criteria and compact/full plan schemas. Require main self-review, combined approval, immediate execution, package grouping, quick verification, main final review, and two checkpoints. Delete all active plan-review dispatch, reviewer-loop, scratch-ref, and reviewer-prompt references.

**Implementation steps:**

1. Update the brainstorming handoff summary so approved designs pass cohesion, specialization, constraints, and success criteria to adaptive planning.
2. Rewrite `writing-plans` around one shared compact core plus grouped-worker-only sections. Keep exact paths, verification commands, no placeholders, and approved-path enforcement.
3. Define the route decision before user approval and prohibit silent route switches.
4. Replace reviewer dispatch with a concise coordinator self-review checklist.
5. Replace three future checkpoints with approved-plan and final-implementation checkpoints.
6. Delete `plan-document-reviewer-prompt.md` and remove every active reference to it.

**Verification:**

- `timeout 30s rg -n 'Implementation Route|Main agent|Grouped workers|cohesive|quick verifier|two coordinator' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md` must show the target contracts.
- `timeout 30s rg -n 'plan-document-reviewer|spawn_agent.*plan reviewer|plan-review/before|plan-review/after' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md` must return no active matches.
- `timeout 30s test ! -e skills/writing-plans/plan-document-reviewer-prompt.md` must pass.

**Completion report:** List changed/deleted files, commands and results, route-schema decisions, and unresolved ambiguity.

### Task 2: Rewrite adaptive execution policy

**Goal:** Let the main agent implement one cohesive package directly, group genuinely parallel workers, retain the FAST verifier, and move final review/fixes to the main agent.

**Contract inputs:** Cohesive package contract; adaptive execution contract; verification and review contract.

**Serialization required:** No.

**Write scope:** `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/implementer-prompt.md`, `skills/subagent-driven-development/quick-verifier-prompt.md`, `skills/subagent-driven-development/scratch-ref-workflow.md`, and deletion of `skills/subagent-driven-development/review-fix-prompt.md`.

**Parallel:** Yes, with Tasks 1, 3, and 4.

**Risk:** High because this changes implementation ownership, failure routing, review authority, and checkpoint timing.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:** Preserve approved-path, file-scope, lifecycle, no-worker-commit, and exact `fork_turns="none"` rules. Add direct implementation. Group worker tasks by cohesive context. Keep quick-verifier dispatch and scratch anchors. Remove final review agent and review-fix scratch phase. Let the coordinator repair in-scope quick failures and conduct final review.

**Implementation steps:**

1. Rewrite the lifecycle to validate the approved route, execute direct or grouped work, quick-verify, coordinator-review/fix, final-verify, and conditionally commit.
2. Define grouped scheduling without tiny task splitting; capacity queues whole approved packages.
3. Compact the worker prompt around package-specific context while keeping it self-contained.
4. Keep the quick verifier restricted to tiny typo fixes; report all non-trivial failures to the coordinator.
5. Reduce scratch mechanics to quick-verifier before/optional-after refs and cleanup.
6. Delete `review-fix-prompt.md` and remove active references and final-review model routing from execution.

**Verification:**

- `timeout 30s rg -n 'Implementation Route|Main agent|Grouped workers|cohesive package|quick verifier|main agent.*review|coordinator.*review' skills/subagent-driven-development` must show the target lifecycle.
- `timeout 30s rg -n 'review-fix-prompt|review-fix/before|review-fix/after|final review\+fix agent' skills/subagent-driven-development` must return no active matches.
- `timeout 30s test ! -e skills/subagent-driven-development/review-fix-prompt.md` must pass.
- `timeout 30s rg -n 'fork_turns="none"|tiny typo-level|NON_TRIVIAL_FAILURES' skills/subagent-driven-development` must retain isolation and verifier boundaries.

**Completion report:** List changed/deleted files, commands and results, direct/grouped routing behavior, and unresolved risks.

### Task 3: Update configuration and user-facing contracts

**Goal:** Document the adaptive workflow consistently while preserving legacy review-key validation compatibility.

**Contract inputs:** All Interface Contract sections, especially compatibility configuration contract.

**Serialization required:** No.

**Write scope:** `AGENTS.md`, `README.md`, `docs/README.codex.md`, `.codex-plugin/plugin.json`, `simplepower.toml.example`, `skills/using-simplepower/SKILL.md`, `skills/using-simplepower/references/simplepower-config.md`, and `skills/using-simplepower/references/codex-tools.md`.

**Parallel:** Yes, with Tasks 1, 2, and 4.

**Risk:** Medium because broad wording must stay aligned across English, Chinese, contributor, configuration, and tool-mapping documentation.

**Model tier:** NORMAL — `gpt-5.5`, reasoning effort `high`.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:** Describe direct versus grouped routes, cohesive packages, main-agent plan/final review, retained FAST verifier, two checkpoints, and quick-only scratch refs. Keep review-related TOML and environment values accepted and validated but mark them deprecated/no-op for the normal chain. Preserve optional explorer semantics, resolution order, AGENTS exclusion, and fork isolation.

**Implementation steps:**

1. Update contributor policy and plugin metadata.
2. Rewrite active workflow sections in both README guides without altering fork attribution or install instructions.
3. Update the example TOML with explicit compatibility comments.
4. Update the shared configuration contract: validate legacy keys and overrides, but remove their active normal-flow routing effects.
5. Update Codex tool mappings to remove plan/final reviewer dispatches and describe direct implementation, grouped workers, and the FAST verifier.
6. Update `using-simplepower` handoffs to the adaptive flow.

**Verification:**

- `timeout 30s rg -n 'Main agent|Grouped workers|cohesive|deprecated|quick verifier|two coordinator' AGENTS.md README.md docs/README.codex.md .codex-plugin/plugin.json simplepower.toml.example skills/using-simplepower` must show target wording.
- `timeout 30s rg -n 'primary plan reviewer|secondary plan reviewer|final review\+fix agent|three coordinator checkpoints' AGENTS.md README.md docs/README.codex.md .codex-plugin/plugin.json skills/using-simplepower` must return no active normal-flow claims; historical descriptions are out of scope.
- `timeout 30s git diff --check -- AGENTS.md README.md docs/README.codex.md .codex-plugin/plugin.json simplepower.toml.example skills/using-simplepower` must pass.

**Completion report:** List changed files, commands and results, compatibility wording, and any cross-document concern.

### Task 4: Replace static and fixture expectations

**Goal:** Make tests enforce both adaptive execution routes and reject the retired reviewer machinery.

**Contract inputs:** Adaptive planning contract; adaptive execution contract; verification/review contract; compatibility configuration contract.

**Serialization required:** No.

**Write scope:** `docs/testing.md`, `tests/simplepower-static/run-tests.sh`, `tests/skill-triggering/prompts/approved-planning-handoff.txt`, and all seven listed `tests/explicit-skill-requests/prompts/*.txt` files in File Ownership.

**Parallel:** Yes, with Tasks 1–3. This package writes only tests/docs and relies on the approved Interface Contract while the other packages edit implementation documents.

**Risk:** Medium because the large static contract suite must stop enforcing retired behavior while retaining unrelated safeguards.

**Model tier:** NORMAL — `gpt-5.5`, reasoning effort `high`.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:** Replace assertions for mandatory plan/final reviewers, four active tiers, review scratch phases, and three checkpoints. Add assertions for adaptive route criteria, compact/full plans, direct main implementation, cohesive workers, mandatory FAST verifier, coordinator final review, quick-only scratch refs, legacy config acceptance/deprecation, two checkpoints, deleted prompts, and package-focused worker context. Preserve unrelated namespace, visual companion, explorer, installation, and pruning tests.

**Implementation steps:**

1. Rewrite only workflow-related static assertions; do not weaken unrelated checks.
2. Add negative checks for plan-review/final-review dispatch and prompt files.
3. Add positive checks for both routes and their selection rules.
4. Update explicit invocation fixtures so they request adaptive execution rather than unconditional parallelism and final review agents.
5. Update testing documentation and manual smoke expectations.

**Verification:**

- `timeout 120s tests/simplepower-static/run-tests.sh` must pass after all packages land.
- `timeout 30s bash -n tests/simplepower-static/run-tests.sh tests/skill-triggering/run-all.sh tests/explicit-skill-requests/run-all.sh` must pass.
- `timeout 30s git diff --check -- docs/testing.md tests/simplepower-static/run-tests.sh tests/skill-triggering/prompts tests/explicit-skill-requests/prompts` must pass.

**Completion report:** List changed files, removed and added assertion categories, commands/results, and any stale fixture concern.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---|---|---|---|
| Task 1 | `sp-impl` planning policy | BEST | `gpt-5.5` | `xhigh` | Broad behavior-shaping plan-schema rewrite |
| Task 2 | `sp-impl` execution policy | BEST | `gpt-5.5` | `xhigh` | High-risk ownership and lifecycle rewrite |
| Task 3 | `sp-impl` configuration/docs | NORMAL | `gpt-5.5` | `high` | Broad but contract-defined documentation alignment |
| Task 4 | `sp-impl` tests/fixtures | NORMAL | `gpt-5.5` | `high` | Large static assertion update requiring careful preservation |
| Plan review for this transition run | Primary read-only reviewer | REVIEW | `gpt-5.5` | `xhigh` | Current installed workflow requires one plan reviewer; `review_model2` is absent |
| Quick verification | Limited-fix verifier | FAST | `gpt-5.3-codex-spark` | `xhigh` | Cheap mechanical checks retained by approved design |
| Final review for this transition run | One review+fix agent | `final_review_model` | `gpt-5.5` | `xhigh` | Current installed workflow requires this final pass before the new policy takes effect |

## Plan Review

The coordinator self-review must confirm before the transition-run reviewer is dispatched:

- Every approved design decision appears in the Interface Contract.
- All changed/deleted files are owned exactly once and worker scopes do not overlap.
- The target direct/grouped route rules are objective and selected before execution.
- Legacy review settings remain accepted and validated but do not affect the target normal chain.
- The target flow keeps the FAST verifier and only quick-verifier scratch refs.
- The plan clearly separates this transition run's current three-checkpoint/reviewer obligations from the resulting two-checkpoint/main-review workflow.
- All verification commands have timeouts and no task contains a placeholder, worker commit, fallback route, or pre-approved scope reduction.

For this transition run, use run id `20260720-013004-1c28b4f` and the existing `refs/simplepower/scratch/20260720-013004-1c28b4f/plan-review/before` snapshot, then dispatch one read-only REVIEW reviewer with `fork_turns="none"`. If it finds blockers, revise this plan, create `plan-review/after-<n>`, and return the exact diff command `git diff refs/simplepower/scratch/20260720-013004-1c28b4f/plan-review/before refs/simplepower/scratch/20260720-013004-1c28b4f/plan-review/after-<n> -- docs/simplepower/plans/2026-07-20-token-efficient-workflow.md` to the same reviewer. For subsequent revisions, compare the previous `after-<n>` ref with the new `after-<n+1>` ref. After combined user approval, commit the plan, clean the plan-review refs, and immediately invoke `simplepower:subagent-driven-development`.

## Quick Verification

After all four implementation packages finish:

1. Create `refs/simplepower/scratch/<run-id>/quick-verifier/before` for every implementation file in File Ownership except this plan.
2. Dispatch the FAST quick verifier with exact `fork_turns="none"` and these commands:
   - `timeout 120s tests/simplepower-static/run-tests.sh` — expected: all static checks pass.
   - `timeout 30s bash -n tests/simplepower-static/run-tests.sh tests/skill-triggering/run-all.sh tests/explicit-skill-requests/run-all.sh` — expected: no shell syntax errors.
   - `timeout 30s git diff --check` — expected: no whitespace errors.
3. Permit only tiny typo-level fixes. Return structural or behavioral failures to the coordinator.
4. If the verifier edits files, create `quick-verifier/after` and inspect the scratch diff.
5. Create the transition run's quick-verified implementation checkpoint, then clean quick-verifier scratch refs.

## Final Review And Fix

For this transition run only, create `review-fix/before` after the quick-verified checkpoint and dispatch exactly one `gpt-5.5`/`xhigh` final review+fix agent with exact `fork_turns="none"`. Give it the approved plan, complete implementation diff, ownership, package reports, and quick-verification evidence. It may fix only in-scope files, must not commit, and must report findings, fixes, focused checks, and remaining risks. Create `review-fix/after` only if it edits files and inspect that scratch diff before final verification.

## Commit Checkpoints

This transition run has exactly three coordinator checkpoints:

1. Commit this reviewed plan after combined user approval and before implementation dispatch.
2. Commit all implementation edits after the FAST quick verifier passes.
3. Commit only remaining final-review or verification edits after final verification; record a no-empty-commit outcome if none remain.

The resulting workflow encoded by the implementation has exactly two coordinator checkpoints: approved plan and final reviewed/verified implementation. Workers and verifiers never commit in either workflow.

## Current-Session Auto-Dispatch

After the transition-run plan reviewer approves, ask for one combined approval covering this plan, its four-package allocation, and immediate execution. After approval, commit the plan and invoke `simplepower:subagent-driven-development` in this session. Dispatch the four non-conflicting packages concurrently subject to capacity, using only each package's relevant contract and scope. Do not switch this approved grouped route to direct implementation without fresh approval.

## Verification

After the transition-run final review/fix phase, the coordinator runs:

1. `timeout 120s tests/simplepower-static/run-tests.sh` — all static workflow assertions pass.
2. `timeout 120s npm --prefix tests/brainstorm-server test` — brainstorm server integration tests pass.
3. `timeout 120s tests/codex-plugin-sync/test-sync-to-codex-plugin.sh` — plugin sync and marketplace metadata checks pass.
4. `timeout 30s bash -n tests/simplepower-static/run-tests.sh tests/skill-triggering/run-all.sh tests/explicit-skill-requests/run-all.sh` — changed shell workflows parse.
5. `timeout 30s git diff --check HEAD^` — final implementation history has no whitespace errors.
6. `timeout 30s git status --short` — only expected final-review fixes may remain before the final commit condition.
7. `timeout 30s git for-each-ref --format='%(refname)' "refs/simplepower/scratch/20260720-013004-1c28b4f"` — no scratch refs remain after successful phase cleanup.

The Codex-backed explicit-skill and skill-triggering fixture runners remain documented manual/extended checks because they invoke external Codex sessions; their prompt contracts and shell syntax are covered here without spending additional model tokens during this token-reduction change.
