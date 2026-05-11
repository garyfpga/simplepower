# Per-User Anti-Lazy Hook Path Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for plan-first parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers according to the approved file ownership, run the quick verifier, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Make the local anti-lazy Codex Stop hook portable across per-user `~/.codex` installs.

**Design Summary:** The approved design keeps this as a per-user `~/.codex` setup only. `hooks/anti_lazy_stop.py` already resolves schema and log files through `Path.home() / ".codex" / "hooks"`, so implementation changes only `hooks.json` to remove the hard-coded `/home/gary` command path. The hook command should use an explicit shell wrapper with `$HOME` rather than `~`, because the hook runner's tilde expansion behavior should not be assumed. Success means the config contains no `/home/gary` path and the configured command runs when `HOME` points at another copied `.codex` layout.

**Architecture:** `hooks.json` remains the Codex config-layer hook entry point. The Stop hook command invokes `/bin/sh -c` and `exec`s `/usr/bin/python3 "$HOME/.codex/hooks/anti_lazy_stop.py"`, preserving stdin for Codex hook input while making the script path user-relative. The Python hook remains responsible for per-user runtime paths through `Path.home()`.

**Tech Stack:** JSON hook config, POSIX shell, Python 3, existing Codex Stop hook script.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `/home/gary/.codex/hooks.json` | Task 1: Make hook command user-relative | modify | Replace the hard-coded anti-lazy Stop hook script path with a `$HOME`-relative shell wrapper command. | Single implementation task owns the only edited file; no parallel file-edit collisions. |

## Implementation Tasks

### Task 1: Make Hook Command User-Relative

**Goal:** Update the anti-lazy Stop hook command so the same `hooks.json` works for another Unix user account with the same per-user `~/.codex/hooks` files.

**Depends on:** Reviewed plan and model/task allocation approval.

**Write scope:** `/home/gary/.codex/hooks.json`

**Parallel:** No. This is the only implementation file-edit task.

**Risk:** Low. The change is localized to one hook command string, and verification exercises JSON parsing plus execution under a temporary `HOME`.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`

**Inputs from the approved design:** Per-user `~/.codex` only; use `$HOME` through an explicit shell wrapper; do not change `anti_lazy_stop.py` because it already uses `Path.home()` for schema and log paths.

**Outputs and file-level responsibilities:**
- `/home/gary/.codex/hooks.json` keeps the existing `Stop` hook structure, `timeout`, and `statusMessage`.
- The inner hook entry's `command` becomes `/bin/sh -c 'exec /usr/bin/python3 "$HOME/.codex/hooks/anti_lazy_stop.py"'`.
- The command string contains no `/home/gary` literal.

**Implementation steps:**
1. Open `/home/gary/.codex/hooks.json` and locate `hooks.Stop[0].hooks[0].command`.
2. Replace the command value:

   ```json
   "/bin/sh -c 'exec /usr/bin/python3 \"$HOME/.codex/hooks/anti_lazy_stop.py\"'"
   ```

3. Leave all other JSON fields unchanged.
4. Run the task verification commands below from `/home/gary/.codex`.

**Verification commands:**
- `timeout 30s python3 -m json.tool /home/gary/.codex/hooks.json >/dev/null`
  Expected: exits `0`; the hook config is valid JSON.
- `timeout 30s python3 -c 'import json; command=json.load(open("/home/gary/.codex/hooks.json"))["hooks"]["Stop"][0]["hooks"][0]["command"]; assert "/home/gary" not in command; assert command == "/bin/sh -c '"'"'exec /usr/bin/python3 \"$HOME/.codex/hooks/anti_lazy_stop.py\"'"'"'", command'`
  Expected: exits `0`; the configured command is exactly the approved `$HOME` wrapper and has no account-specific absolute path.
- `timeout 45s bash -lc 'tmp="$(mktemp -d)"; trap "rm -rf \"$tmp\"" EXIT; mkdir -p "$tmp/.codex"; cp -R /home/gary/.codex/hooks "$tmp/.codex/"; command="$(python3 -c '"'"'import json; print(json.load(open("/home/gary/.codex/hooks.json"))["hooks"]["Stop"][0]["hooks"][0]["command"])'"'"')"; printf "%s\n" "{\"hook_event_name\":\"Stop\",\"last_assistant_message\":\"Completed.\"}" | HOME="$tmp" bash -lc "$command"'`
  Expected: exits `0`; the configured hook command can execute with `HOME` pointing to a different per-user `.codex` directory.

**Completion report requirements:** Report changed files, verification commands run, command results, and any unresolved risks. Do not commit.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Task 1: Make hook command user-relative | `sp-impl` | FAST | `gpt-5.4-mini` | high | Narrow one-file JSON config change with concrete verification. |
| Plan document review | plan reviewer | BEST | `gpt-5.5` | high | Ensures file ownership, verification, and Simple Power execution rules are complete before implementation. |
| Quick verification | quick verifier | fixed | `gpt-5.3-codex-spark` | high | Required quick verifier model for checking coherence before the quick-verified implementation checkpoint. |
| Final review and fix | review+fix agent | BEST | `gpt-5.5` | high | Reviews the whole implementation against the accepted plan and can fix approved owned files before final verification. |

## Plan Review

**Self-review status:** Passed.

**Self-review checklist:**
- Design Summary: captures the approved per-user `~/.codex` design, `$HOME` shell wrapper decision, unchanged Python runtime path behavior, and success criteria.
- File ownership: assigns the only modified file, `/home/gary/.codex/hooks.json`, to exactly one task.
- Task allocation: maps the approved requirement to one complete implementation task.
- Model allocation: uses FAST for the narrow implementation task, BEST for plan review and final review+fix, and the required `gpt-5.3-codex-spark` high-effort quick verifier.
- Review allocation: includes one BEST-tier review+fix agent after quick verification.
- Commit policy: exactly three coordinator checkpoints are defined; no non-coordinator role commits.
- Verification: quick and final commands are concrete and use `timeout`.
- Approved path enforcement: the plan does not authorize unapproved route changes, skipped checks, or reduced deliverables.

**Plan reviewer dispatch:** Dispatch one BEST-tier plan reviewer with `model="gpt-5.5"` and `reasoning_effort="high"` using `skills/writing-plans/plan-document-reviewer-prompt.md`. Provide this saved plan path and the approved brainstorming design context: per-user `~/.codex` only; update `hooks.json` to use `/bin/sh -c 'exec /usr/bin/python3 "$HOME/.codex/hooks/anti_lazy_stop.py"'`; keep `anti_lazy_stop.py` unchanged because it already uses `Path.home()` for schema and log files; verify with JSON parsing, no `/home/gary` literal, and command execution under a temporary copied `.codex` layout.

## Quick Verification

The quick verifier runs after Task 1 completes and before the coordinator creates the quick-verified implementation checkpoint. The quick verifier must use `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

The quick verifier may fix only tiny typo-level errors discovered while running the quick checks. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

**Commands:**
- `timeout 30s python3 -m json.tool /home/gary/.codex/hooks.json >/dev/null`
  Expected: exits `0`; failure means the hook config is invalid JSON.
- `timeout 30s python3 -c 'import json; command=json.load(open("/home/gary/.codex/hooks.json"))["hooks"]["Stop"][0]["hooks"][0]["command"]; assert "/home/gary" not in command; assert command == "/bin/sh -c '"'"'exec /usr/bin/python3 \"$HOME/.codex/hooks/anti_lazy_stop.py\"'"'"'", command'`
  Expected: exits `0`; failure means the command is not the approved portable wrapper.
- `timeout 45s bash -lc 'tmp="$(mktemp -d)"; trap "rm -rf \"$tmp\"" EXIT; mkdir -p "$tmp/.codex"; cp -R /home/gary/.codex/hooks "$tmp/.codex/"; command="$(python3 -c '"'"'import json; print(json.load(open("/home/gary/.codex/hooks.json"))["hooks"]["Stop"][0]["hooks"][0]["command"])'"'"')"; printf "%s\n" "{\"hook_event_name\":\"Stop\",\"last_assistant_message\":\"Completed.\"}" | HOME="$tmp" bash -lc "$command"'`
  Expected: exits `0`; failure means the command cannot execute when `HOME` points at another per-user `.codex` layout.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one BEST-tier review+fix agent with `model="gpt-5.5"` and `reasoning_effort="high"`. That agent reviews and fixes the whole implementation against the accepted plan, file ownership, approved path enforcement, and verification requirements.

The review+fix agent may edit `/home/gary/.codex/hooks.json` when fixing issues it finds. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval. It must not commit.

## Commit Checkpoints

1. Accepted plan checkpoint: after the user approves the reviewed plan and model/task allocation.
2. Quick-verified implementation checkpoint: after Task 1 completes and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

## Context-Size Handoff

The saved plan is the handoff artifact. Do not write a project-local implementation handoff JSON artifact.

Before implementation handoff, compute the saved plan size:

```bash
wc -c "/home/gary/.codex/simplepower/docs/simplepower/plans/2026-05-07-per-user-anti-lazy-hook-path.md"
```

If the byte count is greater than `35840`, recommend fresh context. If it is `35840` or less, recommend continuing in the current session. The comparison is strict greater-than `35840`.

Current-session handoff command:

```text
Use `simplepower:subagent-driven-development` to execute `/home/gary/.codex/simplepower/docs/simplepower/plans/2026-05-07-per-user-anti-lazy-hook-path.md` with plan-first parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

Fresh-context handoff command:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `/home/gary/.codex/simplepower/docs/simplepower/plans/2026-05-07-per-user-anti-lazy-hook-path.md` with plan-first parallel implementation. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

Tell the user to run `/clear` manually before sending the fresh-context command.

## Verification

Run final verification after the BEST-tier review+fix agent completes and before the final checkpoint.

**Commands:**
- `timeout 30s python3 -m json.tool /home/gary/.codex/hooks.json >/dev/null`
  Expected: exits `0`; failure means the final hook config is invalid JSON.
- `timeout 30s python3 -c 'import json; command=json.load(open("/home/gary/.codex/hooks.json"))["hooks"]["Stop"][0]["hooks"][0]["command"]; assert "/home/gary" not in command; assert command == "/bin/sh -c '"'"'exec /usr/bin/python3 \"$HOME/.codex/hooks/anti_lazy_stop.py\"'"'"'", command'`
  Expected: exits `0`; failure means the final command is not the approved portable wrapper.
- `timeout 45s bash -lc 'tmp="$(mktemp -d)"; trap "rm -rf \"$tmp\"" EXIT; mkdir -p "$tmp/.codex"; cp -R /home/gary/.codex/hooks "$tmp/.codex/"; command="$(python3 -c '"'"'import json; print(json.load(open("/home/gary/.codex/hooks.json"))["hooks"]["Stop"][0]["hooks"][0]["command"])'"'"')"; printf "%s\n" "{\"hook_event_name\":\"Stop\",\"last_assistant_message\":\"Completed.\"}" | HOME="$tmp" bash -lc "$command"'`
  Expected: exits `0`; failure means the final command cannot execute when `HOME` points at another per-user `.codex` layout.
- `timeout 30s git -C /home/gary/.codex diff --check -- hooks.json`
  Expected: exits `0`; failure means the final diff has whitespace errors.
- `timeout 30s git -C /home/gary/.codex/simplepower diff --check -- docs/simplepower/plans/2026-05-07-per-user-anti-lazy-hook-path.md`
  Expected: exits `0`; failure means the plan diff has whitespace errors.

The coordinator performs the final checkpoint only after the BEST-tier review+fix agent has completed and all final verification commands pass.
