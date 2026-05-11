# Simple Power Checkpoint Commits Design

## Goal

Update Simple Power so durable workflow checkpoints create coordinator-owned
git commits. The workflow should commit the spec and plan after planning, then
commit each verified implementation wave after the plan progress update is
saved. A final commit should happen only when final verification or cleanup
leaves uncommitted changes.

## Context

Simple Power currently forbids per-task commits and requires one final
coordinator commit after all verification passes. That policy avoids worker
commit conflicts, but long wave-based runs have no committed recovery point
between the plan and final completion.

The new policy keeps the important boundary: workers, reviewers, and fixers do
not commit. The main coordinator owns all commits and creates them only at
stable workflow checkpoints.

## Scope

This change applies to active Simple Power workflow skills, active Codex-facing
project rules, and static tests.

It should update:

- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/executing-plans/SKILL.md`
- `tests/simplepower-static/run-tests.sh`
- `AGENTS.md`

Historical specs and plans do not need to be rewritten unless a test currently
depends on their old final-commit wording.

## Non-Goals

- Do not allow worker, reviewer, or fixer commits.
- Do not add per-task commits.
- Do not add automatic merge, push, pull request, or branch-finishing behavior.
- Do not require brainstorming to commit the design spec before the plan exists.
- Do not reintroduce non-Codex harness support in active docs.

## Commit Policy

Simple Power should replace "one final coordinator commit" with coordinator
checkpoint commits:

1. `simplepower:writing-plans` commits the written spec and plan together after
   the plan is saved and self-reviewed.
2. `simplepower:subagent-driven-development` commits after each implementation
   wave only after the coordinator has accepted results, completed review and
   fixes, run wave verification, updated the plan's `Task Progress` table, and
   saved that plan update.
3. `simplepower:executing-plans` follows the same verified-wave commit boundary
   for inline execution.
4. Final verification creates a final commit only if there are leftover
   uncommitted changes.

"No per-task commits" remains active policy. The wording should be clarified as
"no worker commits and no per-task commits" so verified wave commits are not
misclassified as task commits.

## Planning Flow

`simplepower:brainstorming` should still write and review the design spec
without requiring an immediate commit. Its documentation can clarify that the
spec is committed later with the implementation plan.

After `simplepower:writing-plans` writes and self-reviews the implementation
plan, it must create one coordinator commit containing the spec and plan before
asking the user to approve model allocation or choose an implementation path.

The plan self-review should verify the plan contains checkpoint commit
instructions and does not contain worker commits or per-task commit commands.

The plan document reviewer prompt should reject worker commits and per-task
commits, but accept and expect coordinator checkpoint commit instructions.

## Subagent Wave Flow

`simplepower:subagent-driven-development` should commit each wave at this
boundary:

1. Dispatch and accept `sp-impl` or `sp-impl-reviewer` worker results.
2. Validate changed files against task write scopes.
3. Run separate review and BEST-tier fixer passes when the selected review mode
   requires them.
4. Run wave verification.
5. Update every completed task in the plan's `Task Progress` table.
6. Inspect `git status --short`.
7. Commit the verified wave changes and the plan progress update.
8. Record the commit SHA in the main agent's wave notes or final report.
9. Start the next wave only after the checkpoint commit succeeds.

The exact ordering matters: the commit happens after the plan progress update,
not before it.

## Inline Execution Flow

`simplepower:executing-plans` should mirror the subagent wave boundary. For
inline execution, the main agent still performs implementation and review
steps, updates `Task Progress`, verifies the wave or task group, and then
creates a coordinator checkpoint commit before moving downstream.

If an inline plan is strictly sequential and has no explicit multi-task wave,
the task's verification boundary acts as the wave boundary. The commit is still
coordinator-owned and happens only after the plan progress update is saved.

## Final Verification

At final completion, both execution workflows should:

1. Run the final verification commands from the plan and any repo-required
   checks.
2. Confirm every task in `Task Progress` has `Implemented`, `Reviewed`, and
   `Verified` checked, with `Fixed` either `[x]` or `N/A`.
3. Inspect `git status --short`.
4. Create a final commit only if uncommitted changes remain.
5. Report verification results, checkpoint commit SHAs, any final commit SHA,
   changed files, and subagent lifecycle status.

If `git status --short` is clean after final verification, report that no final
commit was needed because the verified wave commits already captured the
change set.

## Error Handling

If a checkpoint commit fails because there are no changes, the coordinator may
continue only when that state is expected and documented in the wave notes.

If a checkpoint commit fails for any other reason, the coordinator must stop
before downstream work. It should fix the blocking issue when the cause is
clear, or ask the user for help when the cause cannot be diagnosed safely.

No downstream wave should start while the current wave has verified but
uncommitted changes.

## Testing

Static tests should verify:

- `writing-plans` requires a coordinator commit after the spec and plan are
  saved and self-reviewed.
- `writing-plans` still forbids worker commits and per-task commits.
- The plan reviewer prompt accepts coordinator checkpoint commits and rejects
  worker or per-task commits.
- `subagent-driven-development` requires a checkpoint commit after wave
  verification and `Task Progress` updates.
- `executing-plans` requires the same checkpoint commit boundary.
- Final commit wording says to commit only if uncommitted changes remain.
- `AGENTS.md` allows coordinator spec+plan and verified-wave commits while
  still forbidding per-task and worker commit requirements.

Manual review should confirm the revised workflow reads coherently and that the
commit boundary is unambiguous: after plan progress updates, not before.
