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
- Active model docs must preserve root `AGENTS.md` precedence and must not set
  local model override values unless intentionally changing this repo's
  defaults.
- Preserve fork attribution in user-facing docs.
