# Main-Agent Default And Compaction Continuity Implementation Plan

**Goal:** Make main-agent implementation the consent-safe default and preserve Simple Power workflow state across context compaction through the authoritative plan file.

## Design Summary

Simple Power will default every implementation plan to `Main agent`. Brainstorming may recommend `Grouped workers` only when independent non-overlapping packages or material specialization make delegation worthwhile, and it must obtain explicit user consent before that route becomes eligible. The evolving plan records `Grouped Workers Consent: Not requested`, `Declined`, or `Approved`; `simplepower:writing-plans` preserves the brainstorming-approved route and rejects a grouped route without `Approved` consent.

Brainstorming gains a narrow plan-write exception after initial triage establishes a feature name: create the future authoritative Markdown plan early with draft status, goal, and a replaceable `Brainstorming Continuity` snapshot. The hard gate still forbids implementation and unapproved implementation instructions. Planning expands the same file rather than creating a second artifact.

Compaction continuity is instruction-driven, not an executable Codex hook. The main agent refreshes compact snapshots after meaningful decisions or implementation milestones. In an approved grouped run, workers send structured milestone reports and the coordinator alone writes package-specific snapshots. After a compacted or reconstructed context resumes, the main agent rereads the active plan before further questions, tools, or edits; a worker rereads only its package continuity section. Temporary continuity sections are folded into permanent plan content or the final `Execution Summary` and removed when their phase completes.

This is one cohesive behavior-shaping instruction, documentation, fixture, and static-test package. The related workflow contracts must be edited and reviewed together, and no specialized delegation materially improves the work. No executable hook, helper agent, transcript parser, new configuration key, Codex installation change, standalone spec, or second plan artifact is in scope. Success means route consent cannot be silently bypassed, the same plan remains authoritative from brainstorming through completion, plan ownership stays with the coordinator, and existing explorer, plan-review, quick-verification, final-review, commit, and approved-path rules remain intact.

## Implementation Route

**Main agent.** The approved design explicitly selects the default direct route. The changes form one tightly coupled workflow package with overlapping behavioral assertions and no material specialization benefit. `Grouped Workers Consent: Not requested` for this implementation because grouped execution was not recommended and the user explicitly requested that the main agent perform the work.

Create and use branch `feature/main-agent-default-and-compaction-continuity` from the current `main` worktree after combined plan approval and before the accepted-plan checkpoint commit. Do not create the branch during planning.

## Exact Files

- `docs/simplepower/plans/2026-08-30-main-agent-default-and-compaction-continuity.md` — authoritative plan and coordinator-owned execution record.
- `skills/brainstorming/SKILL.md` — early evolving-plan creation, continuity snapshot lifecycle, grouped-route recommendation and explicit-consent gate, and post-compaction recovery.
- `skills/writing-plans/SKILL.md` — same-file promotion, consent validation, main-agent default, compact continuity fields, self-review, and handoff requirements.
- `skills/subagent-driven-development/SKILL.md` — main-agent and grouped-worker milestone reporting, coordinator-only plan writes, recovery reads, lifecycle integration, and final snapshot folding.
- `skills/subagent-driven-development/implementer-prompt.md` — package identifier, structured progress reports, and read-only package continuity recovery for approved grouped workers.
- `skills/using-simplepower/SKILL.md` — top-level description of the evolving plan, route-consent boundary, and instruction-level compaction protocol.
- `AGENTS.md` — active contributor contract for consent-gated grouped routing and coordinator-owned continuity writes.
- `README.md` — synchronized Chinese and English workflow documentation.
- `docs/README.codex.md` — Codex installation and workflow documentation.
- `docs/testing.md` — manual and static acceptance coverage for consent and continuity.
- `.codex-plugin/plugin.json` — concise plugin capability metadata reflecting main-agent default, grouped-route consent, and plan continuity.
- `tests/simplepower-static/run-tests.sh` — focused positive and negative assertions for the new active contracts while retaining existing invariants.
- `tests/skill-triggering/prompts/approved-brainstorming-handoff.txt` — approved brainstorming handoff identifies the already-created evolving plan and recorded route consent.
- `tests/skill-triggering/prompts/approved-planning-handoff.txt` — execution handoff distinguishes the default main route from an explicitly consented grouped route.
- `tests/explicit-skill-requests/prompts/after-planning-flow.txt` — example execution request reflects the consent-gated route contract.

No files are deleted or generated by this change.

## Implementation Steps

1. **Create the approved branch and accepted-plan checkpoint.**
   - After combined approval, create `feature/main-agent-default-and-compaction-continuity` from the current `main` worktree without discarding the uncommitted plan.
   - Confirm only this plan is changed, then commit it as the accepted-plan checkpoint before implementation edits.
   - Follow the coordinator commit and approved-path rules in `AGENTS.md` and `skills/writing-plans/SKILL.md`; no implementation worker, scratch ref, or intermediate convenience commit is authorized.

2. **Add focused static contract coverage before changing workflow text.**
   - Extend `tests/simplepower-static/run-tests.sh` to require all of the following in the appropriate active files:
     - exact `Grouped Workers Consent` states and rejection of grouped planning without `Approved` consent;
     - `Main agent` as the route retained when consent is absent, declined, silent, or uncertain;
     - early creation of one Markdown plan and promotion of that same path by planning;
     - required continuity fields: confirmed requirements or completed work, decisions or partial results, changed files where applicable, verification, blockers/open questions, and next action;
     - main-agent-only writes to the authoritative plan and structured worker milestone reports;
     - plan reread before post-compaction continuation;
     - folding/removal of temporary snapshots at phase completion;
     - explicit absence of executable compaction hooks, helper agents, transcript parsers, extra state artifacts, and new configuration keys.
   - Preserve existing assertions for hard gates, approved-path enforcement, isolated dispatch, quick verification, final diff review, execution summaries, scratch-ref limits, and two checkpoint types.

3. **Make brainstorming own the early plan and route consent.**
   - Update `skills/brainstorming/SKILL.md` so initial triage establishes a feature slug and creates `docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md` before detailed questions.
   - Define the only permitted pre-approval content as draft status, goal, `Grouped Workers Consent`, and `Brainstorming Continuity`; creation or refresh failure stops brainstorming with exact recovery status.
   - Refresh the snapshot after each meaningful decision using confirmed requirements, constraints, decisions/rejected choices, open questions, proposed route/consent status, and exact next action.
   - Make `Main agent` the recorded default. When grouped delegation has objective value, require brainstorming to explain the proposed cohesive packages and material benefit, ask for explicit consent, and record the answer. Silence, ambiguity, or rejection records or retains a non-approved state.
   - Require a compacted or reconstructed brainstorming context to reread the active plan before another question or tool. Missing, ambiguous, or unreadable active-plan state stops rather than guessing.
   - Hand the approved design and the existing plan path to `simplepower:writing-plans`; retain the hard gate against implementation and standalone specs.

4. **Make planning promote the same file and enforce consent.**
   - Update `skills/writing-plans/SKILL.md` to accept the evolving plan path from brainstorming and expand it in place into the shared compact plan core.
   - Default route selection to `Main agent`. Permit `Grouped workers` only when both objective package/specialization criteria and `Grouped Workers Consent: Approved` are present from brainstorming; planning may not solicit consent or promote the route independently.
   - Add route consent and the applicable continuity contract to plan self-review. If consent evidence is missing or contradictory, stop for user direction instead of selecting grouped execution.
   - Define phase transitions: fold `Brainstorming Continuity` into approved design content when planning completes; retain or create the relevant implementation snapshots during execution; fold them into `Execution Summary` and remove temporary sections at completion.
   - Keep mandatory quick verification, optional single-pass plan review, two checkpoint types, bounded coordinator commits, current-session execution handoff, and approved-path enforcement unchanged.

5. **Add execution continuity without shared-plan write conflicts.**
   - Update `skills/subagent-driven-development/SKILL.md` so direct main-agent execution refreshes `Implementation Continuity` after meaningful milestones with completed work, partial results, changed files, verification, blockers, and next action.
   - Before acting from compacted or reconstructed context, require the main agent to reread the active plan and validate route, scope, continuity, and next action. Missing or unreadable state blocks execution.
   - For an explicitly consented grouped route, assign every package a stable package identifier and package-specific continuity section. Workers send a `PROGRESS_SNAPSHOT` after meaningful milestones containing package, completed work, partial results, changed files, verification, blockers, and next action.
   - The coordinator consumes each report, validates ownership, and refreshes the worker's section; workers never edit the plan. A worker must successfully deliver the milestone report before proceeding beyond that milestone and reports a blocker if delivery cannot succeed.
   - After worker-context compaction, permit the worker to reread only its package continuity section from the supplied plan path before resuming. This narrow recovery read does not replace the self-contained worker prompt or authorize full-plan discovery.
   - Integrate snapshot folding/removal into the existing coordinator-owned execution-summary lifecycle without adding commits, checkpoints, reviewers, or scratch phases.

6. **Synchronize the grouped-worker prompt and active documentation.**
   - Update `skills/subagent-driven-development/implementer-prompt.md` with plan path, stable package identifier, exact progress-report format, milestone delivery gate, and read-only package recovery rule while preserving disjoint write ownership, no plan edits, no commits, no subagents, and exact `fork_turns="none"` dispatch.
   - Update `skills/using-simplepower/SKILL.md`, `AGENTS.md`, `.codex-plugin/plugin.json`, `README.md`, and `docs/README.codex.md` with the same main-agent default, brainstorming consent boundary, evolving-plan lifecycle, coordinator single-writer rule, and instruction-level pre/post-compaction semantics.
   - State clearly that optional explorers, optional plan review, and quick-verifier selection remain separately configured and are not governed by grouped-route consent.
   - Update `docs/testing.md` with concrete consent states, same-file lifecycle checks, main/worker recovery scenarios, failure scenarios, and the commands in this plan.

7. **Update handoff fixtures and perform the main-agent review lifecycle.**
   - Update the three listed prompt fixtures so approved brainstorming carries an existing plan path and consent state, while execution treats grouped routing as valid only when the user approved it during brainstorming.
   - Run mandatory quick verification through the main agent, inspect failures, make only approved in-scope repairs, and rerun affected commands.
   - Review the full diff from the accepted-plan checkpoint for semantic consistency, exact file scope, route consent enforcement, plan ownership, preservation of existing workflow invariants, and adequate tests; apply in-scope fixes directly.
   - Run the first final-verification pass, update this plan's `Execution Summary`, inspect that summary diff, and rerun terminal verification without further file edits before the final checkpoint.

## Risks

- **The early plan weakens brainstorming's hard gate.** Limit the exception to named continuity fields, explicitly prohibit implementation authorization, and statically reject standalone specs or a second plan artifact.
- **Planning could infer consent from objective suitability.** Use an exact consent field and require both objective suitability and `Approved`; test absent, declined, silent, and ambiguous cases as main-agent outcomes.
- **Instruction-level checkpointing cannot fire at the exact Codex compaction boundary.** Refresh after every meaningful milestone so the latest durable snapshot is already present; document this as proactive continuity rather than an executable lifecycle event.
- **Grouped workers could overlap on the shared plan.** Keep the coordinator as sole writer, require structured reports, and allow workers only a narrow read of their package continuity section after compaction.
- **Continuity sections could grow indefinitely or duplicate the final summary.** Replace current snapshots in place, fold durable facts into approved plan content or `Execution Summary`, and remove temporary sections when a phase completes.
- **Broad documentation edits could drift from active skill behavior.** Use shared exact terms, focused static assertions, bilingual README parity checks, and main-agent final diff review.

## Quick Verification

Resolved `skip_quick_verifier=true`; executor: **Main agent**. No quick-verifier subagent, run id, lifecycle entry, or scratch refs are used.

Run from the repository root after all implementation edits:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 30s bash tests/skill-triggering/run-all.sh
timeout 30s bash tests/explicit-skill-requests/run-all.sh
timeout 30s git diff --check
```

Expected results: every command exits `0`; static output ends with `All Simple Power static checks passed.`; both fixture suites report zero failures; and `git diff --check` prints no whitespace errors. A failure is diagnosed and repaired only within the approved exact files, then the affected command and the complete quick set are rerun.

## Final Verification

After the main agent reviews the complete accepted-plan-to-working-state diff and applies any in-scope fixes, run the first final pass:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
timeout 30s bash tests/skill-triggering/run-all.sh
timeout 30s bash tests/explicit-skill-requests/run-all.sh
timeout 30s git diff --check
```

Update `## Execution Summary` in this plan, inspect the summary diff, make no further file edits, and run the identical four-command set as terminal verification. Expected results remain four zero exits, zero fixture failures, the static success footer, and no whitespace errors. Any material finding reopens completion: make only approved in-scope repairs, refresh the summary with a labeled follow-up, and repeat affected checks plus the complete terminal set.

## Execution Summary

- **Status and outcome:** Complete on the approved `Main agent` route. Brainstorming now creates one evolving plan, Main agent is the consent-safe implementation default, and grouped workers require objective value plus `Grouped Workers Consent: Approved` from brainstorming. Plan-based pre/post-compaction continuity is coordinator-owned and uses replaceable main/package snapshots without executable helpers or extra state artifacts.
- **Key changes:** Updated the planned workflow skills, grouped-worker prompt, contributor and user documentation, plugin metadata, handoff fixtures, and focused static contracts. Temporary continuity is folded into permanent design content or this summary and removed at phase completion.
- **Verification overview:** The four-command quick set and first final-verification pass both exited `0`: static checks ended with `All Simple Power static checks passed.`, skill-triggering reported 5 passed/0 failed, explicit requests reported 9 passed/0 failed, and `git diff --check` was clean. Focused review checks also passed Bash syntax, plugin JSON parsing, and exact 15-file scope.
- **Review findings and deviations:** Coordinator review found and fixed one omission by requiring execution-time validation of `Grouped Workers Consent: Approved`, preventing crafted or stale grouped plans from bypassing brainstorming consent. No approved-path deviation, extra file, helper agent, configuration key, implementation worker, verifier subagent, scratch ref, or intermediate execution commit occurred.
- **Observed repository state:** Branch `feature/main-agent-default-and-compaction-continuity`; pre-commit HEAD `9f4bcc174378ecf4858498601e788e9a4d66d3da`; worktree contained exactly the 15 approved modified tracked files and no untracked files before this summary update.
- **Unresolved issues and follow-ups:** None.

## Execution Record

This file, `docs/simplepower/plans/2026-08-30-main-agent-default-and-compaction-continuity.md`, is the coordinator-owned execution record. After the first final-verification pass, append or refresh `## Execution Summary` with:

- current status and outcome;
- key changes;
- verification overview;
- notable review findings, fixes, and approved deviations;
- observed branch, pre-commit HEAD, and worktree state; and
- unresolved issues and follow-ups.

Keep it concise and exclude raw logs, exhaustive file narration, and unrelated audits. A later material finding refreshes the current snapshot and adds a phase- or date-labeled follow-up entry before affected and terminal verification rerun. The summary records the observed pre-commit HEAD; the final handoff reports the containing final SHA because a file cannot record its own containing commit without changing itself.

## Checkpoint Conditions

This workflow has exactly two mandatory coordinator checkpoint types. Conditional execution commits below do not add checkpoint types.

1. **Accepted plan checkpoint:** after the user gives combined approval for this final plan, `Implementation Route: Main agent`, immediate current-session execution, creation and use of `feature/main-agent-default-and-compaction-continuity`, the accepted-plan checkpoint commit, the final reviewed/verified completion checkpoint commit, and bounded in-scope coordinator execution commits during the active run. Create the branch, confirm exact scope, then commit this plan. No implementation begins before this checkpoint succeeds.
2. **Final reviewed/verified completion checkpoint:** after direct implementation, mandatory main-agent quick verification, main-agent final diff review and in-scope fixes, the first final-verification pass, execution-summary update, summary-diff inspection, and unchanged terminal verification pass. If uncommitted in-scope changes remain, create the newest final commit without requesting another approval; do not create an empty commit.

An additional coordinator-owned execution commit is allowed only when an objective approved command or work step requires committed state, or when this plan's execution summary must be committed separately or refreshed after a later material finding. This plan expects no intermediate technical-prerequisite commit. Convenience, history shaping, worker, package, or per-task commits do not qualify. Combined approval authorizes only compliant in-scope commits during this active run and expires at final handoff. Any scope, strategy, route, package-boundary, or verification change requires fresh explicit user approval.
