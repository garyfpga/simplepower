# Final Review+Fix Prompt Template

Use this template for exactly one final review+fix agent after the
quick-verified implementation checkpoint. The coordinator must validate the
effective `final_review_model` before dispatch and paste all bracketed content
so the prompt is self-contained. When `final_review_model` is absent, its
effective value is the fully resolved `review_model`.

Dispatch shape:

```text
spawn_agent(agent_type="worker", model=<resolved_final_review_model>, reasoning_effort=<resolved_final_review_effort>, fork_turns="none", message=<this self-contained prompt>)
```

```text
You are the one final review+fix agent for the accepted Simple Power
implementation.

Perform the assigned review directly in this worker. Do not run Codex CLI, do
not spawn subagents, do not invoke Simple Power workflow skills, do not recurse
into another workflow, do not restart execution, and do not reroute execution.

Approved plan context:
- Plan path/title: [PLAN PATH OR TITLE]
- Approved goal/design summary: [SUMMARY]
- Interface Contract: [ENTRIES]
- File Ownership and approved write scopes: [EXACT FILES/OWNERS]
- Contract inputs by task: [SUMMARY]
- Serialization decisions and capacity queue notes: [SUMMARY]
- Verification requirements: [COMMANDS/EXPECTATIONS]
- Worker reports: [SUMMARIES]
- Quick verifier report: [SUMMARY]
- Whole implementation diff or exact non-ref read-only diff command:
  [DIFF OR COMMAND]
- Shared review snapshot: [QUICK-VERIFIED CHECKPOINT AND `review-fix/before`]
- Scratch context: coordinator created
  `refs/simplepower/scratch/<run-id>/review-fix/before`; you must not create,
  update, delete, inspect, or manage refs.

Inspect the actual diff, not only reports. Fix in-scope correctness, quality,
and plan-compliance issues within the approved File Ownership/write scopes, and
run focused verification for fixes when practical.

Rules:
- Stop and report `BLOCKED` if a required fix needs fresh user approval, true
  scope expansion, reduced scope, docs-only substitute, stub substitute,
  skipped verification, changed implementation strategy, or broader rewrite.
- Do not reduce scope, create substitute work, skip review, skip verification,
  switch execution mode, or change the approved path.
- Do not create, update, delete, inspect, or manage scratch refs.
- Do not commit, stage unrelated files, manage refs, create branches, merge,
  rebase, push, or open PRs.
- Preserve concurrent edits and do not revert unrelated changes.

Report exactly:
- Status: FIXED | APPROVED_WITHOUT_CHANGES | PARTIALLY_FIXED | BLOCKED
- Findings
- Fixes made
- Exact changed files
- Focused verification run with results
- Remaining risks, deviations, or user decisions needed
- Whether final verification can proceed
```
