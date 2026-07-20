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
workflow. The static suite is the contract check for the adaptive
implementation route, including both direct main-agent execution and grouped
worker execution.

For focused configuration-contract documentation coverage, run:

```bash
timeout 30s rg -n 'use_subagent|skip_final_review|subagent_model|review_model|review_model2|final_review_model|best_model|normal_model|fast_model|SIMPLEPOWER_USE_SUBAGENT|SIMPLEPOWER_SKIP_FINAL_REVIEW|SIMPLEPOWER_SUBAGENT_MODEL|SIMPLEPOWER_REVIEW_MODEL2|SIMPLEPOWER_FINAL_REVIEW_MODEL|home.*repository|per-key|environment' README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
timeout 30s git diff --check -- AGENTS.md README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
```

The first command should find FAST/NORMAL/BEST active routing, all supported
environment overrides, and per-key home/repository layering. Also confirm the
seven base-key schema includes `use_subagent`, `skip_final_review`,
`subagent_model`, and `review_model`, while the optional `review_model2` and
`final_review_model` keys have no independent built-in defaults and only
`review_model2` lacks an environment override. Confirm exact defaults,
final-dash parsing, and fatal validation. `review_model`, `review_model2`,
`final_review_model`, and `skip_final_review` must remain recognized and
validated compatibility settings, but the normal brainstorming-to-implementation
chain documents them as deprecated no-ops rather than active plan/final reviewer
routing. Separate negative searches for retired `AGENTS.md` model assignments,
declarations that treat `SIMPLEPOWER_REVIEW_MODEL2` as a supported environment
override, and whole-file repository replacement wording should produce no
active-contract matches. References that explicitly say it is unsupported are
expected. The final command should report no whitespace errors.

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

- With no overrides, verify all seven base defaults: `use_subagent = false`,
  `skip_final_review = false`,
  `subagent_model = "gpt-5.6-luna-xhigh"`,
  `review_model = "gpt-5.6-sol-high"`,
  `best_model = "gpt-5.6-sol-high"`,
  `normal_model = "gpt-5.6-luna-max"`, and
  `fast_model = "gpt-5.3-codex-spark-xhigh"`. Verify that `review_model2` and
  `final_review_model` are absent by default rather than assigned independent
  built-in values, and that effective final review falls back to `review_model`.
- Resolve per key in this order: defaults, `~/.codex/simplepower.toml`,
  `<git-root>/simplepower.toml` inside Git, non-empty
  `SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SKIP_FINAL_REVIEW`,
  `SIMPLEPOWER_SUBAGENT_MODEL`, `SIMPLEPOWER_REVIEW_MODEL`,
  `SIMPLEPOWER_FINAL_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
  `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL`, then explicit
  current-session instructions. Missing higher-layer keys inherit; the
  repository file does not replace the home file as a whole.
- Verify all eight environment values configure their matching keys and that
  `SIMPLEPOWER_REVIEW_MODEL2` is not accepted or consulted. Root and nested
  `AGENTS.md` model assignments have no effect.
- Verify Boolean environment values accept case-insensitive `true` and `false`,
  reject every other non-empty value, and ignore empty values. TOML Boolean
  values remain strictly typed.
- Parse every present model, including `review_model2` and
  `final_review_model`, at its final dash.
  Accept only `low`, `medium`, `high`, `xhigh`, `max`, and `ultra` as effort
  suffixes.
- Malformed TOML, unknown keys, wrong types, empty model strings, missing model
  prefixes, invalid effort suffixes, invalid explicit current-session values,
  and invalid non-empty environment overrides are fatal, even if a higher
  layer would replace the value. Missing files/keys inherit, and only empty
  model environment values are ignored.
- With `use_subagent = false`, verify brainstorming and `simplepower:ro` do not
  dispatch any optional explorer. With `true`, verify both workflows begin with
  coordinator-owned initial triage and do not automatically dispatch at
  startup. Only a large, cross-cutting, complex, or stalled investigation may
  trigger fan-out to one or more distinct read-only explorers within runtime
  capacity; each explorer receives a self-contained brief and the coordinator
  synthesizes the reports.
- If an explorer batch is selected, missing multi-agent support, an unavailable
  `subagent_model`, or a spawn failure must stop the affected workflow without
  silently substituting a partial batch.
- For `Implementation Route: Main agent`, verify the coordinator directly edits
  the one cohesive approved package, runs the mandatory FAST quick verifier,
  performs final diff review and in-scope fixes itself, runs final verification,
  and uses exactly two coordinator checkpoint conditions: approved plan and
  final reviewed/verified implementation.
- For `Implementation Route: Grouped workers`, verify the plan contains the
  Interface Contract, File Ownership, cohesive Worker Packages, serialization
  decisions, and FAST/NORMAL/BEST allocation. Dispatch only independent
  non-overlapping packages or specialized work that materially benefits from
  delegation. Closely related code and tests should stay in one package, and
  capacity should queue whole packages rather than split tiny tasks.
- Verify the FAST quick verifier is mandatory on both routes. It may make only
  tiny typo-level fixes; non-trivial failures return to the main agent for
  diagnosis and in-scope repair.
- Verify scratch refs are limited to quick-verifier before/optional-after refs.
  No plan-review or review-fix prompt, dispatch, scratch phase, or checkpoint
  should participate in the normal chain.
- Verify `review_model`, `review_model2`, `final_review_model`, and
  `skip_final_review` remain accepted and validated compatibility keys, but are
  documented as deprecated no-ops for normal execution.
  `SIMPLEPOWER_REVIEW_MODEL2` remains unsupported.
- Every optional and retained mandatory Simple Power dispatch passes
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
- Static checks cover adaptive Main agent and Grouped workers routes, optional plan visual guidance,
  brainstorming visual companion behavior, and
  marketplace install/version metadata.
- Generated implementation plans live under `docs/simplepower/plans/`. The
  normal active workflow does not create standalone specs.
