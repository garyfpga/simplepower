#!/usr/bin/env bash
# Fixture check for invocation contract prompts.
# Usage: ./run-test.sh <fixture-name> <prompt-file>

set -euo pipefail

FIXTURE_NAME="${1:-}"
PROMPT_FILE="${2:-}"

if [[ -z "$FIXTURE_NAME" || -z "$PROMPT_FILE" ]]; then
    echo "Usage: $0 <fixture-name> <prompt-file>"
    echo "Example: $0 ordinary-feature-request ./prompts/ordinary-feature-request.txt"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [[ "$PROMPT_FILE" = /* ]]; then
    PROMPT_PATH="$PROMPT_FILE"
else
    PROMPT_PATH="$REPO_ROOT/$PROMPT_FILE"
fi

if [[ ! -f "$PROMPT_PATH" ]]; then
    echo "FAIL: missing prompt file $PROMPT_FILE"
    exit 1
fi

content="$(cat "$PROMPT_PATH")"
basename="$(basename "$PROMPT_FILE")"
failures=0

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    failures=$((failures + 1))
}

require_contains() {
    local needle="$1"
    local description="$2"
    if grep -Fq -- "$needle" <<<"$content"; then
        pass "$description"
    else
        fail "$description"
        echo "    expected to find: $needle"
    fi
}

require_not_contains() {
    local needle="$1"
    local description="$2"
    if grep -Fq -- "$needle" <<<"$content"; then
        fail "$description"
        echo "    unexpected match: $needle"
    else
        pass "$description"
    fi
}

echo "=== Invocation Contract Fixture Check ==="
echo "Fixture: $FIXTURE_NAME"
echo "Prompt file: $PROMPT_FILE"
echo ""

case "$basename" in
    ordinary-feature-request.txt)
        require_not_contains "simplepower:" "ordinary feature request does not explicitly request a Simple Power skill"
        ;;
    ordinary-bug-report.txt)
        require_not_contains "simplepower:" "ordinary bug report does not explicitly request a Simple Power skill"
        ;;
    ordinary-plan-request.txt)
        require_not_contains "simplepower:" "ordinary plan request does not explicitly request a Simple Power skill"
        ;;
    approved-brainstorming-handoff.txt)
        require_contains "simplepower:writing-plans" "approved brainstorming handoff names the planning skill"
        ;;
    approved-planning-handoff.txt)
        require_contains "simplepower:subagent-driven-development" "approved planning handoff names the plan-first implementation skill"
        ;;
    *)
        fail "unknown invocation contract fixture: $basename"
        ;;
esac

if [[ "$failures" -eq 0 ]]; then
    echo ""
    echo "PASS: prompt fixture is ready for $FIXTURE_NAME"
else
    echo ""
    echo "FAIL: prompt fixture check failed"
    exit 1
fi
