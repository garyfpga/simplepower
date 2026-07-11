# Testing Simple Power

Simple Power testing is Codex-focused. The main checks are static repo
validation, the brainstorm server integration tests, and the Codex plugin sync
smoke test.

## Run the checks

```bash
bash tests/simplepower-static/run-tests.sh
npm --prefix tests/brainstorm-server test
bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
```

Run those in that order when you want a quick signal on the active Codex
workflow.

For focused optional-subagent documentation and configuration coverage, run:

```bash
timeout 30s rg -n "simplepower.toml|use_subagent|subagent_model|gpt-5.6-luna-xhigh|fork_turns" README.md docs/README.codex.md docs/testing.md
git diff --check -- README.md docs/README.codex.md docs/testing.md
```

The first command should find the documented keys, default, and dispatch
isolation rule. Separate negative searches for retired configuration names and
wording should produce no matches. The final command should report no
whitespace errors.

## Manual Codex smoke test

Use this prompt in Codex:

```text
simplepower:brainstorming, let's make a react todo list
```

Expected behavior:

- Codex should trigger `simplepower:brainstorming` only when the prompt names
  `simplepower:brainstorming` or the active Simple Power chain hands off to it.
- The brainstorming flow should use the Simple Power branding and session
  paths, including `.simplepower/brainstorm`.
- After the design is approved, Codex should move on to planning and
  implementation instead of jumping straight into code.

Optional configuration smoke expectations:

- With no `simplepower.toml`, `use_subagent` defaults to `false` and
  `subagent_model` defaults to `gpt-5.6-luna-xhigh`.
- In a Git repository, `<git-root>/simplepower.toml` completely replaces
  `~/.codex/simplepower.toml`; outside Git, only the home file applies.
- Missing keys take defaults. Malformed TOML, unknown keys, wrong types, or
  invalid values stop processing.
- With `use_subagent = true`, verify only the initial read-only brainstorming
  and `simplepower:ro` explorers, plus stalled systematic-debugging Phase 1
  parallel investigation, are enabled. Mandatory plan review,
  implementation, quick verification, and review+fix keep their
  FAST/NORMAL/BEST/REVIEW allocations.
- Missing multi-agent support, an unavailable `subagent_model`, or a spawn
  failure must stop an enabled optional dispatch without silent fallback.
- Every optional and mandatory Simple Power dispatch passes
  `fork_turns="none"` with self-contained context. Explicit current-session
  user instructions override file configuration.
- The repository must not track a default `simplepower.toml`.

## What each check covers

- `tests/simplepower-static/run-tests.sh` verifies active Simple Power docs,
  skill files, prompt fixtures, and pruned harness removals.
- `tests/brainstorm-server` verifies the WebSocket protocol, HTTP serving,
  reload behavior, branding, and `.simplepower/brainstorm` session paths.
- `tests/codex-plugin-sync/test-sync-to-codex-plugin.sh` verifies the Codex
  plugin sync flow, the packaged plugin metadata, and marketplace metadata.
- Static checks cover optional plan visual guidance, brainstorming visual
  companion behavior, and marketplace install/version metadata.
- Generated implementation plans live under `docs/simplepower/plans/`. The
  normal active workflow does not create standalone specs.
