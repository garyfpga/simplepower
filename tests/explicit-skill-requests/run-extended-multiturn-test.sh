#!/usr/bin/env bash
# Fixture check that replaces the old extended conversation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Extended Multi-Turn Fixture Check ==="
exec "$SCRIPT_DIR/run-test.sh" "subagent-driven-development" "$SCRIPT_DIR/prompts/skip-formalities.txt"
