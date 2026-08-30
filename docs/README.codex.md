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
when a plan chooses `Implementation Route: Grouped workers`, and for quick
verification only when `skip_quick_verifier=false` selects the FAST subagent.
`simplepower:writing-plans` also needs it when
optional `plan_review_model` is active.
Add this to your Codex config if it is not already present:

```toml
[features]
multi_agent = true
```

That setting lets Simple Power dispatch grouped workers when brainstorming has
clear delegation value and records explicit user consent for the approved
route, dispatch the optional plan reviewer when configured,
and dispatch the quick verifier when selected. Default main-agent quick
verification needs no multi-agent support.

It is also required when the coordinator selects one or more optional explorers
described below. If a selected explorer cannot use multi-agent support or its
configured model, or spawning fails, Simple Power stops instead of silently
falling back to the coordinator.

## Model Allocation

The normal Simple Power brainstorming-to-implementation chain actively uses
three model tiers: BEST, NORMAL, and FAST. Optional `plan_review_model` adds one
single-pass plan review when explicitly configured. The legacy REVIEW
configuration is still recognized and strictly validated for existing configs,
but it is a deprecated compatibility/no-op setting in the normal chain.

```toml
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
# Optional; no built-in default:
# plan_review_model = "gpt-5.6-luna-max"
# Deprecated compatibility/no-op in the normal chain:
review_model = "gpt-5.6-sol-high"
```

The active assignments are BEST = `gpt-5.6-sol`/`high`, NORMAL =
`gpt-5.6-luna`/`max`, and FAST =
`gpt-5.3-codex-spark`/`xhigh`.

The environment can override `use_subagent`, `skip_quick_verifier`, `subagent_model`, the three active
tiers, optional `plan_review_model`, deprecated compatibility `review_model`,
`final_review_model`, and `skip_final_review` through
`SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SKIP_QUICK_VERIFIER`, `SIMPLEPOWER_SUBAGENT_MODEL`,
`SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_PLAN_REVIEW_MODEL`,
`SIMPLEPOWER_BEST_MODEL`,
`SIMPLEPOWER_NORMAL_MODEL`, `SIMPLEPOWER_FAST_MODEL`,
`SIMPLEPOWER_FINAL_REVIEW_MODEL`, and `SIMPLEPOWER_SKIP_FINAL_REVIEW`. There is
no `SIMPLEPOWER_REVIEW_MODEL2`. Root and nested `AGENTS.md` files do not provide model assignments.

`plan_review_model` has no built-in default and does not fall back to
`review_model`. A key in the home or repository `simplepower.toml`, or a
non-empty `SIMPLEPOWER_PLAN_REVIEW_MODEL`, activates one read-only plan review.
A current-session instruction can override only an active model. The reviewer
returns only Critical and Must Fix findings. The main agent fixes or explicitly
dismisses them once, then treats the plan as reviewed without redispatch or
plan-review scratch refs. A launch failure or unusable report falls back to the
completed main-agent self-review without retrying.

`review_model`, `review_model2`, `final_review_model`, and `skip_final_review`
are deprecated compatibility settings. They remain supported, preserve their
environment behavior, and are strictly validated so existing configs keep
working, but they do not activate the optional plan reviewer or a final
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
fixture/assertion churn, and the quick-verifier subagent when
`skip_quick_verifier=false`.

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

The supported TOML schema has the eight base keys below plus optional
`plan_review_model`, `review_model2`, and `final_review_model`. The eight base
keys have these exact defaults; legacy review keys are deprecated compatibility
no-ops in the normal chain:

```toml
use_subagent = false
skip_quick_verifier = true
skip_final_review = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent`, `skip_quick_verifier`, and `skip_final_review` must be TOML Booleans. Their environment
values accept only case-insensitive `true` or `false`, including forms such as
`True` and `TRUE`; every other non-empty value is fatal. Every present model
key, including optional `plan_review_model`, `review_model2`, and
`final_review_model`, must be a nonempty TOML
string and is parsed at its final dash into a nonempty model prefix and a
reasoning-effort suffix. Valid suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`. Malformed TOML, unknown keys, wrong types, empty model
strings, missing model prefixes, and invalid effort suffixes are fatal. Every
present file, every explicit current-session configuration value, and every
non-empty environment override is validated even if a higher layer would
replace its value; missing files and keys inherit instead of failing. An absent
`final_review_model` uses the fully resolved `review_model`. Empty supported
environment variables are ignored and do not activate plan review. Only
`review_model2` has no environment
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

This gate does not govern approved grouped implementation workers or the
configuration-selected quick-verification executor. Every Simple Power
dispatch, optional or mandatory, passes `fork_turns="none"` and supplies
self-contained context.

`skip_quick_verifier=true` is the default. The main agent runs mandatory quick
verification directly with the plan's same timed commands and creates no
verifier scratch refs. Set it to `false` to dispatch the FAST quick-verifier
subagent with its tiny-fix limit and before/optional-after refs. `fast_model`
selects that subagent's model only.

This change does not create or track a repository-level `simplepower.toml`.
When a repository file is present, it is supported and overlays the home file
per key.

## Implementation Flow

Simple Power keeps generated implementation plans in
`docs/simplepower/plans/` as Markdown files. Brainstorming creates the one
evolving plan after initial triage establishes the feature name; planning
expands that same file in place instead of creating a second workflow-state
artifact. Plans may include optional inline
visual aids when they reduce ambiguity. This is separate from the
`simplepower:brainstorming` visual companion, which uses a temporary localhost
page during brainstorming instead of saved plan visuals. After
`simplepower:writing-plans` saves a plan and the main agent self-reviews it. If
optional `plan_review_model` is active, it then runs one read-only review; the
main agent handles only Critical and Must Fix findings in one fix pass and never
resends the plan. Launch or report failures fall back to the completed
self-review. The plan includes its own path as the coordinator-owned execution
record. Simple Power then asks the user to approve the final plan, route/model
allocation, two mandatory checkpoint types, bounded coordinator execution
commits during the active run, and immediate current-session execution in one
step. If the user approves, the coordinator creates the accepted-plan
checkpoint commit and immediately invokes
`simplepower:subagent-driven-development` with the approved allocation.
`Implementation Route: Main agent` is the default and directly edits one
cohesive package without spawning `sp-impl`. `Implementation Route: Grouped
workers` is eligible only when brainstorming recommends independent,
non-overlapping packages or material specialization and records `Grouped
Workers Consent: Approved`; planning cannot infer or request that consent.
Absent, declined, silent, or uncertain consent retains Main agent. This gate is
separate from optional explorers, optional plan review, and quick-verifier
selection. Grouped workers receive only relevant design, contract, scope, and
verification context. Every route runs mandatory quick verification through
the resolved Main agent or FAST subagent executor, then the main agent performs
final diff review, in-scope fixes, and a first
final-verification pass. It updates the original plan with a concise `Execution
Summary`, then reruns terminal verification without further file edits. The
workflow retains two mandatory checkpoint types. A coordinator execution commit
is additionally allowed only when approved testing/work objectively requires
committed state or when the summary must be committed separately or refreshed
after a later in-run finding. Convenience, worker, and per-task commits remain
forbidden; authorization ends at final handoff. Only FAST-subagent quick
verification uses quick-verifier Git scratch refs as diff anchors. Optional
plan review, main-agent quick verification, and final review have no scratch
phase. Created quick-verifier scratch refs are cleaned up after success; on blockers or
failed checkpoints they are preserved for manual cleanup reporting.

Compaction continuity is plan-based and instruction-level. During brainstorming
or direct implementation, the main agent replaces the current continuity
snapshot after meaningful milestones and rereads the active plan before acting
from compacted or reconstructed context. Grouped workers send structured
`PROGRESS_SNAPSHOT` reports; only the coordinator writes their package
continuity sections, and a recovering worker may reread only its own section.
Temporary snapshots are folded into permanent design content or `Execution
Summary` and removed at phase completion. No executable compaction helper,
helper agent, transcript parser, extra state artifact, or new configuration key
is added.

## Starting Implementation

After the main-agent reviewed plan and route/model allocation are approved,
`simplepower:writing-plans` keeps execution in the current session and starts
the implementation path directly.

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` in the current session. If the plan route is Main agent, implement the cohesive package directly with no `sp-impl` spawn. If the route is Grouped workers, dispatch only the approved cohesive non-overlapping worker packages with `fork_turns="none"` and their relevant design/contract/scope/verification context. Run mandatory quick verification with the plan-approved Main agent or FAST subagent executor; only the FAST subagent has tiny-fix limits and conditional scratch refs. Finish with main-agent review of committed and uncommitted execution changes, in-scope fixes, a first final-verification pass, the original plan's concise Execution Summary, an unchanged terminal verification pass, and the newest final-completion checkpoint. Allow extra coordinator commits only for an objective committed-state prerequisite or a required separate/later summary update during the active run.
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
