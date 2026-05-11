#!/usr/bin/env bash
# Fixture check that replaces the old multi-turn interaction.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Multi-Turn Explicit Skill Request Fixture Check ==="
exec "$SCRIPT_DIR/run-test.sh" "subagent-driven-development" "$SCRIPT_DIR/prompts/mid-conversation-execute-plan.txt"
