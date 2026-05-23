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
for `sp-impl` file-edit workers, the quick verifier, and the REVIEW-tier
review+fix agent.
Add this to your Codex config if it is not already present:

```toml
[features]
multi_agent = true
```

That setting lets Simple Power dispatch the workers required by the approved
plan and model allocation.

## Model Allocation

Simple Power uses four configurable model tiers:

```bash
SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"
```

Resolve model settings in this order: explicit user override, quoted
assignment in project root `AGENTS.md`, process environment variable, built-in
default. Model assignment lookup only reads `<repo>/AGENTS.md`; nested AGENTS
files and repo-wide grep are not part of this feature.

If no override, root `AGENTS.md` assignment, or environment variable provides a
value, use the default shown above. Parse the value as
`<model>-<reasoning_effort>` by taking the final dash-delimited segment as
`reasoning_effort` and the preceding string as `model`. For example,
`gpt-5.4-mini-high` resolves to `model="gpt-5.4-mini"` and
`reasoning_effort="high"`.

Use REVIEW for the plan reviewer and final review+fix agent. Use BEST for
broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or hard-to-test
work. Use NORMAL for routine low-risk implementation work that used to fit the
old FAST tier, especially localized edits. Use FAST for obvious repetitive
work, mechanical edits across many files, large static text sweeps, simple
fixture/assertion churn, and quick verification.

## Implementation Flow

Simple Power keeps generated implementation plans in
`docs/simplepower/plans/` as Markdown files. Plans may include optional inline
visual aids when they reduce ambiguity. This is separate from the
`simplepower:brainstorming` visual companion, which uses a temporary localhost
page during brainstorming instead of saved plan visuals. After
`simplepower:brainstorming` starts, it uses an in-place `feature/<slug>` branch
by default, and `simplepower:systematic-debugging` uses an in-place
`debug/<slug>` branch by default; neither path creates a worktree unless the
user explicitly asks for one. It uses `git checkout -b` for in-place branch
setup. Brainstorming asks the user before invoking simplepower:writing-plans.
After `simplepower:writing-plans` saves and self-reviews a plan, it asks for
explicit approval before dispatching the REVIEW-tier plan reviewer. After that
reviewer approves, it asks the user to approve the reviewed plan, model/task
allocation, and immediate current-session execution in one step. If the user
approves, the coordinator creates the accepted plan checkpoint commit and
immediately invokes
`simplepower:subagent-driven-development` with the approved allocation. The
implementation skill then uses plan-first parallel implementation, quick
verification with the FAST tier by default, one REVIEW-tier review+fix pass,
and final verification.

## Starting Implementation

After the reviewed plan and model/task allocation are approved,
`simplepower:writing-plans` keeps execution in the current session and starts
the implementation path directly. This continues on the in-place branch that
brainstorming or debugging already created; it does not switch to a worktree by
default.

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` in the current session with plan-first parallel implementation. Use the approved FAST/NORMAL/BEST allocation for `sp-impl` workers and REVIEW for the review+fix agent. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick FAST-tier verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one REVIEW-tier review+fix agent, final verification, and final commit.
```

## Usage

- Mention a skill by name, such as `simplepower:brainstorming`.
- Use `simplepower:writing-plans` after a design is approved, or approve the
  `simplepower:brainstorming` handoff to it.
- Approve the REVIEW-tier plan reviewer only after the plan is saved and
  self-reviewed.
- Use `simplepower:subagent-driven-development` for plan-first parallel
  implementation after combined approval in the current session.
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
