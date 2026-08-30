# Plugin Compaction Hooks Implementation Plan

Goal: Replace best-effort instruction-only compaction continuity with real Codex plugin lifecycle enforcement while preserving the Markdown plan as the sole authoritative workflow record.

## Design Summary

Simple Power will ship one Python-standard-library continuity handler and two mutually exclusive hook registrations. Marketplace plugin installations use the bundled `hooks/hooks.json` and Codex-provided `PLUGIN_ROOT`/`PLUGIN_DATA`. Symlink development installations use the same checked-out handler through a user-layer hook definition and store state under `CODEX_HOME`. Simple Power will document both modes without modifying or overwriting a user's existing `~/.codex/hooks.json`.

The lifecycle is:

1. `PostToolUse` observes successful `apply_patch` edits to `docs/simplepower/plans/*.md` and atomically registers the exact active plan for that Codex session.
2. `PreCompact` validates registered state and blocks compaction when that state is corrupt, stale, unreadable, outside the repository, or inconsistent with the plan on disk.
3. `PostCompact` revalidates registered state and atomically marks recovery as pending.
4. `SessionStart` with `source=compact` injects an exact, phase-scoped plan reread instruction before the immediate root continuation, then clears the pending marker.

The JSON pointer stores association metadata only: session identifier, canonical repository root, canonical plan path, phase, accepted plan hash, and recovery status. It never stores or executes plan content and never reads transcript contents. An absent pointer means an ordinary session and is a no-op. An existing invalid pointer fails closed. Ambiguous candidate plans are rejected rather than guessed.

Markdown persistence becomes sparse because built-in compaction summaries carry transient activity and the hooks restore the exact durable record. Brainstorming writes the plan initially, after material accepted scope/approach/route changes, at complete design approval, or on a blocker. Main-agent execution refreshes one replaceable continuity snapshot after a cohesive phase, on a blocker, and for final handoff preparation. Grouped workers report at package completion, on a blocker, or at an explicit coordinator request. The coordinator remains the only writer to the authoritative plan; completed temporary continuity is folded into permanent design content or `Execution Summary` and removed.

Success means both installation modes receive the real pre/post-compaction lifecycle, unregistered sessions remain unaffected, registered invalid state cannot compact silently, the current symlink workflow remains easy to use, and active skills/docs no longer require high-frequency Markdown progress writes.

## Implementation Route

Implementation Route: Main agent

Grouped Workers Consent: Not requested

This is one cohesive package: the event contract, handler, registration, skill policy, installation guidance, and tests must remain synchronized. There are not two independent non-overlapping implementation packages with enough delegation value to justify grouped workers. The configured quick-verifier path is also the main agent because `skip_quick_verifier=true`. No optional plan reviewer is configured.

## Exact Files

Create:

- `hooks/hooks.json` — marketplace-plugin hook registration.
- `hooks/hooks.user.json` — mergeable user-layer registration template for symlink development installs.
- `hooks/simplepower_continuity.py` — shared event handler using only the Python standard library.
- `tests/hooks/test_simplepower_continuity.py` — handler event and filesystem-state tests.

Modify:

- `AGENTS.md` — replace the former no-executable-hook constraint with the approved hook/state boundary and sparse snapshot policy.
- `.codex-plugin/plugin.json` — advertise the bundled hooks and bump the plugin version to `1.2.0`.
- `package.json` — keep the package version aligned at `1.2.0`.
- `README.md` — document real lifecycle enforcement and both installation modes.
- `.codex/INSTALL.md` — add trust/registration instructions and mutually exclusive plugin versus user-layer setup.
- `docs/README.codex.md` — describe runtime behavior, state roots, and recovery semantics.
- `docs/testing.md` — document hook tests and a real `/hooks` smoke check.
- `skills/brainstorming/SKILL.md` — replace per-answer/per-section persistence with the approved sparse durable cadence.
- `skills/writing-plans/SKILL.md` — generate the sparse continuity contract and real-hook assumptions in implementation plans.
- `skills/subagent-driven-development/SKILL.md` — replace frequent coordinator and worker progress persistence with phase/package boundaries.
- `skills/subagent-driven-development/implementer-prompt.md` — make worker snapshots package-completion/blocker/request driven.
- `skills/using-simplepower/SKILL.md` — explain hook-backed compaction recovery and installation-mode expectations.
- `tests/simplepower-static/run-tests.sh` — enforce root hook presence, no transcript parser/plan guessing, sparse cadence, and current policy wording.
- `tests/codex-plugin-sync/test-sync-to-codex-plugin.sh` — prove the plugin sync includes hook registration and handler files.
- `docs/simplepower/plans/2026-08-30-plugin-compaction-hooks.md` — remain the authoritative plan and receive the final execution record.

The completed historical plan `docs/simplepower/plans/2026-08-30-main-agent-default-and-compaction-continuity.md` remains unchanged because it records the earlier instruction-only design accurately for its time.

## Implementation Steps

### 1. Establish failing contract tests

Add `tests/hooks/test_simplepower_continuity.py` before the handler. Drive the handler as a subprocess with isolated temporary repositories, `CODEX_HOME`, `PLUGIN_DATA`, stdin event JSON, and captured stdout/stderr. Cover:

- no pointer/no candidate events are silent successful no-ops;
- plugin and symlink data roots resolve to distinct documented locations;
- successful single-plan `apply_patch` registration and atomic pointer replacement;
- failed tool responses, unrelated patches, ambiguous plan paths, path escape, symlink escape, and non-regular plan files;
- valid and invalid `PreCompact` behavior;
- valid and invalid `PostCompact` behavior and recovery-pending state;
- compact-source `SessionStart` additional context, phase scoping, and pending-state clearing;
- non-compact session starts;
- corrupt JSON, schema mismatch, session mismatch, missing repository/plan, unreadable state, and plan hash mismatch;
- filenames derived safely from the session identifier rather than using it as a raw path component.

Update the static suite's expected policy from “no executable hooks” and high-frequency snapshots to the approved root hooks, metadata-only state, no transcript parsing, no plan guessing, coordinator-only plan writes, and sparse cadence. Update the plugin-sync fixture so the initial red run proves new root hook files are not yet covered.

### 2. Implement the shared continuity handler

Create `hooks/simplepower_continuity.py` as a small stdin-JSON dispatcher keyed by `hook_event_name`.

- Resolve plugin state as `$PLUGIN_DATA/continuity/` when `PLUGIN_DATA` is non-empty. Otherwise resolve user-layer state as `${CODEX_HOME:-$HOME/.codex}/simplepower-data/continuity/`.
- Derive the pointer filename from a cryptographic hash of the hook-provided session identifier. Validate a versioned JSON schema on every read.
- Write state through a same-directory temporary file, flush it, set restrictive permissions where supported, and publish with `os.replace`.
- Resolve and compare canonical paths. Require the plan to be a regular Markdown file beneath the canonical git root's `docs/simplepower/plans/` directory. Reject symlink/path escapes and never evaluate plan text.
- Compute the accepted plan SHA-256 from bytes on disk. Record only the approved association fields and recovery flags.
- Emit valid hook JSON on stdout and diagnostics on stderr; keep exit status and `continue`/`stopReason` semantics aligned with each lifecycle event.

For `PostToolUse`, require the canonical `apply_patch` tool name and a successful tool response. Parse only `*** Add File`, `*** Update File`, and `*** Delete File` patch headers to identify candidate plan paths. Do not inspect transcripts or search the repository for a likely plan. Register one valid added/updated plan; reject multiple candidates. A deletion of the registered plan makes later validation fail closed. Derive the phase from stable Simple Power plan headings/markers and reject a candidate that is not a Simple Power workflow plan.

For `PreCompact`, return a no-op when no pointer exists. For a registered session, validate schema, session, repository, path boundary, file type, and accepted hash. Return `continue: false` with a useful `stopReason` on any failure; otherwise allow compaction.

For `PostCompact`, repeat the validation and atomically set recovery pending. If the now-registered state is invalid, return `continue: false` and explain that the authoritative plan must be repaired before continuation.

For `SessionStart` with `source=compact`, no-op without registered pending recovery. Otherwise validate again and emit `hookSpecificOutput.additionalContext` naming the exact canonical plan and the exact phase section to reread (`Brainstorming Continuity`, `Implementation Continuity`, or a grouped-worker package continuity section). The instruction must require recovery before further work and prohibit plan guessing. Clear pending state atomically only after preparing valid recovery context. Other session-start sources no-op.

### 3. Register plugin and symlink hook modes

Create `hooks/hooks.json` with plugin-root commands for:

- `PostToolUse` matching `apply_patch`;
- `PreCompact` and `PostCompact` matching manual and automatic compaction;
- `SessionStart` matching `compact`.

Use explicit timeouts and a bounded additional-context limit. Commands invoke the shared handler through `PLUGIN_ROOT`, allowing Codex to supply the plugin-specific `PLUGIN_DATA` directory.

Create `hooks/hooks.user.json` with the same event/matcher contract but a `CODEX_HOME`-based command suitable for the current symlinked checkout at `~/.codex/simplepower/hooks/`. Document that a user with a dedicated hook file may symlink the complete template, while a user with existing hooks must merge the entries manually. Never automate replacement of `~/.codex/hooks.json`. State clearly that plugin and user-layer registrations are alternatives, not cumulative setup.

### 4. Replace high-frequency persistence rules

Update brainstorming, writing-plans, subagent-driven-development, its implementer prompt, and using-simplepower together so they describe one consistent contract:

- built-in compaction summaries hold transient activity;
- the real hooks restore the exact authoritative plan after compaction;
- brainstorming refreshes durable Markdown only at initial creation, material accepted design/route change, complete approval, or blocker;
- main-agent implementation refreshes at cohesive phase completion, blocker, or final handoff preparation, not after individual tests/fixes/reviews;
- grouped workers report at package completion, blocker, or explicit coordinator request, not at every internal milestone;
- the coordinator is the sole plan writer and folds/removes temporary continuity at phase completion;
- an active registered workflow cannot silently continue across an invalid compaction boundary.

Retain the minimum persistence needed for semantic decisions because hooks intentionally do not parse transcripts and cannot reconstruct decisions that were never written.

### 5. Update active policy, installation docs, and package metadata

Update `AGENTS.md` to permit exactly the approved shared metadata-only handler and hook files while continuing to forbid a second workflow-state artifact, transcript parser, plan-content execution, configuration key for continuity, or guessed plan discovery.

Update the README and Codex docs with:

- the event sequence and fail-closed/no-op distinction;
- marketplace state under Codex's `PLUGIN_DATA` and symlink state under `${CODEX_HOME:-$HOME/.codex}/simplepower-data`;
- `/hooks` trust review and verification;
- marketplace installation as the distribution path and symlink installation as a supported development/experimentation path;
- the user hook merge/symlink choices and duplicate-registration warning;
- Python 3 as the handler runtime dependency;
- recovery and troubleshooting examples that do not expose or parse transcript contents.

Bump `.codex-plugin/plugin.json` and `package.json` to `1.2.0`, and revise the plugin description to advertise real hook-backed continuity. Rely on the existing plugin sync behavior for the root `hooks/` directory and prove that behavior in its test instead of adding a redundant sync special case.

### 6. Complete quick verification and review

Run the quick-verification commands below. Then inspect the complete diff for event-contract consistency, unsafe path handling, accidental high-frequency snapshot language, duplicated hook registration advice, historical-plan edits, unrelated refactors, and missing package artifacts. Make all in-scope fixes before final verification.

### 7. Complete final verification and execution record

Run the final-verification sequence once, write the `Execution Summary` in this plan, inspect that summary and the resulting diff, then rerun the identical final-verification sequence without intervening edits. Fold any temporary `Implementation Continuity` section into the summary and remove it. Create the final completion checkpoint only after the second clean run.

## Risks

- Hooks do nothing until Codex discovers and trusts the selected registration. Installation docs and the real `/hooks` smoke check must make this visible.
- Patch-header parsing could accidentally select the wrong plan. The handler accepts exactly one explicit valid plan candidate and never searches or guesses.
- External plan edits after registration change the hash. Failing closed is intentional; the recovery message must explain how a successful plan patch refreshes the registration.
- Plugin and user registrations enabled together would run duplicate handlers with different state roots. Documentation and static tests must make mutual exclusion explicit.
- Python availability or command quoting can differ across platforms. Keep the handler standard-library-only, test the exact Linux commands used by the supported symlink workflow, and document Python 3 explicitly rather than claiming unverified platform coverage.
- Session identifiers are untrusted path input. Hash them before constructing filenames and validate the original value inside state.
- A post-compaction failure happens after memory has already compacted. `SessionStart(source=compact)` is therefore the required recovery injection point, while `PreCompact` is the last preventive guard.
- Broad wording edits could weaken existing commit, review, or coordinator ownership rules. Limit changes to the new lifecycle and approved cadence, with static assertions for preserved constraints.

## Quick Verification

Quick Verification Executor: Main agent (`skip_quick_verifier=true`)

No quick-verifier subagent or scratch refs will be created. Run:

```bash
timeout 30s python3 tests/hooks/test_simplepower_continuity.py
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 60s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s git diff --check
```

## Final Verification

Run this exact sequence before writing the execution record, then rerun it unchanged after writing and reviewing the record:

```bash
timeout 30s python3 tests/hooks/test_simplepower_continuity.py
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 60s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 60s bash tests/skill-triggering/run-all.sh
timeout 60s bash tests/explicit-skill-requests/run-all.sh
timeout 60s npm --prefix tests/brainstorm-server test
timeout 30s bash scripts/bump-version.sh --check
timeout 30s git diff --check
```

Record every command, result, and any bounded deviation. A timeout, skip, or unavailable dependency is not a pass and must be reported and resolved or handed off as a blocker.

## Execution Record

At implementation completion, replace this section with `## Execution Summary` containing:

- implemented behavior and any approved deviation from this plan;
- exact files created/modified;
- quick-verification results;
- final diff self-review findings and fixes;
- both final-verification passes with exact commands and results;
- checkpoint commits created under the accepted authorization;
- remaining risks or follow-up, explicitly stating `None` when empty.

Use a single replaceable `## Implementation Continuity` section only after a cohesive phase completion, on a blocker, or for final-handoff preparation. Do not refresh it for every test, fix, or review action. Fold it into `Execution Summary` and remove it before the final checkpoint.

## Checkpoint Conditions

There are two mandatory coordinator-owned checkpoint types:

1. **Accepted-plan checkpoint:** after the user gives one combined approval for this final plan, the main-agent route, immediate current-session execution, the accepted-plan commit, the final reviewed/verified completion commit, and bounded in-scope execution commits during this active run. Commit this accepted plan and immediately invoke `simplepower:subagent-driven-development` in the current session.
2. **Final-completion checkpoint:** after implementation, main-agent quick verification, final diff review and fixes, the first final-verification pass, execution-summary update, summary/diff inspection, and the identical second final-verification pass. Commit all remaining in-scope changes; do not create an empty commit.

An additional coordinator-owned execution commit is permitted only when an objective technical prerequisite requires committed state before approved testing/work, or when the original plan's execution summary must be refreshed separately. None is currently expected. Convenience commits, history-shaping commits, worker commits, and per-task commits remain forbidden. Authorization expires at final handoff.
