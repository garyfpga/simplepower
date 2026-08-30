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
timeout 30s rg -n 'use_subagent|skip_quick_verifier|skip_final_review|subagent_model|plan_review_model|review_model|review_model2|final_review_model|best_model|normal_model|fast_model|SIMPLEPOWER_USE_SUBAGENT|SIMPLEPOWER_SKIP_QUICK_VERIFIER|SIMPLEPOWER_SKIP_FINAL_REVIEW|SIMPLEPOWER_SUBAGENT_MODEL|SIMPLEPOWER_PLAN_REVIEW_MODEL|SIMPLEPOWER_REVIEW_MODEL2|SIMPLEPOWER_FINAL_REVIEW_MODEL|home.*repository|per-key|environment' README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
timeout 30s git diff --check -- AGENTS.md README.md docs/README.codex.md docs/testing.md skills/using-simplepower/references/simplepower-config.md
```

The first command should find FAST/NORMAL/BEST active routing, all supported
environment overrides, and per-key home/repository layering. Also confirm the
eight base-key schema includes `use_subagent`, `skip_quick_verifier`, `skip_final_review`,
`subagent_model`, and `review_model`, while optional `plan_review_model`,
`review_model2`, and `final_review_model` have no independent built-in defaults.
`plan_review_model` supports `SIMPLEPOWER_PLAN_REVIEW_MODEL`; only
`review_model2` lacks an environment override. Confirm exact defaults,
final-dash parsing, and fatal validation. `review_model`, `review_model2`,
`final_review_model`, and `skip_final_review` must remain recognized and
validated compatibility settings, but the normal brainstorming-to-implementation
chain documents them as deprecated no-ops rather than activation sources for
the optional plan reviewer or a final reviewer. Separate negative searches for retired `AGENTS.md` model assignments,
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

- With no overrides, verify all eight base defaults: `use_subagent = false`,
  `skip_quick_verifier = true`, `skip_final_review = false`,
  `subagent_model = "gpt-5.6-luna-xhigh"`,
  `review_model = "gpt-5.6-sol-high"`,
  `best_model = "gpt-5.6-sol-high"`,
  `normal_model = "gpt-5.6-luna-max"`, and
  `fast_model = "gpt-5.3-codex-spark-xhigh"`. Verify that
  `plan_review_model`, `review_model2`, and `final_review_model` are absent by
  default rather than assigned independent built-in values, and that effective
  final review falls back to `review_model`.
- Resolve per key in this order: defaults, `~/.codex/simplepower.toml`,
  `<git-root>/simplepower.toml` inside Git, non-empty
  `SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SKIP_QUICK_VERIFIER`,
  `SIMPLEPOWER_SKIP_FINAL_REVIEW`,
  `SIMPLEPOWER_SUBAGENT_MODEL`, `SIMPLEPOWER_REVIEW_MODEL`,
  `SIMPLEPOWER_PLAN_REVIEW_MODEL`,
  `SIMPLEPOWER_FINAL_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
  `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL`, then explicit
  current-session instructions. Missing higher-layer keys inherit; the
  repository file does not replace the home file as a whole.
- Verify all ten environment values configure their matching keys and that
  `SIMPLEPOWER_REVIEW_MODEL2` is not accepted or consulted. Root and nested
  `AGENTS.md` model assignments have no effect.
- Verify Boolean environment values accept case-insensitive `true` and `false`,
  reject every other non-empty value, and ignore empty values. TOML Boolean
  values remain strictly typed.
- Parse every present model, including `plan_review_model`, `review_model2`,
  and `final_review_model`, at its final dash.
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
  the one cohesive approved package, runs mandatory quick verification through
  the resolved executor,
  performs final diff review and in-scope fixes itself, runs final verification,
  updates the original plan's concise execution summary, reruns terminal
  verification without further file edits, and uses exactly two mandatory
  coordinator checkpoint types: approved plan and final reviewed/verified
  completion.
- Verify both routes include the saved plan in execution write scope, refresh a
  current summary snapshot plus labeled follow-up entries, and keep raw logs and
  unrelated repository audits out of the summary.
- Verify combined approval permits coordinator execution commits only during
  the active run and only for an objective committed-state prerequisite or a
  required separate/later summary update. Convenience, worker, and per-task
  commits remain forbidden, and authorization ends at final handoff.
- Verify an unexpected update or validation failure for a writable tracked plan
  blocks completion and preserves evidence. A genuinely untracked, external, or
  unwritable plan may omit the summary only when the final handoff gives the
  exact reason.
- For `Implementation Route: Grouped workers`, verify the plan contains the
  Interface Contract, File Ownership, cohesive Worker Packages, serialization
  decisions, and FAST/NORMAL/BEST allocation. Dispatch only independent
  non-overlapping packages or specialized work that materially benefits from
  delegation. Closely related code and tests should stay in one package, and
  capacity should queue whole packages rather than split tiny tasks.
- Verify quick verification is mandatory on both implementation routes. With
  default or explicit `skip_quick_verifier=true`, the main agent runs the exact
  commands with no verifier spawn, lifecycle, run id, or scratch refs. With
  `false`, the FAST quick-verifier subagent uses `fork_turns="none"`, may make
  only tiny typo-level fixes, and returns non-trivial failures to the main agent
  for diagnosis and in-scope repair.
- With no file key and no non-empty environment value, verify no plan reviewer
  dispatch occurs. A current-session value alone must not activate review.
- Verify home or repository `plan_review_model`, or non-empty
  `SIMPLEPOWER_PLAN_REVIEW_MODEL`, activates exactly one read-only reviewer
  after main-agent self-review. Repository and environment overlays select the
  expected model; an explicit session value may override only after activation.
- Verify the reviewer reports only Critical and Must Fix findings. The main
  agent applies or dismisses them once, reruns focused self-review, and proceeds
  without redispatch, retry, a second reviewer, or a plan-review scratch ref.
  Launch failures and unusable reports fall back to completed self-review;
  invalid configuration remains fatal.
- Verify scratch refs are absent in main-agent quick-verification mode and are
  limited to quick-verifier before/optional-after refs in FAST-subagent mode.
  No plan-review or review-fix scratch phase or extra checkpoint participates
  in the normal chain.
- Verify `review_model`, `review_model2`, `final_review_model`, and
  `skip_final_review` remain accepted and validated compatibility keys, but are
  documented as deprecated no-ops for normal execution.
  `SIMPLEPOWER_REVIEW_MODEL2` remains unsupported.
- Every optional and retained mandatory Simple Power dispatch passes
  `fork_turns="none"` with self-contained context. Explicit current-session
  user instructions override file configuration, except they cannot activate
  `plan_review_model` without file or environment activation.
- This change must not create or track a repository-level `simplepower.toml`,
  but a present repository file must be supported as a per-key overlay.

## Route-consent and compaction-continuity checks

Run these focused suites from the repository root:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 30s bash tests/skill-triggering/run-all.sh
timeout 30s bash tests/explicit-skill-requests/run-all.sh
timeout 30s git diff --check
```

Manual acceptance scenarios:

- Start brainstorming and verify it creates one evolving plan under
  `docs/simplepower/plans/` after initial triage, before detailed questions.
  Planning must expand that exact path in place; it must not create a second
  state artifact or standalone spec.
- Verify the plan records exactly one of `Grouped Workers Consent: Not
  requested`, `Grouped Workers Consent: Declined`, or `Grouped Workers Consent:
  Approved`. Main agent is the default. Brainstorming asks for consent only
  after it recommends grouped workers with concrete package or specialization
  value. Absent, silent, uncertain, ambiguous, or declined consent keeps
  `Implementation Route: Main agent`; planning cannot ask again or infer
  approval.
- During brainstorming, verify `## Brainstorming Continuity` is replaced after
  meaningful decisions with confirmed requirements and constraints, decisions
  and rejected choices, open questions, proposed route/consent state, and next
  action. Simulate compaction by reconstructing context and verify the main
  agent rereads the active plan before another question or tool.
- During direct implementation, verify `## Implementation Continuity` is a
  replaceable snapshot of completed work, partial results, changed files,
  verification, blockers, and next action. Reconstructed main-agent context
  must reread the plan and revalidate route and scope before editing.
- For an explicitly consented grouped route, verify every worker has a stable
  package identifier and sends `PROGRESS_SNAPSHOT` reports at meaningful
  milestones before continuing. The coordinator alone writes the plan. After
  reconstructed worker context, the worker may read only its package continuity
  section, not the full plan for task discovery.
- Verify a failed plan create, refresh, or reread stops the active phase with
  the exact path and recovery state. A failed worker milestone delivery reports
  `BLOCKED` or `NEEDS_CONTEXT` instead of proceeding from memory.
- At planning and execution phase completion, verify durable facts are folded
  into permanent plan sections or `Execution Summary` and the temporary
  continuity sections are removed. Confirm no executable compaction helper,
  helper agent, transcript parser, extra state artifact, or new configuration
  key was introduced.

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
