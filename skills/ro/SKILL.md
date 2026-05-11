---
name: ro
description: Use only when the user explicitly requests simplepower:ro or asks to use the Simple Power ro/read-only skill. Provides a read-only code discussion mode where Codex may inspect, discuss, run commands, and create tracked temporary files, but must not edit existing repo files.
---

# Purpose

`simplepower:ro` is the Simple Power read-only discussion mode. Use it to inspect code, explain behavior, and reason about changes without modifying repo-tracked source.

## Activation

- Activate only when the user explicitly invokes `simplepower:ro` or asks for the Simple Power read-only skill.
- Keep it active for the current task or discussion until the user explicitly disables it or requests implementation outside read-only mode.
- When RO first needs a temp artifact, announce the active instance id and temp root.

## Write Rules

- Never edit, overwrite, rename, delete, format, migrate, or code-generate over existing repo files.
- Do not use `apply_patch` against existing files while RO is active.
- Do not run commands whose purpose is to modify existing repo files.
- Create and edit only temporary files that belong to the current RO session and are recorded in the manifest.
- Before writing any path, verify that it does not already exist unless it is already recorded in the current RO manifest.
- If the user asks for a code change, provide a proposed patch, diff, or explanation instead of applying the change.
- If a command unexpectedly modifies existing repo files, stop, report what changed, and do not revert without explicit user confirmation.

## Allowed Actions

- Read and search files, configs, schemas, tests, docs, and git history.
- Run existing files, scripts, tests, builds, and checks when they help the discussion.
- Create session-scoped temp scripts, fixtures, notes, logs, outputs, or other artifacts under `<repo>/.codex-ro/<instance-id>/` with a manifest.
- Execute temp scripts from the RO temp root.
- Write cache or build outputs only when they are normal command side effects and do not touch repo-tracked source.

## Temp Workspace

- Use `<repo>/.codex-ro/<instance-id>/` as the temp root.
- Use `<repo>/.codex-ro/<instance-id>/manifest.json` as the manifest path.
- Derive `instance-id` from `$CODEX_THREAD_ID` when available; otherwise use `YYYYMMDD-HHMMSS-<short-random>`.
- Create the manifest before or with the first temp artifact.
- Keep manifest entries consistent and include `instance_id`, `repo_root`, `created_at`, and `artifacts`.
- Record each artifact with `path`, `kind`, `purpose`, `created_at`, and `last_touched_at`.
- Use artifact `kind` values of `script`, `fixture`, `note`, `log`, `output`, or `other`.
- When adding or editing a temp artifact, update its manifest entry in the same turn.
- Paths may be absolute or repo-relative, but use one style consistently within the manifest.
- Create temporary files outside `.codex-ro/<instance-id>/` only when the user explicitly asks for that location, and record them in the same manifest.

## Cleanup And Revert

- On clean up, cleanup, revert, or remove-temp-files requests, read the current manifest first.
- List the recorded artifacts that would be removed and ask for confirmation.
- Delete only manifest-listed artifacts after confirmation.
- Remove empty `.codex-ro/<instance-id>` directories when they are left behind.
- Do not use broad deletion, `git checkout`, `git reset`, or repo-wide cleanup commands.

## Communication

- Be explicit when an action is blocked by RO.
- Prefer concrete findings, file references, command output, and proposed diffs.
- When temp files are created, mention the temp root and manifest path briefly.
