# Simple Power TOML Model Resolution and Conditional Explorer Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use simplepower:subagent-driven-development for aggregate parallel implementation. Dispatch all non-conflicting sp-impl file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Replace AGENTS.md model assignment with layered simplepower.toml and environment resolution, make brainstorming and RO explorer dispatch conditional behind the use_subagent gate, and synchronize the verified result through the home config repository and five remote hosts.

**Design Summary:** The supported model configuration is resolved per key from built-in defaults, ~/.codex/simplepower.toml, the current repository's simplepower.toml, and the four SIMPLEPOWER_*_MODEL environment variables, with explicit current-session instructions remaining highest priority. The four defaults are REVIEW and BEST gpt-5.6-sol-high, NORMAL gpt-5.6-luna-max, and FAST gpt-5.3-codex-spark-xhigh. use_subagent remains a hard gate; false forbids brainstorming and RO explorers, while true lets the coordinator decide whether one read-only explorer is necessary. AGENTS model assignments are retired. The project changes are committed and pushed before the home submodule is updated; the home repository then receives the TOML and AGENTS changes, is committed and pushed, and is fast-forwarded on backup, fpga01, axel, office, and desk. Host-local bashrc cleanup removes only the four legacy model exports and their duplicate/commented copies.

**Architecture:** This remains an instruction-driven Codex workflow with no runtime configuration parser. The shared configuration reference is the Interface Contract for all active docs, skills, prompts, and static tests; non-overlapping workers can update those surfaces in parallel. Cross-repository and SSH deployment is coordinator-owned and serialized after the final Simple Power commit is pushed, so the home submodule always points at the final verified Simple Power commit.

**Tech Stack:** Markdown instruction contracts, TOML configuration, Bash static tests, Git, Git submodules, and SSH aliases.

**Model Allocation:** The current-session values explicitly supplied by the user are authoritative for this plan: REVIEW and BEST use model gpt-5.6-sol with reasoning effort high; NORMAL uses gpt-5.6-luna with reasoning effort max; FAST uses gpt-5.3-codex-spark with reasoning effort xhigh. For future sessions, start each tier at its built-in default, overlay home simplepower.toml, repository simplepower.toml, and the environment variable, then apply any explicit current-session instruction last. Do not read model assignments from AGENTS.md. The plan reviewer and final review+fix agent use REVIEW. The quick verifier uses FAST.

**Commit Policy:** The coordinator uses exactly three Simple Power repository checkpoint stages: the accepted plan checkpoint after reviewed-plan and combined user approval; the quick-verified implementation checkpoint after all file-edit workers and quick verification; and the final checkpoint after REVIEW-tier review+fix and final verification. The first two stages create commits. The final stage creates a commit only if final changes remain; if review+fix and final verification leave no uncommitted changes, record the successful no-final-commit outcome required by the execution skill and do not create an empty commit. Workers, the plan reviewer, quick verifier, review+fix agent, and individual tasks never commit. The requested home-repository synchronization commit is a separate coordinator-owned deployment commit after the final Simple Power push; it is not an additional Simple Power implementation checkpoint. Coordinator-owned temporary scratch refs under refs/simplepower/scratch/<run-id>/ are local review anchors only, are never pushed or accepted history, and are cleaned after successful checkpoints.

---

## Interface Contract

The following contract is authoritative for every implementation task and for
the coordinator-owned deployment stage. It is intentionally instruction-level:
there is no runtime resolver API to add.

### IC-1: Configuration sources and per-key resolution

The exact supported source files are:

1. /home/gary/.codex/simplepower.toml, when it exists.
2. <git-root>/simplepower.toml, when the current context is inside Git and the
   file exists.
3. The process environment for the four model keys.

Start with defaults, overlay keys from the home file, overlay keys from the
repository file, and overlay non-empty environment values. Missing keys at a
higher layer inherit the lower-layer value. A repository file does not replace
the home file as a whole. Explicit current-session user instructions remain
the final override after this resolution.

The environment variables are:

~~~text
SIMPLEPOWER_REVIEW_MODEL
SIMPLEPOWER_BEST_MODEL
SIMPLEPOWER_NORMAL_MODEL
SIMPLEPOWER_FAST_MODEL
~~~

Environment variables override only the four mandatory model tiers. They do
not configure use_subagent or subagent_model.

### IC-2: Supported schema, defaults, and validation

The only supported top-level TOML keys are:

~~~toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
~~~

The four mandatory model defaults are exactly:

~~~text
REVIEW  gpt-5.6-sol-high
BEST    gpt-5.6-sol-high
NORMAL  gpt-5.6-luna-max
FAST    gpt-5.3-codex-spark-xhigh
~~~

use_subagent defaults to Boolean false. subagent_model defaults to
gpt-5.6-luna-xhigh. Every model string is split at its final dash into the
model and reasoning_effort. Valid effort suffixes are low, medium, high,
xhigh, max, and ultra. Any present TOML file with malformed TOML, an unknown
key, a wrong type, an empty model, a missing model prefix, or an unsupported
effort suffix is a configuration error; a higher-precedence value must not
hide a broken lower-precedence file. An invalid non-empty environment model is
also an error. A missing file or missing supported key is not an error.

### IC-3: Optional explorer dispatch

For brainstorming and RO:

- effective use_subagent=false is a hard prohibition on explorer spawning;
  the coordinator performs any needed read-only inspection itself;
- effective use_subagent=true permits, but does not require, dispatch;
- the coordinator decides whether repository context or task complexity makes
  a separate explorer necessary;
- if necessary, dispatch exactly one read-only explorer using the parsed
  subagent_model and effort, with fork_turns="none";
- if unnecessary, continue coordinator-only;
- the explorer receives a self-contained brief, may only inspect and run
  read-only commands, and reports inspected files and commands, conventions,
  relevant history, risks, and explicit no-edit confirmation;
- if the coordinator decides dispatch is necessary but the configured model,
  multi-agent capability, or spawn is unavailable, stop and report the exact
  blocker rather than silently using another model or route.

The existing systematic-debugging rule remains separate: its investigation
agent is available only after its initial Phase 1 investigation stalls and is
still governed by use_subagent.

### IC-4: Mandatory tier allocation

Mandatory plan, implementation, quick-verifier, and review+fix roles are not
controlled by use_subagent. They use the four model tiers from IC-1 and IC-2.
For this approved session, the resolved dispatch settings are:

~~~text
FAST    model=gpt-5.3-codex-spark reasoning_effort=xhigh
NORMAL  model=gpt-5.6-luna reasoning_effort=max
BEST    model=gpt-5.6-sol reasoning_effort=high
REVIEW  model=gpt-5.6-sol reasoning_effort=high
~~~

Every Simple Power spawn, mandatory or optional, passes fork_turns="none" and
uses self-contained context.

### IC-5: Active files and verification commands

The active contract surfaces are the files listed in File Ownership. Historical
plans and specs under docs/simplepower/plans and docs/simplepower/specs are not
rewritten as part of this migration.

The required project checks are:

~~~bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s git diff --check
~~~

The first command is the authoritative static contract check. The second
checks the brainstorming server integration. The third checks packaged Codex
plugin synchronization. The final command catches whitespace errors.

### IC-6: Repository and submodule sequencing

The Simple Power repository is /home/gary/git/simplepower on branch
feature/simplepower-config with origin
git@github.com:garyfpga/simplepower.git.

The home repository is /home/gary/.codex on branch master with origin
git@github.com:garyfpga/codex-config.git. Its simplepower submodule tracks
the feature/simplepower-config branch of the Simple Power repository.

The coordinator must push the final Simple Power commit before updating the
home submodule. The home parent repository then records the final submodule
gitlink plus its config and AGENTS changes and is pushed before any remote-host
pull. No host may be stashed, overwritten, or force-updated.

### IC-7: Host-local shell cleanup

The only removable shell lines are exact active or commented assignments for:

~~~text
SIMPLEPOWER_REVIEW_MODEL
SIMPLEPOWER_BEST_MODEL
SIMPLEPOWER_NORMAL_MODEL
SIMPLEPOWER_FAST_MODEL
~~~

The cleanup may remove duplicate and commented copies of those assignments,
but must preserve every unrelated .bashrc line. If a host contains a shell
expression, conditional, or unexpected assignment form involving these names,
the coordinator reports and skips that host instead of broadening the edit.

## File Ownership

| File or operational target | Owner task | Change type | Responsibility | Parallel safety notes |
| --- | --- | --- | --- | --- |
| docs/simplepower/plans/2026-07-13-simplepower-toml-model-resolution.md | Coordinator planning | create | Authoritative approved implementation plan | Created before worker dispatch; no worker edits |
| AGENTS.md | T1 shared contract and public docs | modify | Replace the old root-AGENTS model-precedence requirement with the TOML/env contract while preserving contributor and checkpoint rules | Only T1 edits this file |
| README.md | T1 shared contract and public docs | modify | Document model defaults, layered sources, schema, validation, and conditional optional dispatch | Only T1 edits this file |
| docs/README.codex.md | T1 shared contract and public docs | modify | Keep the Codex install guide consistent with the shared contract | Only T1 edits this file |
| docs/testing.md | T1 shared contract and public docs | modify | Update static/manual test expectations for layered config and conditional explorers | Only T1 edits this file |
| skills/using-simplepower/references/simplepower-config.md | T1 shared contract and public docs | modify | Define the canonical resolution, schema, defaults, validation, and optional-dispatch contract | Only T1 edits this file |
| skills/brainstorming/SKILL.md | T2 conditional explorer flow | modify | Make use_subagent a hard gate and explorer dispatch a coordinator judgment | Only T2 edits this file |
| skills/ro/SKILL.md | T2 conditional explorer flow | modify | Apply the same hard-gate and conditional initial-explorer behavior to RO | Only T2 edits this file |
| skills/using-simplepower/references/codex-tools.md | T3 tier docs and prompts | modify | Update Codex dispatch mappings and tier resolution to the TOML/env contract | Only T3 edits this file |
| skills/writing-plans/SKILL.md | T3 tier docs and prompts | modify | Update planning model resolution/defaults while preserving plan-review and checkpoint rules | Only T3 edits this file |
| skills/writing-plans/plan-document-reviewer-prompt.md | T3 tier docs and prompts | modify | Make plan review validate the new model source precedence and defaults | Only T3 edits this file |
| skills/subagent-driven-development/SKILL.md | T3 tier docs and prompts | modify | Update implementation/review allocation and model resolution references | Only T3 edits this file |
| skills/subagent-driven-development/quick-verifier-prompt.md | T3 tier docs and prompts | modify | Update the FAST-tier default and parsing example | Only T3 edits this file |
| skills/subagent-driven-development/review-fix-prompt.md | T3 tier docs and prompts | modify | Keep review+fix prompt references aligned with the new contract if present | Only T3 edits this file |
| tests/simplepower-static/run-tests.sh | T4 static contract tests | modify | Replace stale AGENTS/old-default assertions and add layered-config and conditional-dispatch assertions | Only T4 edits this file |
| /home/gary/.codex/simplepower | Coordinator home synchronization | modify | Update the submodule checkout and parent-repo gitlink to the final pushed Simple Power commit | Serialized after final Simple Power push |
| /home/gary/.codex/simplepower.toml | Coordinator home synchronization | modify | Add use_subagent, subagent_model, and the four approved model values | Serialized before the home commit |
| /home/gary/.codex/AGENTS.md | Coordinator home synchronization | modify | Add the home-level Simple Power config pointer and explicitly stop defining model assignments here | Serialized before the home commit |
| /home/gary/.bashrc | Coordinator local shell cleanup | modify | Remove only the four legacy assignments and their duplicate/commented copies | Host-local; not tracked by the home Git repository |
| backup:/home/gary/.codex | Coordinator remote rollout | modify | Fast-forward the home checkout after its push | Serialized per host; clean/master precondition |
| backup:/home/gary/.codex/simplepower | Coordinator remote rollout | modify | Checkout the gitlink supplied by the pulled home parent | Serialized after parent pull |
| backup:/home/gary/.bashrc | Coordinator remote rollout | modify | Remove only the approved legacy assignments | Serialized after safety inspection |
| fpga01:/home/gary/.codex | Coordinator remote rollout | modify | Fast-forward the home checkout after its push | Serialized per host; clean/master precondition |
| fpga01:/home/gary/.codex/simplepower | Coordinator remote rollout | modify | Checkout the gitlink supplied by the pulled home parent | Serialized after parent pull |
| fpga01:/home/gary/.bashrc | Coordinator remote rollout | modify | Remove only the approved legacy assignments | Serialized after safety inspection |
| axel:/home/gary/.codex | Coordinator remote rollout | modify | Fast-forward the home checkout after its push | Serialized per host; clean/master precondition |
| axel:/home/gary/.codex/simplepower | Coordinator remote rollout | modify | Checkout the gitlink supplied by the pulled home parent | Serialized after parent pull |
| axel:/home/gary/.bashrc | Coordinator remote rollout | modify | Remove only the approved legacy assignments | Serialized after safety inspection |
| office:/home/gary/.codex | Coordinator remote rollout | modify | Fast-forward the home checkout after its push | Serialized per host; clean/master precondition |
| office:/home/gary/.codex/simplepower | Coordinator remote rollout | modify | Checkout the gitlink supplied by the pulled home parent | Serialized after parent pull |
| office:/home/gary/.bashrc | Coordinator remote rollout | modify | Remove only the approved legacy assignments | Serialized after safety inspection |
| desk:/home/gary/.codex | Coordinator remote rollout | modify | Fast-forward the home checkout after its push | Serialized per host; clean/master precondition |
| desk:/home/gary/.codex/simplepower | Coordinator remote rollout | modify | Checkout the gitlink supplied by the pulled home parent | Serialized after parent pull |
| desk:/home/gary/.bashrc | Coordinator remote rollout | modify | Remove only the approved legacy assignments | Serialized after safety inspection |

## Implementation Tasks

### T1: Update the shared configuration contract and public documentation

**Goal:** Make the canonical Simple Power documentation describe per-key TOML
resolution and the approved four model defaults, with AGENTS model assignments
retired.

**Contract inputs:** IC-1, IC-2, IC-3, IC-4, IC-5; approved design sections 1
and 3; exact T1 file ownership above.

**Serialization required:** No. The shared contract is explicit and T1 has no
overlapping write scope with T2, T3, or T4.

**Write scope:** AGENTS.md; README.md; docs/README.codex.md; docs/testing.md;
skills/using-simplepower/references/simplepower-config.md.

**Parallel:** Yes, with T2, T3, and T4.

**Risk:** High. These files are the canonical contract and are duplicated into
installation and testing guidance.

**Model tier:** BEST, resolved model gpt-5.6-sol, reasoning effort high.

**Worker role:** sp-impl.

**Implementation steps:**

1. Replace the old root-AGENTS model lookup language with the source order and
   per-key overlay from IC-1. Preserve the rule that explicit current-session
   instructions are highest priority.
2. Add the six-key TOML schema and exact defaults from IC-2. Keep
   use_subagent and subagent_model separate from the four environment overrides.
3. Document final-dash parsing and all validation failures, including the rule
   that a broken lower-precedence file is still fatal.
4. Document that no repository-level TOML is created by this change, while a
   present repository file is supported and overlays the home file.
5. Update active test instructions and public installation guidance. Do not
   modify historical plans or specs.

**Verification commands:**

~~~bash
timeout 30s git diff --check -- AGENTS.md README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
timeout 30s rg -n 'review_model|best_model|normal_model|fast_model|SIMPLEPOWER_REVIEW_MODEL|SIMPLEPOWER_FAST_MODEL|home.*repository|per-key|environment' README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
~~~

Expected result: the new schema, defaults, source order, and validation are
present and no whitespace errors are reported. A failure means T1 is not
internally consistent and must be corrected before the checkpoint.

**Completion report:** List every changed file, both commands and their
results, and any unresolved documentation risk. Do not commit.

### T2: Make brainstorming and RO explorer dispatch conditional

**Goal:** Implement the approved hard gate and model-judged explorer decision
in the two affected active skills.

**Contract inputs:** IC-1, IC-3, IC-4, IC-5; approved design section 2; exact
T2 file ownership above.

**Serialization required:** No. IC-3 supplies the complete dispatch behavior
and T2 has no overlapping write scope with the other tasks.

**Write scope:** skills/brainstorming/SKILL.md; skills/ro/SKILL.md.

**Parallel:** Yes, with T1, T3, and T4.

**Risk:** High. This changes when a separate model is allowed to run and must
not weaken the read-only or isolation guarantees.

**Model tier:** BEST, resolved model gpt-5.6-sol, reasoning effort high.

**Worker role:** sp-impl.

**Implementation steps:**

1. Replace unconditional explorer dispatch under use_subagent=true with an
   explicit coordinator judgment about whether exploration is necessary.
2. Keep use_subagent=false as a hard no-spawn gate and specify coordinator-only
   read-only inspection in that case.
3. Preserve exactly one explorer when needed, the parsed subagent_model, the
   self-contained prompt, read-only scope, no-edit report, and
   fork_turns="none".
4. Keep the existing hard-stop behavior if a required enabled dispatch cannot
   run; do not introduce fallback models or alternate execution routes.
5. Leave systematic-debugging's separate post-stall escalation semantics
   unchanged except where its shared-reference wording is automatically
   covered by IC-1.

**Verification commands:**

~~~bash
timeout 30s rg -n 'use_subagent=false|use_subagent=true|necessary|coordinator|fork_turns="none"|read-only' skills/brainstorming/SKILL.md skills/ro/SKILL.md
timeout 30s git diff --check -- skills/brainstorming/SKILL.md skills/ro/SKILL.md
~~~

Expected result: both skills contain the hard gate, conditional decision, and
isolation requirements. A failure means the dispatch contract is incomplete.

**Completion report:** List changed files, command output summaries, and any
ambiguity requiring coordinator review. Do not commit.

### T3: Update tier allocation docs and dispatch prompt templates

**Goal:** Align every active mandatory-tier document and prompt with the new
TOML/repository/environment resolution and explicit four-tier defaults.

**Contract inputs:** IC-1, IC-2, IC-4, IC-5; approved design sections 1 and 3;
exact T3 file ownership above.

**Serialization required:** No. Each T3 file is owned only by T3 and IC-4
provides the exact values and parsing behavior needed by all prompt surfaces.

**Write scope:** skills/using-simplepower/references/codex-tools.md;
skills/writing-plans/SKILL.md; skills/writing-plans/plan-document-reviewer-prompt.md;
skills/subagent-driven-development/SKILL.md;
skills/subagent-driven-development/quick-verifier-prompt.md;
skills/subagent-driven-development/review-fix-prompt.md.

**Parallel:** Yes, with T1, T2, and T4.

**Risk:** High. These files control future plan allocation, worker isolation,
   review allocation, and verifier behavior.

**Model tier:** BEST, resolved model gpt-5.6-sol, reasoning effort high.

**Worker role:** sp-impl.

**Implementation steps:**

1. Replace every old built-in tier value and old AGENTS lookup with IC-1 and
   IC-2. Do not leave quoted model assignments in active documentation.
2. Preserve the four roles FAST, NORMAL, BEST, and REVIEW; keep REVIEW for
   plan review and review+fix and FAST for quick verification.
3. Keep all plan-interface, scratch-ref, combined-approval, and exactly-three
   checkpoint rules intact while changing only model source/default wording.
4. Update the plan reviewer prompt so it reviews the new source order rather
   than rejecting plans for correctly removing AGENTS model assignments.
5. Update quick-verifier and review+fix templates to use the approved model
   values and retain their no-commit and no-recursion constraints.

**Verification commands:**

~~~bash
timeout 30s rg -n 'SIMPLEPOWER_(REVIEW|BEST|NORMAL|FAST)_MODEL|review_model|best_model|normal_model|fast_model|simplepower.toml|AGENTS' skills/using-simplepower/references/codex-tools.md skills/writing-plans skills/subagent-driven-development
timeout 30s git diff --check -- skills/using-simplepower/references/codex-tools.md skills/writing-plans skills/subagent-driven-development
~~~

Expected result: all active tier documents identify TOML and environment
resolution, use the approved defaults, and retain the required workflow
controls. A failure means one prompt surface is stale or inconsistent.

**Completion report:** List changed files, commands and results, and any
remaining stale-language risk. Do not commit.

### T4: Rewrite static contract assertions

**Goal:** Make the static test harness enforce the new contract and reject
stale AGENTS precedence, old defaults, and unconditional explorer wording.

**Contract inputs:** IC-1 through IC-5; exact T4 file ownership above; T1-T3
are allowed to be uncommitted because the Interface Contract supplies the
expected public text and behavior.

**Serialization required:** No. T4 owns only the test runner and can write
assertions against the accepted Interface Contract while documentation workers
edit their separate files.

**Write scope:** tests/simplepower-static/run-tests.sh.

**Parallel:** Yes, with T1, T2, and T3. The full test command runs in the
coordinator quick-verification stage after all workers finish.

**Risk:** Medium. The edits are mostly mechanical assertion replacement, but
stale negative checks could allow contradictory active documentation.

**Model tier:** FAST, resolved model gpt-5.3-codex-spark, reasoning effort xhigh.

**Worker role:** sp-impl.

**Implementation steps:**

1. Replace old model values with the four IC-2 defaults wherever active
   assertions document tier defaults.
2. Replace assertions requiring root-AGENTS precedence or exclusive
   repository-file replacement with assertions for per-key home-to-repo-to-env
   overlay and AGENTS retirement.
3. Add positive assertions for all six TOML keys, the four environment names,
   final-dash parsing, invalid-file behavior, and explicit current-session
   override wording.
4. Change brainstorming and RO assertions from unconditional enabled dispatch
   to the IC-3 hard gate plus model-judged necessity. Keep systematic-debugging
   post-stall assertions.
5. Preserve all unrelated active-path, namespace, scratch-ref, and checkpoint
   guards.

**Verification commands:**

~~~bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 30s git diff --check -- tests/simplepower-static/run-tests.sh
~~~

Expected result: the runner parses successfully and has no whitespace errors.
The coordinator quick verifier is the first full semantic execution.

**Completion report:** List the test file, both commands and results, and any
assertion that could not be made exact from IC-1 through IC-5. Do not commit.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
| --- | --- | --- | --- | --- | --- |
| T1 shared contract/docs | sp-impl | BEST | gpt-5.6-sol | high | Broad, cross-cutting contract and public documentation behavior |
| T2 brainstorming/RO flow | sp-impl | BEST | gpt-5.6-sol | high | Behavior-shaping dispatch and safety change |
| T3 tier docs/prompts | sp-impl | BEST | gpt-5.6-sol | high | Cross-cutting future workflow and review allocation contract |
| T4 static assertions | sp-impl | FAST | gpt-5.3-codex-spark | xhigh | Mechanical fixture and assertion churn against an exact contract |
| Plan review | REVIEW-tier plan reviewer | REVIEW | gpt-5.6-sol | high | Required independent plan-contract review |
| Quick verification | quick verifier | FAST | gpt-5.3-codex-spark | xhigh | Required static, integration, and packaging checks |
| Final review and fix | REVIEW-tier review+fix | REVIEW | gpt-5.6-sol | high | Whole-implementation correctness and approved-path review |

The model values above are the explicit current-session values. In later
sessions, source resolution follows IC-1; no task or reviewer reads a model
assignment from AGENTS.md.

## Coordinator Operational Rollout

This stage is coordinator-owned, not an sp-impl worker task, because it
mutates a separate Git repository and five SSH hosts and has intentional
sequential dependencies.

### Home repository preparation after the final Simple Power push

1. Recheck that /home/gary/git/simplepower is clean at the final pushed
   feature/simplepower-config commit and record its full commit ID.
2. Recheck /home/gary/.codex is clean on master and that its simplepower
   submodule is clean. If either checkout is dirty, divergent, detached, or
   not on the expected branch, stop before changing it.
3. Update the submodule to the final pushed feature branch commit using
   git -C /home/gary/.codex submodule update --remote --checkout simplepower.
   Verify the submodule HEAD equals the recorded final Simple Power commit.
4. Update /home/gary/.codex/simplepower.toml to:

~~~toml
use_subagent = true
subagent_model = "gpt-5.6-luna-max"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
~~~

5. Add a Simple Power configuration section to
   /home/gary/.codex/AGENTS.md that says model tiers are not assigned in
   AGENTS.md, the home TOML is the base file, a repository simplepower.toml
   overlays it per key, and the four environment variables override both.
   Preserve all existing subagent isolation and Xmake/CUDA instructions.
6. Remove only the four exact active or commented legacy model assignments from
   /home/gary/.bashrc, preserving all unrelated lines.
7. Run the home-repo diff check and confirm only AGENTS.md, simplepower.toml,
   and the simplepower gitlink are tracked changes. The .bashrc change is
   host-local and must not be added to this commit.
8. Commit the home parent repository with a coordinator message such as
   feat: update Simple Power configuration, then push origin master. Verify
   the pushed commit and the gitlink after the push.

The home synchronization commit occurs only after the final Simple Power push,
so it points at the final reviewed implementation. It is separate from the
three Simple Power checkpoint commits and no worker creates it.

### Remote host rollout

Process each host independently in this order: backup, fpga01, axel, office,
desk.

For each host, use a 30-second SSH timeout for the read-only preflight. Confirm
that ~/.codex exists, is a Git checkout on master with no worktree changes,
the submodule is clean, and ~/.bashrc contains only exact legacy assignment
forms if it contains any matches. If any precondition fails, report the host
and skip all mutations on that host.

For a host passing preflight:

1. Run git -C ~/.codex pull --ff-only origin master.
2. Run git -C ~/.codex submodule update --init --recursive and verify the
   submodule equals the home repository's pushed gitlink.
3. Remove only the IC-7 assignments from ~/.bashrc.
4. Verify the parent checkout is clean, the submodule points at the final
   Simple Power commit, and the four legacy names no longer occur in the
   shell file.

Never use force-push, reset, checkout-overwrite, stash, or broad shell-file
rewrites. A failure on one host is reported and does not authorize changing
the approved path for another host.

## Plan Review

Before dispatching the plan reviewer, the coordinator self-reviews this plan
against the writing-plans checklist: compact design summary, exact Interface
Contract, complete file ownership, non-overlapping aggregate tasks, explicit
Contract inputs, concrete Serialization required values, model allocation,
timeouts, exactly three Simple Power checkpoints, and coordinator-only
deployment.

Create a coordinator-owned temporary review anchor using run id format
YYYYMMDD-HHMMSS-<short-head>:

~~~bash
SP_RUN_ID=<run-id>
SP_SCRATCH_PREFIX=refs/simplepower/scratch/$SP_RUN_ID
SP_TMP_INDEX=$(mktemp)
GIT_INDEX_FILE=$SP_TMP_INDEX git read-tree HEAD
GIT_INDEX_FILE=$SP_TMP_INDEX git add -- docs/simplepower/plans/2026-07-13-simplepower-toml-model-resolution.md
SP_TREE=$(GIT_INDEX_FILE=$SP_TMP_INDEX git write-tree)
SP_COMMIT=$(printf '%s\n' "simplepower scratch $SP_RUN_ID plan-review/before" | git commit-tree "$SP_TREE" -p HEAD)
git update-ref "$SP_SCRATCH_PREFIX/plan-review/before" "$SP_COMMIT"
rm -f "$SP_TMP_INDEX"
~~~

Dispatch one REVIEW-tier plan reviewer directly in its current worker with
model gpt-5.6-sol, reasoning effort high, and fork_turns="none". Give it the
plan path, approved brainstorming decisions, exact source-order change,
conditional explorer rule, three-checkpoint policy, and the
plan-review/before ref. It must review read-only, must not run Codex CLI,
spawn agents, invoke Simple Power skills, restart, reroute, or commit, and
must return the status/issues/scratch-ref/recommendations format from the
reviewer prompt.

If it finds a blocking issue, edit only the plan, rerun the focused
self-review, create plan-review/after-1 (or the next numbered ref), and send
the same reviewer a concrete comparison:

~~~bash
git diff refs/simplepower/scratch/<run-id>/plan-review/before refs/simplepower/scratch/<run-id>/plan-review/after-1 -- docs/simplepower/plans/2026-07-13-simplepower-toml-model-resolution.md
~~~

For later revisions compare the previous after ref to the new after ref.
Keep the same reviewer open until approval, unrecoverable interruption, or
explicit user direction.

## Quick Verification

After all T1-T4 workers finish, create
refs/simplepower/scratch/<run-id>/quick-verifier/before for the approved
implementation file list using the temporary-index pattern. Dispatch one
FAST-tier quick verifier with model gpt-5.3-codex-spark, reasoning effort
xhigh, and fork_turns="none". It runs:

~~~bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s git diff --check -- AGENTS.md README.md docs docs/simplepower/plans/2026-07-13-simplepower-toml-model-resolution.md skills tests/simplepower-static/run-tests.sh
~~~

Expected result: all commands pass. The quick verifier may fix only a tiny
typo-level error that directly causes a check to fail. It must report any
behavior change, structural edit, test rewrite, public-interface issue, or
unclear failure to the coordinator and must not commit or modify scratch refs.
If it makes a tiny fix, create quick-verifier/after and inspect:

~~~bash
git diff refs/simplepower/scratch/<run-id>/quick-verifier/before refs/simplepower/scratch/<run-id>/quick-verifier/after -- <approved-files>
~~~

## Final Review And Fix

After the coordinator creates the quick-verified implementation checkpoint,
create refs/simplepower/scratch/<run-id>/review-fix/before for the approved
implementation file list. Dispatch exactly one REVIEW-tier review+fix agent
with model gpt-5.6-sol, reasoning effort high, and fork_turns="none".

The agent reviews the complete implementation against this plan, IC-1
through IC-7, file ownership, the actual diff, and all verification results.
It may fix in-scope issues in the approved files, but must not reduce scope,
skip checks, create substitutes, change the execution route, commit, create
scratch refs, spawn agents, run Codex CLI, invoke Simple Power skills, restart,
or reroute. If it edits files, create review-fix/after and inspect:

~~~bash
git diff refs/simplepower/scratch/<run-id>/review-fix/before refs/simplepower/scratch/<run-id>/review-fix/after -- <approved-files>
~~~

The review+fix report must identify status, findings, fixes, exact files,
focused verification, and remaining issues.

## Commit Checkpoints

Exactly three future coordinator checkpoint stages apply to the Simple Power
repository:

1. Accepted plan checkpoint: after the plan reviewer approves and the user
   gives combined approval for the reviewed plan, model/task allocation, and
   immediate current-session execution. Commit the plan in the current repo
   before invoking simplepower:subagent-driven-development.
2. Quick-verified implementation checkpoint: after T1-T4 finish and the FAST
   quick verifier passes. Commit the implementation in the current repo.
3. Final checkpoint: after the REVIEW-tier review+fix agent and final
   verification pass. If final changes remain, commit the final reviewed state
   in the current repo; otherwise record the successful no-final-commit
   outcome and do not create an empty commit. In either case, push the final
   Simple Power state on feature/simplepower-config before the home submodule
   update.

Workers and all review/verifier roles must not commit. The home parent commit
is the separate coordinator deployment commit defined above.

After each successful phase checkpoint, delete that phase's scratch refs:

~~~bash
git for-each-ref --format='%(refname)' refs/simplepower/scratch/<run-id>/<phase> | while read -r ref; do git update-ref -d "$ref"; done
~~~

If a checkpoint fails or execution stops because of user direction or a
blocker, preserve the refs and report this cleanup command instead:

~~~bash
git for-each-ref --format='%(refname)' refs/simplepower/scratch/<run-id> | while read -r ref; do git update-ref -d "$ref"; done
~~~

## Current-Session Auto-Dispatch

After the plan reviewer approves, request one combined approval covering the
reviewed plan, the model/task allocation, and immediate current-session
execution. Do not create the accepted plan checkpoint before that approval.

After combined approval, create the accepted plan checkpoint and immediately
invoke simplepower:subagent-driven-development in this same session with:

~~~text
Execute docs/simplepower/plans/2026-07-13-simplepower-toml-model-resolution.md with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST/REVIEW allocation. Dispatch all non-conflicting sp-impl workers T1-T4 with fork_turns="none", run the quick FAST-tier verifier with the listed timeouts, commit the quick-verified implementation, run one REVIEW-tier review+fix agent, run final verification, and create the final checkpoint commit only if final changes remain; otherwise record the successful no-final-commit outcome without an empty commit. Then push the final Simple Power state before performing the coordinator-owned home submodule and remote-host rollout.
~~~

Do not create a project-local implementation JSON artifact, offer alternate
execution routes, or authorize reduced scope.

## Verification

The coordinator runs the following final checks after review+fix and before the
final Simple Power checkpoint:

~~~bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s git diff --check
timeout 30s rg -n 'review_model|best_model|normal_model|fast_model|SIMPLEPOWER_REVIEW_MODEL|SIMPLEPOWER_FAST_MODEL|use_subagent=false|use_subagent=true|fork_turns="none"' README.md docs skills tests/simplepower-static/run-tests.sh
~~~

The expected result is a passing active-contract suite, passing integration
and plugin-sync checks, no whitespace errors, and visible new source/default
and conditional-dispatch wording. Any failure blocks the final checkpoint
until the plan-approved implementation is corrected or the user approves a
change to the approved path.

After the final Simple Power push, the coordinator verifies the home commit and
each host using the IC-6 and IC-7 preflight/postflight checks. Finally run:

~~~bash
git for-each-ref --format='%(refname)' refs/simplepower/scratch/<run-id>
~~~

After successful phase cleanup this must print no refs. If the workflow stops
because of user direction, a blocker, or a failed checkpoint commit, preserve
the remaining refs and report the manual cleanup command above.
