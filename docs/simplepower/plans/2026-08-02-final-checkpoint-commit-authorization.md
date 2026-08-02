# Final Checkpoint Commit Authorization Implementation Plan

**Goal:** Make one combined implementation-plan approval explicitly authorize both coordinator checkpoint commits, including the final reviewed and verified implementation commit without a second approval prompt.

## Design Summary

The workflow currently permits an agent to interpret plan approval as implementation authorization while withholding the final commit: the planning approval language names immediate execution but not both commits, the execution skill makes the final commit conditional on ambiguous plan wording, and the Codex tool reference says Simple Power does not automatically commit. Align these sources around one contract: combined approval covers the accepted-plan checkpoint commit, current-session execution, and the final reviewed/verified implementation checkpoint commit. When work remains inside the accepted scope and final verification passes, the coordinator commits remaining in-scope changes without asking again; it skips only an empty commit. Scope, strategy, route, or verification changes still require fresh approval. Workers and quick verifiers remain unable to commit, and merge, push, PR, or unrelated commit operations remain outside this automatic checkpoint authorization.

This is one cohesive instruction-and-regression-test package. The wording is behavior-shaping but localized, and no part materially benefits from specialist delegation. Success means the active workflow cannot reasonably interpret accepted combined approval as permission to implement but not permission to create the final checkpoint commit.

Canonical configuration and dispatch rules remain in `skills/using-simplepower/references/simplepower-config.md`. Effective `fast_model` for this run is `gpt-5.6-luna-max` from `/home/gary/.codex/simplepower.toml`.

## Implementation Route

**Main agent.** The approval wording, execution semantics, tool-reference exception, and static assertions form one coupled policy change. The coordinator implements them directly in the current session; no `sp-impl` worker is dispatched.

## Exact Files

Source repository files:

- `docs/simplepower/plans/2026-08-02-final-checkpoint-commit-authorization.md` — authoritative accepted plan.
- `skills/writing-plans/SKILL.md` — make combined approval explicitly authorize both checkpoint commits.
- `skills/subagent-driven-development/SKILL.md` — make the final commit mandatory after compliant successful execution when uncommitted in-scope changes remain, without another approval prompt.
- `skills/using-simplepower/references/codex-tools.md` — replace the contradictory blanket no-auto-commit statement with the two-checkpoint exception and retain exclusions for other Git side effects.
- `tests/simplepower-static/run-tests.sh` — enforce aligned authorization language and reject the contradictory blanket rule.

Home configuration repository deployment paths, updated only after the source branch is verified, committed, and pushed:

- `/home/gary/.codex/.gitmodules` — set `submodule.simplepower.branch` to `fix/final-checkpoint-commit-authorization`.
- `/home/gary/.codex/simplepower` — update the submodule checkout and parent gitlink to the final pushed source commit on that branch.

No other files may be changed. Generated files are not expected.

## Implementation Steps

1. Confirm the source checkout is on `fix/final-checkpoint-commit-authorization`, the only pre-implementation source change is this plan, and `/home/gary/.codex` is clean on `master` with its Simple Power submodule at the starting source commit.
2. After combined approval, create the accepted-plan checkpoint commit containing only this plan.
3. Update `skills/writing-plans/SKILL.md` so the approval request explicitly covers the plan and route, immediate current-session execution, the accepted-plan checkpoint commit, and the final reviewed/verified implementation checkpoint commit. State that no second commit approval is requested when execution stays on the approved path.
4. Update `skills/subagent-driven-development/SKILL.md` so an accepted plan carrying that combined approval is sufficient commit authorization. After coordinator final diff review and successful final verification, create the final checkpoint commit whenever uncommitted in-scope changes remain; skip only an empty commit. Preserve fresh-approval gates for true scope, strategy, route, review, or verification changes and preserve the no-worker/no-per-task-commit rules.
5. Update `skills/using-simplepower/references/codex-tools.md` to state that Simple Power does not automatically merge, push, open PRs, or create unrelated commits, while the two coordinator checkpoint commits are authorized parts of an accepted normal workflow. Do not broaden authorization beyond those checkpoints.
6. Extend `tests/simplepower-static/run-tests.sh` with positive assertions for combined authorization of both checkpoint commits and no-second-approval final commit behavior. Add a negative assertion rejecting the old blanket statement that Simple Power does not automatically commit. Keep assertions focused on active canonical files.
7. Run the mandatory FAST quick verifier with the commands under Quick Verification. Any non-trivial issue returns to the main agent for an in-scope fix and rerun.
8. Inspect the complete source diff against this plan, correct any in-scope inconsistency, and run Final Verification.
9. Create the final reviewed/verified source checkpoint commit if uncommitted planned changes remain, then push `fix/final-checkpoint-commit-authorization` to `origin` and verify its remote SHA. The approved combined approval authorizes this checkpoint commit and push; no second commit prompt is required.
10. Confirm `/home/gary/.codex` is still clean on `master`. In its `simplepower` submodule, fetch the pushed source branch and check out `fix/final-checkpoint-commit-authorization` at the verified remote SHA. Update `/home/gary/.codex/.gitmodules` so the submodule branch setting names that branch.
11. Verify the home-repository diff contains only `.gitmodules` and the `simplepower` gitlink, the submodule is clean at the pushed source SHA on the new branch, and `.gitmodules` records the same branch.
12. Commit the two home-repository changes with a coordinator-owned commit, push `/home/gary/.codex` `master` to `origin`, and verify the remote SHA and clean final state. This separate deployment commit is explicitly requested by the user and is not a third Simple Power workflow checkpoint.

## Risks

- **Authorization becomes too broad:** Restrict automatic commits to the two named coordinator checkpoints and retain fresh approval for approved-path deviations and all merge/push/PR behavior except the explicitly requested source and home-repository pushes in this run.
- **Wording remains internally inconsistent:** Test both positive authorization anchors and absence of the old blanket no-auto-commit statement across all three canonical workflow sources.
- **An empty commit is created:** Require inspection of uncommitted in-scope changes before the final checkpoint and preserve the no-empty-commit rule.
- **Home configuration tracks the wrong branch or SHA:** Push and verify the source branch first, then update both `.gitmodules` and the gitlink to the exact remote SHA before committing the home repository.
- **Unrelated home changes are captured:** Require a clean home checkout before deployment and stage only `.gitmodules` plus the `simplepower` gitlink.

## Quick Verification

The mandatory FAST quick verifier uses resolved `model="gpt-5.6-luna"`, `reasoning_effort="max"`, exact `fork_turns="none"`, and the canonical restrictions in `skills/subagent-driven-development/quick-verifier-prompt.md`. It runs:

```bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check
```

All commands must exit 0. The static suite must report that combined approval covers both checkpoint commits, final in-scope commit execution requires no second approval, and the contradictory blanket no-auto-commit rule is absent.

## Final Verification

The main agent inspects the complete diff for exact scope, consistent authorization semantics, preserved deviation gates, and precise regression assertions, then runs:

```bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 30s git diff --check
```

All commands must exit 0. Before the final source checkpoint, `git status --short` may list only the five source paths in this plan. After the source commit and push, verify local `HEAD` equals `refs/remotes/origin/fix/final-checkpoint-commit-authorization` and the source tree is clean.

For home deployment, verify:

```bash
timeout 30s git -C /home/gary/.codex diff --check
timeout 30s git -C /home/gary/.codex diff --submodule=short -- .gitmodules simplepower
timeout 30s git -C /home/gary/.codex/simplepower status --short --branch
timeout 30s git -C /home/gary/.codex status --short
```

Before the home commit, only `.gitmodules` and `simplepower` may be modified. After the home commit and push, `/home/gary/.codex` and its submodule must be clean, local `master` must equal `origin/master`, the submodule must be on `fix/final-checkpoint-commit-authorization`, and its `HEAD` must equal the pushed source branch SHA.

## Checkpoint Conditions

1. **Accepted plan checkpoint:** After the user gives one combined approval covering this plan, the `Main agent` route, immediate current-session execution, the accepted-plan checkpoint commit, and the final reviewed/verified implementation checkpoint commit. Commit only this plan, then immediately invoke `simplepower:subagent-driven-development` in the current session.
2. **Final reviewed/verified implementation checkpoint:** After direct main-agent implementation, mandatory FAST quick verification, coordinator final diff review and in-scope fixes, and all final source verification commands pass. Create the final source commit whenever uncommitted in-scope changes remain, without requesting another approval; do not create an empty commit.

The subsequent source push and `/home/gary/.codex` branch/gitlink update, commit, and push are approved delivery operations explicitly requested for this run. They occur only after the final source checkpoint succeeds.
