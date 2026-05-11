#!/usr/bin/env bash
# Run all explicit skill request fixture checks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

echo "=== Running all simplepower explicit skill request fixture checks ==="
echo ""

passed=0
failed=0

tests=(
    "subagent-driven-development|$PROMPTS_DIR/subagent-driven-development-please.txt"
    "systematic-debugging|$PROMPTS_DIR/use-systematic-debugging.txt"
    "brainstorming|$PROMPTS_DIR/please-use-brainstorming.txt"
    "subagent-driven-development|$PROMPTS_DIR/mid-conversation-execute-plan.txt"
    "subagent-driven-development|$PROMPTS_DIR/i-know-what-sdd-means.txt"
    "subagent-driven-development|$PROMPTS_DIR/action-oriented.txt"
    "subagent-driven-development|$PROMPTS_DIR/skip-formalities.txt"
    "subagent-driven-development|$PROMPTS_DIR/after-planning-flow.txt"
    "subagent-driven-development|$PROMPTS_DIR/codex-suggested-it.txt"
)

for test_case in "${tests[@]}"; do
    skill="${test_case%%|*}"
    prompt_file="${test_case#*|}"
    prompt_name="$(basename "$prompt_file")"

    echo "Checking: $prompt_name"
    if "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    echo ""
done

echo "=== Summary ==="
echo "Passed: $passed"
echo "Failed: $failed"

if [[ "$failed" -gt 0 ]]; then
    exit 1
fi
