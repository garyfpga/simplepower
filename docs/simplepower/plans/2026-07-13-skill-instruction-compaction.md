# Simple Power Skill Instruction Compaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Create and push `optimize/skill-compaction`, a behavior-preserving compaction of the brainstorming, systematic-debugging, and subagent-driven-development instructions.

**Design Summary:** Branch A starts at `feature/simplepower-config` and primarily compacts wording and information placement. It removes repeated explanations, uses progressive disclosure for operational detail, and loosens brittle sentence-level static assertions while preserving every gate, safety rule, and verification stage. One user-approved behavior addition makes aggregate dispatch capacity-aware: launch as many ready workers as the runtime permits, then launch queued ready workers immediately as slots free instead of treating a session cap as plan serialization. Acceptance is behavioral; there is no word-count or percentage target. Branch C is a separate reviewed plan built on the final Branch A commit.

**Architecture:** Each main `SKILL.md` remains the authoritative entry point and retains its mandatory decision procedure. Repeated operational detail may move to one focused reference per complex skill, with explicit read conditions in the main skill; shared configuration and Codex dispatch rules continue to use their existing canonical references. The Interface Contract below fixes the observable behavior and stable test anchors so four non-overlapping workers can compact the three skill areas and their static tests in aggregate parallel.

**Tech Stack:** Markdown instruction contracts, Bash static tests, Git branches, and existing Simple Power test runners.

**Model Allocation:** Built-in defaults are FAST `gpt-5.3-codex-spark-xhigh`, NORMAL `gpt-5.6-luna-max`, and BEST/REVIEW `gpt-5.6-sol-high`. The validated current-session resolution after environment overlays is FAST `gpt-5.3-codex-spark-xhigh`, NORMAL `gpt-5.4-high`, BEST `gpt-5.5-xhigh`, and REVIEW `gpt-5.5-xhigh`. Resolution starts with built-in defaults, then overlays each key from `/home/gary/.codex/simplepower.toml`, repository `<git-root>/simplepower.toml`, the four non-empty `SIMPLEPOWER_*_MODEL` environment variables, and explicit current-session instructions last. Missing higher-layer keys inherit; every present TOML file must validate in full even when a higher layer overrides a value. The supported keys are `use_subagent`, `subagent_model`, `review_model`, `best_model`, `normal_model`, and `fast_model`. Parse each model string at its final dash; allowed efforts are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. Do not read model assignments from `AGENTS.md`. Mandatory FAST/NORMAL/BEST/REVIEW allocation is independent of `use_subagent`; the plan reviewer and final review+fix agent use REVIEW, and the quick verifier uses FAST.

**Commit Policy:** This plan has exactly three coordinator checkpoints on `optimize/skill-compaction`: accepted reviewed plan after combined user approval; quick-verified implementation after every Branch A file-edit worker and the FAST verifier complete; and final verified implementation after one REVIEW-tier review+fix agent. The final checkpoint creates a commit only if review+fix leaves tracked changes; do not create an empty commit. Workers, reviewers, verifiers, and individual tasks never commit. Coordinator-owned scratch refs under `refs/simplepower/scratch/<run-id>/...` are local diff anchors only, are never pushed, merged, or rebased, and do not count as accepted commits.

---

## Interface Contract

### A-IC-1: Branch and scope contract

- Source is `/home/gary/git/simplepower` at the approved `feature/simplepower-config` tip.
- The coordinator creates `optimize/skill-compaction` from that tip immediately before the accepted-plan checkpoint.
- Branch A may change instruction wording, ordering, headings, and reference placement without changing workflow decisions, permissions, prohibitions, review stages, or success criteria, except for the explicitly approved capacity-aware dispatch behavior in A-IC-4.
- No test may impose a word count, line count, percentage reduction, or exact prose reproduction.
- Historical plans, creation logs, pressure fixtures, public README summaries, and unrelated skills are outside scope.

### A-IC-2: Brainstorming behavior

`skills/brainstorming/SKILL.md` must continue to guarantee:

1. Resolve and validate `skills/using-simplepower/references/simplepower-config.md` before context exploration.
2. With `use_subagent=false`, do not dispatch an explorer. With `true`, dispatch at most one explorer only when necessary, using resolved `subagent_model`, `fork_turns="none"`, a self-contained read-only brief, and a no-edit report; stop if a selected dispatch cannot run.
3. Explore context before questions; ask one question per message; compare two or three approaches; present complexity-scaled design sections and obtain approval before implementation.
4. Offer the visual companion only for genuinely visual questions, in its own message, and read `visual-companion.md` after consent.
5. Preserve the hard gate, approved-path/fresh-approval rule, and sole terminal handoff to `simplepower:writing-plans` without standalone specs or implementation.

Stable anchors are the skill names/references, `<HARD-GATE>`, `Approved Path Enforcement`, `simplepower-config.md`, `fork_turns="none"`, `visual-companion.md`, and `simplepower:writing-plans`; exact surrounding sentences are not stable.

### A-IC-3: Systematic-debugging behavior

`skills/systematic-debugging/SKILL.md` must continue to guarantee:

1. Root cause is established before fixes; the four phases remain evidence gathering, pattern comparison, hypothesis testing, and implementation/verification.
2. Phase 1 starts with errors, reproduction, recent changes, component boundaries, and backward data-flow tracing.
3. Parallel investigation is optional, starts only after the coordinator's initial Phase 1 work stalls, respects validated `use_subagent`/`subagent_model`, uses at most six non-overlapping read-only angles, passes `fork_turns="none"`, and never authorizes investigator fixes.
4. Investigator temporary output is restricted to `.codex-debug/<instance-id>/`; the coordinator synthesizes reports before any fix.
5. Test one hypothesis with one minimal change, add a minimal failing test or reproduction, verify the result, and question the architecture after three failed fixes.

Stable anchors are `Root Cause`, the four numbered phases, `simplepower-config.md`, `fork_turns="none"`, `.codex-debug/<instance-id>/`, the six-agent maximum, no-fix investigator scope, synthesis, and the three-failure stop; repeated warning sentences are not stable.

### A-IC-4: Subagent-driven-development behavior

The SDD skill and its three prompt templates must continue to guarantee:

1. Execute only an accepted `simplepower:writing-plans` artifact with an Interface Contract, exact File Ownership, `Contract inputs`, and `Serialization required` decisions.
2. Build the full aggregate set of non-conflicting `sp-impl` tasks whose contracts are sufficient. Dispatch up to the runtime's available child-agent capacity, then dispatch the next queued ready task immediately whenever a worker finishes. Capacity queuing is not `Serialization required: Yes`; never leave a slot idle while a contract-ready task remains. Serialize only for an approved overlap, missing dependency, generated-artifact condition, or intentional runtime ordering.
3. Every dispatch uses `fork_turns="none"` and a self-contained brief. Workers do not commit, create scratch refs, expand scope, invent substitute paths, or overwrite another worker's edits.
4. Run the FAST quick verifier after all workers, allow it only typo-level fixes, create the coordinator quick-verified checkpoint, then run exactly one REVIEW-tier review+fix agent and final verification.
5. Preserve approved-path enforcement, implied-scope correction rules, coordinator-only accepted checkpoints, conditional final commit, agent lifecycle closure, and scratch-ref creation/diff/cleanup/preservation behavior.
6. Resolve models through the canonical six-key configuration contract without reading `AGENTS.md` assignments.

Stable anchors are `Interface Contract`, `File Ownership`, `Contract inputs`, `Serialization required`, `sp-impl`, `fork_turns="none"`, FAST/REVIEW role names, prompt filenames, `refs/simplepower/scratch/<run-id>/`, approved-path markers, and no-worker-commit rules. Full duplicated lifecycle and shell-command prose is not stable.

### A-IC-5: Progressive-disclosure contract

- `skills/systematic-debugging/parallel-investigation.md` may hold the detailed optional-investigator angle, brief, permissions, report, and synthesis contract. The main skill must say exactly when it is required and retain the activation gate and summary invariants.
- `skills/subagent-driven-development/scratch-ref-workflow.md` may hold the temporary-index commands, phase ref names, diff commands, and cleanup commands. The main skill must require reading it before scratch-ref use and retain coordinator ownership, phase timing, evidence preservation, and checkpoint semantics.
- Existing `simplepower-config.md`, `codex-tools.md`, and `visual-companion.md` remain canonical and must not be copied into new files.
- Moving content is allowed only when the effective read path retains the original behavior.

### A-IC-6: Verification contract

The following commands are authoritative and must pass without native builds:

```bash
timeout 30s git diff --check
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s npm --prefix tests/brainstorm-server test
```

No `*.c`, `*.cc`, `*.cpp`, `*.h`, `*.hpp`, `*.cu`, or `*.cuh` file is in scope, so `xmake b` is not required.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
| --- | --- | --- | --- | --- |
| `docs/simplepower/plans/2026-07-13-skill-instruction-compaction.md` | Coordinator planning | create | Authoritative Branch A plan | No worker edits |
| `skills/brainstorming/SKILL.md` | A1 | modify | Compact brainstorming without behavioral change | A1 only |
| `skills/systematic-debugging/SKILL.md` | A2 | modify | Compact core four-phase procedure | A2 only |
| `skills/systematic-debugging/parallel-investigation.md` | A2 | create | Detailed optional-investigator contract | A2 only |
| `skills/subagent-driven-development/SKILL.md` | A3 | modify | Compact SDD lifecycle, canonical references, and capacity-aware rolling dispatch | A3 only |
| `skills/subagent-driven-development/implementer-prompt.md` | A3 | modify | Concise self-contained worker prompt | A3 only |
| `skills/subagent-driven-development/quick-verifier-prompt.md` | A3 | modify | Concise verifier prompt with unchanged limits | A3 only |
| `skills/subagent-driven-development/review-fix-prompt.md` | A3 | modify | Concise REVIEW prompt with unchanged authority | A3 only |
| `skills/subagent-driven-development/scratch-ref-workflow.md` | A3 | create | Canonical SDD scratch-ref mechanics | A3 only |
| `tests/simplepower-static/run-tests.sh` | A4 | modify | Replace sentence-coupled checks with invariant checks | A4 only; works from A-IC anchors |

## Implementation Tasks

### A1: Compact brainstorming

**Goal:** Express the approved brainstorming behavior once, with visual and configuration detail behind existing references.

**Contract inputs:** A-IC-1, A-IC-2, A-IC-5, A-IC-6.

**Serialization required:** No. A1 owns one file and A-IC-2 fixes behavior and stable anchors.

**Write scope:** `skills/brainstorming/SKILL.md`.

**Parallel:** Yes, with A2, A3, and A4.

**Risk:** High because concise wording must preserve hard gates and interaction order.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Replace the separate checklist, DOT flow, repeated process narrative, after-design section, and repeated principles with one ordered procedure.
2. Keep the hard gate and approved-path rule prominent and explicit.
3. Keep one concise context-explorer contract and reference canonical configuration rather than restating its schema.
4. Keep only the consent and per-question decision summary for the visual companion; direct accepted users to the existing guide.
5. Preserve A-IC-2 anchors and behavior; do not add runtime-efficiency behavior reserved for Branch C.

**Verification commands:**

```bash
timeout 30s git diff --check -- skills/brainstorming/SKILL.md
timeout 30s rg -n 'HARD-GATE|Approved Path Enforcement|simplepower-config.md|fork_turns="none"|visual-companion.md|simplepower:writing-plans' skills/brainstorming/SKILL.md
```

Expected: all anchors remain, the ordered flow is unambiguous, and whitespace is clean. Report changed files, commands/results, and any possible semantic ambiguity.

### A2: Compact systematic debugging

**Goal:** Keep the root-cause-first four-phase workflow in the main skill while moving detailed optional-investigator mechanics to one required reference.

**Contract inputs:** A-IC-1, A-IC-3, A-IC-5, A-IC-6.

**Serialization required:** No. A2 has an isolated write scope and a complete behavior contract.

**Write scope:** `skills/systematic-debugging/SKILL.md`; create `skills/systematic-debugging/parallel-investigation.md`.

**Parallel:** Yes, with A1, A3, and A4.

**Risk:** High because intentional pressure-resistant warnings must be compressed without authorizing guesses or premature fixes.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Retain one iron law and one four-phase procedure; merge duplicate stop/red-flag/rationalization language into phase-local rules.
2. Create `parallel-investigation.md` from the existing detailed activation, angle, brief, permissions, report, synthesis, and outcome material.
3. In the main skill, keep the initial-investigation stall gate, config validation, no-fix rule, six-agent cap, and mandatory read of the new reference before dispatch.
4. Preserve the minimal reproduction, single-hypothesis, single-change, verification, and three-failure rules.
5. Do not change examples or supporting references outside the write scope.

**Verification commands:**

```bash
timeout 30s git diff --check -- skills/systematic-debugging/SKILL.md skills/systematic-debugging/parallel-investigation.md
timeout 30s rg -n 'Root Cause|Phase 1|Phase 2|Phase 3|Phase 4|simplepower-config.md|fork_turns="none"|\.codex-debug/<instance-id>/|six|three' skills/systematic-debugging/SKILL.md skills/systematic-debugging/parallel-investigation.md
```

Expected: main and reference together satisfy A-IC-3 without duplicated full procedures. Report changed files, commands/results, and any pressure-resistance risk.

### A3: Compact subagent-driven development and prompts

**Goal:** Define the SDD lifecycle once, add capacity-aware rolling dispatch, and retain self-contained, concise worker/verifier/reviewer templates.

**Contract inputs:** A-IC-1, A-IC-4, A-IC-5, A-IC-6.

**Serialization required:** No. A3 owns the whole SDD skill family; no other task edits these files.

**Write scope:** `skills/subagent-driven-development/SKILL.md`; `skills/subagent-driven-development/implementer-prompt.md`; `skills/subagent-driven-development/quick-verifier-prompt.md`; `skills/subagent-driven-development/review-fix-prompt.md`; create `skills/subagent-driven-development/scratch-ref-workflow.md`.

**Parallel:** Yes, with A1, A2, and A4.

**Risk:** High because this is the largest and most interconnected contract and must keep all checkpoint, scope, and review safeguards.

**Model tier:** BEST — `gpt-5.5`, reasoning effort `xhigh`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Replace the repeated 22-step overview and later lifecycle restatements with one authoritative sequence from plan validation through final cleanup.
2. Consolidate model/config text to the canonical config reference while keeping resolved-tier validation and routing decisions explicit.
3. Create `scratch-ref-workflow.md` with the exact temporary-index, ref naming, diff, phase cleanup, and blocker-preservation mechanics; require its use at the relevant phases.
4. Rewrite the three prompts to state each required input, permission, prohibition, output, and direct-review rule once. They remain self-contained and must not rely on inherited turns.
5. Add the A-IC-4 rolling scheduler: compute the full ready set, fill available child-agent slots, close finished workers by default, and immediately launch queued ready work as each slot frees. State explicitly that runtime capacity is queuing, not task serialization, and that a ready task must not wait while a slot is free.
6. Preserve A-IC-4 stable anchors and do not introduce Branch C's delta-reporting or minimum-test guidance.

**Verification commands:**

```bash
timeout 30s git diff --check -- skills/subagent-driven-development
timeout 30s rg -n 'Interface Contract|File Ownership|Contract inputs|Serialization required|sp-impl|fork_turns="none"|quick-verifier-prompt.md|review-fix-prompt.md|refs/simplepower/scratch/<run-id>/|No worker commits|final commit' skills/subagent-driven-development
```

Expected: all lifecycle and role anchors remain and the prompt inputs/outputs are complete. Report changed files, commands/results, and any cross-file ambiguity.

### A4: Make static tests behavior-focused

**Goal:** Protect the A-IC invariants without pinning every original sentence or any size target.

**Contract inputs:** A-IC-1 through A-IC-6, especially the stable anchors in A-IC-2 through A-IC-4.

**Serialization required:** No. The Interface Contract defines assertions independently of workers' prose.

**Write scope:** `tests/simplepower-static/run-tests.sh`.

**Parallel:** Yes, with A1, A2, and A3.

**Risk:** Medium because removing brittle needles must not erase coverage of safety-critical rules.

**Model tier:** NORMAL — `gpt-5.4`, reasoning effort `high`.

**Worker role:** `sp-impl`.

**Implementation steps:**

1. Replace assertions that require full incidental sentences with checks for stable headings, references, limits, role names, and prohibited behavior from the Interface Contract.
2. Add file-existence and main-skill-reference checks for the two new progressive-disclosure files.
3. Retain negative checks for forbidden standalone specs, worker commits, unapproved fallbacks, agent fixes, and recursive reviewer behavior.
4. Add stable assertions for filling available capacity, immediate queued dispatch after completion, and the rule that capacity queuing does not change `Serialization required`.
5. Do not add line-count, word-count, percentage, snapshot, or exhaustive synonym assertions.
6. Keep unrelated static tests unchanged.

**Verification commands:**

```bash
timeout 30s git diff --check -- tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
```

Expected: the harness passes against the contractual anchors and fails clearly when a required invariant is absent. Report changed files, commands/results, and any invariant whose assertion remains wording-sensitive.

## Model Allocation

| Stage | Role | Tier | Resolved model | Effort | Reason |
| --- | --- | --- | --- | --- | --- |
| A1 | `sp-impl` brainstorming compaction | BEST | `gpt-5.5` | `xhigh` | Interaction-order and hard-gate semantics are behavior-shaping |
| A2 | `sp-impl` debugging compaction | BEST | `gpt-5.5` | `xhigh` | Root-cause and escalation safeguards are pressure-sensitive |
| A3 | `sp-impl` SDD compaction | BEST | `gpt-5.5` | `xhigh` | Broad cross-file workflow contract with high coordination risk |
| A4 | `sp-impl` static tests | NORMAL | `gpt-5.4` | `high` | Localized test-contract rewrite with explicit anchors |
| Plan review | Plan document reviewer | REVIEW | `gpt-5.5` | `xhigh` | Validate ownership, invariants, and executable workflow |
| Quick verification | Quick verifier | FAST | `gpt-5.3-codex-spark` | `xhigh` | Run mechanical checks and report nontrivial issues |
| Final review | Review+fix agent | REVIEW | `gpt-5.5` | `xhigh` | Review the complete behavior-preserving compaction |

Every dispatch passes `fork_turns="none"` and a self-contained task brief. Reviewers act directly: no Codex CLI, subagents, Simple Power skills, execution restart, or rerouting.

## Plan Review and Scratch Refs

The coordinator assigns an A-specific run id `YYYYMMDD-HHMMSS-<short-head>` and creates `refs/simplepower/scratch/<A-run-id>/plan-review/before` for this plan before REVIEW dispatch. Scratch refs must capture only the approved files without changing the real index:

```bash
A_RUN_ID="${A_RUN_ID:-$(date -u +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD)}"
A_PREFIX="refs/simplepower/scratch/$A_RUN_ID"
A_REF="$A_PREFIX/<phase>/<label>"
A_TMP_INDEX="$(mktemp)"
GIT_INDEX_FILE="$A_TMP_INDEX" git read-tree HEAD
GIT_INDEX_FILE="$A_TMP_INDEX" git add -- <approved-files>
A_TREE="$(GIT_INDEX_FILE="$A_TMP_INDEX" git write-tree)"
A_COMMIT="$(printf '%s\n' "simplepower scratch $A_RUN_ID <phase>/<label>" | git commit-tree "$A_TREE" -p HEAD)"
git update-ref "$A_REF" "$A_COMMIT"
rm -f "$A_TMP_INDEX"
```

If blocking issues require plan edits, create `plan-review/after-<n>` and return the same reviewer this concrete diff shape from the preceding anchor:

```bash
git diff refs/simplepower/scratch/<A-run-id>/plan-review/<previous-label> refs/simplepower/scratch/<A-run-id>/plan-review/after-<n> -- docs/simplepower/plans/2026-07-13-skill-instruction-compaction.md
```

Scratch refs are coordinator-only and local; failure to create a required anchor stops that review phase.

After combined approval and a successful accepted-plan commit, delete the A plan-review refs. Before quick verification create `quick-verifier/before` for every A implementation file. If the verifier makes typo-only edits, create `quick-verifier/after` and inspect that diff before checkpointing. Before final review create `review-fix/before`; if the reviewer edits, create `review-fix/after` and inspect the diff before final verification. Delete each phase after its successful checkpoint. On a blocker or failed checkpoint, preserve refs and report:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<A-run-id>" | while read -r ref; do git update-ref -d "$ref"; done
```

## Quick Verification

After A1-A4 finish, create the quick-verifier anchor and dispatch one FAST verifier. It may fix only obvious typos; structural, behavioral, test, or unclear changes are reported. Run:

```bash
timeout 30s git diff --check
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
```

Passing means the Branch A files are coherent enough for the coordinator's quick-verified checkpoint. Any failure blocks that checkpoint.

## Final Review and Fix

After the quick-verified checkpoint, create the review-fix anchor and dispatch exactly one REVIEW-tier review+fix agent over all Branch A-owned files. It may edit those files, must compare the result to A-IC-1 through A-IC-6, and reports files, commands, results, risks, and deviations. It does not commit or manage refs. The coordinator inspects any anchored review diff before final verification.

## Commit Checkpoints and Branch Delivery

1. **Accepted plan:** after both branch plans are reviewed and the user gives combined approval for both plans, allocations, and immediate sequential execution, create `optimize/skill-compaction` from `feature/simplepower-config` and commit only this Branch A plan.
2. **Quick-verified implementation:** after A1-A4 and the FAST verifier pass, commit all approved Branch A implementation files and tests.
3. **Final:** after REVIEW review+fix and final verification, commit remaining approved changes only when present; do not create an empty commit.

After the final checkpoint, push `optimize/skill-compaction` to `origin`. A push/authentication error is a blocker; do not rewrite history or switch to another remote. Branch C starts only from this final pushed Branch A tip.

## Current-Session Auto-Dispatch

After both plans receive REVIEW approval, ask once for combined approval of both reviewed plans, both allocations, and immediate sequential execution. On approval, perform Branch A's accepted-plan checkpoint and immediately invoke `simplepower:subagent-driven-development` for this file. In the current four-slot session, keep the coordinator slot and launch A1, A2, and A3 first; as soon as any finishes and its lifecycle checkpoint frees a slot, launch A4 without waiting for the other two. This runtime queue does not change A4's `Serialization required: No` contract. Do not offer another execution route. After Branch A is final-verified and pushed, proceed to the separately reviewed Branch C plan and its own accepted-plan checkpoint under the same combined approval.

## Final Verification

After review+fix, the coordinator runs all A-IC-6 commands. Every command must pass before the final checkpoint and push. A failure means the behavioral-equivalence contract is not verified and must be fixed within scope or reported as a blocker.

Finally check:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/<A-run-id>"
git status --short
git log -3 --oneline --decorate
```

No A scratch refs or unplanned tracked changes may remain after successful cleanup.

## Approved Path Enforcement

Do not remove or weaken an invariant to make compaction easier. Do not substitute docs-only changes, placeholders, skipped tests/review, a different branch topology, or a different execution route. If semantic equivalence, a required test, branch creation, commit, or push is blocked, stop with exact status and request fresh user approval before changing the approved path.
