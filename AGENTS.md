# Simple Power Contributor Notes

Simple Power is a Codex-only fork of Superpowers. Keep active docs, tests, and
skill handoffs focused on Codex.

## Development Rules

- Use `simplepower:*` skill references in active docs and examples.
- Write generated plans under `docs/simplepower/plans/`.
- Do not add standalone spec generation to the normal active workflow.
- Do not add Claude, Gemini, OpenCode, Cursor, or Copilot harness support to
  the active repo.
- Do not add worker-owned or per-task commit requirements to planning or
  execution workflows.
- Coordinator-owned commits are allowed only at approved checkpoints. Normal
  workflows use two coordinator checkpoints: after the main-agent
  reviewed plan and route are accepted, and after the final reviewed/verified
  implementation. The main agent implements one cohesive package directly, or
  uses grouped workers only for at least two independent non-overlapping
  packages or specialized work with clear delegation value. Grouped workers,
  the mandatory FAST quick verifier, and any optional explorers must receive
  exact `fork_turns="none"` dispatches and must not commit.
- Coordinator-owned temporary scratch refs under
  `refs/simplepower/scratch/<run-id>/...` are allowed only as local
  quick-verifier diff anchors in the normal workflow. Scratch refs are not commits in accepted history,
  and they must be deleted after successful
  checkpoints or reported for manual cleanup on blockers or failed checkpoints.
- The normal workflow has no plan-review agent, secondary plan reviewer, final
  review agent, review-fix phase, worker-owned commits, or per-task commits.
  The main agent self-reviews plans, performs the final diff review, and makes
  in-scope fixes before final verification.
- Active configuration docs must use the per-key Simple Power resolution
  order: built-in defaults, `~/.codex/simplepower.toml`,
  `<git-root>/simplepower.toml`, supported non-empty environment overrides,
  then explicit current-session instructions. Root or nested `AGENTS.md` files
  do not provide model assignments.
- Preserve fork attribution in user-facing docs.
