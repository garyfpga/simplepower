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
- Coordinator-owned commits require accepted workflow authorization. Normal
  workflows retain two mandatory checkpoint types: after the main-agent
  reviewed plan and route are accepted, and after the final reviewed/verified
  completion. The same combined approval may authorize additional
  coordinator-owned execution commits during the active run only when an
  objective technical prerequisite requires committed state before approved
  testing or work, or when the original plan's execution summary must be
  created or refreshed separately. Convenience and history-shaping commits,
  worker-owned commits, and per-task commits remain forbidden; active-run
  authorization ends at final handoff. The main agent implements one cohesive
  package directly, or uses grouped workers only for at least two independent
  non-overlapping packages or specialized work with clear delegation value.
  Grouped workers, the optional single-pass plan reviewer, the mandatory FAST
  quick verifier, and any optional explorers must receive exact
  `fork_turns="none"` dispatches and must not commit.
- Coordinator-owned temporary scratch refs under
  `refs/simplepower/scratch/<run-id>/...` are allowed only as local
  quick-verifier diff anchors in the normal workflow. Scratch refs are not commits in accepted history,
  and they must be deleted after successful
  checkpoints or reported for manual cleanup on blockers or failed checkpoints.
- The normal workflow has at most one optional read-only plan-review agent,
  activated only by `plan_review_model` in a supported `simplepower.toml` or a
  non-empty `SIMPLEPOWER_PLAN_REVIEW_MODEL`. The main agent applies accepted
  Critical and Must Fix findings once without redispatch. There is no plan
  review loop, secondary plan reviewer, plan-review scratch phase, final review
  agent, review-fix phase, worker-owned commit, or per-task commit. The main
  agent self-reviews plans, performs the final diff review, and makes in-scope
  fixes before final verification.
- Active configuration docs must use the per-key Simple Power resolution
  order: built-in defaults, `~/.codex/simplepower.toml`,
  `<git-root>/simplepower.toml`, supported non-empty environment overrides,
  then explicit current-session instructions. Root or nested `AGENTS.md` files
  do not provide model assignments.
- Preserve fork attribution in user-facing docs.
