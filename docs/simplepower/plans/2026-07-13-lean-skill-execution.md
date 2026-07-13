# Simple Power Balanced Lean Execution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Create and push `optimize/lean-execution` on top of Branch A, adding balanced runtime concision and minimum-sufficient testing behavior to three Simple Power workflows.

**Design Summary:** Branch C starts only from the final pushed `optimize/skill-compaction` tip. It keeps all Branch A safety, capacity-aware rolling dispatch, approval, review, and verification invariants while making runtime work proportional: concise sentences, no replay of accepted context, only decision-relevant questions/evidence, delta-focused reports, and risk-based tests that cover meaningful behavior without trivial or framework-owned cases. Acceptance is behavioral with no token, word, turn, or test-count quota. After both experimental branches are pushed, the clean nested Simple Power repository at `/home/gary/.codex/simplepower` is fetched and checked out to Branch A; dirty parent-repository config files are preserved.

**Architecture:** Lean behavior is expressed locally in each main skill so it is available when that workflow runs; prompt templates apply the same contract to subagent reports. Branch A's progressive-disclosure references retain operational mechanics, while the Branch C core files define proportional effort and stopping rules. The Interface Contract separates the three skill edits from static-test updates for aggregate parallel work after the intentional branch dependency is satisfied.

**Tech Stack:** Markdown instruction contracts, Bash static tests, Git branches/remotes, and the nested Git checkout at `/home/gary/.codex/simplepower`.

**Model Allocation:** Built-in defaults are FAST `gpt-5.3-codex-spark-xhigh`, NORMAL `gpt-5.6-luna-max`, and BEST/REVIEW `gpt-5.6-sol-high`. The validated current-session resolution after environment overlays is `use_subagent=true`, inherited `subagent_model=gpt-5.6-luna-xhigh`, FAST `gpt-5.3-codex-spark-xhigh`, NORMAL `gpt-5.4-high`, BEST `gpt-5.5-xhigh`, and REVIEW `gpt-5.5-xhigh`. Resolution starts with built-in defaults, then overlays each key from `/home/gary/.codex/simplepower.toml`, repository `<git-root>/simplepower.toml`, the four non-empty `SIMPLEPOWER_*_MODEL` environment variables, and explicit current-session instructions last. Missing keys inherit; every present TOML file must validate fully even when overridden. Supported keys are `use_subagent`, `subagent_model`, `review_model`, `best_model`, `normal_model`, and `fast_model`; model values split at the final dash and accept only `low`, `medium`, `high`, `xhigh`, `max`, or `ultra`. Do not read model assignments from `AGENTS.md`. Mandatory tiers are independent of `use_subagent`. REVIEW handles plan review and final review+fix; FAST handles quick verification.

**Commit Policy:** This plan has exactly three coordinator checkpoints on `optimize/lean-execution`: accepted reviewed plan after combined approval and after Branch A is final/pushed; quick-verified Branch C implementation after all file workers and FAST verification; and final verified implementation after one REVIEW review+fix pass. The final checkpoint commits only remaining changes and never creates an empty commit. Workers, reviewers, verifiers, and tasks do not commit. Scratch refs under `refs/simplepower/scratch/<run-id>/...` are coordinator-owned local anchors, not accepted commits, and are never pushed, merged, or rebased.

---

## Interface Contract

### C-IC-1: Branch dependency and preserved invariants

- `optimize/lean-execution` is created from the final pushed `optimize/skill-compaction` tip; it is not an independent branch from `feature/simplepower-config`.
- All Branch A behavior contracts remain in force: brainstorming approval before implementation, root-cause-before-fix, validated isolated dispatch, capacity-aware rolling aggregate dispatch, accepted plan/File Ownership, approved path, coordinator checkpoints, quick verification, one REVIEW pass, final verification, and no worker commits.
- Lean defaults never authorize skipped gates, skipped required evidence, skipped review, skipped verification, or an unsafe shortcut.
- There is no numeric response, token, turn, word, or test-count budget.

### C-IC-2: Shared lean-execution behavior

All three skills must instruct the coordinator/worker to:

1. Use concise sentences without changing the intended meaning.
2. Reuse accepted conversation and plan context; do not restate it unless needed to resolve ambiguity or risk.
3. Scale explanation, evidence gathering, alternatives, tests, and reporting to complexity and consequence.
4. Stop an exploratory activity when the next decision is adequately supported; continue when uncertainty could change the decision or safety outcome.
5. Report deltas: decisions, changed files, evidence, failures, risks, and blockers rather than replaying the full workflow.

These are proportionality rules, not permission to omit information required by C-IC-1.

### C-IC-3: Lean brainstorming

`skills/brainstorming/SKILL.md` must additionally guarantee:

- Ask only unresolved questions whose answers can change scope, design, constraints, or success criteria; retain one question per message.
- When materially distinct approaches exist, compare two or three. When constraints dictate one reasonable approach, state that briefly rather than inventing alternatives.
- A simple design may be presented and approved as one compact section. Complex designs retain incremental section approval.
- Include architecture, components, data flow, error handling, and testing only to the extent relevant to the requested change.
- The hard gate and `simplepower:writing-plans` handoff remain unchanged.

### C-IC-4: Lean systematic debugging

`skills/systematic-debugging/SKILL.md` and `parallel-investigation.md` must additionally guarantee:

- Start with the smallest useful reproduction and the evidence boundaries most likely to distinguish causes.
- Do not collect extra logs, angles, or reports after the root-cause decision is adequately supported.
- Add investigator angles only when distinct uncertainty remains; never dispatch angles merely to fill the six-agent allowance.
- Keep coordinator and investigator reports focused on cause, supporting/contradicting evidence, next decision, and unresolved risk.
- Preserve one-hypothesis/one-change discipline, the minimal regression reproduction, and the three-failed-fix architectural stop.

### C-IC-5: Lean SDD and minimum-sufficient tests

The SDD skill and prompts must additionally guarantee:

- Self-contained briefs contain the exact contract inputs, scope, commands, and risks needed by that role, without replaying unrelated plan prose.
- Worker completion reports contain changed files, commands/results, deviations, risks, and blockers; omit process narration that adds no decision value.
- Quick and final review reports prioritize actionable findings and deltas.
- Test meaningful changed behavior, the regression boundary for a defect, and important failure paths. Do not test trivial getters, framework/library behavior, or mechanically obvious wiring unless project history, risk, or a known regression justifies it.
- Prefer the smallest set of tests that can fail for a meaningful defect. Add cases when they cover a distinct risk, not to maximize counts.
- Existing TDD ordering and mandatory verification remain intact.

### C-IC-6: Static and scenario acceptance

`tests/simplepower-static/run-tests.sh` must assert the lean rules and preserved gates through stable semantic anchors, not full prose snapshots or numeric size quotas. Review scenarios must cover:

1. A small brainstorming task produces only decision-relevant questions and a compact design while retaining approval.
2. A nuanced brainstorming task still compares alternatives and uses incremental approval.
3. A simple reproducible bug does not trigger unnecessary parallel investigation.
4. An ambiguous cross-component bug still gathers sufficient evidence and may use distinct investigator angles.
5. An SDD worker proposes meaningful regression/failure tests but rejects trivial framework/getter/wiring tests absent risk.
6. Worker/verifier/reviewer reports remain self-contained and decision-complete without replaying the whole plan.

Automated checks are:

```bash
timeout 30s git diff --check
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s npm --prefix tests/brainstorm-server test
```

No native source is in scope; `xmake b` is not required.

### C-IC-7: Push and installed-checkout contract

1. Push final Branch A before Branch C starts; push final Branch C after its final verification.
2. `/home/gary/.codex/simplepower` is a nested clean Git repository with remote `origin` pointing to `git@github.com:garyfpga/simplepower.git`; its current detached HEAD is acceptable.
3. The parent `/home/gary/.codex` has user changes in `config.toml` and `simplepower.toml`. They are out of scope and must not be staged, stashed, reset, cleaned, or overwritten.
4. After both pushes, run `git -C /home/gary/.codex/simplepower fetch origin`, verify the nested checkout is clean, and run `git -C /home/gary/.codex/simplepower switch --detach origin/optimize/skill-compaction`.
5. Verify nested HEAD equals `origin/optimize/skill-compaction`. Do not commit or push the parent repository's resulting gitlink change.
6. Authentication failure, a dirty nested checkout, a missing remote branch, or a conflicting checkout is a blocker; do not force, stash, or clean.

## File Ownership

| File or operational target | Owner task | Change type | Responsibility | Parallel safety notes |
| --- | --- | --- | --- | --- |
| `docs/simplepower/plans/2026-07-13-lean-skill-execution.md` | Coordinator planning | create | Authoritative Branch C plan | No worker edits |
| `skills/brainstorming/SKILL.md` | C1 | modify | Add proportional brainstorming behavior | C1 only |
| `skills/systematic-debugging/SKILL.md` | C2 | modify | Add minimum-sufficient evidence/stopping rules | C2 only |
| `skills/systematic-debugging/parallel-investigation.md` | C2 | modify | Add distinct-angle and concise-report rules | C2 only |
| `skills/subagent-driven-development/SKILL.md` | C3 | modify | Add lean briefs/reports and test guidance | C3 only |
| `skills/subagent-driven-development/implementer-prompt.md` | C3 | modify | Apply concise self-contained reporting and test policy | C3 only |
| `skills/subagent-driven-development/quick-verifier-prompt.md` | C3 | modify | Apply delta-focused verification reporting | C3 only |
| `skills/subagent-driven-development/review-fix-prompt.md` | C3 | modify | Apply actionable delta-focused review reporting | C3 only |
| `tests/simplepower-static/run-tests.sh` | C4 | modify | Assert lean behavior and preserved invariants | C4 only |
| `/home/gary/.codex/simplepower` | Coordinator delivery | operational checkout | Fetch both pushed branches and detach at Branch A | Serialized after Branch C push; no worker edits |

## Implementation Tasks

### C1: Add balanced lean brainstorming

**Goal:** Make brainstorming proportional without weakening design approval.

**Contract inputs:** C-IC-1, C-IC-2, C-IC-3, C-IC-6.

**Serialization required:** No. Branch A must exist first, but once Branch C begins C1 has isolated ownership.

**Write scope:** `skills/brainstorming/SKILL.md`.

**Parallel:** Yes, with C2, C3, and C4.

**Risk:** High because the change intentionally alters interaction depth while retaining the hard gate.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Add the C-IC-2 concision, reuse, proportionality, stop, and delta principles at the point where they govern questions/design output.
2. Implement C-IC-3's decision-relevant question rule and conditional alternatives rule.
3. Allow one compact approval section for simple work while retaining incremental approval for nuanced designs.
4. Make design coverage relevance-based without dropping applicable architecture, component, flow, error, or testing considerations.
5. Keep the Branch A hard gate, approved-path rules, visual consent, context exploration, and writing-plans handoff.

**Verification commands:**

```bash
timeout 30s git diff --check -- skills/brainstorming/SKILL.md
timeout 30s rg -n 'concise|decision|approach|compact|approval|HARD-GATE|simplepower:writing-plans' skills/brainstorming/SKILL.md
```

Expected: small tasks can be concise, complex tasks remain rigorous, and all gates remain. Report files, commands/results, and ambiguity risks.

### C2: Add balanced lean debugging

**Goal:** Stop unnecessary investigation while preserving evidence-based root-cause confidence.

**Contract inputs:** C-IC-1, C-IC-2, C-IC-4, C-IC-6.

**Serialization required:** No. C2 owns the main debugging file and its Branch A reference.

**Write scope:** `skills/systematic-debugging/SKILL.md`; `skills/systematic-debugging/parallel-investigation.md`.

**Parallel:** Yes, with C1, C3, and C4.

**Risk:** High because stopping too early could weaken diagnosis and continuing too long defeats the goal.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Add the smallest-useful-reproduction and discriminating-boundary defaults to Phase 1.
2. Define adequate support as evidence sufficient for the next hypothesis/fix decision, while retaining contradictory-evidence checks.
3. Make optional investigators proportional to unresolved distinct angles rather than the available maximum.
4. Make reports use cause/evidence/decision/risk fields without redundant process narration.
5. Preserve all Branch A phase, dispatch, no-fix, synthesis, minimal-change, and three-failure invariants.

**Verification commands:**

```bash
timeout 30s git diff --check -- skills/systematic-debugging/SKILL.md skills/systematic-debugging/parallel-investigation.md
timeout 30s rg -n 'smallest|evidence|distinct|cause|risk|Root Cause|three' skills/systematic-debugging/SKILL.md skills/systematic-debugging/parallel-investigation.md
```

Expected: investigation stops proportionally but only after the decision is supported. Report files, commands/results, and premature-stop risks.

### C3: Add lean SDD reporting and tests

**Goal:** Keep SDD briefs and reports self-contained while eliminating replay and over-engineered test requests.

**Contract inputs:** C-IC-1, C-IC-2, C-IC-5, C-IC-6.

**Serialization required:** No. C3 exclusively owns the SDD skill and prompts.

**Write scope:** `skills/subagent-driven-development/SKILL.md`; `skills/subagent-driven-development/implementer-prompt.md`; `skills/subagent-driven-development/quick-verifier-prompt.md`; `skills/subagent-driven-development/review-fix-prompt.md`.

**Parallel:** Yes, with C1, C2, and C4.

**Risk:** High because this intentionally changes worker/reviewer output and test-design defaults across the implementation lifecycle.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Add the concise self-contained brief rule: exact contract/scope/commands/risks only, with no irrelevant plan replay.
2. Make completion and review reports delta-focused while retaining required files, commands/results, deviations, risks, and blockers.
3. Add C-IC-5's meaningful-behavior, regression-boundary, distinct-failure, and no-trivial-test guidance.
4. State that risk/history can justify otherwise trivial-looking coverage and that mandatory TDD/verification remains.
5. Apply consistent wording to all three prompt templates without changing their permissions or direct-review prohibitions.

**Verification commands:**

```bash
timeout 30s git diff --check -- skills/subagent-driven-development
timeout 30s rg -n 'concise|self-contained|changed files|results|risk|blocker|trivial|framework|wiring|regression' skills/subagent-driven-development
```

Expected: reports remain decision-complete, and test guidance is minimum-sufficient rather than count-driven. Report files, commands/results, and any loss-of-context risk.

### C4: Add lean-behavior contract tests

**Goal:** Assert Branch C's proportionality and minimum-sufficient testing rules while retaining Branch A safeguards.

**Contract inputs:** C-IC-1 through C-IC-6.

**Serialization required:** No. Stable contract anchors let this worker update tests without reading another worker's uncommitted prose.

**Write scope:** `tests/simplepower-static/run-tests.sh`.

**Parallel:** Yes, with C1, C2, and C3.

**Risk:** Medium because static wording checks approximate behavioral instruction contracts and must avoid becoming brittle.

**Model tier:** NORMAL — `gpt-5.4`, reasoning effort `high`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Add stable checks for concise meaning-preserving sentences, proportional effort, decision-relevant questions, distinct investigation angles, delta reports, and meaningful nontrivial tests.
2. Retain Branch A safety assertions for gates, root cause, dispatch, review, and commits.
3. Use a small set of anchors/negative checks per behavior; do not snapshot paragraphs or add numeric quotas.
4. Keep unrelated assertions unchanged.

**Verification commands:**

```bash
timeout 30s git diff --check -- tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
```

Expected: the static suite passes and each C-IC lean rule has durable coverage. Report files, commands/results, and any check still coupled to incidental prose.

## Model Allocation

| Stage | Role | Tier | Resolved model | Effort | Reason |
| --- | --- | --- | --- | --- | --- |
| C1 | `sp-impl` lean brainstorming | BEST | `gpt-5.5` | `xhigh` | Intentionally changes interaction behavior |
| C2 | `sp-impl` lean debugging | BEST | `gpt-5.5` | `xhigh` | Balances diagnostic sufficiency against stopping |
| C3 | `sp-impl` lean SDD/testing | BEST | `gpt-5.5` | `xhigh` | Cross-file behavior-shaping worker/review contract |
| C4 | `sp-impl` static tests | NORMAL | `gpt-5.4` | `high` | Localized semantic test-contract update |
| Plan review | Plan document reviewer | REVIEW | `gpt-5.5` | `xhigh` | Validate proportionality and preserved safeguards |
| Quick verification | Quick verifier | FAST | `gpt-5.3-codex-spark` | `xhigh` | Mechanical commands and typo-only authority |
| Final review | Review+fix agent | REVIEW | `gpt-5.5` | `xhigh` | Review complete behavior-shaping changes |

Every dispatch passes `fork_turns="none"` and a self-contained brief. Review roles work directly and may not run Codex CLI, spawn subagents, invoke Simple Power skills, restart execution, or reroute it.

## Plan Review and Scratch Refs

The coordinator assigns a C-specific run id `YYYYMMDD-HHMMSS-<short-head>` and creates `refs/simplepower/scratch/<C-run-id>/plan-review/before` for this plan before REVIEW dispatch. Use a temporary index so the real index and branch history do not change:

```bash
C_RUN_ID="${C_RUN_ID:-$(date -u +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD)}"
C_PREFIX="refs/simplepower/scratch/$C_RUN_ID"
C_REF="$C_PREFIX/<phase>/<label>"
C_TMP_INDEX="$(mktemp)"
GIT_INDEX_FILE="$C_TMP_INDEX" git read-tree HEAD
GIT_INDEX_FILE="$C_TMP_INDEX" git add -- <approved-files>
C_TREE="$(GIT_INDEX_FILE="$C_TMP_INDEX" git write-tree)"
C_COMMIT="$(printf '%s\n' "simplepower scratch $C_RUN_ID <phase>/<label>" | git commit-tree "$C_TREE" -p HEAD)"
git update-ref "$C_REF" "$C_COMMIT"
rm -f "$C_TMP_INDEX"
```

Revised plans use `after-<n>` refs and return the same reviewer this consecutive-anchor diff shape:

```bash
git diff refs/simplepower/scratch/<C-run-id>/plan-review/<previous-label> refs/simplepower/scratch/<C-run-id>/plan-review/after-<n> -- docs/simplepower/plans/2026-07-13-lean-skill-execution.md
```

Failure to create a required anchor stops that phase. Keep C's plan-review refs until the C accepted-plan checkpoint succeeds, even while Branch A executes.

Before quick verification create `quick-verifier/before` for C implementation files; create `after` only for verifier typo edits and inspect the diff. Before final review create `review-fix/before`; create `after` only if the reviewer edits and inspect it. Delete phase refs after their checkpoint succeeds. Preserve evidence on a blocker and report:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<C-run-id>" | while read -r ref; do git update-ref -d "$ref"; done
```

## Quick Verification

After C1-C4 complete, dispatch one FAST verifier with typo-only authority and run:

```bash
timeout 30s git diff --check
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
```

Any structural, behavioral, test-rewrite, or unclear issue is reported rather than fixed by the verifier. All commands must pass before the quick-verified checkpoint.

## Final Review and Fix

After the quick-verified checkpoint, dispatch exactly one REVIEW-tier review+fix agent across every Branch C-owned implementation file. It may edit within ownership, must check C-IC-1 through C-IC-7, and must report files, commands/results, remaining risks, and deviations. It does not commit, manage refs, recurse, or reroute.

## Commit Checkpoints and Delivery

1. **Accepted plan:** after Branch A is final-verified and pushed, create `optimize/lean-execution` from the exact Branch A tip and commit only this reviewed Branch C plan under the user's combined approval.
2. **Quick-verified implementation:** after C1-C4 and the FAST verifier pass, commit all approved Branch C implementation files and tests.
3. **Final:** after REVIEW review+fix and final verification, commit remaining approved changes only if present; never create an empty commit.

Push `optimize/lean-execution` to `origin` only after the final checkpoint. Then perform C-IC-7's clean nested-repository fetch and detached checkout of `origin/optimize/skill-compaction`. Do not commit the parent `/home/gary/.codex` gitlink change or its existing config changes.

## Current-Session Auto-Dispatch

The user's single combined approval covers this reviewed plan, its allocation, and immediate execution after the reviewed Branch A plan finishes. After Branch A is pushed, create C's accepted-plan checkpoint and immediately invoke `simplepower:subagent-driven-development` for this plan. In the current four-slot session, launch C1, C2, and C3 first, then launch C4 immediately when any worker finishes and frees a child-agent slot; C4 remains `Serialization required: No`. Do not offer alternate routes or pause for route selection; stop only for an approved-path blocker.

## Final Verification

After review+fix, run every C-IC-6 command. Every project command must pass before the final Branch C checkpoint. After that checkpoint and the Branch C push, run the post-delivery checks and installed checkout:

```bash
timeout 30s git ls-remote --exit-code --heads origin optimize/skill-compaction
timeout 30s git ls-remote --exit-code --heads origin optimize/lean-execution
timeout 60s git -C /home/gary/.codex/simplepower fetch origin
timeout 30s bash -c 'test -z "$(git -C /home/gary/.codex/simplepower status --porcelain)"'
timeout 30s git -C /home/gary/.codex/simplepower switch --detach origin/optimize/skill-compaction
timeout 30s bash -c 'test "$(git -C /home/gary/.codex/simplepower rev-parse HEAD)" = "$(git -C /home/gary/.codex/simplepower rev-parse origin/optimize/skill-compaction)"'
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<C-run-id>"
```

The final checkpoint and Branch C push occur only after project tests pass. The installed checkout occurs only after both remote branches are confirmed; a dirty nested checkout or fetch/switch failure blocks without stash, reset, force, or clean.

## Approved Path Enforcement

Do not convert balanced proportionality into hard quotas or permission to skip evidence, tests, review, or approval. Do not substitute an independent C branch, docs-only wording, placeholders, or another checkout location. If Branch A is not final/pushed, a test or push fails, or `/home/gary/.codex/simplepower` is dirty/conflicted, stop with exact status and obtain fresh approval before changing the path.
