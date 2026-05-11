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
  plus final verification.
- Preserve fork attribution in user-facing docs.
