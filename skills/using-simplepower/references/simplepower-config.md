# Simple Power Configuration

This reference is the operational configuration contract for active Simple
Power workflows. Resolve and validate it when an affected skill starts, before
making any configuration-controlled dispatch.

## Select One Configuration Source

The exact filename is `simplepower.toml`.

1. Determine whether the current working context is inside a Git repository.
   When it is, determine the repository root and check exactly
   `<git-root>/simplepower.toml`.
2. If the repository file exists, use it exclusively. In that case, do not read, merge, or fall back to `~/.codex/simplepower.toml`, even when the repository file is invalid or omits a supported key.
3. If there is no repository file, select `~/.codex/simplepower.toml` when it
   exists. Use defaults if neither exists.
4. Outside Git, there is no repository candidate: select the home file when it
   exists, otherwise use the defaults.
5. Explicit current-session user instructions override the effective supported
   keys after file/default resolution.

Do not create a default configuration file. Configuration is instruction-driven
and requires no runtime parser dependency.

## Schema, Defaults, And Validation

Only these top-level keys are supported:

```toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
```

`use_subagent` must be a TOML Boolean and defaults to `false` when missing.
`subagent_model` must be a nonempty TOML string and defaults to
`gpt-5.6-luna-xhigh` when missing.

Parse `subagent_model` by splitting on its final dash. The nonempty prefix is
the `model`, and the suffix is the `reasoning_effort`. The only valid effort
suffixes are `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`. For example,
the default resolves to model `gpt-5.6-luna` and reasoning effort `xhigh`.

Malformed TOML, unknown top-level keys, wrong types, empty model strings,
missing model prefixes, and unknown effort suffixes are errors. This includes
any value without a nonempty model prefix and final supported effort suffix.
On any configuration error, stop the affected skill before dispatch and name
the selected configuration path plus the precise problem. An invalid selected
repository file never falls back to the home file. A missing file or missing
supported key is not an error and uses its default.

## Optional Dispatch Behavior

When effective `use_subagent=false`, each affected workflow follows its
documented coordinator-only behavior. When effective `use_subagent=true`, use
the parsed `subagent_model` model and reasoning effort only for the optional
explorer or investigator roles explicitly governed by this switch.

The switch and `subagent_model` do not govern mandatory plan reviewers,
`sp-impl` workers, quick verifiers, review+fix agents, or their
FAST/NORMAL/BEST/REVIEW allocation. They also do not govern explicitly invoked
general delegation skills.

If there is missing multi-agent support, an unavailable configured model, or a
spawn failure while `use_subagent=true`, stop the affected workflow and report
the blocker. Do not silently switch to coordinator-only work or a different model, and do not authorize substitute behavior.

## Universal Dispatch Isolation

Every Simple Power `spawn_agent` call or documented equivalent, whether
optional or mandatory, must pass exactly `fork_turns="none"`. Give every agent
a self-contained task brief containing the task, scope, constraints, relevant
evidence or contracts, expected output, and verification. Do not depend on
conversation inheritance.
