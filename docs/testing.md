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
