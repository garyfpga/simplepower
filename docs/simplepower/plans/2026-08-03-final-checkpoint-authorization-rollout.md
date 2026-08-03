# Final Checkpoint Authorization And Lean-Branch Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use simplepower:subagent-driven-development for aggregate parallel implementation. Dispatch all non-conflicting sp-impl file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent before final verification and final commit.

**Goal:** Make the final coordinator checkpoint commit unambiguous on optimize/lean-execution, then publish that branch, point the local /home/gary/.codex submodule at it in a parent commit, and fast-forward the matching parent/submodule checkouts on backup, axel, fpga01, desk, and office.

**Design Summary:** The current branch inherits a commit-authorization gap: simplepower:subagent-driven-development requires a final commit when in-scope changes remain, while the Codex tool mapping still says Simple Power does not automatically commit and the planning approval does not explicitly authorize the final checkpoint. Port the known authorization fix from sibling commit 3733c1e into the lean wording, add static assertions for the exception, and preserve the no-empty-commit rule. The source repository is verified and pushed first. The nested Simple Power checkout in /home/gary/.codex is then switched to the pushed optimize/lean-execution commit, and only the parent gitlink is committed on /home/gary/.codex master. Each remote host is then reconciled to its master parent branch and the gitlink-recorded optimize/lean-execution submodule commit using fetch, clean branch switches, and fast-forward-only parent updates. No reset, stash, force push, destructive cleanup, or unrelated file commit is authorized.

**Architecture:** The source fix has two non-overlapping implementation ownership units: policy-contract Markdown files and static-test assertions. The Interface Contract defines the exact authorization anchors so both workers can proceed in aggregate without depending on uncommitted prose. All cross-repository commits, pushes, submodule branch switches, and remote-host updates remain coordinator-owned delivery work after the source final checkpoint; they are not worker tasks or additional Simple Power implementation checkpoints.

**Tech Stack:** Markdown workflow contracts, Bash static checks, Git submodules, GitHub origin, and SSH aliases for the five deployment hosts.

**Implementation Route:** Grouped workers for the two disjoint source ownership units, followed by coordinator-owned source delivery and deployment synchronization.

**Model Allocation:** FAST/NORMAL/BEST/REVIEW tiers are assigned below and are independent of use_subagent. Resolve and validate the full six-key contract in skills/using-simplepower/references/simplepower-config.md: built-in defaults, then per-key overlays from /home/gary/.codex/simplepower.toml, repository <git-root>/simplepower.toml, the four non-empty SIMPLEPOWER_*_MODEL environment values, and explicit current-session instructions last. Missing higher-layer keys inherit, and every present TOML file is fatal if invalid even when a higher layer overrides its values. Do not read model assignments from AGENTS.md. FAST defaults to gpt-5.3-codex-spark-xhigh, NORMAL defaults to gpt-5.6-luna-max, and BEST and REVIEW default to gpt-5.6-sol-high. Parse the final dash as reasoning effort; valid suffixes are low, medium, high, xhigh, max, and ultra. The plan reviewer is a REVIEW-tier plan reviewer, the final review+fix agent is a REVIEW-tier review+fix agent, and the quick verifier uses FAST. The validated current-session values are BEST gpt-5.6-sol-medium, NORMAL gpt-5.6-luna-max, FAST gpt-5.6-luna-max, and REVIEW gpt-5.6-sol-high.

**Commit Policy:** The coordinator creates exactly three Simple Power source-repository checkpoints: the accepted plan after combined approval, the quick-verified implementation before final review, and the final reviewed/verified implementation. Workers, plan reviewers, quick verifiers, and review+fix agents do not commit. After the final source checkpoint is pushed, the explicitly user-authorized /home/gary/.codex parent gitlink commit is a separate deployment commit, not an additional Simple Power implementation checkpoint. Scratch refs under refs/simplepower/scratch/<run-id>/... are coordinator-owned local review anchors only; they are never pushed, merged, rebased, or counted as accepted commits.

---

## Interface Contract

### IC-1: Final checkpoint authorization

- The accepted combined approval covers the reviewed plan, model/task allocation, immediate current-session execution, and all three coordinator checkpoint commits: accepted plan, quick-verified implementation, and final reviewed/verified implementation.
- Once final verification passes on the approved path, the coordinator must create a final commit whenever uncommitted in-scope changes remain; it must not request a second commit approval for that already-approved checkpoint.
- The final checkpoint must not create an empty commit. If final verification leaves no uncommitted in-scope changes, the coordinator records the successful no-empty-commit outcome.
- Workers, plan reviewers, quick verifiers, review+fix agents, and individual tasks never commit, stage unrelated files, or manage refs.

### IC-2: Codex mapping exception

- The generic Codex tool mapping must preserve the rule that Simple Power does not otherwise automatically commit, merge, push, or open PRs.
- That rule has an explicit exception for the coordinator-owned, already-authorized Simple Power checkpoint commits defined by IC-1.
- No language may reintroduce a blanket prohibition that contradicts IC-1.

### IC-3: Required source anchors

The source contract must contain stable, testable anchors expressing:

- the exact phrase "combined approval authorizes all three coordinator checkpoint commits";
- the exact phrase "without requesting another approval" for a compliant final checkpoint;
- the exact phrase "must create a final commit when uncommitted in-scope changes remain";
- the exact phrase "do not create an empty commit"; and
- the exact phrase "does not otherwise automatically create" in the narrowed Codex mapping rule.

The exact wording may remain concise, but all five behaviors must be observable in the three policy files and asserted by the static test.

### IC-4: Source ownership and verification

- Policy-contract ownership is exactly skills/subagent-driven-development/SKILL.md, skills/writing-plans/SKILL.md, and skills/using-simplepower/references/codex-tools.md.
- Static-test ownership is exactly tests/simplepower-static/run-tests.sh.
- The quick verifier runs timeout 120s bash tests/simplepower-static/run-tests.sh after both workers finish and before the quick-verified checkpoint.
- Final verification reruns the static suite, git diff --check over all changed source files, and the final source status/diff checks before the source final checkpoint.

### IC-5: Source delivery and parent gitlink

- The source repository remains on optimize/lean-execution; its final verified commit is pushed to origin/optimize/lean-execution before the parent repository changes.
- The local parent repository is /home/gary/.codex, on master, with the nested repository at /home/gary/.codex/simplepower.
- The parent deployment commit stages only the simplepower gitlink, and records the exact pushed source commit. Existing parent configuration files remain untouched.
- The parent deployment commit is pushed to origin/master before remote rollout.

### IC-6: Remote synchronization

- Parent repository branch: master on every host.
- Nested Simple Power branch: optimize/lean-execution, checked out at the exact source commit recorded by the parent gitlink.
- Host paths: backup uses /home/gary/.codex; axel and fpga01 use /home/scpuser/.codex; desk and office use /home/gary/.codex.
- Remote parent updates use git fetch and fast-forward-only synchronization to origin/master; no reset, stash, force, or destructive cleanup is allowed.
- A remote host is clean only when the parent worktree is clean, parent HEAD equals origin/master, the nested checkout is clean, and nested HEAD equals git ls-tree HEAD simplepower from the parent.
- Any unrelated dirty path, non-fast-forward condition, fetch failure, checkout failure, or SHA mismatch blocks that host's rollout and is reported with exact status.

## File Ownership

| File or checkout | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---|---|---|
| docs/simplepower/plans/2026-08-03-final-checkpoint-authorization-rollout.md | Coordinator | create | Authoritative approved implementation plan and rollout contract | Planning artifact; no implementation worker edits it |
| skills/subagent-driven-development/SKILL.md | T1 policy contract | modify | Authorize the final checkpoint through combined approval and require a non-empty final commit when dirty in-scope changes remain | T1-only; no other worker edits this file |
| skills/writing-plans/SKILL.md | T1 policy contract | modify | Carry final checkpoint authorization through plan approval and current-session handoff | T1-only; no other worker edits this file |
| skills/using-simplepower/references/codex-tools.md | T1 policy contract | modify | Narrow the blanket no-auto-commit statement to preserve the approved checkpoint exception | T1-only; no other worker edits this file |
| tests/simplepower-static/run-tests.sh | T2 static contract tests | modify | Assert IC-1 through IC-3 and reject the contradictory blanket mapping | T2-only; may run in parallel with T1 because IC-3 supplies stable anchors |
| /home/gary/.codex/simplepower | Coordinator delivery | checkout state | Check out pushed optimize/lean-execution at the final source SHA | External nested checkout; no worker access |
| /home/gary/.codex | Coordinator delivery | modify gitlink and commit | Stage only the nested simplepower gitlink on parent master, commit it, and push origin/master | Separate repository and post-source-final deployment step |
| backup:/home/gary/.codex | Coordinator rollout | checkout state | Fast-forward parent master and nested optimize/lean-execution, then verify clean/SHA-aligned state | Remote coordinator work; no worker access |
| axel:/home/scpuser/.codex | Coordinator rollout | checkout state | Fast-forward parent master and nested optimize/lean-execution, then verify clean/SHA-aligned state | Remote coordinator work; no worker access |
| fpga01:/home/scpuser/.codex | Coordinator rollout | checkout state | Fast-forward parent master and nested optimize/lean-execution, then verify clean/SHA-aligned state | Remote coordinator work; no worker access |
| desk:/home/gary/.codex | Coordinator rollout | checkout state | Fast-forward parent master and nested optimize/lean-execution, then verify clean/SHA-aligned state | Remote coordinator work; no worker access |
| office:/home/gary/.codex | Coordinator rollout | checkout state | Fast-forward parent master and nested optimize/lean-execution, then verify clean/SHA-aligned state | Remote coordinator work; no worker access |

No source file outside this table may be edited. Parent and remote rollout operations may change only Git checkout metadata and the explicitly authorized parent gitlink commit.

## Implementation Tasks

### T1 — Update the final checkpoint policy contract

**Goal:** Port the known final-checkpoint authorization fix into the current lean wording without changing unrelated workflow behavior.

**Contract inputs:** IC-1, IC-2, IC-3, IC-4, the approved brainstorming design, and sibling commit 3733c1e as the known semantic reference. The current lean branch retains the three-checkpoint workflow and no-empty-commit behavior; this task adds explicit authorization and removes the contradiction.

**Serialization required:** No. T1 owns three non-overlapping policy files, and IC-1 through IC-3 define the shared behavior before dispatch.

**Write scope:**

- skills/subagent-driven-development/SKILL.md
- skills/writing-plans/SKILL.md
- skills/using-simplepower/references/codex-tools.md

**Parallel:** Yes, with T2. T1 does not edit tests/simplepower-static/run-tests.sh.

**Risk:** Medium. The change is documentation-contract behavior that affects whether the coordinator proceeds to a final commit, and the three files must not contradict one another.

**Model tier:** BEST — gpt-5.6-sol, reasoning effort medium, because the task is cross-file and behavior-shaping despite its small diff.

**Worker role:** sp-impl.

**Steps:**

1. Read the assigned files, IC-1 through IC-3, and sibling commit 3733c1e; preserve the current lean brief/report changes and the three-checkpoint structure.
2. In skills/subagent-driven-development/SKILL.md, state that accepted combined approval authorizes all three coordinator checkpoint commits, that compliant final verification requires committing remaining in-scope changes without a second approval, and that empty final commits remain forbidden.
3. In skills/writing-plans/SKILL.md, make the combined approval and current-session handoff carry the same final-checkpoint authorization; do not authorize worker or per-task commits.
4. In skills/using-simplepower/references/codex-tools.md, retain the no-automatic-commit rule for ordinary actions while explicitly excluding the approved coordinator checkpoint commits.
5. Run focused rg checks for every IC-3 anchor and timeout 30s git diff --check over the three policy files.

**Verification:**

- timeout 30s git diff --check -- skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/using-simplepower/references/codex-tools.md — must pass; failure means whitespace or patch corruption.
- timeout 30s rg -n "combined approval|without requesting another approval|must create a final commit when uncommitted|does not otherwise automatically create|do not create an empty commit" skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/using-simplepower/references/codex-tools.md — must find the IC-3 anchors; missing anchors block acceptance.

**Output:** Report changed files, exact anchors added or preserved, commands/results, deviations, risks, and readiness for coordinator acceptance. Do not commit, stage unrelated files, or manage refs.

### T2 — Add regression assertions for checkpoint authorization

**Goal:** Extend the static suite so it catches the missing authorization and contradictory blanket rule that caused the intermittent final-commit omission.

**Contract inputs:** IC-1, IC-2, IC-3, IC-4, the approved brainstorming design, and the existing tests/simplepower-static/run-tests.sh assertion style. T2 may assert against the exact stable phrases defined by IC-3 while T1 updates the policy files.

**Serialization required:** No. The Interface Contract supplies the required behavior and exact assertion anchors; T2 has no overlapping write scope with T1.

**Write scope:**

- tests/simplepower-static/run-tests.sh

**Parallel:** Yes, with T1.

**Risk:** Low. This is localized assertion churn, but a weak test could allow the policy contradiction to return.

**Model tier:** FAST — gpt-5.6-luna, reasoning effort max, because the task is mechanical static-test extension.

**Worker role:** sp-impl.

**Steps:**

1. Read IC-1 through IC-4 and the existing static-test helpers and commit-policy assertions.
2. Add require_contains_all checks for the writing-plans combined-approval authorization, SDD final-commit mandate/no-empty guard, and Codex mapping exception.
3. Add require_not_contains or equivalent negative coverage for the old contradictory blanket sentence if the updated mapping replaces it.
4. Preserve the existing lean checks, worker no-commit checks, and all current Simple Power namespace checks.
5. Run bash -n tests/simplepower-static/run-tests.sh and inspect the diff; the full suite runs in the coordinator quick-verification stage after T1 and T2 are integrated.

**Verification:**

- timeout 30s bash -n tests/simplepower-static/run-tests.sh — must pass; failure means invalid test-shell syntax.
- timeout 30s git diff --check -- tests/simplepower-static/run-tests.sh — must pass; failure means whitespace or patch corruption.

**Output:** Report changed files, assertions added, commands/results, deviations, risks, and readiness for coordinator acceptance. Do not commit, stage unrelated files, or manage refs.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---|---|---|---|
| Implementation | T1 policy contract | BEST | gpt-5.6-sol | medium | Cross-file behavior contract and contradiction removal |
| Implementation | T2 static contract tests | FAST | gpt-5.6-luna | max | Mechanical assertion additions with stable anchors |
| Planning | Plan reviewer | REVIEW | gpt-5.6-sol | high | Review authoritative plan, ownership, gates, and rollout safety |
| Verification | Quick verifier | FAST | gpt-5.6-luna | max | Run the static suite and inspect the integrated source diff |
| Final review | Review+fix agent | REVIEW | gpt-5.6-sol | high | Review the whole source change and fix only in-scope issues |

No optional explorer is needed: initial triage directly established the policy contradiction, exact source files, local submodule state, parent branch, host paths, and remote ancestry. use_subagent=true permits but does not require exploration.

## Plan Review And Approval

The coordinator records the run id in the format YYYYMMDD-HHMMSS-<short-head> and creates refs/simplepower/scratch/<run-id>/plan-review/before for this plan with the temporary-index procedure in skills/subagent-driven-development/scratch-ref-workflow.md before the first review. The plan reviewer receives the saved plan path, approved brainstorming context, run id, before ref, and a self-contained read-only review prompt.

Dispatch the plan reviewer exactly as spawn_agent(agent_type="worker", model="gpt-5.6-sol", reasoning_effort="high", fork_turns="none", message=<self-contained-review-prompt>). The REVIEW-tier reviewer performs the plan review directly in its worker; it does not run Codex CLI, spawn subagents, invoke Simple Power skills, restart execution, reroute the workflow, edit files, create refs, commit, or push.

If the reviewer reports blocking issues, the coordinator edits only this plan, reruns the focused self-review, creates refs/simplepower/scratch/<run-id>/plan-review/after-1 (or the next numbered after ref) with the same temporary-index procedure, and sends the same reviewer the exact diff command:

~~~bash
git diff refs/simplepower/scratch/<run-id>/plan-review/before refs/simplepower/scratch/<run-id>/plan-review/after-1 -- docs/simplepower/plans/2026-08-03-final-checkpoint-authorization-rollout.md
~~~

For later revisions, compare the immediately previous after ref to the new after ref with the same command shape. Keep the reviewer open until approval, unrecoverable interruption, or explicit user direction. Delete plan-review refs only after the accepted-plan checkpoint succeeds; preserve them and report the manual cleanup command on a blocker or failed checkpoint.

After reviewer approval, ask the user for one combined approval covering this reviewed plan, its model/task allocation, immediate current-session execution, and all three coordinator checkpoint commits. Do not create the accepted-plan checkpoint or dispatch implementation before that combined approval.

## Quick Verification

After T1 and T2 finish, the coordinator validates their reports and actual diff against IC-1 through IC-4, confirms every changed file is in ownership, and creates refs/simplepower/scratch/<run-id>/quick-verifier/before for the four approved source files. Dispatch one FAST quick verifier with spawn_agent(agent_type="worker", model="gpt-5.6-luna", reasoning_effort="max", fork_turns="none", message=<self-contained-prompt>). The prompt contains the approved files, contract anchors, worker deltas, risks, and these commands:

~~~bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check -- skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
~~~

All commands must pass. The quick verifier performs the assigned checks directly; it does not run Codex CLI, spawn subagents, invoke Simple Power skills, restart execution, reroute the workflow, commit, or manage refs. It may make only tiny typo-level edits that directly cause a command failure; it must report structural, semantic, test-rewrite, or unclear failures. If it edits files, the coordinator creates quick-verifier/after and inspects the anchored diff before the quick checkpoint. If it makes no edits, no after ref is created.

## Review+Fix

After the quick-verified source checkpoint, the coordinator creates refs/simplepower/scratch/<run-id>/review-fix/before for the same four source files and dispatches exactly one REVIEW-tier review+fix agent with spawn_agent(agent_type="worker", model="gpt-5.6-sol", reasoning_effort="high", fork_turns="none", message=<self-contained-prompt>). The reviewer checks IC-1 through IC-4, ownership, the lean-branch invariants, static-test coverage, no-worker-commit rules, and the approved path. It performs the assigned review directly in this worker; it must not run Codex CLI, spawn subagents, invoke Simple Power skills, restart execution, reroute the workflow, commit, or manage refs. It may edit only the four owned source files and must run focused verification for any fix. If it edits, the coordinator creates and inspects review-fix/after; otherwise no after ref is created.

## Commit Checkpoints

1. **Accepted plan:** After this plan, its allocation, immediate current-session execution, and all three checkpoint commits receive combined user approval, create the accepted-plan checkpoint in optimize/lean-execution before invoking simplepower:subagent-driven-development.
2. **Quick-verified implementation:** After T1/T2 and the FAST verifier pass, commit the four approved source files before REVIEW review+fix.
3. **Final source implementation:** After REVIEW review+fix and final verification pass, commit remaining in-scope source changes when present; do not create an empty commit. The accepted combined approval authorizes this checkpoint without another approval prompt.

Workers, the plan reviewer, quick verifier, and review+fix agent never commit. After the final source checkpoint, the coordinator pushes optimize/lean-execution to origin.

## Coordinator-Owned Delivery And Remote Rollout

These steps occur only after the final source checkpoint and push succeed. They are explicitly authorized by the user and are separate from the three Simple Power source checkpoints.

### Local parent deployment

1. Confirm the pushed source SHA with git ls-remote --exit-code --heads origin optimize/lean-execution and record the exact SHA.
2. In /home/gary/.codex/simplepower, fetch origin/optimize/lean-execution and confirm the nested worktree is clean. If local branch optimize/lean-execution does not exist, create it with git switch --track -c optimize/lean-execution origin/optimize/lean-execution. If it exists, switch to it and advance it only after git merge-base --is-ancestor optimize/lean-execution origin/optimize/lean-execution passes, using git merge --ff-only origin/optimize/lean-execution. In either case, require the nested HEAD to equal origin/optimize/lean-execution; never reset or force-update the branch.
3. In /home/gary/.codex, confirm branch master, confirm git status --short contains only the intended simplepower gitlink difference, stage only simplepower, and inspect git diff --cached --submodule=short -- simplepower.
4. Commit the parent gitlink with the coordinator deployment message chore: point codex config at lean execution, then push origin master.
5. Verify the parent is clean, HEAD equals origin/master, and git ls-tree HEAD simplepower equals /home/gary/.codex/simplepower HEAD.

Do not stage /home/gary/.codex configuration files, generated files, or any unrelated path.

### Remote host synchronization

For each host, use its exact parent path from IC-6. Fetch both the parent master and source optimize/lean-execution refs. Confirm the nested checkout has no file modifications. If local nested branch optimize/lean-execution does not exist, create and check it out with git switch --track -c optimize/lean-execution origin/optimize/lean-execution. If it exists, first switch to it, then require git merge-base --is-ancestor optimize/lean-execution origin/optimize/lean-execution and advance it with git merge --ff-only origin/optimize/lean-execution. Require nested HEAD to equal origin/optimize/lean-execution, then fast-forward the parent master to origin/master with git merge --ff-only origin/master. This order reconciles the existing submodule-only dirty state without reset or stash.

Run the following exact verification helper after synchronization. Its host/path pairs are fixed by IC-6:

~~~bash
check_remote() {
  host=$1
  codex_root=$2
  timeout 60s ssh "$host" "git -C '$codex_root' status --short --branch; git -C '$codex_root' rev-parse HEAD; git -C '$codex_root' rev-parse origin/master; git -C '$codex_root' ls-tree HEAD simplepower; git -C '$codex_root/simplepower' branch --show-current; git -C '$codex_root/simplepower' rev-parse HEAD; git -C '$codex_root/simplepower' status --short"
}
check_remote backup /home/gary/.codex
check_remote axel /home/scpuser/.codex
check_remote fpga01 /home/scpuser/.codex
check_remote desk /home/gary/.codex
check_remote office /home/gary/.codex
~~~

Expected results are: parent branch master, parent HEAD equals origin/master, parent status empty, nested branch optimize/lean-execution, nested HEAD equals the parent gitlink SHA, and nested status empty. Record each host's result. A failure blocks only that host and preserves its state for reporting; do not repair it with an unapproved alternate route.

## Final Verification

After review+fix, run every source check below before the final source checkpoint:

~~~bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check -- skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
timeout 30s git status --short --branch
timeout 30s git diff --name-only -- skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh
~~~

The coordinator performs the final source checkpoint only after the REVIEW-tier review+fix agent has completed and all final commands pass. The name-only diff must contain only the four approved source files; it is allowed to be non-empty because those changes are what the final source checkpoint commits. After that checkpoint, run timeout 30s git diff --exit-code -- skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md skills/using-simplepower/references/codex-tools.md tests/simplepower-static/run-tests.sh and the local parent checks. After the source push and parent deployment, run the remote host verification in the delivery section. A failed source test, failed push, dirty unrelated path, non-fast-forward parent update, or remote SHA mismatch blocks the affected checkpoint/host and is reported exactly.

At final reporting, run:

~~~bash
git for-each-ref --format='%(refname)' refs/simplepower/scratch/<run-id>
~~~

Successful checkpoints delete their phase refs. On a blocker or failed checkpoint, preserve remaining refs and report the manual cleanup command from skills/subagent-driven-development/scratch-ref-workflow.md.

## Current-Session Auto-Dispatch

After the plan reviewer approves and the user gives combined approval for this reviewed plan, its model/task allocation, and immediate current-session execution, the coordinator creates the accepted-plan checkpoint and immediately invokes simplepower:subagent-driven-development with:

~~~text
Execute docs/simplepower/plans/2026-08-03-final-checkpoint-authorization-rollout.md with aggregate parallel implementation from the approved Interface Contract. Use the approved FAST/NORMAL/BEST/REVIEW model allocation. Dispatch T1 and T2 as non-conflicting sp-impl workers with fork_turns="none", run the FAST quick verifier with the exact commands and timeouts, commit the quick-verified source implementation, run one REVIEW-tier review+fix agent, perform final verification, create the final source checkpoint when remaining in-scope changes exist, push the source branch, then perform the explicitly authorized coordinator-owned /home/gary/.codex gitlink deployment and remote host fast-forward verification.
~~~

No alternate route, reduced scope, skipped review, skipped verification, or worker-owned commit is authorized.
