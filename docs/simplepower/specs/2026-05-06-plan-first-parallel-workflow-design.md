# Plan-First Parallel Workflow Design

## Context

Simple Power is still close to its Superpowers upstream shape. The current
active workflow preserves a standalone spec step, spec review, detailed
wave-by-wave planning, wave review, and multiple implementation mode choices.
That keeps discipline, but it makes Simple Power feel like a lightly adapted
fork instead of a Codex-first workflow optimized for fast parallel execution.

The new workflow should keep the most valuable part: brainstorming through
questions and design validation. After that, the normal path should move
directly into an authoritative implementation plan. The plan should include a
compact design summary, task allocation, model allocation, verification
commands, review allocation, and commit checkpoints. There should be no
standalone spec document in the future normal flow.

This file is a transition artifact produced by the current
`simplepower:brainstorming` workflow. The implementation of this design removes
standalone spec documents from future active Simple Power workflows.

## Goals

- Keep `simplepower:brainstorming` as the design conversation entry point.
- Eliminate standalone spec files from the normal active workflow.
- Write the implementation plan directly after brainstorming questions and
  design approval.
- Make the plan the authoritative workflow artifact.
- Include a compact `Design Summary` section inside each plan.
- Dispatch a BEST-tier plan reviewer to review the plan and allocation before
  user approval.
- Ask the user to approve the reviewed plan and model/task allocation together.
- Commit after the reviewed plan and allocation are accepted.
- Replace wave-by-wave implementation review with broad parallel file-edit
  dispatch.
- Use one `sp-impl` worker per practical ownership unit, where a unit can be
  one file or multiple related files.
- Run a quick verification subagent after all implementation workers finish and
  before the pre-review implementation checkpoint.
- Use `gpt-5.3-codex-spark` with `reasoning_effort="high"` for the quick
  verifier.
- Require the quick verifier to run linting checks, compile/build checks, and
  tests with proper timeouts.
- Allow the quick verifier to fix only tiny typo-level errors.
- Commit after all file edits and quick verification complete, before deep
  review.
- Dispatch one BEST-tier review+fix agent after the pre-review implementation
  checkpoint.
- Commit after final review/fix and final verification.
- Keep context-size guidance before implementation, including `/clear`
  recommendation and exact command text.
- Remove or rewrite active `.md` flow references that still describe the old
  standalone spec, spec review, or wave-review workflow.

## Non-Goals

- Do not keep the old spec-first flow as an active alternate path.
- Do not preserve wave-by-wave reviewer loops as the normal implementation
  model.
- Do not add worker-owned commits or per-task commits.
- Do not let implementation workers, plan reviewers, quick verifiers, or
  review+fix agents commit.
- Do not allow the quick verifier to make broad behavioral, architectural, or
  scope-changing fixes.
- Do not automatically run `/clear`; the user still performs it manually when a
  fresh-context path is recommended.
- Do not add Claude, Gemini, OpenCode, Cursor, or Copilot harness support.
- Leave historical archived specs and plans unchanged except where active docs
  or tests depend on their wording.

## Architecture

The active workflow becomes plan-first and aggressively parallel:

1. `simplepower:brainstorming` explores the project, asks clarifying questions,
   proposes approaches, and presents the design in conversation.
2. After the user approves the design, brainstorming invokes
   `simplepower:writing-plans` directly.
3. `simplepower:writing-plans` writes a single authoritative plan under
   `docs/simplepower/plans/`.
4. The plan contains a compact `Design Summary`, exact write scopes,
   implementation task allocation, model allocation, review allocation,
   verification commands, context-size handoff guidance, and commit checkpoints.
5. A BEST-tier plan reviewer reviews the plan and allocation.
6. The user approves the reviewed plan and allocation.
7. The coordinator commits the accepted plan.
8. `simplepower:subagent-driven-development` dispatches all non-conflicting
   implementation workers according to the approved file ownership.
9. A quick verifier subagent runs linting, build/compile checks, and tests with
   explicit timeouts. It may fix only tiny typo-level issues.
10. The coordinator commits the quick-verified implementation before deep
    review.
11. One BEST-tier review+fix agent reviews the whole implementation and fixes
    approved in-scope issues.
12. The coordinator runs final verification, commits final changes, and reports
    results.

The plan replaces the old spec+plan artifact pair. It is the single source of
truth for implementation scope, allocation, verification, and commit gates.

## Component Changes

`skills/brainstorming/SKILL.md` should keep project exploration, clarifying
questions, approach comparison, and conversational design approval. It should
remove the future requirement to write `docs/simplepower/specs/` files and
remove the user spec-review gate. Its terminal handoff should invoke
`simplepower:writing-plans` directly after design approval.

`skills/writing-plans/SKILL.md` should become the authoritative plan generator.
It should write a compact `Design Summary`, file ownership, task allocation,
model allocation, review allocation, exact verification commands, timeout
requirements, context-size handoff guidance, and the three coordinator commit
checkpoints. It should dispatch a BEST-tier plan reviewer before user approval.

`skills/writing-plans/plan-document-reviewer-prompt.md` should check that the
plan is complete, matches the approved conversation design, has practical file
ownership, uses appropriate FAST/BEST allocation, includes the quick verifier,
keeps `/clear` guidance, and contains no old spec-review or wave-review
requirements.

`skills/subagent-driven-development/SKILL.md` should replace the current
wave-by-wave implementation/review flow with plan-first broad parallel
implementation. It should dispatch `sp-impl` workers for non-conflicting file
ownership units, run the quick verifier, create the pre-review implementation
checkpoint, dispatch one BEST-tier review+fix agent, run final verification,
and create the final checkpoint.

`skills/subagent-driven-development/implementer-prompt.md` should remain the
prompt for file-edit workers. It should emphasize exact write scope, no
commits, no scope expansion, and concise reporting of changed files,
verification run by that worker, and blockers.

Add `skills/subagent-driven-development/review-fix-prompt.md` as the active
whole-implementation BEST-tier review+fix prompt. Update
`skills/subagent-driven-development/reviewer-prompt.md` and
`skills/subagent-driven-development/fixer-prompt.md` so active guidance no
longer routes through a per-wave reviewer plus fixer loop.

Add `skills/subagent-driven-development/quick-verifier-prompt.md` as the active
quick verifier prompt. The quick verifier must run linting, build/compile
checks, and tests with proper timeouts, and may edit only tiny typo-level
mistakes.

`README.md`, active skill docs, and static tests should describe only the new
plan-first workflow. Existing historical documents under old spec/plan archives
remain only as inactive history; active guidance must not recommend the retired
flow.

## Model Allocation

Simple Power should keep FAST/BEST model tiers for implementation allocation:

- FAST defaults to `SIMPLEPOWER_FAST_MODEL`.
- BEST defaults to `SIMPLEPOWER_BEST_MODEL`.
- `sp-impl` file-edit workers use FAST for narrow, localized, low-risk tasks.
- `sp-impl` file-edit workers use BEST for broad, ambiguous, cross-cutting,
  behavior-shaping, high-risk, or hard-to-test tasks.
- The plan reviewer uses BEST.
- The quick verifier always uses `model="gpt-5.3-codex-spark"` and
  `reasoning_effort="high"`.
- The final review+fix agent uses BEST.

The plan must show the allocation clearly enough for the user to approve or
request changes before implementation starts.

## Commit Policy

The coordinator owns exactly three normal commit checkpoints:

1. Commit after the user accepts the reviewed plan and allocation.
2. Commit after all implementation file edits and quick verification complete,
   before final review+fix.
3. Commit after final review+fix and final verification.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit.
If a required commit command fails, the coordinator stops, reports the failure
and current status, and asks the user how to proceed.

## Implementation Flow

After the accepted plan checkpoint, `simplepower:subagent-driven-development`
reads the plan and validates file ownership before dispatch. It then dispatches
all safe implementation tasks concurrently. A task is safe to run concurrently
when its write scope does not collide with another task and it does not depend
on another uncompleted task's edits. When common sense says one worker should
own multiple related files, the plan should assign those files together instead
of forcing one worker per file.

After all implementation workers finish, the coordinator validates changed files
against the approved write scopes. If a worker needs a true scope expansion, the
coordinator stops and asks the user. If a missing file was already implied by
the approved plan text, the coordinator may correct the plan's write scope and
record the correction before continuing.

The quick verifier then runs linting checks, build or compile checks, and tests
with explicit timeouts. It may fix tiny typo-level issues such as misspelled
identifiers, trivial import typos, or obvious punctuation mistakes that directly
cause the command failure. It must not make broader behavioral fixes, rewrite
architecture, change scope, or skip commands. Non-trivial failures are reported
back to the coordinator for the final review+fix phase or for user direction if
they block the approved path.

After quick verification is complete, the coordinator commits the pre-review
implementation checkpoint. Then one BEST-tier review+fix agent reviews the full
implementation against the approved plan, fixes in-scope issues, and reports
changed files, findings, verification commands, and any remaining concerns. The
coordinator runs final verification, creates the final commit, and reports.

## Context-Size Handoff

The new flow should still provide current-session versus `/clear` guidance
before implementation starts. After the reviewed plan and allocation are
accepted and the plan checkpoint is committed, `simplepower:writing-plans`
should compute the saved plan size with `wc -c "$PLAN_PATH"` or an equivalent
byte-counting command over the saved plan file.

If the plan is small enough for current context, the handoff should recommend
continuing in the current session and show the exact command:

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with plan-first parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

If the plan is large enough that fresh context is recommended, the handoff
should tell the user to run `/clear` manually and show:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with plan-first parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

Use the current strict greater-than `35840` byte threshold for fresh-context
recommendations, applied to the saved plan file because there is no standalone
spec file in the new flow.

## Error Handling

The workflow stops and asks the user when:

- The BEST-tier plan reviewer rejects the plan.
- The user rejects the plan or allocation.
- A worker needs a true scope expansion.
- Changed files do not match approved write scopes and the mismatch is not an
  implied write-scope omission.
- The quick verifier finds non-trivial lint, build, compile, or test failures.
- The final review+fix agent reports issues it cannot fix within approved
  scope.
- Any required verification command fails after the final review+fix pass.
- Any required coordinator commit fails.

The workflow does not authorize alternate implementation work, reduced scope,
stub substitutes, docs-only substitutes, skipped review, skipped verification,
or execution-mode switches. Any deviation from the approved plan requires fresh
explicit user approval at the moment the deviation is needed.

## Active Documentation Cleanup

The implementation should remove or rewrite active `.md` references to:

- standalone `docs/simplepower/specs/` generation in the normal workflow
- spec review as an active gate
- spec+plan checkpoint commits
- wave-by-wave implementation and reviewer loops
- separate reviewer versus inline reviewer mode as the primary implementation
  choice
- old `/clear` commands that describe wave-by-wave execution
- model allocation approval that depends on a spec+plan artifact pair
- task progress tables designed around per-wave `Implemented`, `Reviewed`,
  `Fixed`, and `Verified` status

Historical archived docs can remain if they are clearly historical and are not
used as active instructions, tests, or README guidance.

## Testing

Focused static tests should verify:

- `brainstorming` no longer requires writing `docs/simplepower/specs/`.
- `brainstorming` hands off directly to `simplepower:writing-plans`.
- `writing-plans` requires a compact `Design Summary` inside the plan.
- `writing-plans` dispatches a BEST-tier plan reviewer before user approval.
- `writing-plans` asks the user to approve the reviewed plan and allocation.
- `writing-plans` commits after the accepted plan and allocation.
- `subagent-driven-development` uses broad parallel `sp-impl` file-edit
  workers instead of wave-by-wave reviewer loops.
- `subagent-driven-development` requires quick verification with
  `gpt-5.3-codex-spark` and `reasoning_effort="high"`.
- Quick verification requires linting, build or compile checks, tests, and
  proper timeouts.
- Quick verification may fix only tiny typo-level issues.
- The final deep review/fix is one BEST-tier agent.
- Commit policy is exactly: after accepted plan, after all file edits plus quick
  verification before review, and after final review/fix plus final
  verification.
- Active README and skill guidance no longer recommend standalone spec review
  or old wave-based flow.
- Implementation handoff still includes `/clear` guidance and exact command
  text when context size suggests it.

Verification should include the existing Simple Power static test suite,
especially `tests/simplepower-static/run-tests.sh`, plus any skill-triggering
tests affected by the wording.
