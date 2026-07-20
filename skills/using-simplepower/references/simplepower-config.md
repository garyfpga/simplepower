# Simple Power Configuration

This reference is the operational configuration contract for active Simple
Power workflows. Resolve and validate it when an affected skill starts, before
making any configuration-controlled dispatch. The normal
brainstorming-to-implementation chain actively uses `best_model`,
`normal_model`, and `fast_model` for implementation and the mandatory quick
verifier. `review_model`, `review_model2`, `final_review_model`, and
`skip_final_review` remain recognized and strictly validated compatibility
settings, but they are deprecated no-ops for the normal chain's plan review and
final review phases.

## Resolve Configuration Per Key

The exact filename is `simplepower.toml`.

Resolve every supported key independently in this order:

1. Start with the built-in defaults for the seven base keys. `review_model2` and
   `final_review_model` have no independent built-in defaults and start absent.
2. If `~/.codex/simplepower.toml` exists, overlay the keys present there.
3. When inside a Git repository, if `<git-root>/simplepower.toml` exists,
   overlay the keys present there. It does not replace the home file as a
   whole; missing repository keys retain home or default values.
4. Overlay each non-empty supported environment variable onto its matching
   key: `SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SUBAGENT_MODEL`,
   `SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_FINAL_REVIEW_MODEL`,
   `SIMPLEPOWER_BEST_MODEL`, `SIMPLEPOWER_NORMAL_MODEL`,
   `SIMPLEPOWER_FAST_MODEL`, and `SIMPLEPOWER_SKIP_FINAL_REVIEW`.
5. Apply explicit current-session instructions last.

Outside Git, skip the repository-file layer. Root and nested `AGENTS.md` files
are not configuration sources for model assignments. There is no
`SIMPLEPOWER_REVIEW_MODEL2` environment variable; `review_model2` remains
configurable only through the home file, repository file, or explicit
current-session instructions.

Do not create a default configuration file. Configuration is instruction-driven
and requires no runtime parser dependency. This change does not create a
repository-level TOML file, but a file supplied at the repository path is fully
supported as the per-key overlay described above.

## Schema, Defaults, And Validation

Only these seven base top-level keys plus optional `review_model2` and
`final_review_model` are supported:

```toml
use_subagent = false
skip_final_review = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"

# Optional: no built-in default.
# final_review_model = "gpt-5.6-luna-max"
# review_model2 = "gpt-5.6-luna-max"
```

`use_subagent` and `skip_final_review` must be TOML Booleans and default to
`false` when missing.
The five base model keys must be nonempty TOML strings and default to the exact
values shown above when missing from all higher-priority layers.
`review_model2` has no built-in default: it remains absent unless a home,
repository, or explicit current-session configuration supplies it.
`final_review_model` likewise has no independent built-in default. When it is
absent from all allowed layers, its effective value is the fully resolved
`review_model`. When either optional key is present in a TOML file or explicit
current-session configuration, it must be a nonempty model/effort string.

For `SIMPLEPOWER_USE_SUBAGENT` and `SIMPLEPOWER_SKIP_FINAL_REVIEW`, accept only
case-insensitive `true` or `false` after confirming the value is non-empty.
Values such as `true`, `True`, and `TRUE` are equivalent, as are the matching
forms of `false`. Any other non-empty Boolean environment value is invalid.

Parse every present model value by splitting on its final dash. The nonempty
prefix is the `model`, and the suffix is the `reasoning_effort`. The only valid
effort suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. The
base defaults therefore resolve to `subagent_model` = `gpt-5.6-luna`/`xhigh`,
REVIEW = `gpt-5.6-sol`/`high`, BEST = `gpt-5.6-sol`/`high`, NORMAL =
`gpt-5.6-luna`/`max`, and FAST = `gpt-5.3-codex-spark`/`xhigh`.

Malformed TOML, unknown top-level keys, wrong types, empty model strings,
missing model prefixes, and unknown effort suffixes are errors. This includes
any present `review_model2` or `final_review_model` without a nonempty model
prefix and final supported effort suffix. Every present file, every explicit
current-session configuration value, and every non-empty environment override
must be validated even if a higher layer would override the same key. On any
configuration error, stop the affected skill before dispatch and name the
source plus the precise problem. A missing file or key is not an error; it
inherits the value already resolved from lower-priority layers.
`review_model2` remains absent when no allowed layer supplies it;
`final_review_model` then falls back to fully resolved `review_model`. Only
empty supported environment variables are ignored rather than treated as
overrides.

## Deprecated Compatibility Review Settings

Resolve `review_model` first. Then resolve a present `final_review_model` from
the home file, repository file, `SIMPLEPOWER_FINAL_REVIEW_MODEL`, and explicit
current-session instructions. If `final_review_model` is absent, use the fully
resolved `review_model` for compatibility. Validate the effective value even
though the normal chain does not dispatch a final review+fix agent.

`skip_final_review` keeps its default and supported environment behavior, and
all non-empty values remain strictly validated. In the normal chain it is a
deprecated no-op: final verification and main-agent final diff review always
run, and no final-review scratch refs or final review+fix agent are created.
`final_review_model` is not a fifth mandatory tier.

Compare fully resolved `review_model2` and `review_model` strings exactly.
An absent `review_model2`, or one exactly equal to `review_model`, preserves the
single-reviewer compatibility resolution result. Any distinct valid
`review_model2` preserves the legacy secondary-reviewer resolution result, but
the normal chain does not dispatch plan reviewers. It is optional and is not a
mandatory model tier.

## Optional Explorer Fan-Out

When effective `use_subagent=false`, brainstorming and `simplepower:ro` must
not dispatch optional explorers. When effective `use_subagent=true`, optional
exploration is permitted, not required. Both workflows begin with
coordinator-owned read-only initial triage and must not dispatch explorers
automatically at workflow activation.

Only after initial triage identifies a large, cross-cutting, complex, or
stalled investigation may the coordinator dispatch one or more read-only
explorers. Assign every selected explorer a distinct useful investigation angle.
There is no policy numeric cap; runtime capacity and the availability of
non-overlapping useful angles are the practical limits.

Every selected explorer uses the model and reasoning effort parsed from
`subagent_model`, rather than a model tier, and passes exact
`fork_turns="none"`. Give each a self-contained brief with the task, assigned
distinct angle, repository scope, read-only and no-file-creation restrictions,
known evidence, expected report, and verification. Explorers may inspect files
and run read-only commands only. They may not edit or create files, create RO
artifacts, answer user design questions, choose approaches, approve designs, or
transfer coordinator ownership. Require each report to identify its assigned
angle, inspected files and commands, findings and evidence, risks or
uncertainties, and explicit no-edit confirmation.

The coordinator synthesizes all explorer reports. If any explorer in a
selected batch cannot dispatch because multi-agent support, the configured
model, or spawning is unavailable, stop the affected workflow and report the
precise blocker; a partial batch is not a substitute.

The switch and `subagent_model` do not govern approved grouped `sp-impl`
workers, quick verifiers, or their FAST/NORMAL/BEST allocation. They also do
not govern explicitly invoked general delegation skills.
The deprecated review compatibility settings do not govern normal brainstorming-to-implementation execution.

## Universal Dispatch Isolation

Every Simple Power `spawn_agent` call or documented equivalent, whether
optional or mandatory, must pass exactly `fork_turns="none"`. Give every agent
a self-contained task brief containing the task, scope, constraints, relevant
evidence or contracts, expected output, and verification. Do not depend on
conversation inheritance.
