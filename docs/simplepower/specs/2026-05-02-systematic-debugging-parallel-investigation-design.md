# Systematic Debugging Parallel Investigation Design

## Context

`simplepower:systematic-debugging` currently enforces a single-threaded
root-cause workflow: read the error, reproduce, inspect recent changes, trace
data flow, compare patterns, form one hypothesis, then fix only after the root
cause is understood.

That discipline is still correct, but difficult bugs can stall after the main
agent completes initial Phase 1 investigation. At that point, the workflow can
benefit from bounded parallel investigation if each subagent receives a distinct
angle and returns evidence instead of fixes.

Simple Power already has model-routing precedent in subagent workflows:
localized, lower-risk work can use `gpt-5.4-mini` with high effort, while
ambiguous or cross-cutting work should use `gpt-5.4` with high effort.

## Goals

- Add a parallel investigation escalation to `simplepower:systematic-debugging`
  for cases where initial Phase 1 investigation stalls.
- Preserve the root-cause-first rule: no fixes before a root cause hypothesis is
  supported by evidence.
- Dispatch at most six investigation agents.
- Route each investigation angle to either `gpt-5.4-mini` high effort or
  `gpt-5.4` high effort according to predicted difficulty.
- Allow investigation agents to create temporary diagnostic scripts and
  artifacts while forbidding edits to existing repo files.
- Require the main agent to synthesize agent reports into one next hypothesis or
  one next diagnostic test before moving forward.

## Non-Goals

- Do not make subagent dispatch mandatory for every bug.
- Do not dispatch agents before the main agent performs initial Phase 1
  investigation.
- Do not force exactly three mini agents and three full agents. The limit is up
  to six total agents, with the split chosen by angle difficulty.
- Do not let investigation agents implement fixes.
- Do not replace Phase 2 pattern analysis, Phase 3 hypothesis testing, or Phase
  4 implementation.
- Do not add new runtime dependencies.

## Escalation Point

Parallel investigation is allowed only after the main agent has completed
initial Phase 1 work and still cannot identify a plausible root cause.

Before dispatching agents, the main agent must have attempted the relevant
initial investigation steps:

- read the full error output or stack trace
- reproduced the failure or documented why reproduction is not yet reliable
- checked recent changes or relevant diffs
- identified relevant files, commands, components, or system boundaries
- traced obvious data flow when the failure appears deep in the call stack

If those steps reveal a plausible root cause, the main agent should continue
with the normal systematic-debugging flow instead of dispatching agents.

## Investigation Brief

The main agent writes a compact investigation brief before spawning agents. The
brief should include:

- symptom and observed behavior
- reproduction command or steps
- relevant error output, stack trace, or failing assertions
- known facts
- causes already ruled out
- relevant files, modules, components, or recent changes
- constraints, including "do not fix" and "do not edit existing repo files"
- expected output format

The brief is copied into each agent prompt, along with one angle-specific task.
Simple Power subagents should default to `fork_context=false`; the prompt should
contain the brief instead of relying on inherited conversation history.

## Angle Selection

The main agent chooses distinct investigation angles and dispatches one agent per
angle, capped at six total agents.

Common angles include:

- error-message and stack-trace interpretation
- recent-change regression analysis
- similar working pattern comparison
- data-flow or backward-tracing origin search
- async, timing, race, or flaky-test investigation
- configuration, environment, dependency, or boundary propagation analysis
- architecture-level coupling or invariant analysis

Agents must not duplicate the same angle. If two candidate angles overlap, the
main agent should merge them or dispatch only the more useful one.

## Model Routing

Each angle gets a model based on predicted difficulty:

- `gpt-5.4-mini` with `reasoning_effort="high"` for localized, concrete, narrow
  investigation angles with clear files or commands.
- `gpt-5.4` with `reasoning_effort="high"` for ambiguous, cross-cutting,
  architecture-level, async/timing, deep data-flow, or multi-component boundary
  angles.

When escalation is used, the main agent may dispatch any mix from one to six
agents. It should not spend full-model budget on narrow mechanical checks, and it
should not assign complex system reasoning to mini solely to satisfy a fixed
quota.

## Investigation Agent Rules

Investigation agents may:

- read and search repo files
- run existing tests, builds, scripts, or reproduction commands
- create temporary diagnostic scripts, fixtures, notes, logs, or outputs
- execute temporary diagnostic scripts
- inspect git history and diffs with read-only commands

Investigation agents must not:

- edit, overwrite, format, rename, or delete existing repo files
- apply a fix or prepare a patch as their primary output
- make broad refactors
- duplicate another agent's angle
- continue after a diagnostic command unexpectedly modifies existing repo files

If an agent needs diagnostics, it should create them under
`.codex-debug/<instance-id>/` by default and report the artifact paths in its
final output. If a different temp location is necessary, the agent must explain
why in its final output.

## Agent Output Contract

Each investigation agent returns:

- assigned angle
- files, commands, and artifacts inspected
- evidence found
- root-cause hypothesis, if any
- confidence level and why
- causes ruled out
- recommended next minimal diagnostic test
- any temporary artifacts created
- confirmation that no existing repo files were intentionally modified

Agents should say clearly when they do not understand the failure or when their
angle did not produce useful evidence.

## Synthesis

After agents return, the main agent consumes each report and closes the agent
unless there is a written reason to keep it open.

The main agent then compares evidence across reports. It must not choose a root
cause by vote count alone. If reports disagree, the main agent identifies the
smallest diagnostic test that distinguishes between the competing hypotheses.

The result of synthesis is one of:

- a supported root-cause hypothesis, followed by Phase 3 minimal testing
- a next diagnostic test needed before forming the hypothesis
- a documented "still unknown" state with what has been ruled out and whether to
  gather more evidence or discuss architecture-level concerns with the user

Only after synthesis supports a root-cause hypothesis should the main agent
continue to Phase 4 implementation.

## Guardrails

- Parallel investigation is an escalation inside Phase 1, not a replacement for
  Phase 1.
- Dispatch no more than six investigation agents.
- Use `fork_context=false` by default.
- Give each agent exactly one investigation angle.
- Do not dispatch agents without a written investigation brief.
- Do not dispatch agents to implement fixes.
- Do not proceed to fixes until the main agent has synthesized the evidence.
- If all agents fail to find root cause, document the negative evidence and
  either gather more diagnostics or discuss whether the architecture or test
  strategy needs to change.
- If temporary diagnostics accidentally modify existing repo files, stop and
  report what changed before continuing.

## Testing

Focused tests should be static and prompt-behavior checks that match the
existing skill test style.

Static checks should verify that `skills/systematic-debugging/SKILL.md`
mentions:

- parallel investigation escalation
- initial Phase 1 investigation before agent dispatch
- at most six investigation agents
- `gpt-5.4-mini` with high effort
- `gpt-5.4` with high effort
- `fork_context=false`
- temporary diagnostics allowed
- no fixes by investigation agents
- synthesis before implementation

Prompt-behavior checks should verify:

- a debugging prompt does not dispatch agents immediately
- escalation happens only after initial Phase 1 investigation stalls
- investigation agents receive a brief, one angle, constraints, and a structured
  output contract
- the root-cause-first language remains intact

Existing Simple Power static checks and skill-triggering tests should continue
to pass.
