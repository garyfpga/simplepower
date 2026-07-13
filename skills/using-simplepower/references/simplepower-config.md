# Simple Power Configuration

This reference is the operational configuration contract for active Simple
Power workflows. Resolve and validate it when an affected skill starts, before
making any configuration-controlled dispatch.

## Resolve Configuration Per Key

The exact filename is `simplepower.toml`.

Resolve every supported key independently in this order:

1. Start with the built-in defaults.
2. If `~/.codex/simplepower.toml` exists, overlay the keys present there.
3. When inside a Git repository, if `<git-root>/simplepower.toml` exists,
   overlay the keys present there. It does not replace the home file as a
   whole; missing repository keys retain home or default values.
4. Overlay each non-empty model-tier environment variable onto its matching
   key: `SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
   `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL`.
5. Apply explicit current-session instructions last.

Outside Git, skip the repository-file layer. Root and nested `AGENTS.md` files
are not configuration sources for model assignments. The environment configures
only the four mandatory model tiers; it does not configure `use_subagent` or
`subagent_model`.

Do not create a default configuration file. Configuration is instruction-driven
and requires no runtime parser dependency. This change does not create a
repository-level TOML file, but a file supplied at the repository path is fully
supported as the per-key overlay described above.

## Schema, Defaults, And Validation

Only these top-level keys are supported:

```toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent` must be a TOML Boolean and defaults to `false` when missing.
Each model key must be a nonempty TOML string and defaults to the exact value
shown above when missing from all higher-priority layers.

Parse every model value by splitting on its final dash. The nonempty prefix is
the `model`, and the suffix is the `reasoning_effort`. The only valid effort
suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. The defaults
therefore resolve to `subagent_model` = `gpt-5.6-luna`/`xhigh`, REVIEW =
`gpt-5.6-sol`/`high`, BEST = `gpt-5.6-sol`/`high`, NORMAL =
`gpt-5.6-luna`/`max`, and FAST = `gpt-5.3-codex-spark`/`xhigh`.

Malformed TOML, unknown top-level keys, wrong types, empty model strings,
missing model prefixes, and unknown effort suffixes are errors. This includes
any value without a nonempty model prefix and final supported effort suffix.
Every present file, every explicit current-session configuration value, and
every non-empty environment override must be validated even if a higher layer
would override the same key. On any configuration error, stop the affected
skill before dispatch and name the source plus the precise problem. A missing
file or key is not an error; it inherits the value already resolved from
lower-priority layers. Only empty model environment variables are ignored
rather than treated as overrides.

## Optional Dispatch Behavior

When effective `use_subagent=false`, brainstorming and `simplepower:ro` must
not dispatch an optional explorer. When effective `use_subagent=true`, the
coordinator may, but is not required to, select one read-only explorer for
brainstorming or one read-only explorer for `simplepower:ro`, using the parsed
`subagent_model` model and reasoning effort. Coordinator judgment determines
whether that single explorer is useful for the current workflow.

The switch and `subagent_model` do not govern mandatory plan reviewers,
`sp-impl` workers, quick verifiers, review+fix agents, or their
FAST/NORMAL/BEST/REVIEW allocation. They also do not govern explicitly invoked
general delegation skills.

If the coordinator selects an optional explorer but multi-agent support or the
configured model is unavailable, or spawning fails, stop the affected workflow
and report the blocker. Do not silently switch to coordinator-only work or a
different model, and do not authorize substitute behavior.

## Universal Dispatch Isolation

Every Simple Power `spawn_agent` call or documented equivalent, whether
optional or mandatory, must pass exactly `fork_turns="none"`. Give every agent
a self-contained task brief containing the task, scope, constraints, relevant
evidence or contracts, expected output, and verification. Do not depend on
conversation inheritance.
