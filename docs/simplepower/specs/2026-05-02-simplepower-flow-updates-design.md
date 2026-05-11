# Simple Power Flow Updates Design

## Goal

Update the Simple Power workflow so user-choice prompts use Codex's built-in
`askUserQuestion`-style multiple-choice question tool, implementation progress
is tracked in the plan document at task level, obsolete implementation handoff
JSON is removed, and completed implementation work is committed once after
final verification.

## Scope

This change applies to active Simple Power skills and active Codex-facing docs
and tests. It does not add Claude, Gemini, OpenCode, Cursor, or Copilot support.
It does not add per-task commits, automatic merge, automatic push, or automatic
PR creation.

## User Questions

Simple Power skills must use Codex's built-in `askUserQuestion`-style
user-question tool whenever a skill needs the user to choose between known
options.

Question requirements:

- Use multiple-choice answers when the choices are known.
- Offer 2-3 mutually exclusive choices.
- Mark one choice with `(Recommended)` when the workflow has a preferred path.
- Add short choice details that explain the tradeoff.
- Use free-form user input only when the answer cannot be safely reduced to
  fixed choices.

The main post-plan question must offer:

1. Start subagent implementation (Recommended): use
   `simplepower:subagent-driven-development`.
2. Start inline implementation: use `simplepower:executing-plans`.
3. Stop after plan: leave the plan ready for later.

If the Codex question tool is unavailable in the active mode, the agent must
ask the same options in plain text and continue from the user's answer.

## Remove Implementation Handoff JSON

Remove `.simplepower/implementation-handoff.json` from the Simple Power flow.
The file currently exists only for hook-based clear-context recovery and is not
read by `simplepower:subagent-driven-development`.

The implementation must remove:

- the writing-plans instructions that create the JSON artifact
- the handoff hook script
- hook-specific docs that describe installing the handoff hook
- tests that exist only to validate the handoff hook or JSON artifact

Plan files remain the source of truth for implementation handoff. A user who
wants to continue later can restart from the saved plan path.

## Task Progress Table

Every generated plan must include a task-level progress table near the top of
the plan, before the dependency graph:

```markdown
## Task Progress

| Task | Implemented | Reviewed | Fixed | Verified |
|------|-------------|----------|-------|----------|
| Task 1: Add Static Coverage | [ ] | [ ] | N/A | [ ] |
| Task 2: Update Skill Text | [ ] | [ ] | N/A | [ ] |
```

The table has one row for every task in the plan.

Lifecycle semantics:

- `Implemented`: checked after the task's implementation changes are accepted
  into the working tree.
- `Reviewed`: checked after reviewer/fixer review covers that task.
- `Fixed`: starts as `N/A`; change to `[x]` only if review found issues and a
  fix pass was applied for that task.
- `Verified`: checked after the task's required verification passes, or after
  wave verification passes for that task.

The coordinator updates this table. Subagent workers and reviewer/fixers report
task outcomes, but they do not edit the plan progress table unless explicitly
assigned. This avoids parallel write conflicts when a wave has multiple workers.

## Subagent Implementation Flow

`simplepower:subagent-driven-development` must update the task progress table
at task-level lifecycle points:

1. After an `sp-impl` worker returns and the coordinator accepts the changed
   files as in-scope, mark that task `Implemented`.
2. After the wave reviewer/fixer reviews that task, mark it `Reviewed`.
3. If the reviewer/fixer applied fixes for that task, mark `Fixed` as `[x]`;
   otherwise leave `Fixed` as `N/A`.
4. After the task's required verification or the containing wave verification
   passes, mark that task `Verified`.

Wave gating remains unchanged: downstream waves can start only after the current
wave is implemented, reviewed, fixed or confirmed as no-fix-needed, and
verified.

## Inline Implementation Flow

`simplepower:executing-plans` must use the same task progress table semantics
while executing tasks inline. The inline coordinator marks `Implemented`,
`Reviewed`, `Fixed`, and `Verified` as each lifecycle point completes.

If the inline flow does not dispatch a reviewer subagent for a low-risk task,
the main agent's explicit self-review counts as the review event and must be
recorded before verification is marked complete.

## Completion And Commit

Workers and reviewer/fixers still must not commit. The coordinator commits once
after all planned work is complete.

Completion requirements:

1. Run the plan's final verification and repo-required checks.
2. Confirm the task progress table is complete: every task has `Implemented`,
   `Reviewed`, and `Verified` checked; `Fixed` is either `[x]` or `N/A`.
3. Inspect `git status --short` and summarize the final diff.
4. Create one commit for the completed change set.
5. Do not merge, push, or create a PR unless the user separately asks.

This replaces final lifecycle wording that says to stop at a diff handoff or to
avoid committing entirely. It does not permit per-task commits.

## Files And Responsibilities

Expected implementation areas:

- `skills/writing-plans/SKILL.md`: require the task progress table, remove JSON
  handoff instructions, add the multiple-choice post-plan implementation
  question, and update self-review checks.
- `skills/subagent-driven-development/SKILL.md`: add task progress update
  checkpoints and final coordinator commit behavior.
- `skills/executing-plans/SKILL.md`: add inline task progress update checkpoints
  and final coordinator commit behavior.
- `skills/subagent-driven-development/implementer-prompt.md`: keep worker
  prompts from editing the progress table or committing.
- `skills/subagent-driven-development/wave-reviewer-fixer-prompt.md`: require
  task-by-task review/fix outcome reporting and no commits.
- active docs and tests: remove handoff JSON/hook coverage, add static coverage
  for the new question, progress table, and final commit rules.

## Testing

Static tests must verify:

- active Simple Power skill docs no longer reference
  `.simplepower/implementation-handoff.json`
- the handoff hook script and hook-specific tests are gone
- writing-plans requires `## Task Progress`
- writing-plans describes multiple-choice user questions with a recommended
  option
- subagent-driven-development and executing-plans describe task progress updates
- workers and reviewer/fixers still say not to commit
- coordinator workflows require one final commit after verification
- active planning and execution workflows still forbid per-task commits

Manual review must confirm generated plan examples are readable and that the
new progress table does not duplicate or replace the detailed step checkboxes.
