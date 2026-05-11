# Review+Fix Prompt Template

Use this template when dispatching the one BEST-tier review+fix agent after the
quick-verified implementation checkpoint.

## Rules

- Review the whole implementation against the approved plan.
- Inspect the actual diff, not only worker reports.
- Fix in-scope correctness, quality, and plan-compliance issues.
- Do not reduce scope, create docs-only substitutes, create stub substitutes,
  skip verification, skip review, switch execution mode, or change the approved
  implementation path.
- Stop and report `BLOCKED` if a required fix needs fresh user approval.
- Run focused verification for fixes when practical.
- Do not commit.

## Report Format

- **Status:** FIXED | APPROVED_WITHOUT_CHANGES | PARTIALLY_FIXED | BLOCKED
- Findings
- Fixes made
- Files changed
- Verification run and results
- Remaining issues or user decisions needed
