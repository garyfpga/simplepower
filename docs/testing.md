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

For focused configuration-contract documentation coverage, run:

```bash
timeout 30s rg -n 'review_model|best_model|normal_model|fast_model|SIMPLEPOWER_REVIEW_MODEL|SIMPLEPOWER_FAST_MODEL|home.*repository|per-key|environment' README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
timeout 30s git diff --check -- AGENTS.md README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
```

The first command should find all four mandatory tier keys, environment
overrides, and per-key home/repository layering. Also confirm the six-key schema
includes `use_subagent` and `subagent_model`, exact defaults, final-dash parsing,
and fatal validation. Separate negative searches for retired `AGENTS.md` model
assignments and whole-file repository replacement wording should produce no
matches. The final command should report no whitespace errors.

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

Configuration smoke expectations:

- With no overrides, verify all six defaults: `use_subagent = false`,
  `subagent_model = "gpt-5.6-luna-xhigh"`,
  `review_model = "gpt-5.6-sol-high"`,
  `best_model = "gpt-5.6-sol-high"`,
  `normal_model = "gpt-5.6-luna-max"`, and
  `fast_model = "gpt-5.3-codex-spark-xhigh"`.
- Resolve per key in this order: defaults, `~/.codex/simplepower.toml`,
  `<git-root>/simplepower.toml` inside Git, non-empty
  `SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
  `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL`, then explicit
  current-session instructions. Missing higher-layer keys inherit; the
  repository file does not replace the home file as a whole.
- Verify environment values configure only the four mandatory tiers. Root and
  nested `AGENTS.md` model assignments have no effect.
- Parse every model at its final dash. Accept only `low`, `medium`, `high`,
  `xhigh`, `max`, and `ultra` as effort suffixes.
- Malformed TOML, unknown keys, wrong types, empty model strings, missing model
  prefixes, invalid effort suffixes, invalid explicit current-session values,
  and invalid non-empty environment overrides are fatal, even if a higher
  layer would replace the value. Missing files/keys inherit, and only empty
  model environment values are ignored.
- With `use_subagent = false`, verify brainstorming and `simplepower:ro` do not
  dispatch an optional explorer. With `true`, verify the coordinator may, but
  need not, select one read-only explorer for the relevant workflow. Mandatory
  plan review, implementation, quick verification, and review+fix keep their
  FAST/NORMAL/BEST/REVIEW allocations.
- If an optional explorer is selected, missing multi-agent support, an
  unavailable `subagent_model`, or a spawn failure must stop that dispatch
  without silent fallback.
- Every optional and mandatory Simple Power dispatch passes
  `fork_turns="none"` with self-contained context. Explicit current-session
  user instructions override file configuration.
- This change must not create or track a repository-level `simplepower.toml`,
  but a present repository file must be supported as a per-key overlay.

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
