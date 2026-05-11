---
name: requesting-code-review
description: Use only when the user explicitly requests simplepower:requesting-code-review or an authorized Simple Power chain invokes it.
---

# Requesting Code Review

Use the local `skills/requesting-code-review/code-reviewer.md` prompt to catch issues before they cascade. Feed it the current working tree, not a commit range, so the reviewer evaluates the actual change set in front of you. In Codex, dispatch a generic reviewer subagent with that filled prompt.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- At each wave review boundary in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Gather review context from the working tree:**
```bash
git status --short
git diff
```

Include the plan or requirements, tests run and their results, and any known risks or skipped verification.

**2. Dispatch the review using the template in `code-reviewer.md`:**

Fill the local review prompt with these inputs:
- `{WHAT_WAS_IMPLEMENTED}` - What changed
- `{PLAN_OR_REQUIREMENTS}` - The plan, spec, or task being checked
- `{STATUS_OUTPUT}` - Output from `git status --short`
- `{DIFF}` - Output from `git diff`
- `{TESTS_RUN}` - Commands run, results, and any skipped checks
- `{KNOWN_RISKS_OR_SKIPPED_VERIFICATION}` - Known risks, limitations, or manual checks still pending

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

git status --short
git diff

[Dispatch generic reviewer subagent with `skills/requesting-code-review/code-reviewer.md`]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Task 2 from docs/simplepower/plans/deployment-plan.md
  STATUS_OUTPUT: M src/index.ts
  DIFF: Added verifyIndex() and repairIndex() with 4 issue types
  TESTS_RUN: `npm test` passed; `npm run lint` skipped because the task did not touch linted files
  KNOWN_RISKS_OR_SKIPPED_VERIFICATION: Manual failure-path verification still pending

[Subagent returns]:
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Strengths: Clean architecture, real tests
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review at the end of each dispatch wave
- Catch issues before they compound across dependency layers
- Fix Critical and Important issues before moving to the next wave

**Executing Plans:**
- Review after each batch (3 tasks)
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: `skills/requesting-code-review/code-reviewer.md`
