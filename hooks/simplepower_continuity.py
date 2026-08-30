#!/usr/bin/env python3
"""Metadata-only compaction continuity for Simple Power workflows."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
from typing import Any


SCHEMA_VERSION = 1
PLAN_PREFIX = "docs/simplepower/plans/"
PATCH_HEADER = re.compile(r"^\*\*\* (Add|Update|Delete) File: (.+)$")
PACKAGE_CONTINUITY = re.compile(r"^## (?:Package|Grouped Worker) .+ Continuity$", re.MULTILINE)
REQUIRED_STATE_FIELDS = {
    "schema_version",
    "session_id",
    "repo_root",
    "plan_path",
    "phase",
    "plan_sha256",
    "recovery_status",
}


class ContinuityError(Exception):
    """A registered workflow cannot safely proceed."""


def emit_stop(reason: str) -> None:
    print(
        json.dumps(
            {
                "continue": False,
                "stopReason": reason,
                "systemMessage": f"Simple Power continuity: {reason}",
            },
            separators=(",", ":"),
        )
    )


def require_string(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ContinuityError(f"missing or invalid {field.replace('_', ' ')}")
    return value


def data_root() -> Path:
    plugin_data = os.environ.get("PLUGIN_DATA", "").strip()
    if plugin_data:
        root = Path(plugin_data).expanduser()
    else:
        codex_home = os.environ.get("CODEX_HOME", "").strip()
        root = Path(codex_home).expanduser() if codex_home else Path.home() / ".codex"
        root = root / "simplepower-data"
    if not root.is_absolute():
        raise ContinuityError("continuity data root must be an absolute path")
    return root


def state_path(session_id: str) -> Path:
    digest = hashlib.sha256(session_id.encode("utf-8")).hexdigest()
    return data_root() / "continuity" / f"{digest}.json"


def atomic_write(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(
        dir=path.parent, prefix=f".{path.stem}.", suffix=".tmp"
    )
    temp_path = Path(temp_name)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, sort_keys=True, separators=(",", ":"))
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_path, path)
        try:
            directory_fd = os.open(path.parent, os.O_RDONLY)
            try:
                os.fsync(directory_fd)
            finally:
                os.close(directory_fd)
        except OSError:
            pass
    except BaseException:
        try:
            os.close(fd)
        except OSError:
            pass
        try:
            temp_path.unlink()
        except FileNotFoundError:
            pass
        raise


def find_repo_root(cwd_value: Any) -> Path:
    cwd = Path(require_string(cwd_value, "cwd")).expanduser()
    try:
        current = cwd.resolve(strict=True)
    except OSError as exc:
        raise ContinuityError(f"cwd is unreadable: {exc}") from exc
    if not current.is_dir():
        raise ContinuityError("cwd is not a directory")
    for candidate in (current, *current.parents):
        if (candidate / ".git").exists():
            return candidate
    raise ContinuityError("cwd is not inside a git repository")


def within(path: Path, directory: Path) -> bool:
    try:
        path.relative_to(directory)
        return True
    except ValueError:
        return False


def plan_directory(repo_root: Path) -> Path:
    current = repo_root
    for component in ("docs", "simplepower", "plans"):
        current = current / component
        if current.is_symlink():
            raise ContinuityError("docs/simplepower/plans contains a symlink escape")
    try:
        canonical = current.resolve(strict=True)
    except OSError as exc:
        raise ContinuityError(f"plan directory is missing or unreadable: {exc}") from exc
    if not canonical.is_dir() or not within(canonical, repo_root):
        raise ContinuityError("plan directory is outside the registered repository")
    return canonical


def phase_and_section(text: str) -> tuple[str, str]:
    if "## Brainstorming Continuity" in text:
        return "brainstorming", "## Brainstorming Continuity"
    if "## Implementation Continuity" in text:
        return "implementation", "## Implementation Continuity"
    if "## Design Summary" in text and "Implementation Route:" in text:
        if "## Execution Summary" in text:
            return "implementation", "## Execution Summary"
        if "## Implementation Steps" in text:
            return "implementation", "## Implementation Steps"
    package_sections = PACKAGE_CONTINUITY.findall(text)
    if len(package_sections) == 1:
        return "grouped-worker", package_sections[0]
    raise ContinuityError("plan lacks a recognized Simple Power phase marker")


def inspect_plan(path: Path, repo_root: Path) -> tuple[Path, str, str, str]:
    expected_dir = plan_directory(repo_root)
    if path.is_symlink():
        raise ContinuityError("plan path is a symlink")
    try:
        mode = path.stat().st_mode
    except FileNotFoundError as exc:
        raise ContinuityError("registered plan is missing") from exc
    except OSError as exc:
        raise ContinuityError(f"registered plan is unreadable: {exc}") from exc
    if not stat.S_ISREG(mode):
        raise ContinuityError("registered plan is not a regular file")
    try:
        canonical = path.resolve(strict=True)
    except OSError as exc:
        raise ContinuityError(f"registered plan is unreadable: {exc}") from exc
    if not within(canonical, expected_dir):
        raise ContinuityError("plan is outside docs/simplepower/plans")
    if canonical.suffix.lower() != ".md":
        raise ContinuityError("plan is not a Markdown file")
    try:
        content = canonical.read_bytes()
        text = content.decode("utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise ContinuityError(f"registered plan is unreadable: {exc}") from exc
    phase, section = phase_and_section(text)
    digest = hashlib.sha256(content).hexdigest()
    return canonical, phase, section, digest


def load_registered_state(session_id: str) -> tuple[Path, dict[str, Any]] | None:
    path = state_path(session_id)
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return None
    except OSError as exc:
        raise ContinuityError(f"registered state is unreadable: {exc}") from exc
    if stat.S_ISLNK(mode):
        raise ContinuityError("registered state is a symlink")
    if not stat.S_ISREG(mode):
        raise ContinuityError("registered state is not a regular file")
    try:
        with path.open(encoding="utf-8") as handle:
            value = json.load(handle)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ContinuityError(f"registered state is unreadable or corrupt: {exc}") from exc
    if not isinstance(value, dict):
        raise ContinuityError("registered state is not a JSON object")
    missing = REQUIRED_STATE_FIELDS - value.keys()
    if missing:
        raise ContinuityError(
            f"registered state is missing field: {sorted(missing)[0].replace('_', ' ')}"
        )
    unexpected = value.keys() - REQUIRED_STATE_FIELDS
    if unexpected:
        raise ContinuityError(
            "registered state has unexpected field: "
            f"{sorted(unexpected)[0].replace('_', ' ')}"
        )
    if value.get("schema_version") != SCHEMA_VERSION:
        raise ContinuityError("registered state schema version mismatch")
    if value.get("session_id") != session_id:
        raise ContinuityError("registered state session id mismatch")
    for field in ("repo_root", "plan_path", "phase", "plan_sha256", "recovery_status"):
        require_string(value.get(field), field)
    if value["phase"] not in {"brainstorming", "implementation", "grouped-worker"}:
        raise ContinuityError("registered state phase is invalid")
    if value["recovery_status"] not in {"ready", "pending"}:
        raise ContinuityError("registered state recovery status is invalid")
    return path, value


def validate_state(session_id: str) -> tuple[Path, dict[str, Any], str] | None:
    loaded = load_registered_state(session_id)
    if loaded is None:
        return None
    state_file, state = loaded
    repo_value = Path(state["repo_root"])
    if not repo_value.is_absolute():
        raise ContinuityError("registered repository root is not absolute")
    try:
        repo_root = repo_value.resolve(strict=True)
    except OSError as exc:
        raise ContinuityError(f"registered repository root is unreadable: {exc}") from exc
    if str(repo_root) != state["repo_root"]:
        raise ContinuityError("registered repository root is not canonical")
    if not (repo_root / ".git").exists():
        raise ContinuityError("registered repository root is missing its git metadata")
    plan_value = Path(state["plan_path"])
    if not plan_value.is_absolute():
        raise ContinuityError("registered plan path is not absolute")
    canonical, phase, section, digest = inspect_plan(plan_value, repo_root)
    if str(canonical) != state["plan_path"]:
        raise ContinuityError("registered plan path is not canonical")
    if phase != state["phase"]:
        raise ContinuityError("registered plan phase mismatch")
    if digest != state["plan_sha256"]:
        raise ContinuityError(
            "registered plan hash mismatch; refresh it with a successful apply_patch"
        )
    return state_file, state, section


def response_failed(response: Any) -> bool:
    if response is None:
        return True
    if isinstance(response, dict):
        return bool(
            response.get("isError")
            or response.get("is_error")
            or response.get("error")
        )
    if isinstance(response, str):
        lowered = response.strip().lower()
        return lowered.startswith("error") or any(
            marker in lowered
            for marker in ("apply_patch verification failed", "script failed")
        )
    return False


def patch_plan_candidates(command: str, repo_root: Path, cwd: Path) -> list[Path]:
    raw_candidates: list[str] = []
    for line in command.splitlines():
        match = PATCH_HEADER.match(line)
        if match and match.group(1) in {"Add", "Update"}:
            raw = match.group(2).strip()
            normalized = raw.replace("\\", "/")
            if PLAN_PREFIX in normalized.lstrip("./"):
                raw_candidates.append(raw)
    if not raw_candidates:
        return []

    expected_dir = plan_directory(repo_root)
    candidates: list[Path] = []
    for raw in raw_candidates:
        candidate = Path(raw).expanduser()
        if not candidate.is_absolute():
            candidate = cwd / candidate
        if candidate.is_symlink():
            raise ContinuityError("plan path is a symlink")
        try:
            canonical = candidate.resolve(strict=True)
        except FileNotFoundError as exc:
            raise ContinuityError("patched plan is missing after apply_patch") from exc
        except OSError as exc:
            raise ContinuityError(f"patched plan is unreadable: {exc}") from exc
        if not within(canonical, expected_dir):
            raise ContinuityError("patched plan is outside docs/simplepower/plans")
        if canonical not in candidates:
            candidates.append(canonical)
    return candidates


def handle_post_tool_use(event: dict[str, Any], session_id: str) -> None:
    if event.get("tool_name") != "apply_patch":
        return
    tool_input = event.get("tool_input")
    if not isinstance(tool_input, dict) or not isinstance(tool_input.get("command"), str):
        raise ContinuityError("apply_patch hook input lacks tool_input.command")
    if response_failed(event.get("tool_response")):
        return
    repo_root = find_repo_root(event.get("cwd"))
    cwd = Path(require_string(event.get("cwd"), "cwd")).expanduser().resolve(strict=True)
    candidates = patch_plan_candidates(tool_input["command"], repo_root, cwd)
    if not candidates:
        return
    if len(candidates) != 1:
        raise ContinuityError("multiple Simple Power plan candidates; refusing to guess")
    canonical, phase, _section, digest = inspect_plan(candidates[0], repo_root)
    state = {
        "schema_version": SCHEMA_VERSION,
        "session_id": session_id,
        "repo_root": str(repo_root),
        "plan_path": str(canonical),
        "phase": phase,
        "plan_sha256": digest,
        "recovery_status": "ready",
    }
    atomic_write(state_path(session_id), state)


def handle_pre_compact(session_id: str) -> None:
    validate_state(session_id)


def handle_post_compact(session_id: str) -> None:
    validated = validate_state(session_id)
    if validated is None:
        return
    state_file, state, _section = validated
    state["recovery_status"] = "pending"
    atomic_write(state_file, state)


def handle_session_start(event: dict[str, Any], session_id: str) -> None:
    if event.get("source") != "compact":
        return
    validated = validate_state(session_id)
    if validated is None:
        return
    state_file, state, section = validated
    if state["recovery_status"] != "pending":
        return
    context = (
        "Simple Power compaction recovery is required before any further work. "
        f"Reread the authoritative plan at {state['plan_path']} and recover from "
        f"the exact {section} section. Revalidate the {state['phase']} phase, "
        "approved route, changed-file scope, blockers, and next action before "
        "asking a question, invoking a tool, editing, dispatching, verifying, or "
        "committing. Do not guess another plan or recover from transcript content."
    )
    state["recovery_status"] = "ready"
    atomic_write(state_file, state)
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": context,
                }
            },
            separators=(",", ":"),
        )
    )


def main() -> int:
    try:
        event = json.load(sys.stdin)
        if not isinstance(event, dict):
            raise ContinuityError("hook input is not a JSON object")
        event_name = require_string(event.get("hook_event_name"), "hook_event_name")
        session_id = require_string(event.get("session_id"), "session_id")
        if event_name == "PostToolUse":
            handle_post_tool_use(event, session_id)
        elif event_name == "PreCompact":
            handle_pre_compact(session_id)
        elif event_name == "PostCompact":
            handle_post_compact(session_id)
        elif event_name == "SessionStart":
            handle_session_start(event, session_id)
        return 0
    except (ContinuityError, OSError, json.JSONDecodeError) as exc:
        print(f"Simple Power continuity error: {exc}", file=sys.stderr)
        emit_stop(str(exc))
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
