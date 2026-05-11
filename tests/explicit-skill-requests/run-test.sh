#!/usr/bin/env bash
# Fixture check for explicit skill request prompts.
# Usage: ./run-test.sh <skill-name> <prompt-file>

set -euo pipefail

SKILL_NAME="${1:-}"
PROMPT_FILE="${2:-}"

if [[ -z "$SKILL_NAME" || -z "$PROMPT_FILE" ]]; then
    echo "Usage: $0 <skill-name> <prompt-file>"
    echo "Example: $0 subagent-driven-development ./prompts/subagent-driven-development-please.txt"
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

echo "=== Explicit Skill Request Fixture Check ==="
echo "Skill: $SKILL_NAME"
echo "Prompt file: $PROMPT_FILE"
echo ""

case "$basename" in
    subagent-driven-development-please.txt)
        require_contains "simplepower:subagent-driven-development, please" "prompt requests the Simple Power plan-first implementation skill"
        ;;
    use-systematic-debugging.txt)
        require_contains "simplepower:systematic-debugging" "prompt requests the Simple Power debugging skill"
        ;;
    please-use-brainstorming.txt)
        require_contains "simplepower:brainstorming" "prompt requests the Simple Power brainstorming skill"
        ;;
    mid-conversation-execute-plan.txt)
        require_contains "docs/simplepower/plans/auth-system.md" "prompt points at the Simple Power plan path"
        require_contains "simplepower:subagent-driven-development, please" "prompt requests the Simple Power plan-first implementation skill"
        ;;
    i-know-what-sdd-means.txt)
        require_contains "docs/simplepower/plans/auth-system.md" "prompt points at the Simple Power plan path"
        require_contains "simplepower:subagent-driven-development" "prompt names the Simple Power plan-first implementation skill"
        ;;
    action-oriented.txt)
        require_contains "docs/simplepower/plans/auth-system.md" "prompt points at the Simple Power plan path"
        require_contains "simplepower:subagent-driven-development" "prompt names the Simple Power plan-first implementation skill"
        ;;
    skip-formalities.txt)
        require_contains "docs/simplepower/plans/auth-system.md" "prompt points at the Simple Power plan path"
        require_contains "simplepower:subagent-driven-development, please" "prompt requests the Simple Power plan-first implementation skill"
        ;;
    after-planning-flow.txt)
        require_contains "docs/simplepower/plans/auth-system.md" "prompt points at the Simple Power plan path"
        require_contains "simplepower:subagent-driven-development, please" "prompt requests the Simple Power plan-first implementation skill"
        ;;
    codex-suggested-it.txt)
        require_contains "docs/simplepower/plans/auth-system.md" "prompt points at the Simple Power plan path"
        require_contains "simplepower:subagent-driven-development, please" "prompt requests the Simple Power plan-first implementation skill"
        ;;
    *)
        fail "unknown prompt fixture: $basename"
        ;;
esac

if [[ "$failures" -eq 0 ]]; then
    echo ""
    echo "PASS: prompt fixture is ready for $SKILL_NAME"
else
    echo ""
    echo "FAIL: prompt fixture check failed"
    exit 1
fi
