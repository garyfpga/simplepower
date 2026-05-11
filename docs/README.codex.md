# Simple Power for Codex

Simple Power is a Codex-only skill fork of
[Superpowers](https://github.com/obra/superpowers) by Jesse Vincent / Prime
Radiant.

Skills are exposed through the `simplepower:*` namespace.

## Installation

Install Simple Power from the Codex plugin marketplace:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin marketplace upgrade
```

Use `codex plugin marketplace upgrade` again whenever you want to pull
marketplace updates.

## Subagent Support

`simplepower:subagent-driven-development` depends on Codex multi-agent support
for `sp-impl` file-edit workers, the quick verifier, and the review+fix agent.
Add this to your Codex config if it is not already present:

```toml
[features]
multi_agent = true
```

That setting lets Simple Power dispatch the workers required by the approved
plan and model allocation.

## Model Allocation

Simple Power uses two configurable model tiers:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"
```

If either environment variable is unset, use the default shown above. Parse the
value as `<model>-<reasoning_effort>` by taking the final dash-delimited
segment as `reasoning_effort` and the preceding string as `model`. For
example, `gpt-5.4-mini-high` resolves to `model="gpt-5.4-mini"` and
`reasoning_effort="high"`.

Use FAST for narrow, low-risk, localized implementation or review work. Use
BEST for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test work. Every `fixer` stage uses BEST.

## Implementation Flow

Simple Power keeps generated implementation plans in
`docs/simplepower/plans/` as Markdown files. Plans may include optional inline
visual aids when they reduce ambiguity. This is separate from the
`simplepower:brainstorming` visual companion, which uses a temporary localhost
page during brainstorming instead of saved plan visuals. After
`simplepower:writing-plans` saves a plan, it asks the user to approve the
reviewed plan and model/task allocation. After the accepted plan checkpoint
commit, it checks current Codex context usage when available, falls back to
saved plan size only if context measurement fails, and asks which
implementation handoff to use. The implementation skill then uses plan-first
parallel implementation, quick verification, one BEST-tier review+fix pass, and
final verification.

## Starting Implementation

After the reviewed plan and model/task allocation are approved,
`simplepower:writing-plans` checks current Codex context usage when available.
It recommends current-session execution below `55%` and `/clear` at `55%` or
higher. If context usage cannot be measured, it falls back to saved plan size.
It still shows both commands and asks which implementation handoff to use.

For current-session implementation:

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with plan-first parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

For fresh context, Run `/clear` first.

```text
/clear
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with plan-first parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

## Usage

- Mention a skill by name, such as `simplepower:brainstorming`.
- Continue through approved Simple Power handoffs when prompted.
- Use `simplepower:writing-plans` after a design is approved, or approve the
  `simplepower:brainstorming` handoff to it.
- Use `simplepower:subagent-driven-development` for plan-first parallel
  implementation when explicitly selected.
- Use `simplepower:requesting-code-review` and
  `simplepower:verification-before-completion` to review and verify the work
  before handoff.
- Write generated plans to `docs/simplepower/plans/`.

## Updating

```bash
codex plugin marketplace upgrade
```

Restart Codex if you want it to rescan installed skills immediately.

## Uninstalling

Use Codex plugin management to remove marketplace-installed plugins.
