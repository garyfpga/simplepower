# Parallel Investigation

Read this reference only when `simplepower:systematic-debugging` Phase 1 has
stalled and the main skill's Activation Gate is considering optional
investigation-agent escalation.

## Contents

- Purpose and Authority
- Dispatch Preconditions
- Config and Spawn Requirements
- Investigation Brief
- Angle Selection
- Investigator Permissions
- Investigator Report
- Coordinator Synthesis

## Purpose and Authority

Parallel investigation is bounded evidence gathering inside Phase 1: Root
Cause Investigation. It does not authorize fixes, skip the four-phase workflow,
or choose a root cause by vote count. The coordinator remains responsible for
synthesis and cannot proceed to Phase 2, Phase 3, or Phase 4 until synthesis
supports a root-cause hypothesis or identifies the next diagnostic test.
Evidence gathering stops when the next decision is adequately supported, after
checking plausible contradictions; it continues when unresolved uncertainty
could change that decision or its safety.

## Dispatch Preconditions

Before dispatching investigators, confirm all of the following:

- The coordinator read the full error output or stack trace.
- The smallest useful reproduction was attempted, or unreliable reproduction is
  documented.
- Recent changes, diffs, dependencies, config, and environment were checked.
- Relevant files, commands, components, and discriminating system boundaries
  were identified.
- Obvious backward data-flow tracing was attempted for deep stack symptoms.
- `skills/using-simplepower/references/simplepower-config.md` was read and
  validated for effective `use_subagent` and `subagent_model`.
- `use_subagent=true`; if it is false, disabled subagents mean no dispatch.

If those steps adequately support the next root-cause hypothesis or diagnostic
test, do not dispatch. Continue in Phase 1 with that diagnostic test, or proceed
to Phase 2 when a root-cause hypothesis is supported.

## Config and Spawn Requirements

Parse the resolved `subagent_model` at its final dash. The prefix is the
investigator `model`; the suffix is `reasoning_effort`. If parsing, capability,
model, reasoning-effort, or spawn fails, stop and report an explicit blocker.
Do not substitute another model, effort, or execution path.

Missing candidate config files or keys inherit defaults only as
`simplepower-config.md` allows. Invalid or unreadable selected config is a
blocker, not a reason to fall back. This switch governs only optional
investigation-agent escalation; mandatory plan, implementation, and review tiers
remain outside it.

Every spawn must:

- Use the resolved model and reasoning effort.
- Pass exact `fork_turns="none"`.
- Include a complete, self-contained investigation brief, isolated from inherited
  context.
- Stay within the six-agent maximum.
- Assign one distinct read-only angle per investigator.

## Investigation Brief

Write the brief before spawning. Include:

- Symptom and observed behavior.
- Reproduction command or exact steps.
- Relevant error output, stack trace, or failing assertions.
- Known facts and evidence already collected.
- Causes already ruled out.
- The decision that remains unsupported and the contradictory evidence that
  would change it.
- Relevant files, modules, components, boundaries, and recent changes.
- Constraints: do not implement fixes; do not edit existing repo files.
- Temporary-output rule: use only `.codex-debug/<instance-id>/`.
- Expected report format.

## Angle Selection

Choose only the distinct angles needed for unresolved, decision-changing
uncertainty, up to the six-agent maximum. Do not fill the allowance just because
it exists, and do not duplicate angles across investigators. Each angle should
target a different cause, contradiction, boundary, or missing fact that could
change the next hypothesis, diagnostic test, fix, or safety decision. Useful
angles include:

- Error-message and stack-trace interpretation.
- Recent-change regression analysis.
- Similar working pattern comparison.
- Data-flow or backward-tracing origin search.
- Async, timing, race, or flaky-test investigation.
- Configuration, environment, dependency, or boundary propagation analysis.
- Architecture-level coupling or invariant analysis.

## Investigator Permissions

Investigators may read files, search, run existing tests or scripts, inspect
read-only git history, and create temporary diagnostic scripts, fixtures, logs,
notes, or outputs only under `.codex-debug/<instance-id>/`.

Investigators must not edit, overwrite, format, rename, or delete existing repo
files. They must not apply fixes, prepare patches as their primary output, or
make broad refactors. If a diagnostic command unexpectedly modifies existing
repo files, the investigator must stop and report what changed.

## Investigator Report

Each report must include:

- Assigned angle.
- Files, commands, and artifacts inspected.
- Likely cause or root-cause hypothesis, if any.
- Supporting evidence.
- Contradicting evidence checked or found.
- Confidence level and why.
- Causes ruled out.
- Recommended next decision or minimal diagnostic test.
- Unresolved risk that could still change the decision.
- Temporary artifacts created.
- Confirmation that no existing repo files were intentionally modified.

## Coordinator Synthesis

After investigators return, consume each report and close the agent unless
there is a written reason to keep it open. Synthesize the reports into one of:

- A supported root-cause hypothesis, followed by Phase 3 minimal testing.
- The next diagnostic test needed before a hypothesis is justified.
- A documented "still unknown" state with what has been ruled out and whether
  to gather more evidence or discuss architecture-level concerns with the user.

If reports disagree, run the smallest diagnostic test that distinguishes the
competing hypotheses. If the next decision is adequately supported and plausible
contradictions were checked, do not collect extra angles, logs, or reports.
Never proceed to implementation until synthesis supports a root-cause
hypothesis.
