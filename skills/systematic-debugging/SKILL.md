---
name: systematic-debugging
description: Use only when the user explicitly requests simplepower:systematic-debugging or an authorized Simple Power chain invokes it.
---

# Systematic Debugging

Use this skill for technical failures: test, build, production, integration,
performance, and unexpected-behavior bugs. It is most important under pressure,
after a failed fix, or when a quick patch seems obvious.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If Phase 1 has not produced a supported root-cause hypothesis, do not propose
or implement fixes. Guessing, piling on changes, or "one quick try" violates
the process.

## Activation Gate

Follow the four phases in order. Optional parallel investigation is a Phase 1
escalation only; it never replaces coordinator-owned Root Cause investigation.

Before any investigation-agent dispatch:

- The coordinator must have attempted the initial Phase 1 evidence work and
  stalled without a plausible root cause.
- Read and validate
  `skills/using-simplepower/references/simplepower-config.md`, resolving the
  effective `use_subagent` and `subagent_model` values by that contract. If the
  selected config is invalid or unreadable, stop and report the blocker.
  Missing candidate config files or keys inherit defaults only as that contract
  allows; do not replace invalid selected config with defaults.
- If `use_subagent=false`, do not dispatch. Continue Phase 1 directly.
- If `use_subagent=true`, read
  [`parallel-investigation.md`](parallel-investigation.md) before dispatch.
  Use the resolved model and reasoning effort, pass exact
  `fork_turns="none"`, assign at most six distinct read-only angles, forbid
  investigator fixes, allow temporary output only under
  `.codex-debug/<instance-id>/`, and synthesize all reports before fixes.

## Phase 1: Root Cause Investigation

Start with evidence, not solutions:

1. Read errors, warnings, stack traces, failing assertions, line numbers, file
   paths, and error codes completely.
2. Reproduce the failure consistently, or document exactly why reproduction is
   not reliable yet and gather more data.
3. Check recent changes: diffs, commits, dependencies, config, environment, and
   deployment/build differences.
4. Inspect component boundaries. For each boundary, verify inputs, outputs,
   environment/config propagation, and state at that layer before blaming a
   downstream symptom.
5. Trace data flow backward from the bad value or deep stack-frame symptom to
   its origin. For the full technique, read
   [`root-cause-tracing.md`](root-cause-tracing.md).

Phase-local stop signs: proposing solutions before tracing data flow, ignoring
error text, assuming a component boundary is fine without evidence, dispatching
agents before the stall/config/reference gates, dispatching more than six
agents, duplicating angles, asking investigators to fix code, or proceeding
before synthesis. If the human partner says "stop guessing," "is that
happening?", or "will it show us?", treat it as missing evidence. Stop and
resume Phase 1.

## Phase 2: Pattern Comparison

Find the working pattern before changing code:

1. Locate similar working code, tests, configs, workflows, or scripts in the
   same codebase.
2. Read relevant reference implementations completely before adapting them.
3. List differences between working and broken paths, however small.
4. Identify dependencies, assumptions, environment, and configuration required
   by the working pattern.

Phase-local stop signs: skimming references, dismissing a difference without
evidence, or adapting a pattern you do not fully understand. Return to the
pattern comparison until the differences are explicit.

## Phase 3: Hypothesis Testing

Use the scientific method:

1. State one specific hypothesis: "I think X is the root cause because Y."
2. Create or preserve the smallest failing test, reproduction, diagnostic
   command, or fixture that exposes the issue.
3. Test one hypothesis with one minimal change or diagnostic at a time. Do not
   bundle variables.
4. Verify the result. If confirmed, proceed to Phase 4. If rejected, record what
   it ruled out and return to Phase 1 or Phase 2 with the new evidence.

Phase-local stop signs: multiple simultaneous fixes, vague theories, manual
verification when an automated or scripted reproduction is feasible, or
pretending to understand an unknown. Say what is unknown and gather more
evidence.

## Phase 4: Implementation and Verification

Fix the confirmed root cause, not the symptom:

1. Keep the failing test or minimal reproduction from Phase 3. Use
   `simplepower:test-driven-development` when writing proper failing tests.
2. Implement one minimal root-cause fix. No bundled refactors, formatting, or
   "while here" improvements.
3. Verify the targeted reproduction/test passes and run appropriate regression
   checks. Use `simplepower:verification-before-completion` before claiming
   success.
4. If the fix fails, do not stack another change on top. Record the failed
   attempt and return to Phase 1 with the new evidence.
5. After three failed fixes, stop. The three-failure stop means question the
   architecture with the human partner before attempting another fix. Repeated
   failures across shared state, coupling, or unrelated symptoms usually mean
   the pattern itself is wrong.

If investigation shows the issue is truly environmental, timing-dependent, or
external, document what was ruled out, implement handling such as retry,
timeout, clearer error reporting, or monitoring, and verify that behavior. Most
"no root cause" conclusions are incomplete investigations.

## Supporting Techniques

- [`root-cause-tracing.md`](root-cause-tracing.md) — trace bugs backward to the
  original trigger.
- [`parallel-investigation.md`](parallel-investigation.md) — optional bounded
  Phase 1 investigator escalation after coordinator stall.
- [`defense-in-depth.md`](defense-in-depth.md) — add layered validation after
  finding root cause.
- [`condition-based-waiting.md`](condition-based-waiting.md) — replace arbitrary
  sleeps with condition polling.
