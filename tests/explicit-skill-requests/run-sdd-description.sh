#!/usr/bin/env bash
# Fixture check that replaces the old SDD-description scenario.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Describe SDD Fixture Check ==="
exec "$SCRIPT_DIR/run-test.sh" "subagent-driven-development" "$SCRIPT_DIR/prompts/codex-suggested-it.txt"
