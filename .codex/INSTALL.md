# Installing Simple Power for Codex

Simple Power is a Codex-only skill fork of
[Superpowers](https://github.com/obra/superpowers) by Jesse Vincent / Prime
Radiant.

## Install

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

Simple Power requires Python 3 for its compaction continuity handler. The
plugin bundles `hooks/hooks.json`; Codex supplies `PLUGIN_ROOT` and a writable
`PLUGIN_DATA`, and Simple Power stores metadata under
`$PLUGIN_DATA/continuity/`. Users do not set `PLUGIN_DATA` themselves.

After install or upgrade, open `/hooks` in Codex, inspect the Simple Power hook
definition, and trust its current hash. Changed hooks are skipped until they are
trusted again.

## Symlink development install

A symlink checkout remains supported for experiments. One current Linux layout
is:

```bash
git clone https://github.com/garyfpga/simplepower.git "${CODEX_HOME:-$HOME/.codex}/simplepower"
ln -s "${CODEX_HOME:-$HOME/.codex}/simplepower/skills" "$HOME/.agents/skills"
```

Use that whole-directory skills symlink only when `~/.agents/skills` is
dedicated to Simple Power and does not already exist. Preserve and merge any
shared skill layout instead of replacing it.

Symlink mode needs the user-layer hook definition in
`hooks/hooks.user.json`. If `~/.codex/hooks.json` is dedicated to Simple Power
and absent, it may point directly at the tracked template:

```bash
ln -s "${CODEX_HOME:-$HOME/.codex}/simplepower/hooks/hooks.user.json" "${CODEX_HOME:-$HOME/.codex}/hooks.json"
```

If `~/.codex/hooks.json` already contains other hooks, merge the template's
four event groups into its existing `hooks` object. Do not overwrite it. The
symlink handler stores metadata under
`${CODEX_HOME:-$HOME/.codex}/simplepower-data/continuity/`.

Enable exactly one registration mode. Do not keep the user-layer Simple Power
hooks active while the marketplace plugin is enabled, because Codex runs all
matching hooks from all sources. Restart Codex, then inspect and trust the
selected definition through `/hooks`.

## Compaction lifecycle

- `PostToolUse` registers the exact successfully patched Simple Power plan.
- `PreCompact` blocks corrupt, stale, escaped, missing, or hash-mismatched
  registered state; sessions with no pointer are unaffected.
- `PostCompact` validates again and marks recovery pending.
- `SessionStart` for `compact` injects the exact plan and phase section before
  Codex's immediate continuation.

The metadata pointer contains no plan or transcript content. Repair a stale
pointer by restoring the authoritative plan and successfully patching it again;
never select a replacement plan by guesswork.

## Multi-Agent Support

If you want to use subagent workflows such as `simplepower:subagent-driven-development`,
enable Codex multi-agent support in your config:

```toml
[features]
multi_agent = true
```

Restart Codex after changing the config.
