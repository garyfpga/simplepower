#!/usr/bin/env bash
# Run all invocation contract fixture checks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

tests=(
    "ordinary-feature-request|$PROMPTS_DIR/ordinary-feature-request.txt"
    "ordinary-bug-report|$PROMPTS_DIR/ordinary-bug-report.txt"
    "ordinary-plan-request|$PROMPTS_DIR/ordinary-plan-request.txt"
    "approved-brainstorming-handoff|$PROMPTS_DIR/approved-brainstorming-handoff.txt"
    "approved-planning-handoff|$PROMPTS_DIR/approved-planning-handoff.txt"
)

passed=0
failed=0

echo "=== Running simplepower invocation contract fixture checks ==="
echo ""

for test_case in "${tests[@]}"; do
    test_name="${test_case%%|*}"
    prompt_file="${test_case#*|}"

    if [[ ! -f "$prompt_file" ]]; then
        echo "  [FAIL] $test_name (missing prompt file)"
        failed=$((failed + 1))
        continue
    fi

    echo "Checking: $test_name"
    if "$SCRIPT_DIR/run-test.sh" "$test_name" "$prompt_file"; then
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
