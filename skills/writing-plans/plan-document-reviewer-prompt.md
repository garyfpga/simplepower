# Plan Document Reviewer Prompt Template

Use this template for the optional single-pass plan review after the saved plan
passes main-agent self-review.

Dispatch shape:

```text
spawn_agent(agent_type="worker", model=<resolved_plan_review_model>, reasoning_effort=<resolved_effort>, fork_turns="none", message=<this self-contained prompt>)
```

```text
Your task is to review one Simple Power implementation plan. Perform the review
directly and return only problems serious enough to require a plan change before
implementation.

<agent-instructions>
Plan path: [EXACT SAVED PLAN PATH]
Approved brainstorming design: [COMPLETE RELEVANT DESIGN CONTEXT]
Selected implementation route and allocation: [ROUTE AND ALLOCATION]

Read the complete plan at the given path and compare it with the approved
design. Report only these severities:

- Critical: The plan would produce an incorrect or unsafe result, violate a
  required user goal or constraint, or authorize a fundamentally invalid
  implementation.
- Must Fix: The plan has a contradiction, missing requirement, ambiguous
  interface or ownership boundary, non-executable step, or inadequate required
  verification that is likely to block or misdirect implementation.

Do not report minor issues, style preferences, wording improvements, optional
enhancements, speculative risks, advisory recommendations, or any other
severity. Do not praise or summarize the plan.

This is a read-only single pass. Do not edit or create files, stage or commit,
create or manage refs, run Codex CLI, spawn subagents, invoke workflow skills,
restart execution, or reroute the workflow. Do not request a revised plan and
do not expect another review pass.

Return exactly:

Status: <PASS or ISSUES_FOUND>

Critical:
<Write `- None`, or one or more findings.>

Must Fix:
<Write `- None`, or one or more findings.>

Use this exact format for every finding:
- [plan section or exact location]: [specific issue] - [implementation impact]
  - Required correction: [minimum correction]

Use PASS only when both sections are `None`. Use ISSUES_FOUND when either
section contains at least one finding. Do not add other sections.
</agent-instructions>

Execute this now. Output only the structured report.
```
