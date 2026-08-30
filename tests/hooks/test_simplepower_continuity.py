#!/usr/bin/env python3

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
HANDLER = REPO_ROOT / "hooks" / "simplepower_continuity.py"
SESSION_ID = "thr/test session/../unsafe"


class ContinuityHookTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        (self.repo / ".git").mkdir()
        self.plans = self.repo / "docs" / "simplepower" / "plans"
        self.plans.mkdir(parents=True)
        self.codex_home = self.root / "codex-home"
        self.plugin_data = self.root / "plugin-data"

    def tearDown(self):
        self.tempdir.cleanup()

    def event(self, name, **fields):
        event = {
            "session_id": SESSION_ID,
            "transcript_path": str(self.root / "must-not-be-read.jsonl"),
            "cwd": str(self.repo),
            "hook_event_name": name,
            "model": "test-model",
        }
        event.update(fields)
        return event

    def run_hook(self, event, *, plugin=True):
        env = os.environ.copy()
        env["CODEX_HOME"] = str(self.codex_home)
        if plugin:
            env["PLUGIN_DATA"] = str(self.plugin_data)
        else:
            env.pop("PLUGIN_DATA", None)
        return subprocess.run(
            [sys.executable, str(HANDLER)],
            input=json.dumps(event),
            text=True,
            capture_output=True,
            env=env,
            timeout=5,
            check=False,
        )

    def state_path(self, *, plugin=True):
        digest = hashlib.sha256(SESSION_ID.encode("utf-8")).hexdigest()
        base = self.plugin_data if plugin else self.codex_home / "simplepower-data"
        return base / "continuity" / f"{digest}.json"

    def write_plan(self, name="active.md", *, phase="implementation"):
        plan = self.plans / name
        if phase == "brainstorming":
            content = """# Feature Design

Goal: Test the feature.

Grouped Workers Consent: Not requested

## Brainstorming Continuity

- Decisions: The design is still being developed.
"""
        else:
            content = """# Feature Implementation Plan

Goal: Test the feature.

## Design Summary

Implement the approved behavior.

## Implementation Route

Implementation Route: Main agent

Grouped Workers Consent: Not requested

## Implementation Steps

1. Implement it.

## Implementation Continuity

- Completed work: Contract accepted.
- Next action: Implement it.

## Execution Record

Record results here.
"""
        plan.write_text(content, encoding="utf-8")
        return plan

    def registration_event(self, *paths, response=None):
        headers = "\n".join(f"*** Update File: {path}" for path in paths)
        return self.event(
            "PostToolUse",
            turn_id="turn-1",
            tool_name="apply_patch",
            tool_use_id="tool-1",
            tool_input={"command": f"*** Begin Patch\n{headers}\n*** End Patch"},
            tool_response={"output": "Success"} if response is None else response,
        )

    def register(self, plan, *, plugin=True):
        result = self.run_hook(
            self.registration_event(plan.relative_to(self.repo)), plugin=plugin
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        return self.state_path(plugin=plugin)

    def read_state(self, *, plugin=True):
        return json.loads(self.state_path(plugin=plugin).read_text(encoding="utf-8"))

    def test_unregistered_and_unrelated_events_are_noops(self):
        unrelated = self.repo / "README.md"
        unrelated.write_text("test\n", encoding="utf-8")
        post = self.run_hook(self.registration_event("README.md"))
        pre = self.run_hook(
            self.event("PreCompact", turn_id="turn-2", trigger="auto")
        )
        start = self.run_hook(self.event("SessionStart", source="compact"))

        self.assertEqual((post.returncode, post.stdout), (0, ""))
        self.assertEqual((pre.returncode, pre.stdout), (0, ""))
        self.assertEqual((start.returncode, start.stdout), (0, ""))
        self.assertFalse(self.plugin_data.exists())

    def test_plugin_registration_writes_metadata_atomically(self):
        plan = self.write_plan()
        state_path = self.register(plan)
        state = self.read_state()

        self.assertEqual(state["schema_version"], 1)
        self.assertEqual(state["session_id"], SESSION_ID)
        self.assertEqual(state["repo_root"], str(self.repo.resolve()))
        self.assertEqual(state["plan_path"], str(plan.resolve()))
        self.assertEqual(state["phase"], "implementation")
        self.assertEqual(state["recovery_status"], "ready")
        self.assertEqual(
            state["plan_sha256"], hashlib.sha256(plan.read_bytes()).hexdigest()
        )
        self.assertEqual(state_path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(state_path.parent.glob("*.tmp")), [])
        self.assertNotIn(SESSION_ID, state_path.name)

    def test_symlink_mode_uses_codex_home_data_root(self):
        plan = self.write_plan()
        user_state = self.register(plan, plugin=False)

        self.assertTrue(user_state.is_file())
        self.assertFalse(self.plugin_data.exists())

    def test_explicit_tool_error_does_not_register(self):
        plan = self.write_plan()
        result = self.run_hook(
            self.registration_event(
                plan.relative_to(self.repo), response={"isError": True, "message": "no"}
            )
        )

        self.assertEqual((result.returncode, result.stdout), (0, ""))
        self.assertFalse(self.state_path().exists())

    def test_ambiguous_plan_candidates_fail_closed_without_guessing(self):
        first = self.write_plan("first.md")
        second = self.write_plan("second.md")
        result = self.run_hook(
            self.registration_event(
                first.relative_to(self.repo), second.relative_to(self.repo)
            )
        )

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("multiple", output["stopReason"].lower())
        self.assertFalse(self.state_path().exists())

    def test_plan_like_path_escape_fails_closed(self):
        escaped = self.repo / "docs" / "evil.md"
        escaped.write_text("# not a plan\n", encoding="utf-8")
        result = self.run_hook(
            self.registration_event("docs/simplepower/plans/../../evil.md")
        )

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("outside", output["stopReason"].lower())

    def test_symlink_plan_is_rejected(self):
        target = self.repo / "real.md"
        target.write_text("# target\n", encoding="utf-8")
        link = self.plans / "linked.md"
        link.symlink_to(target)
        result = self.run_hook(self.registration_event(link.relative_to(self.repo)))

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("symlink", output["stopReason"].lower())

    def test_symlinked_plan_directory_escape_is_rejected(self):
        self.plans.rmdir()
        outside = self.root / "outside-plans"
        outside.mkdir()
        self.plans.symlink_to(outside, target_is_directory=True)
        plan = self.write_plan()
        result = self.run_hook(self.registration_event(plan.relative_to(self.repo)))

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("symlink escape", output["stopReason"].lower())

    def test_valid_precompact_allows_compaction(self):
        plan = self.write_plan()
        self.register(plan)
        result = self.run_hook(
            self.event("PreCompact", turn_id="turn-2", trigger="manual")
        )

        self.assertEqual((result.returncode, result.stdout), (0, ""))

    def test_corrupt_registered_state_blocks_precompact(self):
        state_path = self.state_path()
        state_path.parent.mkdir(parents=True)
        state_path.write_text("not json\n", encoding="utf-8")
        result = self.run_hook(
            self.event("PreCompact", turn_id="turn-2", trigger="auto")
        )

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("state", output["stopReason"].lower())

    def test_broken_state_symlink_blocks_precompact(self):
        state_path = self.state_path()
        state_path.parent.mkdir(parents=True)
        state_path.symlink_to(self.root / "missing-state.json")
        result = self.run_hook(
            self.event("PreCompact", turn_id="turn-2", trigger="auto")
        )

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("state is a symlink", output["stopReason"].lower())

    def test_schema_and_session_mismatches_block_precompact(self):
        plan = self.write_plan()
        self.register(plan)
        for key, value in (("schema_version", 99), ("session_id", "different")):
            state = self.read_state()
            state[key] = value
            self.state_path().write_text(json.dumps(state), encoding="utf-8")
            result = self.run_hook(
                self.event("PreCompact", turn_id="turn-2", trigger="auto")
            )
            output = json.loads(result.stdout)
            self.assertFalse(output["continue"])
            self.assertIn(key.replace("_", " "), output["stopReason"].lower())
            self.register(plan)

    def test_unexpected_state_field_blocks_precompact(self):
        plan = self.write_plan()
        self.register(plan)
        state = self.read_state()
        state["transcript_path"] = str(self.root / "must-not-be-read.jsonl")
        self.state_path().write_text(json.dumps(state), encoding="utf-8")
        result = self.run_hook(
            self.event("PreCompact", turn_id="turn-2", trigger="auto")
        )

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("unexpected field", output["stopReason"].lower())

    def test_missing_plan_and_hash_mismatch_block_precompact(self):
        plan = self.write_plan()
        self.register(plan)
        plan.write_text(plan.read_text(encoding="utf-8") + "\nchanged\n", encoding="utf-8")
        changed = self.run_hook(
            self.event("PreCompact", turn_id="turn-2", trigger="auto")
        )
        self.assertIn("hash", json.loads(changed.stdout)["stopReason"].lower())

        self.register(plan)
        plan.unlink()
        missing = self.run_hook(
            self.event("PreCompact", turn_id="turn-3", trigger="auto")
        )
        self.assertIn("missing", json.loads(missing.stdout)["stopReason"].lower())

    def test_postcompact_marks_recovery_pending(self):
        plan = self.write_plan()
        self.register(plan)
        result = self.run_hook(
            self.event("PostCompact", turn_id="turn-2", trigger="auto")
        )

        self.assertEqual((result.returncode, result.stdout), (0, ""))
        self.assertEqual(self.read_state()["recovery_status"], "pending")

    def test_invalid_postcompact_state_stops_after_compaction(self):
        plan = self.write_plan()
        self.register(plan)
        plan.write_text(plan.read_text(encoding="utf-8") + "\nstale\n", encoding="utf-8")
        result = self.run_hook(
            self.event("PostCompact", turn_id="turn-2", trigger="auto")
        )

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("hash mismatch", output["stopReason"].lower())

    def test_compact_session_injects_exact_recovery_context_and_clears_pending(self):
        plan = self.write_plan()
        self.register(plan)
        self.run_hook(self.event("PostCompact", turn_id="turn-2", trigger="auto"))
        result = self.run_hook(self.event("SessionStart", source="compact"))

        output = json.loads(result.stdout)
        context = output["hookSpecificOutput"]["additionalContext"]
        self.assertEqual(
            output["hookSpecificOutput"]["hookEventName"], "SessionStart"
        )
        self.assertIn(str(plan.resolve()), context)
        self.assertIn("## Implementation Continuity", context)
        self.assertIn("before any further work", context)
        self.assertIn("Do not guess", context)
        self.assertEqual(self.read_state()["recovery_status"], "ready")

        repeated = self.run_hook(self.event("SessionStart", source="compact"))
        self.assertEqual((repeated.returncode, repeated.stdout), (0, ""))

    def test_noncompact_session_does_not_consume_pending_recovery(self):
        plan = self.write_plan()
        self.register(plan)
        self.run_hook(self.event("PostCompact", turn_id="turn-2", trigger="manual"))
        result = self.run_hook(self.event("SessionStart", source="resume"))

        self.assertEqual((result.returncode, result.stdout), (0, ""))
        self.assertEqual(self.read_state()["recovery_status"], "pending")

    def test_invalid_compact_session_stops_without_consuming_pending_recovery(self):
        plan = self.write_plan()
        self.register(plan)
        self.run_hook(self.event("PostCompact", turn_id="turn-2", trigger="auto"))
        plan.write_text(plan.read_text(encoding="utf-8") + "\nstale\n", encoding="utf-8")
        result = self.run_hook(self.event("SessionStart", source="compact"))

        output = json.loads(result.stdout)
        self.assertFalse(output["continue"])
        self.assertIn("hash mismatch", output["stopReason"].lower())
        self.assertEqual(self.read_state()["recovery_status"], "pending")

    def test_brainstorming_phase_is_registered_and_recovered(self):
        plan = self.write_plan(phase="brainstorming")
        self.register(plan)
        self.assertEqual(self.read_state()["phase"], "brainstorming")
        self.run_hook(self.event("PostCompact", turn_id="turn-2", trigger="auto"))
        result = self.run_hook(self.event("SessionStart", source="compact"))

        context = json.loads(result.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("## Brainstorming Continuity", context)


if __name__ == "__main__":
    unittest.main(verbosity=2)
