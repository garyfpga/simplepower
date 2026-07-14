# Simple Power for Codex

Simple Power is a Codex-only skill fork of
[Superpowers](https://github.com/obra/superpowers) by Jesse Vincent / Prime
Radiant.

Skills are exposed through the `simplepower:*` namespace.

## Installation

Install Simple Power from the Codex plugin marketplace:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin add simplepower@garyfpga-codex-plugins
```

Use this whenever you want to pull marketplace updates:

```bash
codex plugin marketplace upgrade garyfpga-codex-plugins
```

Restart Codex after install or update if you want it to rescan installed skills
immediately.

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

It is also required when the coordinator selects one or more optional explorers
described below. If a selected explorer cannot use multi-agent support or its
configured model, or spawning fails, Simple Power stops instead of silently
falling back to the coordinator.

## Model Allocation

Simple Power uses four mandatory model tiers. Their built-in defaults are also
the approved current-session values:

```toml
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

The resulting assignments are REVIEW = `gpt-5.6-sol`/`high`, BEST =
`gpt-5.6-sol`/`high`, NORMAL = `gpt-5.6-luna`/`max`, and FAST =
`gpt-5.3-codex-spark`/`xhigh`.

The environment can override only these four tiers, with non-empty
`SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
`SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL` values. There is no
`SIMPLEPOWER_REVIEW_MODEL2`. Root and nested `AGENTS.md` files do not provide
model assignments.

`review_model2` is optional and is not a fifth mandatory tier. It has no
built-in default and no environment override. If absent or exactly equal to
the resolved `review_model`, it leaves one primary reviewer. A distinct value
enables a read-only secondary reviewer: plan review has two concurrent read-only
reviewers, and final review has two initial read-only reports before synthesis
and primary-only in-scope fixes. The secondary is an extra pair of eyes, never
a concurrent writer. If either reviewer cannot dispatch, the review checkpoint
stops rather than silently downgrading to one reviewer.

Use REVIEW for the primary plan reviewer and final review+fix agent. Use BEST for
broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or hard-to-test
work. Use NORMAL for routine low-risk implementation work that used to fit the
old FAST tier, especially localized edits. Use FAST for obvious repetitive
work, mechanical edits across many files, large static text sweeps, simple
fixture/assertion churn, and quick verification.

## Configuration

Simple Power resolves every configuration key independently. Start with the
built-in defaults, overlay keys from `~/.codex/simplepower.toml`, overlay keys
from `<git-root>/simplepower.toml` when inside a Git repository, overlay the
four non-empty model-tier environment variables named above, then apply
explicit current-session instructions last. Missing higher-layer keys inherit
the lower-layer value. In particular, a repository file overlays the home file
per key; it does not replace it as a whole. Outside Git, the repository layer
is skipped.

See [simplepower.toml.example](../simplepower.toml.example) for a copyable full
example; the example itself is not active repository configuration.

The supported TOML schema is the six base keys below plus optional
`review_model2`. The six base keys have these exact defaults:

```toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent` must be a TOML Boolean. Every present model key, including
optional `review_model2`, must be a nonempty TOML string and is parsed at its
final dash into a nonempty model prefix and a reasoning-effort suffix. Valid
suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. Malformed
TOML, unknown keys, wrong types, empty model strings, missing model prefixes,
and invalid effort suffixes are fatal. Every present file, every explicit
current-session configuration value, and every non-empty environment override
is validated even if a higher layer would replace its value; missing files and
keys inherit instead of failing. Only empty model-tier environment variables
are ignored. The environment does not configure `use_subagent`,
`subagent_model`, or `review_model2`.

`use_subagent` is a hard gate for optional read-only exploration:

- `false` prohibits every optional explorer in brainstorming and
  `simplepower:ro`;
- `true` is permission, not an instruction to spawn.

Both workflows begin with coordinator-owned initial triage and do not dispatch
explorers automatically at startup. Only when triage identifies a large,
cross-cutting, complex, or stalled investigation may the coordinator fan-out
one or more distinct read-only explorers within runtime capacity. Each explorer
gets a self-contained brief, uses `fork_turns="none"`, and may inspect files
and run read-only commands only. The coordinator synthesizes all reports. If a
selected batch cannot fully dispatch, the workflow stops rather than treating a
partial batch as a substitute.

This gate does not govern the mandatory plan reviewer, implementation workers,
quick verifier, or review+fix agent. Those remain assigned through the
FAST/NORMAL/BEST/REVIEW tiers. Every Simple Power dispatch, optional or
mandatory, passes `fork_turns="none"` and supplies self-contained context.

This change does not create or track a repository-level `simplepower.toml`.
When a repository file is present, it is supported and overlays the home file
per key.

## Implementation Flow

Simple Power keeps generated implementation plans in
`docs/simplepower/plans/` as Markdown files. Plans may include optional inline
visual aids when they reduce ambiguity. This is separate from the
`simplepower:brainstorming` visual companion, which uses a temporary localhost
page during brainstorming instead of saved plan visuals. After
`simplepower:writing-plans` saves a plan, it asks the user to approve the
reviewed plan, model/task allocation, and immediate current-session execution in
one step. If the user approves, the coordinator creates the accepted plan
checkpoint commit and immediately invokes
`simplepower:subagent-driven-development` with the approved allocation. The
implementation skill then uses plan-first parallel implementation, quick
verification with the FAST tier by default, one primary REVIEW-tier review+fix
pass, and final verification. With a distinct `review_model2`, it first
collects two initial read-only final-review reports against the same verified
snapshot, synthesizes them, and authorizes only the primary to make in-scope
fixes. The secondary never edits.
For revised plans and review/fix work, Simple Power also writes temporary local
Git scratch refs as diff anchors so reviewers can compare before/after changes;
the accepted checkpoint history stays at the usual three coordinator commits,
and the scratch refs are cleaned up after success.

## Starting Implementation

After the reviewed plan and model/task allocation are approved,
`simplepower:writing-plans` keeps execution in the current session and starts
the implementation path directly.

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` in the current session with plan-first parallel implementation. Use the approved FAST/NORMAL/BEST allocation for `sp-impl` workers and REVIEW for the primary review+fix agent. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick FAST-tier verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run the primary REVIEW-tier review+fix phase; only a distinct `review_model2` adds a concurrent read-only secondary report before primary-only fixes. Finish with final verification and the final commit.
```

## Usage

- Mention a skill by name, such as `simplepower:brainstorming`.
- Use `simplepower:writing-plans` after a design is approved, or approve the
  `simplepower:brainstorming` handoff to it.
- Use `simplepower:subagent-driven-development` for plan-first parallel
  implementation after combined approval in the current session.
- Use `simplepower:requesting-code-review` and
  `simplepower:verification-before-completion` to review and verify the work
  before handoff.
- Write generated plans to `docs/simplepower/plans/`.

## Updating

```bash
codex plugin marketplace upgrade garyfpga-codex-plugins
```

Restart Codex if you want it to rescan installed skills immediately.

## Uninstalling

Use Codex plugin management to remove marketplace-installed plugins.
