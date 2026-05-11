# Installing Simple Power for Codex

Simple Power is a Codex-only skill fork of
[Superpowers](https://github.com/obra/superpowers) by Jesse Vincent / Prime
Radiant.

## Install

Install Simple Power from the Codex plugin marketplace:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin marketplace upgrade
```

Use `codex plugin marketplace upgrade` again whenever you want to pull
marketplace updates.

Restart Codex if you want it to rescan installed skills immediately.

## Multi-Agent Support

If you want to use subagent workflows such as `simplepower:subagent-driven-development`,
enable Codex multi-agent support in your config:

```toml
[features]
multi_agent = true
```

Restart Codex after changing the config.
