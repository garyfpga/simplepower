# Simple Power Codex Fork Design

## Context

Simple Power is a Codex-only fork of Superpowers. The fork keeps the parts of
Superpowers that are working well for this workflow, especially brainstorming,
and removes multi-harness compatibility work that is not needed for a Codex-only
setup.

The fork also changes implementation execution from linear, per-task subagent
work into DAG-aware wave execution. The goal is faster development through safe
parallelism without giving up the quality gates that make the original workflow
valuable.

## Goals

- Rename active product, package, plugin, docs, and skill namespace references
  from Superpowers to Simple Power / `simplepower`.
- Make the repo Codex-only and hard-prune Claude, Gemini, OpenCode, and Cursor
  harness support from the active codebase.
- Keep brainstorming behavior unchanged while updating brand, namespace, and
  output paths.
- Change planning so implementation plans include a dependency graph, task write
  scopes, dispatch waves, and verification boundaries.
- Change subagent-driven development so independent tasks can run in parallel by
  wave.
- Use an implementation subagent role named `sp-impl`, mapped to
  `gpt-5.4-mini` with high effort.
- Replace separate spec-compliance and code-quality review subagents with one
  wave-level reviewer/fixer subagent that uses the main agent's type and effort.
- Remove per-task git commit requirements from plans, implementer prompts, and
  review mechanics.
- Preserve explicit fork attribution in the landing page and explain why the
  fork exists.

## Non-Goals

- Supporting Claude Code, Gemini, OpenCode, Cursor, or Copilot as active
  harnesses.
- Rewriting brainstorming behavior beyond required brand, namespace, and path
  updates.
- Replacing the full skill system with a new architecture.
- Adding third-party runtime dependencies.
- Automating commits, merges, pushes, or PR creation as part of execution.

## Product Identity

The active product name is **Simple Power**.

The active skill namespace and install directory are:

- Skill namespace: `simplepower:*`
- Codex skill symlink: `~/.agents/skills/simplepower`
- Docs output path: `docs/simplepower/...`
- Plugin/package identifier: `simplepower`

The README landing page should include a clear attribution note:

> Simple Power is a fork of Superpowers by Jesse Vincent / Prime Radiant. This
> fork exists because I use Codex only and want a smaller workflow tuned for
> faster parallel implementation while keeping the design and review discipline
> that works well in Superpowers.

Historical release notes or archived material may mention Superpowers, but active
usage docs, skill handoffs, generated paths, and examples should use
`simplepower`.

## Architecture

Simple Power has three active workflow lanes.

### Brainstorming

Brainstorming keeps the current behavior:

- explore project context before proposing designs
- ask one clarifying question at a time
- propose alternatives before selecting a design
- present design sections for user validation
- write an approved design document
- transition to planning only after user approval

Allowed changes are limited to brand, namespace, and path updates. For example,
generated specs should move from `docs/superpowers/specs/...` to
`docs/simplepower/specs/...`.

### Planning

`writing-plans` changes from a purely linear plan writer into a DAG-aware
dispatch planner.

Plans still include exact file paths, implementation guidance, test guidance,
and verification commands. Each task also declares:

- dependencies
- owned files or write scope
- whether it can run in parallel
- risk level
- review boundary
- focused verification command

Every plan includes a **Dispatch Plan** section that groups tasks into waves. A
wave can run in parallel only when all tasks in the wave have no dependency edge
between them and no overlapping write scope.

The plan self-review and plan reviewer prompt must validate:

- every task is reachable in the dependency graph
- no cycles exist
- every dependency references a real task
- each task has a declared write scope
- parallel waves have non-overlapping write scopes
- downstream tasks wait for upstream outputs
- verification commands cover each wave and the final integration

### Execution

`subagent-driven-development` executes one dispatch wave at a time.

For each wave, the main agent:

1. Records the starting state with read-only git commands such as `git diff` and
   `git status --short`.
2. Dispatches one `sp-impl` worker per independent task in the wave.
3. Gives each worker its full task text, local context, owned write scope, and
   verification command.
4. Waits for all workers in the wave.
5. Checks changed files for overlap or unexpected edits.
6. Dispatches one reviewer/fixer subagent for the whole wave.
7. Runs wave verification.
8. Marks the wave complete only after verification passes.

The reviewer/fixer subagent uses the same agent type and effort as the main
agent. It reviews the actual diff, not the implementer reports, for both spec
compliance and code quality. If it finds problems, it fixes them directly within
the wave's allowed scope and reports all changes.

No downstream wave starts until the current wave review and verification pass.

## Components

### Active Components To Update

- `README.md`: rebrand to Simple Power, explain the fork, and document Codex-only
  usage.
- `.codex-plugin/plugin.json`: rename plugin identity, display name,
  descriptions, links, and icon paths.
- `package.json`: rename the package to `simplepower` and remove stale non-Codex
  entrypoints.
- `docs/README.codex.md`: become the primary install and usage guide.
- `skills/using-superpowers/`: rename to `skills/using-simplepower/` and update
  bootstrap language.
- `skills/brainstorming/SKILL.md`: preserve behavior while updating brand,
  namespace, and output paths.
- `skills/writing-plans/SKILL.md`: add DAG analysis, dispatch waves, write
  scopes, and no-commit plan structure.
- `skills/writing-plans/plan-document-reviewer-prompt.md`: validate dependency
  graph correctness and dispatch safety.
- `skills/subagent-driven-development/SKILL.md`: replace linear per-task review
  with wave execution and combined review/fix.
- `skills/subagent-driven-development/implementer-prompt.md`: remove commit
  requirements, define `sp-impl`, require changed-file reporting, and preserve
  focused verification.
- `skills/subagent-driven-development/wave-reviewer-fixer-prompt.md`: new
  combined spec-compliance and code-quality review/fix prompt.
- `skills/requesting-code-review/`: simplify to diff-based final/manual review
  or remove it from the SDD dependency path.

### Components To Prune From Active Repo

- `.claude-plugin/`
- `.cursor-plugin/`
- `.opencode/`
- `GEMINI.md`
- Claude, Gemini, OpenCode, Cursor, and Copilot installation docs
- harness-specific hooks used only for non-Codex session bootstrap
- non-Codex harness tests

`CLAUDE.md` may be removed or replaced with a Codex-oriented contributor guide.
The upstream PR rejection guidance does not apply to this fork unless changes are
being proposed back to upstream Superpowers.

## Plan Format

Implementation plans should include a dispatch manifest like this:

```markdown
## Dispatch Plan

### Wave 1
**Tasks:** 1, 2
**Can run in parallel:** yes
**Shared dependencies:** none
**Write scopes:** non-overlapping
**Review:** wave-level
**Verification:** npm test -- parser

### Wave 2
**Tasks:** 3
**Can run in parallel:** no
**Shared dependencies:** Task 1, Task 2
**Write scopes:** `skills/subagent-driven-development/**`
**Review:** wave-level
**Verification:** npm test -- subagent-driven-development
```

Each task should include:

```markdown
### Task N: Task Name

**Depends on:** Task M, or none
**Write scope:** `path/to/file`, `path/to/dir/**`
**Parallel:** yes/no
**Risk:** low/medium/high
**Review boundary:** task-level or wave-level
**Verification:** exact command with expected result

**Files:**
- Modify: `exact/path`
- Test: `exact/path`

- [ ] Step 1: Make the specified code or test change.
- [ ] Step 2: Run the focused verification command and confirm the expected
      result.
- [ ] Step 3: Report changed files, verification results, and any concerns.
```

Task-level review remains available for high-risk work, but the default is
wave-level review.

## Subagent Roles

### `sp-impl`

`sp-impl` is the implementation worker role.

- Model: `gpt-5.4-mini`
- Effort: high
- Responsibility: code changes for one assigned task
- May run focused tests when practical
- Must stay inside assigned write scope unless it stops and asks
- Must not commit
- Must report status, files changed, tests run, and concerns

### Wave Reviewer/Fixer

The wave reviewer/fixer:

- uses the same agent type and effort as the main agent
- reviews the full wave diff for spec compliance and code quality
- inspects actual code instead of trusting worker reports
- fixes problems directly when they are inside wave scope
- stops and reports if a fix would exceed scope or conflict with later waves
- reports files changed, issues found, fixes made, and verification guidance

## Git And Review Mechanics

Per-task commits are removed.

Review should use:

- `git status --short`
- `git diff`
- optional task-start and wave-start diff snapshots
- changed-file lists reported by implementers
- write-scope validation from the dispatch plan

Final completion reports the complete diff and verification results. The main
agent does not automatically commit, merge, push, or open a PR.

## Error Handling

If an implementer edits outside its scope, the main agent stops the wave and
decides whether the edit is necessary, should be reverted manually, or requires a
plan update.

If two implementers edit the same file unexpectedly, the main agent stops before
review/fix and resolves the conflict or splits the wave.

If a worker reports `BLOCKED` or `NEEDS_CONTEXT`, the main agent either supplies
context and reruns the task, splits the task, or asks the user.

If the reviewer/fixer finds a defect outside the current wave scope, it reports
the issue instead of changing unrelated files.

If wave verification fails after review/fix, the main agent uses systematic
debugging before changing behavior.

## Testing Strategy

Testing focuses on Codex behavior and behavior-shaping text.

Static and prompt-level tests should verify:

- active skill examples use `simplepower:` namespace
- active generated docs paths use `docs/simplepower/...`
- active install docs use `~/.agents/skills/simplepower`
- no active plan template contains per-task `git commit` steps
- `writing-plans` requires dependency graphs and dispatch waves
- plan review checks graph correctness, write scopes, and wave safety
- `subagent-driven-development` describes wave execution
- SDD prompts mention `sp-impl`, `gpt-5.4-mini`, high effort, no commits, and
  changed-file reporting
- combined wave reviewer/fixer prompt covers both spec compliance and code
  quality

Tests that require Claude, Gemini, OpenCode, Cursor, or Copilot should be
removed from the active suite. Existing Codex sync or skill-triggering tests can
be kept if they are updated for `simplepower`.

## Migration Plan

1. Rebrand active metadata, README, Codex docs, and skill namespace references.
2. Hard-prune non-Codex harness files, docs, and tests.
3. Rename `using-superpowers` to `using-simplepower` and update active skill
   references.
4. Update brainstorming paths and names without changing its workflow behavior.
5. Update `writing-plans` and plan review prompt for DAG dispatch planning.
6. Update SDD and implementer prompt for wave execution, `sp-impl`, and no
   commits.
7. Add the wave reviewer/fixer prompt and remove SDD dependence on separate spec
   and code-quality reviewers.
8. Update or add Codex-focused tests.
9. Run static tests and a manual Codex workflow smoke test.

## Success Criteria

- A Codex user can install and invoke skills under the `simplepower:` namespace.
- Brainstorming behaves the same as before except for brand, namespace, and path
  updates.
- New plans include a dependency graph, write scopes, dispatch waves, and
  verification boundaries.
- SDD can execute independent wave tasks in parallel and then run one combined
  review/fix pass.
- No active workflow requires per-task commits.
- Active docs no longer present Simple Power as a multi-harness plugin.
- README clearly states that Simple Power is a fork of Superpowers and explains
  why it exists.
