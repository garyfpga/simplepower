# Post-Plan Implementation Handoff Design

## Context

Simple Power currently moves from `simplepower:brainstorming` to
`simplepower:writing-plans`, then asks the current session to execute the plan
with `simplepower:subagent-driven-development` or `simplepower:executing-plans`.
That keeps momentum, but it also carries all brainstorming and planning context
into implementation.

Codex built-in plan mode offers a cleaner transition: after planning, the user
can clear context and start implementation from the approved plan. Simple Power
should offer the same style of transition after writing an implementation plan.

A second related issue showed up during Simple Power execution. The user's
global `~/.codex/AGENTS.md` says subagents should use high effort and the same
model as the main agent unless specified otherwise. Simple Power's `sp-impl`
workers are already specified as `gpt-5.4-mini` with high effort, but the
dispatcher still spawned implementation workers with the main model. The workflow
needs to make the Simple Power dispatch settings explicit enough to override
generic same-model defaults.

## Goals

- After `simplepower:writing-plans` saves a plan, ask the user whether to clear
  context and start implementation.
- If the user says yes, write a self-contained implementation handoff artifact.
- Make the handoff artifact sufficient for a fresh post-clear session to start
  implementation without relying on the old conversation.
- Use Codex hooks as a support mechanism for re-injecting the handoff after a
  clear or on the next prompt, where hooks are available.
- Keep the clear action user-mediated. Simple Power should not pretend it can
  programmatically press Codex's clear-context control.
- Make `sp-impl` dispatch settings an explicit Simple Power override:
  `agent_type="worker"`, `model="gpt-5.4-mini"`, `reasoning_effort="high"`,
  and `fork_context=false`, unless the user explicitly overrides.
- Document the recommended local `~/.codex/AGENTS.md` carveout so global
  same-model defaults do not override Simple Power's explicit worker policy.

## Non-Goals

- Do not make implementation start automatically without user consent.
- Do not add an automatic command that clears Codex context.
- Do not depend on plugin-local Codex hooks running from `.codex-plugin/`.
  Current Codex behavior appears to execute hooks from config-layer
  `~/.codex/hooks.json`; plugin-local hook support is not reliable enough to be
  the only path.
- Do not add an automatic hook installer in the first implementation. The first
  version should ship the hook script and document the `~/.codex/hooks.json`
  entry the user can add.
- Do not change reviewer/fixer model routing except where needed to preserve the
  existing planned reviewer/fixer rules.
- Do not reintroduce Claude, Cursor, OpenCode, Gemini, Copilot, or other
  non-Codex harness support.

## User Flow

At the end of `simplepower:writing-plans`, after the plan has been written and
self-reviewed, the agent asks:

> Plan complete and saved to `<plan-path>`. Clear context and start
> implementation from this plan?

If the user says no, the existing handoff remains available:

- use `simplepower:subagent-driven-development` wave-by-wave in the current
  session
- use `simplepower:executing-plans` for inline execution when subagents are
  unavailable or explicitly not desired

If the user says yes, the agent writes a handoff artifact and tells the user to
clear context. The final message includes the exact restart prompt in case hooks
are not installed:

```text
After clearing context, start implementation with:

Use `simplepower:subagent-driven-development` to execute
`docs/simplepower/plans/<plan-file>.md` wave-by-wave. Read the Simple Power
handoff artifact first if present. Use `sp-impl` workers with
agent_type="worker", model="gpt-5.4-mini", reasoning_effort="high", and
fork_context=false unless I explicitly override.
```

## Handoff Artifact

The handoff artifact should live under `.simplepower/implementation-handoff.json`
in the active project. It is project-local state, not generated documentation.

The artifact should include:

- plan path
- spec path, or `null` when the plan was not generated from a known spec file
- created timestamp
- current working directory
- recommended execution skill:
  `simplepower:subagent-driven-development`
- fallback execution skill: `simplepower:executing-plans`
- exact `sp-impl` dispatch settings
- hook injection text for a fresh post-clear session
- status field with one of: `pending`, `consumed`, or `expired`

The hook injection text should be concise and self-contained. It should tell the
fresh session to read the named plan, use wave-by-wave Simple Power execution,
respect the plan's write scopes and verification boundaries, and use the
explicit `sp-impl` worker dispatch settings.

## Hook Support

Hook support should be optional and additive. The workflow must still work when
the hook is absent.

Codex currently supports hook-driven `additionalContext` injection for lifecycle
events such as `SessionStart` and `UserPromptSubmit`. However, installed plugin
local hooks are not a reliable assumption. The first implementation should
therefore provide both of these pieces:

- document a manual `~/.codex/hooks.json` entry that runs a Simple Power handoff
  hook script
- ship the hook script used by that documented entry

The hook should:

1. Check for `.simplepower/implementation-handoff.json` in the current project.
2. Ignore missing, expired, or consumed handoffs.
3. Return `hookSpecificOutput.additionalContext` containing the artifact's
   implementation bootstrap text.
4. Avoid injecting large plan contents directly; inject the plan path and
   execution rules instead.

The hook should not try to start implementation by itself. It only injects the
fresh-session instructions needed after the user clears context.

## AGENTS.md Carveout

The user's global `~/.codex/AGENTS.md` can keep its default same-model rule, but
it should include a Simple Power exception:

```md
3. Exception: when a Simple Power skill or plan specifies subagent dispatch
   settings, those settings count as "specified otherwise" and override the
   same-model default. In particular, Simple Power `sp-impl` workers use
   `model="gpt-5.4-mini"` and `reasoning_effort="high"` unless the user
   explicitly overrides.
```

This local carveout is useful for the user's machine, but Simple Power should
also carry its own portable wording so future users and fresh sessions do not
depend on local configuration.

## Skill Changes

`simplepower:writing-plans` should change its execution handoff so it asks the
post-plan clear-context question and, on yes, writes the handoff artifact.

`simplepower:subagent-driven-development` should state that `sp-impl` settings
are an explicit override to generic same-model subagent defaults. The model
selection section should remain:

- `sp-impl`: `agent_type="worker"`, `model="gpt-5.4-mini"`,
  `reasoning_effort="high"`, `fork_context=false`

`skills/using-simplepower/references/codex-tools.md` should state the same
override in the Codex tool mapping so the instruction is visible at the exact
dispatch surface.

Documentation should mention that hook-assisted restart requires config-layer
Codex hooks until Codex reliably supports plugin-local hooks.

## Testing

Static tests should verify:

- `writing-plans` asks whether to clear context and start implementation after a
  plan is complete.
- `writing-plans` names `.simplepower/implementation-handoff.json`.
- `writing-plans` records explicit `sp-impl` dispatch settings in the handoff.
- `subagent-driven-development` says `sp-impl` dispatch settings override
  generic same-model defaults.
- `using-simplepower/references/codex-tools.md` includes the explicit
  `gpt-5.4-mini` high-effort `sp-impl` mapping and override wording.
- Codex-only static checks still reject stale non-Codex harness support in the
  active repo.

Focused hook tests should verify:

- missing handoff files produce no injected context
- valid pending handoffs produce `hookSpecificOutput.additionalContext`
- consumed or expired handoffs do not inject stale implementation instructions
- the hook output references the plan path and explicit `sp-impl` settings
