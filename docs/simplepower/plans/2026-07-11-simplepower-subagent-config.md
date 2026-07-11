# Simple Power Subagent Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Add strict repository-or-home `simplepower.toml` configuration for optional investigative subagents and require isolated context for every Simple Power dispatch.

**Design Summary:** Add a centralized, instruction-driven configuration contract with top-level `use_subagent` and `subagent_model` keys. A repository-root `simplepower.toml` completely replaces `~/.codex/simplepower.toml` when present; missing keys default to `false` and `gpt-5.6-luna-xhigh`; explicit current-session user instructions override the selected file; malformed or invalid config and enabled-agent capability/model/spawn failures stop the workflow. The switch governs only brainstorming context exploration, `simplepower:ro` initial analysis, and systematic-debugging investigation. Mandatory plan review, implementation, quick verification, and review+fix keep FAST/NORMAL/BEST/REVIEW allocation. Every Simple Power spawn passes `fork_turns="none"` with a self-contained prompt.

**Architecture:** `skills/using-simplepower/references/simplepower-config.md` is the single source of truth for discovery, file-level replacement, defaults, validation, model parsing, and failures. The three configurable skills consume it at activation. The Codex tool mapping and all active dispatch workflows enforce `fork_turns="none"`; exact file ownership separates contract behavior, debugging behavior, dispatch wording, tests, and docs for aggregate parallel work.

**Tech Stack:** Markdown Codex skills/references, TOML interpreted by Codex, Bash/`rg` static checks, Git, and existing plugin-sync and skill-trigger test suites.

**Model Allocation:** FAST/NORMAL/BEST/REVIEW tiers are assigned below. Resolve each by explicit user override, quoted assignment in project-root `<repo>/AGENTS.md`, process environment variable, then built-in default; never scan nested AGENTS files or use repo-wide grep. FAST defaults to `SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`, NORMAL to `SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"`, BEST to `SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"`, and REVIEW to `SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"`. This session resolves FAST=`gpt-5.6-luna-max`, NORMAL=`gpt-5.6-sol-medium`, BEST=`gpt-5.6-sol-high`, and REVIEW=`gpt-5.6-sol-xhigh`. REVIEW is used for plan review and final review+fix; FAST is used for quick verification.

**Commit Policy:** The coordinator commits after combined acceptance of the reviewed plan/allocation/immediate execution, after implementation plus quick verification, and after review+fix plus final verification. Workers and reviewers never commit; there are no per-task commits. Coordinator scratch refs under `refs/simplepower/scratch/<run-id>/...` are local diff anchors, not accepted history, and are cleaned after successful checkpoints or preserved/reported on blockers.

---

## Approved Path Enforcement

This approved design and the accepted implementation plan are authoritative. Do not authorize backup routes, reduced scope, docs-only substitutes, stub or placeholder implementations, skipped verification, skipped review, or execution-route changes. If the approved path is blocked, stop and report the exact mismatch; any alternate implementation requires fresh explicit user approval at that moment.

Execution must remain on the existing in-place branch `feature/simplepower-config`. Before the accepted-plan checkpoint and again before final reporting, verify `git branch --show-current` returns exactly `feature/simplepower-config`; a mismatch blocks execution until the user directs how to proceed.

## Interface Contract

### C1. Configuration selection

- The exact filename is `simplepower.toml`.
- Inside Git, check `<git-root>/simplepower.toml`; otherwise there is no repository candidate.
- If the repository file exists, use it exclusively: do not read, merge, or fall back to `~/.codex/simplepower.toml`.
- If no repository file exists, use `~/.codex/simplepower.toml` when present; if neither exists, use defaults.
- Explicit current-session user instructions override the effective values after file/default resolution.

### C2. Schema and parsing

Only these top-level keys are valid:

```toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
```

- Missing `use_subagent` defaults to Boolean `false`; missing `subagent_model` defaults to the string shown above.
- Split `subagent_model` on the final dash into `model` and `reasoning_effort`; the default becomes `gpt-5.6-luna` plus `xhigh`.
- Valid effort suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`; availability is checked at dispatch.
- Malformed TOML, unknown top-level keys, wrong types, empty model strings, missing model prefixes, and unknown effort suffixes are errors.
- An invalid selected repository file never falls back to the home file.

### C3. Optional workflow behavior

- Brainstorming: `false` preserves coordinator exploration; `true` dispatches exactly one read-only context explorer. The coordinator retains every question, approach comparison, design approval, and planning handoff.
- RO: `false` preserves coordinator-only analysis; `true` dispatches exactly one read-only initial explorer. The explorer cannot edit tracked files or create `.codex-ro` artifacts; temporary artifacts remain coordinator-owned.
- Systematic debugging: `false` disables investigation-agent escalation while the coordinator continues Phase 1. `true` preserves the escalation only after initial Phase 1 stalls, with at most six distinct read-only angles using the resolved optional model. Existing briefs, diagnostic-artifact rules, structured reports, and synthesis remain.
- The switch does not govern plan reviewers, `sp-impl`, quick verifiers, review+fix agents, or explicitly invoked general delegation skills; their tier/skill routing remains.

### C4. Universal dispatch isolation

- Every Simple Power `spawn_agent` invocation or documented equivalent passes exactly `fork_turns="none"`.
- Active workflows contain no `fork_context` and no live/inherited-context exception.
- Every agent gets a self-contained brief with task, scope, constraints, relevant evidence/contracts, expected output, and verification.
- `subagent_model` never replaces FAST/NORMAL/BEST/REVIEW for mandatory roles.

### C5. Failure behavior

- Config errors stop the affected skill before dispatch and name the selected path plus the precise problem.
- With `use_subagent=true`, missing multi-agent support, unavailable configured model, or spawn failure stops and reports the blocker.
- Do not silently switch to coordinator-only work or a different model after enabled dispatch fails.
- Missing files and missing supported keys are normal and use defaults.

### C6. Verification contract

- Static tests assert C1-C5 in the reference and affected skills.
- Active coverage includes RO, systematic debugging, parallel dispatch, requesting review, and mandatory dispatch workflows.
- A global active-source guard rejects `fork_context` and asserts canonical `fork_turns="none"` wording.
- No tracked root `simplepower.toml` is created; docs provide examples.

## File Ownership

| File | Owner | Type | Responsibility | Parallel safety |
|---|---|---|---|---|
| `tests/simplepower-static/run-tests.sh` | Task 1 | modify | Failing-first contract and global isolation checks | Test-only owner |
| `skills/using-simplepower/references/simplepower-config.md` | Task 2 | create | Central C1-C5 contract | New file |
| `skills/using-simplepower/SKILL.md` | Task 2 | modify | Link config and universal dispatch rules | Single owner |
| `skills/brainstorming/SKILL.md` | Task 2 | modify | Conditional context explorer | Single owner |
| `skills/ro/SKILL.md` | Task 2 | modify | Conditional initial explorer | Single owner |
| `skills/systematic-debugging/SKILL.md` | Task 3 | modify | Config-gated escalation/model | Single owner |
| `skills/using-simplepower/references/codex-tools.md` | Task 4 | modify | Canonical tool argument/mappings | Single owner |
| `skills/subagent-driven-development/SKILL.md` | Task 4 | modify | Isolated mandatory dispatch | Single owner |
| `skills/writing-plans/SKILL.md` | Task 4 | modify | Isolated review/planned dispatch | Single owner |
| `skills/requesting-code-review/SKILL.md` | Task 4 | modify | Isolated review dispatch | Single owner |
| `skills/dispatching-parallel-agents/SKILL.md` | Task 4 | modify | Current Codex isolated examples | Single owner |
| `README.md` | Task 5 | modify | Bilingual config docs | Single owner |
| `docs/README.codex.md` | Task 5 | modify | Codex config docs | Single owner |
| `docs/testing.md` | Task 5 | modify | Verification docs | Single owner |

No native/CUDA/generated/version/manifest/plugin-sync files and no root config file are modified.

## Implementation Tasks

### Task 1: Add failing static contracts

**Goal:** Lock the approved behavior before skill edits.

**Contract inputs:** C1-C6.

**Serialization required:** No; exact strings and paths are fixed.

**Write scope:** `tests/simplepower-static/run-tests.sh`

**Parallel:** Yes, with Tasks 2-5.

**Risk:** Medium; weak checks could permit instruction drift.

**Model tier:** NORMAL — `gpt-5.6-sol`, effort `medium`. **Worker role:** `sp-impl`.

**Steps and outputs:**

1. Require the shared reference, exact keys/defaults, exclusive repo replacement, home fallback, current-session overrides, validation, and stop behavior.
2. Assert enabled/disabled behavior in brainstorming, RO, and debugging; replace hard-coded debug-model assertions.
3. Expand active paths and add a negative `fork_context` guard plus positive canonical isolation checks.
4. Assert no tracked root config exists.
5. Run `timeout 60s bash tests/simplepower-static/run-tests.sh`; before integration it must fail only on new/stale contract expectations, then pass after integration.

**Verification:** `timeout 60s bash -n tests/simplepower-static/run-tests.sh` and the static runner above.

**Report:** Changed assertions, syntax result, expected initial failures, coverage gaps.

### Task 2: Add config contract plus brainstorming and RO explorers

**Goal:** Create the source of truth and conditionally delegate initial read-only exploration.

**Contract inputs:** C1-C5, especially brainstorming/RO clauses.

**Serialization required:** No; the Interface Contract fully defines the new reference.

**Write scope:** `skills/using-simplepower/references/simplepower-config.md`, `skills/using-simplepower/SKILL.md`, `skills/brainstorming/SKILL.md`, `skills/ro/SKILL.md`

**Parallel:** Yes, with Tasks 1, 3, 4, 5.

**Risk:** High; this defines public config and entry-workflow boundaries.

**Model tier:** BEST — `gpt-5.6-sol`, effort `high`. **Worker role:** `sp-impl`.

**Steps and outputs:**

1. Create operational C1-C5 instructions and the exact TOML example.
2. Link them from using-simplepower and add the unconditional isolation rule.
3. Add config resolution to brainstorming context exploration; the optional explorer returns inspected files/commands, architecture/conventions, recent changes, risks, and no-edit confirmation.
4. Add equivalent RO initial analysis while keeping manifests/temp artifacts coordinator-owned.
5. Preserve brainstorming's hard gate and planning-only handoff and all RO write/cleanup restrictions.

**Verification:**

```bash
timeout 30s rg -n "use_subagent|subagent_model|simplepower-config|fork_turns" skills/using-simplepower/SKILL.md skills/using-simplepower/references/simplepower-config.md skills/brainstorming/SKILL.md skills/ro/SKILL.md
timeout 30s rg -n "bs_use_subagent|bs_subagent_model|fork_context" skills/using-simplepower/SKILL.md skills/using-simplepower/references/simplepower-config.md skills/brainstorming/SKILL.md skills/ro/SKILL.md
```

Second command must return no matches. Report files, commands/results, behavior boundaries, and risks.

### Task 3: Gate systematic-debugging investigation agents

**Goal:** Preserve Phase 1 discipline while making escalation optional and shared-model driven.

**Contract inputs:** C1-C5, especially the systematic-debugging clause.

**Serialization required:** No; the reference path and semantics are fixed.

**Write scope:** `skills/systematic-debugging/SKILL.md`

**Parallel:** Yes, with Tasks 1, 2, 4, 5.

**Risk:** High; eager dispatch or fallback would weaken rigid debugging behavior.

**Model tier:** BEST — `gpt-5.6-sol`, effort `high`. **Worker role:** `sp-impl`.

**Steps and outputs:**

1. Resolve config at activation while keeping initial Phase 1 coordinator-owned.
2. With `false`, continue without agent escalation; with `true`, retain the stall gate, six-agent cap, distinct angles, read-only/temp rules, reports, and synthesis.
3. Replace both hard-coded investigator model routes with resolved `subagent_model` and `fork_turns="none"`.
4. Remove all `fork_context`; keep the Iron Law and Phases 1-4 intact.

**Verification:**

```bash
timeout 30s rg -n "simplepower-config|use_subagent|subagent_model|fork_turns=\"none\"|at most six investigation agents|initial Phase 1" skills/systematic-debugging/SKILL.md
timeout 30s rg -n "fork_context|model=\"gpt-5.4-mini\"|model=\"gpt-5.4\"" skills/systematic-debugging/SKILL.md
```

Second command must return no matches. Report changed clauses, results, and root-cause-discipline confirmation.

### Task 4: Enforce isolated context across all dispatch phases

**Goal:** Make `fork_turns="none"` unconditional for optional and mandatory agents without changing tier routing.

**Contract inputs:** C4-C5 and the mandatory-role boundary in C3.

**Serialization required:** No; canonical syntax and tier behavior are exact.

**Write scope:** `skills/using-simplepower/references/codex-tools.md`, `skills/subagent-driven-development/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/requesting-code-review/SKILL.md`, `skills/dispatching-parallel-agents/SKILL.md`

**Parallel:** Yes, with Tasks 1-3 and 5.

**Risk:** High; this crosses every dispatch phase and must remove all inherited-context exceptions.

**Model tier:** BEST — `gpt-5.6-sol`, effort `high`. **Worker role:** `sp-impl`.

**Steps and outputs:**

1. Change exact `spawn_agent` mappings, including generic review/task examples, to `fork_turns="none"`.
2. Update SDD plan-review/worker/verifier/review+fix dispatch rules and delete its live-context exception.
3. Update writing-plans and requesting-code-review to state the exact argument and self-contained brief requirement.
4. Replace legacy `Task(...)` parallel examples with Codex `spawn_agent(..., fork_turns="none", message=...)` examples.
5. Preserve FAST/NORMAL/BEST/REVIEW selection; never route mandatory agents via `subagent_model`.

**Verification:**

```bash
timeout 30s rg -n "spawn_agent|fork_turns=\"none\"" skills/using-simplepower/references/codex-tools.md skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/requesting-code-review/SKILL.md skills/dispatching-parallel-agents/SKILL.md
timeout 30s rg -n "fork_context|fork_turns=\"(all|[1-9][0-9]*)\"" skills/using-simplepower/references/codex-tools.md skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/requesting-code-review/SKILL.md skills/dispatching-parallel-agents/SKILL.md
```

Second command must return no matches. Report dispatch sites, results, unchanged tiers, and ambiguous wording.

### Task 5: Document config and tests

**Goal:** Explain optional delegation precisely in Chinese and English without shipping an overriding config.

**Contract inputs:** C1-C6 and the approved no-default-file decision.

**Serialization required:** No; docs are specified by the Interface Contract.

**Write scope:** `README.md`, `docs/README.codex.md`, `docs/testing.md`

**Parallel:** Yes, with Tasks 1-4.

**Risk:** Medium; unclear replacement/scope semantics would surprise users.

**Model tier:** NORMAL — `gpt-5.6-sol`, effort `medium`. **Worker role:** `sp-impl`.

**Steps and outputs:**

1. Add matching bilingual README config sections with exact keys/defaults, repository-file replacement (no merging), strict errors, and affected workflows.
2. Explain mandatory tier separation and universal `fork_turns="none"`.
3. Add Codex multi-agent/config guidance and testing expectations/commands.
4. Preserve Codex-only scope and upstream attribution; do not create config/version/harness files.

**Verification:**

```bash
timeout 30s rg -n "simplepower.toml|use_subagent|subagent_model|gpt-5.6-luna-xhigh|fork_turns" README.md docs/README.codex.md docs/testing.md
timeout 30s rg -n "bs_use_subagent|bs_subagent_model|fork_context" README.md docs/README.codex.md docs/testing.md
```

Second command must return no matches. Report sections, results, and no-config-file confirmation.

## Model Allocation

| Stage | Role | Tier | Model | Effort | Reason |
|---|---|---|---|---|---|
| Task 1 | `sp-impl` tests | NORMAL | `gpt-5.6-sol` | `medium` | Localized but careful negative-guard design |
| Task 2 | `sp-impl` config/brainstorm/RO | BEST | `gpt-5.6-sol` | `high` | New cross-workflow public behavior |
| Task 3 | `sp-impl` debugging | BEST | `gpt-5.6-sol` | `high` | Rigid escalation semantics |
| Task 4 | `sp-impl` dispatch contract | BEST | `gpt-5.6-sol` | `high` | Cross-cuts every agent phase |
| Task 5 | `sp-impl` docs | NORMAL | `gpt-5.6-sol` | `medium` | Precise bilingual documentation |
| Plan review | reviewer | REVIEW | `gpt-5.6-sol` | `xhigh` | Validate design/ownership/isolation |
| Quick verification | verifier | FAST | `gpt-5.6-luna` | `max` | Mechanical integrated checks |
| Final review+fix | reviewer/fixer | REVIEW | `gpt-5.6-sol` | `xhigh` | Whole-change quality and fixes |

Every dispatch also passes `fork_turns="none"`; it does not alter tier selection.

## Plan Review

Self-review confirms C1-C6 coverage; non-overlapping ownership; every requirement mapped to a task; aggregate parallel readiness; preserved mandatory tier routing; exact three coordinator commits; concrete timed verification; no runtime parser or root config; and no fallback, skipped checks, or inherited-context exception.

Use run id `YYYYMMDD-HHMMSS-<short-head>`. Before review, create `refs/simplepower/scratch/<run-id>/plan-review/before` for this plan using a temporary index that stages only the plan without changing the real index. Dispatch one REVIEW reviewer with `model="gpt-5.6-sol"`, `reasoning_effort="xhigh"`, `fork_turns="none"`, and `skills/writing-plans/plan-document-reviewer-prompt.md`. It must review directly, and must not run Codex CLI, spawn agents, invoke skills, restart execution, or reroute the workflow. Keep it open for recoverable revisions. For revision `n`, create `plan-review/after-<n>` and send `git diff <previous-plan-review-ref> refs/simplepower/scratch/<run-id>/plan-review/after-<n> -- docs/simplepower/plans/2026-07-11-simplepower-subagent-config.md`. Delete plan-review refs only after the accepted-plan checkpoint; preserve and report the manual cleanup command on stop or failure.

## Quick Verification

After Tasks 1-5, create `quick-verifier/before` over all implementation-owned files and dispatch FAST with `model="gpt-5.6-luna"`, `reasoning_effort="max"`, `fork_turns="none"`.

```bash
timeout 60s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s rg -n "fork_context|bs_use_subagent|bs_subagent_model" README.md docs/README.codex.md docs/testing.md skills
git status --short
```

All syntax/suites pass; stale-term search returns no active matches; status contains only approved files. The quick verifier may fix only tiny typo-level errors. It must report behavior changes, structural edits, test rewrites, public-interface changes, or unclear issues rather than fixing them. If edited, create `quick-verifier/after` and inspect `git diff refs/simplepower/scratch/<run-id>/quick-verifier/before refs/simplepower/scratch/<run-id>/quick-verifier/after -- <approved-files>`. Delete phase refs after the quick-verified checkpoint; otherwise preserve/report them.

## Final Review And Fix

After the quick-verified checkpoint, create `refs/simplepower/scratch/<run-id>/review-fix/before` over approved files. Dispatch one REVIEW review+fix agent with `model="gpt-5.6-sol"`, `reasoning_effort="xhigh"`, `fork_turns="none"`, and the local prompt. It must review/fix directly; may fix only approved files; must preserve C1-C6/gates; and must not run Codex CLI, commit, spawn agents, invoke skills, restart execution, reroute, or touch scratch refs. If edited, create `review-fix/after` and inspect `git diff refs/simplepower/scratch/<run-id>/review-fix/before refs/simplepower/scratch/<run-id>/review-fix/after -- <approved-files>` before final verification.

## Commit Checkpoints

1. Accepted plan: after combined approval and before implementation dispatch.
2. Quick-verified implementation: after all workers and quick checks.
3. Final: after REVIEW review+fix and final checks. Create this third coordinator checkpoint even when review+fix produces no file edits, so accepted history records all three required checkpoints.

Only the coordinator commits. Scratch refs are local-only, cleaned after successful phase checkpoints, and preserved/reported on blockers.

## Current-Session Auto-Dispatch

After review approval, request one combined approval for this reviewed plan, allocation, and immediate current-session execution. After approval, verify the current branch is `feature/simplepower-config`, commit the plan checkpoint, clean plan-review refs, and immediately invoke `simplepower:subagent-driven-development` in this current session with:

```text
Execute `docs/simplepower/plans/2026-07-11-simplepower-subagent-config.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST/REVIEW allocation. Dispatch every agent with `fork_turns="none"`. Run the FAST quick verifier after all workers, commit the quick-verified implementation, then run one REVIEW review+fix agent, final verification, and final commit.
```

## Verification

After final review/fix, run:

```bash
timeout 60s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
test "$(git branch --show-current)" = "feature/simplepower-config"
timeout 30s rg -n "fork_context|bs_use_subagent|bs_subagent_model" README.md docs/README.codex.md docs/testing.md skills
timeout 30s rg -n "simplepower.toml|use_subagent|subagent_model|fork_turns=\"none\"" README.md docs/README.codex.md docs/testing.md skills tests/simplepower-static/run-tests.sh
git diff --check
git status --short
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>"
```

All tests pass, stale terms are absent, contract terms are consistent, diff check is clean, status contains only approved files, and scratch output is empty after cleanup. Any failure blocks the final checkpoint. On stop/failure preserve refs and report:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<run-id>" | while read -r ref; do git update-ref -d "$ref"; done
```
