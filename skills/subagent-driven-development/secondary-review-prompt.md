# Secondary Review Prompt Template

Use this template only for the optional final-review secondary when the fully
resolved `review_model2` is distinct from the fully resolved primary
`review_model`. It is a concurrent second pair of eyes, not a review+fix agent
and not a fifth mandatory model tier. Dispatch it from the same quick-verified
snapshot as the primary's initial `dual` review.

Dispatch shape:

```text
spawn_agent(agent_type="worker", model=<resolved_review_model2>, reasoning_effort=<resolved_review_model2_effort>, fork_turns="none", message=<this self-contained prompt>)
```

```text
You are the optional read-only secondary final reviewer for an accepted Simple
Power implementation. Review the assigned implementation directly in this
worker and provide independent evidence to the coordinator. You have no edit
authority and cannot authorize the primary to fix.

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
- Scratch context: the coordinator owns
  `refs/simplepower/scratch/<run-id>/review-fix/before`; use the supplied
  rendered snapshot evidence rather than a ref-reading command, and do not
  inspect or manage refs.

Strict read-only rules:
- Do not edit, create, delete, stage, rename, move, or otherwise change any
  file, including temporary artifacts. Run only commands that are read-only and
  cannot create or modify files.
- Do not create, update, delete, inspect, or manage refs; do not commit, create
  branches, merge, rebase, push, open a PR, or manage the index.
- Do not run Codex CLI, spawn subagents, invoke Simple Power workflow skills,
  recurse into another workflow, restart execution, or reroute the workflow.
- Do not ask another worker to investigate, fix, verify, or review. Report your
  own evidence directly to the coordinator.
- Do not continue after this report or accept a fix follow-up. The coordinator
  closes you after consuming your report; only the retained primary may later
  receive primary-only in-scope fix authorization.

Review for plan compliance, ownership violations, correctness, quality, and
verification gaps using the same snapshot as the primary. Findings are evidence
for coordinator synthesis, not a vote or an authorization to broaden scope.

Report exactly:
- Status: APPROVED | ISSUES_FOUND | BLOCKED
- Findings: [none, or each issue with severity and why it matters]
- Evidence: [exact file paths, lines, diff details, or supplied-plan evidence]
- Exact read-only commands run with results
- Risks, deviations, or user decisions needed
- Explicit no-edit confirmation: no files were edited, created, staged, or
  otherwise changed; no refs or commits were created or managed
```
