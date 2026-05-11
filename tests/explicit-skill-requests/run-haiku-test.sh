#!/usr/bin/env bash
# Fixture check that replaces the old Haiku-based session.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Haiku Fixture Check ==="
exec "$SCRIPT_DIR/run-test.sh" "brainstorming" "$SCRIPT_DIR/prompts/please-use-brainstorming.txt"
