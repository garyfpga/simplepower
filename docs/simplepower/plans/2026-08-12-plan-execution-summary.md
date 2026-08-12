# Plan Execution Summary Implementation Plan

**Goal:** Make every normal Simple Power run maintain a concise execution summary in its original plan while allowing narrowly bounded coordinator commits when committed state or later summary updates are genuinely required.

## Design Summary

The original tracked implementation plan becomes the coordinator-owned execution record. Future plans explicitly include their own path in execution write scope. Near completion, the coordinator appends an `Execution Summary` with current status and outcome, key changes, verification overview, notable findings/fixes/deviations, observed branch/HEAD/worktree state, and unresolved follow-ups. Later in-run findings refresh the current snapshot and append a labeled follow-up entry. Summaries remain concise: no raw logs, exhaustive file narration, or unrelated repository audit.

The workflow retains two mandatory checkpoint types: accepted plan and final completion. One combined approval also authorizes bounded coordinator-owned execution commits during the active run: an objective technical-prerequisite commit when approved testing or work requires committed state, and a summary-update commit when the summary cannot join the implementation commit or later findings reopen completion. Convenience commits, worker commits, and per-task commits remain forbidden. Fresh approval remains mandatory for scope, strategy, route, or verification changes, and authorization ends at final handoff.

The summary is mandatory when the original plan is a writable tracked file in the current Git repository. A genuinely impossible update may be skipped only with the exact reason reported. A writable summary that fails validation blocks completion. Because a document cannot record its own containing SHA without changing that SHA, the summary records observed pre-commit repository state; the final handoff reports the containing commit SHA.

This is one cohesive behavior-and-contract package. The skills, governance text, user documentation, metadata, and static assertions must change together to avoid contradictory commit or completion semantics. There is no material specialization benefit from delegation. Success means active guidance consistently implements the summary lifecycle and bounded commit exceptions, preserves existing safety gates, and all Codex-focused test suites pass.

## Implementation Route

**Main agent.** The policy, lifecycle, documentation, and regression assertions form one tightly coupled package. The coordinator will implement it directly in the current session with no `sp-impl` implementation worker.

## Exact Files

- `docs/simplepower/plans/2026-08-12-plan-execution-summary.md` — authoritative plan and coordinator-owned execution record for this run.
- `AGENTS.md` — contributor-level checkpoint and execution-commit policy.
- `README.md` — English and Chinese user-facing workflow and commit behavior.
- `.codex-plugin/plugin.json` — concise plugin capability metadata.
- `docs/README.codex.md` — Codex installation/workflow explanation.
- `docs/testing.md` — documented contract and verification expectations.
- `skills/brainstorming/SKILL.md` — approved design handoff facts required by planning.
- `skills/writing-plans/SKILL.md` — generated-plan structure, approval scope, and execution-record contract.
- `skills/subagent-driven-development/SKILL.md` — runtime summary lifecycle, bounded commits, failure handling, and finalization.
- `skills/subagent-driven-development/scratch-ref-workflow.md` — retain verifier evidence through the newest final-completion checkpoint.
- `skills/subagent-driven-development/quick-verifier-prompt.md` — keep the original plan read-only to the verifier.
- `skills/using-simplepower/references/codex-tools.md` — canonical Codex commit authorization and repository-state guidance.
- `tests/simplepower-static/run-tests.sh` — positive and negative regression assertions for the active contract.

## Implementation Steps

1. Confirm the work remains on `feature/plan-execution-summary`, the accepted-plan commit contains only this plan, and no unrelated worktree changes are present.
2. Update `AGENTS.md` to describe two mandatory coordinator checkpoint types plus approved, active-run execution commits. Preserve the bans on worker-owned and per-task commits and restrict extra commits to objective technical prerequisites or execution-summary updates.
3. Update `skills/brainstorming/SKILL.md` so its planning handoff carries the execution-record requirement, two mandatory checkpoint types, bounded conditional commits, and active-run approval boundary.
4. Update `skills/writing-plans/SKILL.md` so every new plan:
   - includes its own path in exact execution write scope and defines the coordinator-owned execution record;
   - requires the concise `Execution Summary` fields and labeled follow-up updates;
   - distinguishes two mandatory checkpoint types from conditional execution commits;
   - asks for one combined approval covering in-scope coordinator commits only for the active run;
   - retains fresh-approval gates, no-empty-commit behavior, and worker/per-task commit bans; and
   - hands the complete execution-record and commit contract to `simplepower:subagent-driven-development`.
5. Update `skills/subagent-driven-development/SKILL.md` to validate the plan path and execution-record authorization before edits. Add the runtime sequence:
   - collect coordinator-observed implementation, review, verification, and repository-state facts;
   - permit a coordinator prerequisite commit only when a concrete approved command or work step objectively requires committed state, never for convenience or history shaping;
   - after implementation and review verification, append or refresh the concise summary in the original plan;
   - when later findings arise before handoff, reopen completion, append a labeled follow-up, apply only approved in-scope work, and rerun affected and terminal verification;
   - after the last summary edit, inspect its diff and rerun required terminal checks before the newest final-completion commit;
   - report the final containing SHA outside the self-referential summary; and
   - when a tracked writable plan unexpectedly fails to update or validate, preserve work and scratch refs, report recovery details, and do not claim completion; when the plan is genuinely untracked, outside the repository, or unwritable, preserve verified work and allow completion only with the exact omission reason in the final handoff.
6. Update `skills/subagent-driven-development/scratch-ref-workflow.md` so quick-verifier refs survive every prerequisite or summary update and are deleted only after the newest final-completion checkpoint succeeds.
7. Update `skills/subagent-driven-development/quick-verifier-prompt.md` so the verifier reports any plan typo instead of editing the coordinator-owned execution record, even when the plan appears in the approved changed-file list.
8. Update `skills/using-simplepower/references/codex-tools.md` with the same bounded authorization semantics. State that intermediate commits require objective technical necessity, summary commits are coordinator-owned, authorization ends at handoff, and unrelated commits/merge/push/PR operations remain unauthorized.
9. Update `README.md`, `.codex-plugin/plugin.json`, `docs/README.codex.md`, and `docs/testing.md` to describe concise plan execution summaries, two mandatory checkpoints, conditional execution commits, fresh post-summary verification, and preserved worker/per-task restrictions. Keep both README languages semantically aligned.
10. Extend `tests/simplepower-static/run-tests.sh` with focused positive assertions for:
   - original-plan execution-record scope and required concise summary fields;
   - current-snapshot refresh plus labeled follow-up entries;
   - two mandatory checkpoint types plus objective prerequisite and summary-update commits;
   - combined active-run authorization and authorization expiry at handoff;
   - post-summary diff inspection and terminal verification; and
   - precise failure reporting when plan updates are genuinely impossible.
11. Add negative assertions rejecting always-separate summary commits, raw-log or unrelated full-repository audits, convenience commits, worker/per-task commits, indefinite post-handoff authorization, and completion after an unvalidated writable summary.
12. Run the mandatory FAST quick verifier using the commands below. Return every non-trivial finding to the main agent for diagnosis, an approved in-scope fix, and focused rerun.
13. Inspect the complete implementation diff against this plan, correct in-scope inconsistencies, and run the full Final Verification command set once.
14. Update this plan with its concise `Execution Summary`, including the first full verification results. Make no further content edits, inspect the summary diff, and rerun the complete Final Verification command set as terminal evidence.
15. Apply the final checkpoint condition: commit all remaining in-scope implementation and summary changes without another approval, do not create an empty commit, clean quick-verifier scratch refs after success, and report the final SHA and branch state.

## Risks

- **Commit authorization becomes broad:** Require an objective technical prerequisite or an execution-record update, coordinator ownership, approved in-scope content, active-run timing, and a recorded reason. Preserve fresh approval for path changes and all unrelated repository operations.
- **“Two checkpoints” remains contradictory:** Use “two mandatory checkpoint types” consistently and distinguish conditional execution commits from worker/per-task checkpoints across canonical skills, governance, docs, metadata, and tests.
- **The summary becomes noisy or stale:** Fix the concise field set, exclude raw logs and unrelated audits, refresh the current snapshot, and append only material follow-up facts.
- **Summary edits invalidate prior evidence:** Run the complete final suite before recording results, then rerun it unchanged after the last plan edit and before the final commit.
- **Self-referential commit data is inaccurate:** Record the observed pre-commit HEAD in the plan and reserve the containing final SHA for the final handoff or a later follow-up.
- **Failure handling loses evidence:** Keep the worktree and quick-verifier scratch refs intact on unexpected summary, validation, or commit blockers and report exact cleanup or recovery commands; distinguish those blockers from a genuinely impossible plan update that is explicitly disclosed at handoff.
- **Historical plans are rewritten unnecessarily:** Apply the new contract to newly generated and actively executing plans only; do not convert archived plans.

## Quick Verification

The mandatory FAST quick verifier uses resolved `model="gpt-5.6-luna"`, `reasoning_effort="xhigh"`, exact `fork_turns="none"`, and the restrictions in `skills/subagent-driven-development/quick-verifier-prompt.md`. It runs:

```bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check
```

All commands must exit 0. The static suite must prove the new execution-record lifecycle and bounded commit authorization while preserving no-worker/no-per-task rules.

## Final Verification

The main agent first inspects the complete diff for exact file scope, consistent summary fields, bounded authorization, failure behavior, English/Chinese documentation parity, and regression quality. Before writing this plan's execution summary, run:

```bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 30s git diff --check
```

All commands must exit 0. Then update only this plan with the concise execution summary and rerun the same six commands without further file edits. The second run is the terminal evidence for the final completion claim. Before the final commit, `git status --short` may list only the thirteen paths in `Exact Files`; after the commit, the worktree must be clean on `feature/plan-execution-summary`.

## Checkpoint Conditions

1. **Accepted plan checkpoint:** After one combined user approval covering this reviewed plan, the `Main agent` route, immediate current-session execution, this accepted-plan checkpoint commit, and the final reviewed/verified implementation checkpoint commit. Commit only this plan, then immediately invoke `simplepower:subagent-driven-development` in the current session.
2. **Final reviewed/verified implementation checkpoint:** After direct main-agent implementation, the mandatory FAST quick verifier, main-agent final diff review and in-scope fixes, the first full verification pass, this plan's execution-summary update, and the unchanged terminal verification pass. Create the final commit whenever uncommitted in-scope changes remain, without requesting another approval; do not create an empty commit.

This task has no objective need for an intermediate execution commit. Its requested execution summary will be included in the final checkpoint commit. The implementation being introduced will allow future accepted plans to authorize bounded prerequisite and follow-up summary commits during their active runs.

## Execution Summary

- **Status and outcome:** Implementation and first full verification are complete. The workflow now keeps a concise execution record in the original plan and permits only bounded, coordinator-owned prerequisite or summary-update commits during the approved active run. Terminal verification and the final checkpoint commit remain.
- **Key changes:** Updated governance, planning and execution skills, Codex guidance, English and Chinese user documentation, plugin metadata, and static regression coverage. The plan summary uses one current snapshot plus labeled follow-up entries for later material findings.
- **Verification overview:** Two FAST quick-verifier passes completed with no verifier edits. The main agent's first full pass succeeded: Simple Power static checks, 26 brainstorm-server tests, plugin-sync regression tests, five invocation-contract fixtures, nine explicit-request fixtures, and `git diff --check`.
- **Review findings, fixes, and deviations:** Main-agent review found two implied-scope omissions. The scratch-ref guide now retains evidence through the newest final-completion checkpoint, and the quick-verifier prompt now keeps the coordinator-owned plan read-only. Both files were added to exact scope and verification was rerun; the approved design and `Main agent` route did not change.
- **Repository state:** Branch `feature/plan-execution-summary`; pre-commit HEAD `8e339f3bb68d3d6b821e540f94a3e72c3c15eee4`; the worktree contains only the thirteen in-scope files. The containing final SHA will be reported in the handoff.
- **Unresolved issues and follow-ups:** None for this task. Two pre-existing, unrelated July scratch refs remain untouched.
