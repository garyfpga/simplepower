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
- Coordinator-owned commits are allowed only at approved checkpoints: after
  the reviewed plan and allocation are accepted, after all implementation file
  edits plus quick verification before final review, and after final review/fix
  plus final verification. Coordinator-owned temporary scratch refs under
  `refs/simplepower/scratch/<run-id>/...` are allowed only as local review diff
  anchors. Scratch refs are not commits in accepted history, and they must be
  deleted after successful checkpoints or reported for manual cleanup on
  blockers or failed checkpoints.
- Active configuration docs must use the per-key Simple Power resolution
  order: built-in defaults, `~/.codex/simplepower.toml`,
  `<git-root>/simplepower.toml`, non-empty model-tier environment overrides,
  then explicit current-session instructions. Root or nested `AGENTS.md` files
  do not provide model assignments.
- Preserve fork attribution in user-facing docs.
