# Configurable Quick-Verifier Subagent Implementation Plan

**Goal:** Add `skip_quick_verifier = true` as the default Simple Power behavior so the main agent performs the existing quick-verification commands without a verifier subagent, while preserving the current FAST subagent path when explicitly enabled.

## Design Summary

Add `skip_quick_verifier` as the eighth base Simple Power configuration key with built-in default `true`, plus the `SIMPLEPOWER_SKIP_QUICK_VERIFIER` environment override. It follows the existing per-key resolution order and strict Boolean validation. Effective `true` changes only the quick-verification executor: the main agent runs the exact planned quick checks at the existing lifecycle point, diagnoses approved in-scope failures, applies in-scope repairs, and reruns affected checks. It does not create quick-verifier scratch refs or invoke subagent lifecycle handling. Effective `false` preserves the current FAST quick-verifier dispatch, tiny-fix authority, non-trivial-failure return path, and coordinator-owned before/optional-after scratch refs.

Quick verification remains mandatory in both modes. Main-agent final diff review, final verification, execution-summary maintenance, terminal verification, checkpoint policy, grouped implementation routing, and optional explorer behavior remain unchanged. Active documentation must distinguish mandatory quick verification from the optional quick-verifier subagent.

This is one cohesive configuration-and-workflow contract package. Configuration schema, planning, execution, scratch behavior, user guidance, plugin metadata, fixtures, and static assertions must change together; no specialized delegation materially improves the work. Success means missing configuration defaults to main-agent quick verification, `false` restores the existing subagent path exactly, invalid values fail before execution, and all Codex-focused suites pass.

## Implementation Route

**Main agent.** The schema and its two execution branches form one tightly coupled package with overlapping documentation and regression coverage. The coordinator implements it directly with no `sp-impl` worker. The approved design also authorizes main-agent quick verification for this implementation run after the new default is in place; no quick-verifier subagent or quick-verifier scratch refs are used for this run.

## Exact Files

### Simple Power repository

- `docs/simplepower/plans/2026-08-17-skip-quick-verifier.md` — authoritative plan and coordinator-owned execution record.
- `AGENTS.md` — contributor contract for conditional verifier dispatch and scratch refs.
- `README.md` — English and Chinese configuration and workflow guidance.
- `.codex-plugin/plugin.json` — concise capability metadata; keep version `1.1.0`.
- `docs/README.codex.md` — Codex installation, configuration, and execution guidance.
- `docs/testing.md` — manual configuration and lifecycle expectations.
- `simplepower.toml.example` — copyable eighth base key with default `true`.
- `skills/brainstorming/SKILL.md` — approved-design handoff facts for the selected verifier executor.
- `skills/writing-plans/SKILL.md` — generated-plan requirements, approval text, and conditional quick-verification routing.
- `skills/subagent-driven-development/SKILL.md` — runtime branch between main-agent and FAST-subagent quick verification.
- `skills/subagent-driven-development/quick-verifier-prompt.md` — mark the prompt as subagent-mode-only while preserving its safeguards.
- `skills/subagent-driven-development/scratch-ref-workflow.md` — scope scratch mechanics to effective `skip_quick_verifier=false`.
- `skills/using-simplepower/SKILL.md` — top-level tool/config routing summary.
- `skills/using-simplepower/references/simplepower-config.md` — canonical schema, precedence, environment mapping, validation, and semantics.
- `skills/using-simplepower/references/codex-tools.md` — Codex mapping for both verifier executors.
- `tests/simplepower-static/run-tests.sh` — positive and negative contract assertions.
- `tests/explicit-skill-requests/prompts/action-oriented.txt` — explicit request fixture for configuration-selected verification.
- `tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt` — SDD fixture for both executor modes.

### `/home/gary/.codex` repository

- `/home/gary/.codex/.gitmodules` — change `submodule.simplepower.branch` to `feature/skip-quick-verifier`.
- `/home/gary/.codex/simplepower` — advance the tracked gitlink to the pushed Simple Power feature-branch commit.

## Implementation Steps

1. After combined approval, verify `/home/gary/git/simplepower` is clean except for this plan at HEAD `a29a9f1a417703b17acd21898b0b00f88244c5ae`, create and switch to `feature/skip-quick-verifier`, and create the accepted-plan checkpoint containing only this plan.
2. Extend the canonical configuration contract:
   - add Boolean `skip_quick_verifier = true` to the base schema and change all “seven base keys” wording to eight;
   - add `SIMPLEPOWER_SKIP_QUICK_VERIFIER` to the supported non-empty environment layer;
   - validate TOML and environment values exactly like the existing Boolean keys, accepting only case-insensitive `true` or `false` from the environment;
   - retain per-key default → home TOML → repository TOML → environment → explicit-session precedence; and
   - state that a missing or empty environment value does not override lower layers, so the built-in `true` remains effective when no home, repository, or session layer changes the key.
3. Update brainstorming and planning contracts so every plan keeps exact timed quick-verification commands and records the resolved value and executor:
   - `true` selects `Main agent` for quick verification and has no FAST verifier allocation;
   - `false` selects `FAST subagent`, records the resolved FAST model/effort, and retains exact `fork_turns="none"`; and
   - changing the approved executor after plan approval requires fresh approval under approved-path enforcement.
4. Update `simplepower:subagent-driven-development` to resolve and validate the new key before quick verification, then branch without changing verification coverage:
   - for `true`, run the plan's exact quick commands in the coordinator, inspect failures, make only approved in-scope repairs under normal main-agent authority, rerun affected commands, and stop for fresh approval on scope or strategy changes;
   - for `false`, retain the current FAST worker dispatch, prompt, report statuses, tiny typo-fix limit, non-trivial failure handling, and lifecycle close; and
   - converge both branches before the existing coordinator final diff review and final-verification lifecycle.
5. Make scratch-ref behavior conditional. Create, diff, preserve, report, and clean `quick-verifier/before` and optional `quick-verifier/after` only in subagent mode. In main-agent mode, create no verifier run id or refs and omit verifier-ref lifecycle reporting. Keep scratch mechanics unchanged for subagent mode.
6. Update the subagent prompt and Codex tool mapping so `quick-verifier-prompt.md` is used only when effective `skip_quick_verifier=false`. Preserve all existing subagent restrictions and make clear that `fast_model` selects a model only for the subagent path; absence of a FAST environment override never disables or enables verification.
7. Update `AGENTS.md`, both README languages, the Codex guide, testing guide, example TOML, top-level Simple Power routing guidance, and plugin descriptions. Use “mandatory quick verification” for the phase and “optional/configuration-selected FAST quick-verifier subagent” for the worker. Keep plugin version `1.1.0` and avoid unrelated release or marketplace changes.
8. Extend static regression coverage to require:
   - the eighth base key, built-in `true`, environment mapping, resolution order, and strict Boolean validation;
   - default and explicit-`true` main-agent quick verification with no spawn, quick-verifier refs, or verifier lifecycle;
   - explicit `false` FAST dispatch with `fork_turns="none"`, unchanged tiny-fix boundaries, and before/optional-after refs;
   - mandatory quick and final verification in both modes;
   - no use of `use_subagent`, `skip_final_review`, or missing `SIMPLEPOWER_FAST_MODEL` as a quick-verifier enable/disable switch; and
   - updated explicit-invocation fixtures and absence of stale unconditional-subagent wording in active contracts.
9. Run the main-agent Quick Verification commands below. Diagnose failures directly, make only approved in-scope repairs, and rerun affected commands. Do not create quick-verifier scratch refs.
10. Inspect the full accepted-plan-to-working-state diff, correct in-scope inconsistencies, and run the complete Final Verification suite once.
11. Update this plan's concise `Execution Summary` with source implementation and verification facts. Because the external submodule must point to a committed source SHA, create the verified Simple Power final checkpoint commit, push `feature/skip-quick-verifier`, and report its SHA in the final handoff rather than trying to record the containing SHA in this plan.
12. In `/home/gary/.codex`, require a clean `master`, fetch the pushed source branch in the `simplepower` submodule, set `.gitmodules` to `branch = feature/skip-quick-verifier`, check out the pushed feature branch in the submodule, and stage only `.gitmodules` plus the `simplepower` gitlink. Verify the gitlink equals the pushed source SHA, commit the deployment update, and push `origin/master`.
13. Verify both pushed refs with `git ls-remote`, verify `/home/gary/.codex` is clean and its submodule branch configuration and gitlink are correct, and report the source and Codex-config SHAs. These post-source-commit delivery facts belong in the final handoff so the source plan and the gitlink do not create a cross-repository self-reference cycle.

## Risks

- **The key name implies all verification is skipped:** State everywhere that only the verifier subagent is skipped; quick and final verification remain mandatory.
- **Default behavior changes silently for existing users:** Document built-in `true` prominently and test that an absent key selects main-agent verification, while `false` restores the previous behavior.
- **The two paths drift in command coverage:** Plans define one exact quick command set; only the executor changes, and both paths converge before final review.
- **Scratch refs leak into main-agent mode:** Guard every creation, diff, preservation, reporting, and cleanup instruction with effective `skip_quick_verifier=false` and add negative static assertions.
- **Invalid Boolean values are treated as truthy strings:** Reuse strict TOML/environment validation and stop before execution on every invalid non-empty value.
- **FAST configuration is misread as an enable switch:** Keep `fast_model` as model selection only for subagent mode and explicitly test that missing/empty FAST overrides inherit a model without changing executor selection.
- **Source and `/home/gary/.codex` diverge:** Push the source branch before updating the submodule, verify the gitlink against the pushed source SHA, and push only the two approved parent-repository paths.
- **Concurrent branch movement or unrelated changes:** Recheck branch, HEAD, worktree, and remote state before each commit or push; stop and report any unexpected overlap rather than overwriting it.

## Quick Verification

For this approved implementation, target `skip_quick_verifier=true` selects the main agent. The coordinator runs these commands directly with no verifier subagent or scratch refs:

```bash
timeout 30s bash -n tests/simplepower-static/run-tests.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s rg -n 'skip_quick_verifier|SIMPLEPOWER_SKIP_QUICK_VERIFIER|Main agent|FAST subagent' AGENTS.md README.md docs/README.codex.md docs/testing.md simplepower.toml.example skills tests/simplepower-static/run-tests.sh
timeout 30s git diff --check
```

Every command must exit 0. The search must find the new key, environment override, main-agent default, and preserved FAST-subagent path in canonical contracts and tests. Any failure is diagnosed and repaired by the main agent within approved scope, followed by a focused rerun.

## Final Verification

The main agent reviews the complete diff for exact scope, English/Chinese parity, schema consistency, conditional dispatch, conditional scratch refs, unchanged final-review/checkpoint behavior, fixture quality, and absence of stale unconditional verifier-subagent claims. Before the execution-summary edit, run:

```bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 120s npm --prefix tests/brainstorm-server test
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s bash tests/skill-triggering/run-all.sh
timeout 120s bash tests/explicit-skill-requests/run-all.sh
timeout 30s bash scripts/bump-version.sh --check
timeout 30s git diff --check
```

All commands must exit 0. Then update only this plan's `Execution Summary` and rerun the same seven commands without further source-file edits. The second pass is terminal source evidence. Before the source final commit, `git status --short` may list only the eighteen Simple Power paths above; after the commit and push, the source worktree must be clean on `feature/skip-quick-verifier`.

After updating `/home/gary/.codex`, run:

```bash
timeout 30s git -C /home/gary/.codex config -f .gitmodules --get submodule.simplepower.branch
timeout 30s git -C /home/gary/.codex submodule status simplepower
timeout 30s git -C /home/gary/.codex diff --check
timeout 30s git -C /home/gary/.codex status --short
timeout 30s git ls-remote --heads origin feature/skip-quick-verifier
timeout 30s git -C /home/gary/.codex ls-remote --heads origin master
```

The configured branch must be `feature/skip-quick-verifier`; the gitlink and checked-out submodule must equal the pushed Simple Power source SHA; both pushed refs must resolve to their local final SHAs; and both repositories must be clean.

## Execution Record

This file is the coordinator-owned execution record. After the first complete source Final Verification pass, append or refresh `## Execution Summary` with current status and outcome, key changes, verification overview, notable findings/fixes/deviations, observed branch, pre-commit HEAD and worktree state, and unresolved follow-ups. Exclude raw logs, exhaustive file narration, and unrelated audits. A later material source finding refreshes the snapshot and adds a phase- or date-labeled follow-up before affected and terminal verification are rerun.

The source containing SHA and the later `/home/gary/.codex` deployment SHA are reported in the final handoff. Post-source-commit push and submodule-deployment results are not written back into this plan, because doing so would change the source SHA that the external gitlink is required to pin.

## Checkpoint Conditions

1. **Accepted plan checkpoint:** After one combined user approval covering this reviewed plan, `Implementation Route: Main agent`, the configuration-selected main-agent quick-verification executor for this run, immediate current-session execution, creation of `feature/skip-quick-verifier`, this accepted-plan checkpoint commit, the final reviewed/verified completion checkpoint, the required source and `/home/gary/.codex` pushes, and bounded in-scope coordinator execution commits during the active run. Commit only this plan at this checkpoint, then immediately invoke `simplepower:subagent-driven-development`.
2. **Final reviewed/verified completion checkpoint:** After direct implementation, main-agent quick verification, main-agent final diff review and in-scope fixes, the first source final-verification pass, execution-summary update, unchanged terminal source verification, the source final commit and push, the verified `/home/gary/.codex` branch/gitlink update, its commit and push, and final remote/cleanliness checks. Do not create empty commits.

Conditional execution commits do not add checkpoint types. This plan expects the source final commit before the `/home/gary/.codex` commit because a Git submodule pointer objectively requires committed source state; that source commit is both the verified source checkpoint and the technical prerequisite for the approved deployment step. The parent-repository commit then records the requested deployment. Combined approval authorizes only these coordinator-owned, in-scope commits and pushes during this active run and expires at final handoff. Convenience, history-shaping, worker, package, and per-task commits remain forbidden. Fresh approval remains required for scope, strategy, route, verification, destination branch, force-push, merge, or PR changes.

## Execution Summary

- **Status and outcome:** Source implementation and the first complete final-verification pass are successful. `skip_quick_verifier` now defaults to `true`, keeping mandatory quick verification in the main agent; explicit `false` preserves the FAST subagent and conditional scratch-ref path. Source commit/push and `/home/gary/.codex` deployment remain as approved delivery steps.
- **Key changes:** Added the eighth base key and `SIMPLEPOWER_SKIP_QUICK_VERIFIER`, strict Boolean resolution, configuration-selected planning/runtime branches, subagent-only scratch mechanics, aligned English/Chinese and Codex guidance, plugin metadata, fixtures, and static regression coverage.
- **Verification overview:** Main-agent quick verification passed without a verifier spawn, run id, scratch refs, or repairs. The first final pass passed the Simple Power static suite, 26 brainstorm-server tests, plugin-sync regression suite, five triggering fixtures, nine explicit-request fixtures, version consistency, and `git diff --check`.
- **Review findings, fixes, and deviations:** Main-agent diff review clarified that FAST allocation applies only to a selected verifier subagent and that tiny-fix authority is subagent-only. Focused static checks and the full final suite passed afterward. No `sp-impl` worker was dispatched, and the approved design, Main-agent route, file scope, and verification strategy did not change.
- **Repository state:** Branch `feature/skip-quick-verifier`; pre-commit HEAD `d43426168d8757672aa4ad41d9d45f0b7e847c3b`; the worktree contains only the eighteen approved Simple Power paths. The containing source SHA will be reported in the final handoff.
- **Unresolved issues and follow-ups:** No source issue is unresolved. The approved source branch push and `/home/gary/.codex` submodule branch/gitlink commit and push remain pending and will be reported without rewriting this plan.
