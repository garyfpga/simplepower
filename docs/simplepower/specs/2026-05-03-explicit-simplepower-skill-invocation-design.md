# Explicit Simple Power Skill Invocation Design

## Goal

Make Simple Power skills run only when the user explicitly asks for them, while
preserving the approved Simple Power chain:

```text
simplepower:brainstorming
-> simplepower:writing-plans
-> implementation path selection
-> simplepower:subagent-driven-development or simplepower:executing-plans
-> review, fix, verification, and checkpoint workflows
```

The change should stop ambient skill activation based only on task shape. A
plain request such as "build this feature" must not automatically invoke
`simplepower:brainstorming`; a plain failing-test report must not automatically
invoke `simplepower:systematic-debugging`; and a plain implementation request
must not automatically invoke `simplepower:writing-plans`.

## Invocation Contract

A Simple Power skill may be invoked only when one of these conditions is true:

1. The user explicitly names the skill, such as `simplepower:brainstorming`.
2. The user explicitly accepts a presented option that names the skill.
3. A currently active Simple Power skill reaches a documented handoff point that
   invokes the next skill in the approved chain.

Frontmatter descriptions are discovery hints only. They must not authorize
semantic auto-triggering from ordinary user requests. The wording in active
skills and docs must make this clear.

## Chain Handoff Rules

Chain invocation is allowed only inside an already active Simple Power workflow.
It is not a general-purpose auto-trigger rule.

`simplepower:brainstorming` may invoke `simplepower:writing-plans` only after:

- the design has been presented and approved
- the design spec has been written
- the spec self-review has passed
- the user has reviewed and approved the written spec

`simplepower:writing-plans` may invoke an implementation skill only after:

- the implementation plan has been written and self-reviewed
- any required planning checkpoint has been handled
- model allocation has been accepted or updated and accepted
- the user selects a current-session implementation option

The allowed implementation handoffs are:

- current-session subagent implementation:
  `simplepower:subagent-driven-development`
- current-session inline implementation:
  `simplepower:executing-plans`

New-session `/clear` commands are explicit user instructions because the command
text names the required skill.

## Skill Text Changes

Update `skills/using-simplepower/SKILL.md` first. Replace the current broad
"1% chance" and "task matches a skill" policy with the explicit invocation
contract above.

The `using-simplepower` skill should say:

- do not invoke Simple Power skills from semantic task matching alone
- do invoke explicitly requested skills before responding
- do allow documented chain handoffs from an active Simple Power skill
- do treat direct user instructions and `AGENTS.md` as higher priority than
  Simple Power workflow text

Update active `SKILL.md` frontmatter descriptions so they no longer read like
automatic triggers. Descriptions should use wording like:

```yaml
description: Use only when the user explicitly requests simplepower:<skill-name> or an authorized Simple Power chain invokes it.
```

Apply that pattern to active Simple Power skills, including:

- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/executing-plans/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/requesting-code-review/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/receiving-code-review/SKILL.md`
- `skills/finishing-a-development-branch/SKILL.md`
- `skills/using-git-worktrees/SKILL.md`
- `skills/writing-skills/SKILL.md`

Internal workflow instructions may still be strict after the skill is active.
For example, once the user explicitly invokes `simplepower:brainstorming`, its
design gate remains mandatory. The change is about entry conditions, not about
weakening an active workflow.

## Documentation Changes

Update user-facing docs so they do not promise automatic activation from task
shape.

In `README.md` and `docs/README.codex.md`, describe usage as:

- mention a `simplepower:*` skill explicitly
- continue through approved Simple Power handoffs when prompted
- use `/clear` restart commands that explicitly name the implementation skill

Remove or rewrite language that says Codex will activate a skill when a task
matches the skill description.

## Test Changes

Keep `tests/explicit-skill-requests` as the positive coverage for explicit
requests. Add or update fixtures so they confirm:

- explicit `simplepower:brainstorming` requests are preserved
- explicit `simplepower:systematic-debugging` requests are preserved
- explicit `simplepower:subagent-driven-development` requests are preserved
- post-planning handoff prompts still explicitly name the selected execution
  skill

Repurpose `tests/skill-triggering` so it no longer encodes the old ambient
trigger model. The new coverage should verify the invocation contract instead:

- ordinary feature requests do not include or imply Simple Power skill names
- ordinary bug reports do not include or imply Simple Power skill names
- ordinary implementation-plan requests do not include or imply Simple Power
  skill names unless the prompt explicitly names one
- approved chain fixtures still include the next skill name at handoff points

Extend `tests/simplepower-static/run-tests.sh` with static checks:

- `skills/using-simplepower/SKILL.md` contains the explicit invocation contract
- active skill files do not contain the old "1% chance" policy
- active skill frontmatter descriptions do not contain broad `Use when`
  trigger wording
- `skills/brainstorming/SKILL.md` still names
  `simplepower:writing-plans` as the approved next skill
- `skills/writing-plans/SKILL.md` still names
  `simplepower:subagent-driven-development` and
  `simplepower:executing-plans` as user-selected implementation handoffs

## Verification

Run the relevant static and fixture checks after implementation:

```bash
bash tests/simplepower-static/run-tests.sh
bash tests/explicit-skill-requests/run-all.sh
bash tests/skill-triggering/run-all.sh
```

If `tests/skill-triggering` is renamed during implementation, update the
verification command and docs in the same change.

## Non-Goals

- Do not remove Simple Power's approved workflow chain.
- Do not weaken gates inside active skills, such as brainstorming's design
  approval gate or writing-plans' model allocation approval gate.
- Do not make implementation start automatically without the user accepting an
  execution path.
- Do not add Claude, Gemini, OpenCode, Cursor, Copilot, or other non-Codex
  harness support to active docs or tests.
- Do not add worker-owned or per-task commit requirements.

## Expected Outcome

After implementation, Simple Power remains easy to invoke deliberately:

```text
simplepower:brainstorming, please help me design this
```

but no longer activates just because an ordinary task resembles a skill
description. Once a user deliberately enters the Simple Power flow, approved
handoffs still keep the chain moving without requiring the user to retype every
next skill name.
