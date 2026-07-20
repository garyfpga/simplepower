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
when a plan chooses `Implementation Route: Grouped workers`, and always for the
mandatory FAST quick verifier.
Add this to your Codex config if it is not already present:

```toml
[features]
multi_agent = true
```

That setting lets Simple Power dispatch grouped workers when the approved route
has clear delegation value, and dispatch the quick verifier.

It is also required when the coordinator selects one or more optional explorers
described below. If a selected explorer cannot use multi-agent support or its
configured model, or spawning fails, Simple Power stops instead of silently
falling back to the coordinator.

## Model Allocation

The normal Simple Power brainstorming-to-implementation chain actively uses
three model tiers: BEST, NORMAL, and FAST. The legacy REVIEW configuration is
still recognized and strictly validated for existing configs, but it is a
deprecated compatibility/no-op setting in the normal chain.

```toml
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
# Deprecated compatibility/no-op in the normal chain:
review_model = "gpt-5.6-sol-high"
```

The active assignments are BEST = `gpt-5.6-sol`/`high`, NORMAL =
`gpt-5.6-luna`/`max`, and FAST =
`gpt-5.3-codex-spark`/`xhigh`.

The environment can override `use_subagent`, `subagent_model`, the three active
tiers, deprecated compatibility `review_model`, `final_review_model`, and
`skip_final_review` through
`SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SUBAGENT_MODEL`,
`SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
`SIMPLEPOWER_NORMAL_MODEL`, `SIMPLEPOWER_FAST_MODEL`,
`SIMPLEPOWER_FINAL_REVIEW_MODEL`, and `SIMPLEPOWER_SKIP_FINAL_REVIEW`. There is
no `SIMPLEPOWER_REVIEW_MODEL2`. Root and nested `AGENTS.md` files do not provide model assignments.

`review_model`, `review_model2`, `final_review_model`, and `skip_final_review`
are deprecated compatibility settings. They remain supported, preserve their
environment behavior, and are strictly validated so existing configs keep
working, but the normal chain no longer dispatches plan reviewers or a final
review+fix agent, and `skip_final_review` no longer changes final verification.
When absent, `final_review_model` still resolves to `review_model` for
compatibility; `skip_final_review` still defaults to `false` but is a no-op in
the normal chain.

`review_model2` is an optional compatibility key. It has no built-in default
and no environment override. If present and distinct from `review_model`, it
must still be a valid model string, but the normal chain does not create a
secondary plan reviewer.

Use FAST/NORMAL/BEST as the active tiers. Use BEST for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test work.
Use NORMAL for routine low-risk implementation work that used to fit the old
FAST tier, especially localized edits. Use FAST for obvious repetitive work,
mechanical edits across many files, large static text sweeps, simple
fixture/assertion churn, and the mandatory quick verifier.

## Configuration

Simple Power resolves every configuration key independently. Start with the
built-in defaults, overlay keys from `~/.codex/simplepower.toml`, overlay keys
from `<git-root>/simplepower.toml` when inside a Git repository, overlay the
supported non-empty environment variables named above, then apply
explicit current-session instructions last. Missing higher-layer keys inherit
the lower-layer value. In particular, a repository file overlays the home file
per key; it does not replace it as a whole. Outside Git, the repository layer
is skipped.

See [simplepower.toml.example](../simplepower.toml.example) for a copyable full
example; the example itself is not active repository configuration.

The supported TOML schema is still the seven base keys below plus optional
`review_model2` and `final_review_model`. The seven base keys have these exact
defaults; review-related keys are deprecated compatibility no-ops in the normal
chain:

```toml
use_subagent = false
skip_final_review = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent` and `skip_final_review` must be TOML Booleans. Their environment
values accept only case-insensitive `true` or `false`, including forms such as
`True` and `TRUE`; every other non-empty value is fatal. Every present model
key, including optional `review_model2` and `final_review_model`, must be a nonempty TOML
string and is parsed at its final dash into a nonempty model prefix and a
reasoning-effort suffix. Valid suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`. Malformed TOML, unknown keys, wrong types, empty model
strings, missing model prefixes, and invalid effort suffixes are fatal. Every
present file, every explicit current-session configuration value, and every
non-empty environment override is validated even if a higher layer would
replace its value; missing files and keys inherit instead of failing. An absent
`final_review_model` uses the fully resolved `review_model`. Empty supported
environment variables are ignored. Only `review_model2` has no environment
override.

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

This gate does not govern the approved grouped implementation workers or the
mandatory FAST quick verifier. Every Simple Power dispatch, optional or
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
`simplepower:writing-plans` saves a plan, the main agent self-reviews it, then
asks the user to approve the plan, route/model allocation, and immediate
current-session execution in one step. If the user approves, the coordinator
creates the accepted plan checkpoint commit and immediately invokes
`simplepower:subagent-driven-development` with the approved allocation.
`Implementation Route: Main agent` directly edits one cohesive package without
spawning `sp-impl`. `Implementation Route: Grouped workers` dispatches only
cohesive packages that are independent, non-overlapping, or materially benefit
from specialization; workers receive only relevant design, contract, scope, and
verification context. Every route runs the mandatory FAST quick verifier, then
the main agent performs final diff review, in-scope fixes, final verification,
and the final reviewed/verified implementation checkpoint. The normal workflow
uses two coordinator checkpoints and keeps only quick-verifier Git scratch refs as diff anchors.
Those scratch refs are cleaned up after success; on blockers or
failed checkpoints they are preserved for manual cleanup reporting.

## Starting Implementation

After the main-agent reviewed plan and route/model allocation are approved,
`simplepower:writing-plans` keeps execution in the current session and starts
the implementation path directly.

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` in the current session. If the plan route is Main agent, implement the cohesive package directly with no `sp-impl` spawn. If the route is Grouped workers, dispatch only the approved cohesive non-overlapping worker packages with `fork_turns="none"` and their relevant design/contract/scope/verification context. Run the mandatory FAST quick verifier with lint/build/tests and timeouts; it may make only tiny typo-level fixes and must return non-trivial failures to the main agent. Finish with main-agent final diff review, in-scope fixes, final verification, and the final reviewed/verified implementation checkpoint.
```

## Usage

- Mention a skill by name, such as `simplepower:brainstorming`.
- Use `simplepower:writing-plans` after a design is approved, or approve the
  `simplepower:brainstorming` handoff to it.
- Use `simplepower:subagent-driven-development` for adaptive direct/grouped
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
