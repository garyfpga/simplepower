#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

failures=0

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    failures=$((failures + 1))
}

require_file() {
    local path="$1"
    local description="$2"

    if [[ -f "$REPO_ROOT/$path" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    missing: $path"
    fi
}

require_executable() {
    local path="$1"
    local description="$2"

    if [[ -x "$REPO_ROOT/$path" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    not executable: $path"
    fi
}

require_dir_absent() {
    local path="$1"
    local description="$2"

    if [[ ! -e "$REPO_ROOT/$path" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    unexpected path: $path"
    fi
}

require_contains() {
    local path="$1"
    local needle="$2"
    local description="$3"

    if grep -Fq -- "$needle" "$REPO_ROOT/$path"; then
        pass "$description"
    else
        fail "$description"
        echo "    expected to find: $needle"
        echo "    in: $path"
    fi
}

require_not_contains() {
    local path="$1"
    local needle="$2"
    local description="$3"

    if grep -Fq -- "$needle" "$REPO_ROOT/$path"; then
        fail "$description"
        echo "    unexpected match: $needle"
        echo "    in: $path"
    else
        pass "$description"
    fi
}

require_regex_contains() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if grep -Eq -- "$pattern" "$REPO_ROOT/$path"; then
        pass "$description"
    else
        fail "$description"
        echo "    expected to match pattern: $pattern"
        echo "    in: $path"
    fi
}

require_no_active_match() {
    local pattern="$1"
    local description="$2"
    shift 2

    local matches
    matches="$(
        cd "$REPO_ROOT"
        rg -n -- "$pattern" "$@" || true
    )"

    if [[ -z "$matches" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "$matches" | sed 's/^/    /'
    fi
}

echo "=== Simple Power Static Checks ==="

require_executable "tests/simplepower-static/run-tests.sh" "static test runner is executable"

require_file "skills/using-simplepower/SKILL.md" "using-simplepower skill exists"
require_dir_absent "skills/using-superpowers" "using-superpowers skill directory is absent"

require_contains "README.md" "simplepower:*" "README uses the Simple Power namespace"
require_not_contains "README.md" "author =" "README does not include an author line"
require_not_contains "README.md" "Gary Chow" "README does not name a personal author"
require_contains "README.md" "Thanks to Jesse Vincent / Prime Radiant for the upstream project this fork is" "README credits the upstream project"
require_contains "README.md" "codex plugin marketplace add garyfpga/codex-plugins" "README documents the marketplace install command"
require_contains "README.md" "codex plugin marketplace upgrade" "README documents the marketplace update command"
require_contains "README.md" "SIMPLEPOWER_BEST_MODEL=\"gpt-5.5-high\"" "README documents the BEST model env var"
require_contains "README.md" "SIMPLEPOWER_FAST_MODEL=\"gpt-5.4-mini-high\"" "README documents the FAST model env var"
require_contains "README.md" "<model>-<reasoning_effort>" "README explains model tier parsing as <model>-<reasoning_effort>"
require_contains "README.md" "批准已审阅的 plan、模型分配，以及立刻在当前 session 里启动" "README documents combined approval and immediate current-session execution"
require_contains "README.md" "accepted plan checkpoint commit" "README documents the accepted plan checkpoint"
require_contains "README.md" "simplepower:subagent-driven-development" "README documents current-session auto-dispatch"
require_contains "README.md" "temporary localhost visual companion" "README distinguishes the brainstorming visual companion"
require_not_contains "README.md" "git clone https://github.com/garyfpga/simplepower.git ~/.codex/simplepower" "README does not document the manual clone install flow"
require_not_contains "README.md" "ln -s ~/.codex/simplepower/skills ~/.agents/skills/simplepower" "README does not document the manual symlink install flow"
require_not_contains "README.md" "checks the saved plan size and asks which" "README does not describe plan-size-primary handoff routing"
require_not_contains "README.md" "/clear" "README does not preserve the retired /clear handoff flow"
require_not_contains "README.md" "current Codex context usage" "README does not preserve context-usage routing"
require_not_contains "README.md" "saved plan size" "README does not preserve the saved plan-size fallback"
require_not_contains "README.md" "implementation handoff to use" "README does not preserve the handoff choice prompt"
require_not_contains "README.md" "both commands" "README does not preserve the dual-command handoff flow"
require_not_contains "README.md" "55%" "README does not preserve the 55 percent routing threshold"
require_not_contains "README.md" "current-session-context.md" "README does not preserve the retired context helper reference"

require_contains ".codex-plugin/plugin.json" '"version": "1.0.0"' "plugin manifest version is 1.0.0"
require_contains "package.json" '"version": "1.0.0"' "package.json version is 1.0.0"

require_contains "AGENTS.md" "simplepower:*" "AGENTS.md uses the Simple Power namespace"
require_contains "AGENTS.md" "docs/simplepower" "AGENTS.md points generated docs at docs/simplepower"

require_contains "docs/README.codex.md" "simplepower:*" "Codex install guide uses the Simple Power namespace"
require_contains "docs/README.codex.md" "sp-impl" "Codex install guide mentions sp-impl"
require_contains "docs/README.codex.md" "docs/simplepower" "Codex install guide points generated docs at docs/simplepower"
require_contains "docs/README.codex.md" "SIMPLEPOWER_BEST_MODEL=\"gpt-5.5-high\"" "Codex install guide documents the BEST model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_FAST_MODEL=\"gpt-5.4-mini-high\"" "Codex install guide documents the FAST model env var"
require_contains "docs/README.codex.md" "after combined approval in the current session" "Codex install guide documents combined approval in the current session"
require_contains "docs/README.codex.md" "simplepower:subagent-driven-development" "Codex install guide documents current-session auto-dispatch"
require_not_contains "docs/README.codex.md" "checks the saved plan size and asks which" "Codex install guide does not describe plan-size-primary handoff routing"
require_not_contains "docs/README.codex.md" "implementation-handoff-hook" "Codex install guide no longer documents the implementation handoff hook"
require_not_contains "docs/README.codex.md" ".simplepower/implementation-handoff.json" "Codex install guide no longer documents the handoff artifact"
require_not_contains "docs/README.codex.md" "/clear" "Codex install guide does not preserve the retired /clear handoff flow"
require_not_contains "docs/README.codex.md" "current Codex context usage" "Codex install guide does not preserve context-usage routing"
require_not_contains "docs/README.codex.md" "saved plan size" "Codex install guide does not preserve the saved plan-size fallback"
require_not_contains "docs/README.codex.md" "implementation handoff to use" "Codex install guide does not preserve the handoff choice prompt"
require_not_contains "docs/README.codex.md" "both commands" "Codex install guide does not preserve the dual-command handoff flow"
require_not_contains "docs/README.codex.md" "55%" "Codex install guide does not preserve the 55 percent routing threshold"
require_not_contains "docs/README.codex.md" "current-session-context.md" "Codex install guide does not preserve the retired context helper reference"

require_contains "docs/testing.md" "bash tests/simplepower-static/run-tests.sh" "testing docs cover the static test harness"
require_contains "docs/testing.md" "npm --prefix tests/brainstorm-server test" "testing docs cover brainstorm server tests"
require_contains "docs/testing.md" "bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" "testing docs cover Codex plugin sync tests"
require_contains "docs/testing.md" "simplepower:brainstorming" "testing docs mention the Codex smoke test skill trigger"
require_contains "docs/testing.md" "docs/simplepower" "testing docs point generated artifacts at docs/simplepower"
require_contains "docs/testing.md" "optional plan visual guidance" "testing docs cover optional plan visual guidance"
require_contains "docs/testing.md" "companion behavior" "testing docs cover brainstorming visual companion behavior"
require_contains "docs/testing.md" "marketplace metadata" "testing docs mention marketplace metadata coverage"

require_contains "skills/using-simplepower/SKILL.md" "simplepower:*" "using-simplepower skill uses the Simple Power namespace"
require_contains "skills/using-simplepower/SKILL.md" "docs/simplepower" "using-simplepower skill points generated docs at docs/simplepower"
require_not_contains "skills/using-simplepower/SKILL.md" "using-superpowers" "using-simplepower skill no longer references using-superpowers"
require_contains "skills/using-simplepower/SKILL.md" "Explicit user request required" "using-simplepower requires explicit invocation"
require_contains "skills/using-simplepower/SKILL.md" "authorized Simple Power chain handoff" "using-simplepower preserves approved chain handoffs"
require_contains "skills/using-simplepower/SKILL.md" "Do not invoke Simple Power skills from semantic task matching alone" "using-simplepower blocks semantic auto-triggering"

require_not_contains "skills/brainstorming/SKILL.md" "docs/simplepower/specs" "brainstorming no longer writes standalone specs"
require_not_contains "skills/brainstorming/SKILL.md" "User reviews written spec" "brainstorming no longer has a written spec review gate"
require_dir_absent "skills/brainstorming/spec-document-reviewer-prompt.md" "old brainstorming spec reviewer prompt is absent"
require_contains "skills/brainstorming/SKILL.md" "simplepower:writing-plans" "brainstorming still hands off to writing-plans"
require_contains "skills/brainstorming/visual-companion.md" ".simplepower/brainstorm" "visual companion uses the Simple Power brainstorming session path"
require_contains "skills/brainstorming/SKILL.md" "start the localhost server" "brainstorming visual companion starts a localhost server"
require_contains "skills/brainstorming/SKILL.md" "give the local URL" "brainstorming visual companion gives a local URL"
require_contains "skills/brainstorming/SKILL.md" "temporary brainstorming aids, not generated implementation plan artifacts" "brainstorming distinguishes temporary companion pages from plan artifacts"
require_contains "skills/brainstorming/SKILL.md" 'Optional inline visuals in saved Markdown plans belong to `simplepower:writing-plans`, not to brainstorming' "brainstorming distinguishes saved Markdown plan visuals"
require_contains "skills/brainstorming/visual-companion.md" "temporary localhost aid for brainstorming" "visual companion guide documents localhost behavior"
require_contains "skills/brainstorming/visual-companion.md" "distinct from optional inline visuals in saved Markdown implementation plans" "visual companion guide distinguishes saved Markdown plan visuals"
require_contains "skills/brainstorming/scripts/start-server.sh" ".simplepower/brainstorm" "brainstorm server startup script uses the Simple Power session path"
require_contains "skills/brainstorming/scripts/frame-template.html" "Simple Power Brainstorming" "brainstorm frame shows Simple Power branding"

require_contains "skills/writing-plans/SKILL.md" "File Ownership" "writing-plans requires File Ownership"
require_contains "skills/writing-plans/SKILL.md" "Implementation Tasks" "writing-plans requires Implementation Tasks"
require_contains "skills/writing-plans/SKILL.md" "Plan Review" "writing-plans requires Plan Review"
require_contains "skills/writing-plans/SKILL.md" "Quick Verification" "writing-plans requires Quick Verification"
require_contains "skills/writing-plans/SKILL.md" "Final Review And Fix" "writing-plans requires Final Review And Fix"
require_contains "skills/writing-plans/SKILL.md" "Commit Checkpoints" "writing-plans requires Commit Checkpoints"
require_contains "skills/writing-plans/SKILL.md" "Verification" "writing-plans requires Verification"
require_contains "skills/writing-plans/SKILL.md" "Model Allocation" "writing-plans requires model allocation sections"
require_contains "skills/writing-plans/SKILL.md" "Design Summary" "writing-plans requires Design Summary"
require_contains "skills/writing-plans/SKILL.md" "Interface Contract" "writing-plans requires Interface Contract"
require_contains "skills/writing-plans/SKILL.md" "Contract inputs" "writing-plans requires Contract inputs"
require_contains "skills/writing-plans/SKILL.md" "Serialization required" "writing-plans requires Serialization required"
require_contains "skills/writing-plans/SKILL.md" "aggregate parallel dispatch" "writing-plans requires aggregate parallel dispatch"
require_contains "skills/writing-plans/SKILL.md" "docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md" "writing-plans keeps Markdown plan format under docs/simplepower/plans"
require_contains "skills/writing-plans/SKILL.md" "## Visual Aids" "writing-plans documents optional Visual Aids guidance"
require_contains "skills/writing-plans/SKILL.md" "reduce ambiguity" "writing-plans keeps Visual Aids optional"
require_contains "skills/writing-plans/SKILL.md" "workflow flowcharts" "writing-plans names workflow flowchart visual aid cases"
require_contains "skills/writing-plans/SKILL.md" "architecture or data-flow" "writing-plans names architecture or data-flow visual aid cases"
require_contains "skills/writing-plans/SKILL.md" "task ownership matrices" "writing-plans names task ownership matrix visual aid cases"
require_contains "skills/writing-plans/SKILL.md" "state or error-path diagrams" "writing-plans names state or error-path visual aid cases"
require_dir_absent "skills/writing-plans/current-session-context.md" "writing-plans current session context helper is absent"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_BEST_MODEL" "writing-plans documents the BEST model env var"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_FAST_MODEL" "writing-plans documents the FAST model env var"
require_contains "skills/writing-plans/SKILL.md" "BEST-tier plan reviewer" "writing-plans dispatches a BEST-tier plan reviewer"
require_contains "skills/writing-plans/SKILL.md" "aggregate parallel implementation" "writing-plans emits aggregate implementation handoff"
require_contains "skills/writing-plans/SKILL.md" "gpt-5.3-codex-spark" "writing-plans pins gpt-5.3-codex-spark"
require_contains "skills/writing-plans/SKILL.md" "review+fix" "writing-plans uses review+fix"
require_contains "skills/writing-plans/SKILL.md" "current-session auto-dispatch" "writing-plans documents current-session auto-dispatch"
require_contains "skills/writing-plans/SKILL.md" "combined approval" "writing-plans documents combined approval"
require_contains "skills/writing-plans/SKILL.md" "accepted plan checkpoint commit" "writing-plans documents the accepted plan checkpoint"
require_contains "skills/writing-plans/SKILL.md" "send the revised plan back to the same reviewer" "writing-plans documents the reusable reviewer loop"
require_contains "skills/writing-plans/SKILL.md" 'immediately invokes `simplepower:subagent-driven-development`' "writing-plans documents immediate invocation after approval"
require_contains "skills/writing-plans/SKILL.md" "docs/simplepower/plans" "writing-plans writes plans under docs/simplepower/plans"
require_contains "skills/writing-plans/SKILL.md" "Workers, plan reviewers, quick verifiers, and review+fix agents must not commit" "writing-plans forbids non-coordinator commits"
require_not_contains "skills/writing-plans/SKILL.md" ".simplepower/implementation-handoff.json" "writing-plans no longer names the implementation handoff artifact"
require_not_contains "skills/writing-plans/SKILL.md" "implementation-handoff-hook" "writing-plans no longer references the handoff hook script"
require_not_contains "skills/writing-plans/SKILL.md" "hookSpecificOutput.additionalContext" "writing-plans no longer documents hook context injection"
require_not_contains "skills/writing-plans/SKILL.md" "Context-Size Handoff" "writing-plans no longer documents context-size handoff"
require_not_contains "skills/writing-plans/SKILL.md" "current-session-context.md" "writing-plans no longer references the retired context helper"
require_not_contains "skills/writing-plans/SKILL.md" "current Codex context usage" "writing-plans no longer documents context-usage routing"
require_not_contains "skills/writing-plans/SKILL.md" "saved plan size" "writing-plans no longer documents the saved plan-size fallback"
require_not_contains "skills/writing-plans/SKILL.md" "55%" "writing-plans no longer documents the 55 percent routing threshold"
require_not_contains "skills/writing-plans/SKILL.md" "35840" "writing-plans no longer documents the saved plan-size threshold"
require_not_contains "skills/writing-plans/SKILL.md" 'wc -c "$PLAN_PATH"' "writing-plans no longer documents the saved plan-size command"
require_not_contains "skills/writing-plans/SKILL.md" "show both commands" "writing-plans no longer documents the dual-command handoff flow"
require_not_contains "skills/writing-plans/SKILL.md" "handoff choice" "writing-plans no longer documents the handoff choice prompt"
require_not_contains "skills/writing-plans/SKILL.md" "which implementation handoff to use" "writing-plans no longer asks which implementation handoff to use"
require_not_contains "skills/writing-plans/SKILL.md" "/clear" "writing-plans no longer documents the retired /clear handoff flow"
require_contains "skills/writing-plans/SKILL.md" "simplepower:subagent-driven-development" "writing-plans points to the plan-first implementation skill"
require_contains "skills/writing-plans/SKILL.md" "simplepower:subagent-driven-development" "writing-plans still offers subagent implementation"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Design Summary" "plan reviewer checks Design Summary"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Visual Aids" "plan reviewer checks visual aids"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "absence is acceptable" "plan reviewer does not require visual aids"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "File Ownership" "plan reviewer checks file ownership"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Model Allocation" "plan reviewer checks model allocation coverage"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Quick Verification" "plan reviewer checks quick verification"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Quick Verifier Scope" "plan reviewer checks quick verifier scope"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Review+Fix" "plan reviewer checks review+fix"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "coordinator checkpoint commits" "plan reviewer checks coordinator checkpoint commits"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "No worker commits or per-task commits" "plan reviewer checks the worker commit restriction"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Commit Policy" "plan reviewer checks commit policy"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Current-Session Auto-Dispatch" "plan reviewer checks current-session auto-dispatch"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "combined approval" "plan reviewer checks combined approval"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "same reviewer" "plan reviewer checks the same reviewer loop"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "accepted-plan checkpoint commit" "plan reviewer checks the accepted plan checkpoint"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "same reviewer loop open" "plan reviewer checks the reusable reviewer loop"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" 'immediately invokes `simplepower:subagent-driven-development`' "plan reviewer checks immediate invocation after approval"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Context Handoff" "plan reviewer no longer checks the retired context handoff flow"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "current-session context pct" "plan reviewer no longer checks the current-session context percentage"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "current-session-context.md" "plan reviewer no longer checks the current session context helper"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "wc -c" "plan reviewer no longer checks the saved plan-size fallback"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "35840" "plan reviewer no longer checks the saved plan-size threshold"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "55%" "plan reviewer no longer checks the 55 percent routing threshold"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "asking the user which implementation handoff to use" "plan reviewer no longer checks the post-plan handoff ask"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" 'always shows both current-session and `/clear` commands' "plan reviewer no longer checks both handoff commands"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "/clear" "plan reviewer no longer preserves the retired /clear flow"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" 'wc -c "$PLAN_PATH"` drives' "plan reviewer rejects old plan-size-primary routing"
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "omit the size-based recommendation" "plan reviewer rejects stale size-based recommendation wording"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Retired Flow Removal" "plan reviewer checks retired flow removal"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Approved Path Enforcement" "plan reviewer checks approved path enforcement"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Interface Contract" "plan reviewer checks Interface Contract"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Contract inputs" "plan reviewer checks Contract inputs"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Serialization required" "plan reviewer checks Serialization required"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "aggregate parallel readiness" "plan reviewer checks aggregate parallel readiness"

require_contains "skills/brainstorming/SKILL.md" "Approved Path Enforcement" "brainstorming documents approved path enforcement"
require_contains "skills/brainstorming/SKILL.md" "fresh explicit approval" "brainstorming requires fresh approval for alternate paths"
require_contains "skills/brainstorming/SKILL.md" "backup plan" "brainstorming blocks backup plans"
require_contains "skills/brainstorming/SKILL.md" "escape plan" "brainstorming blocks escape plans"

require_contains "skills/writing-plans/SKILL.md" "Approved Path Enforcement" "writing-plans documents approved path enforcement"
require_contains "skills/writing-plans/SKILL.md" "docs-only substitute" "writing-plans blocks docs-only substitutes"
require_contains "skills/writing-plans/SKILL.md" "stub substitute" "writing-plans blocks stub substitutes"
require_contains "skills/writing-plans/SKILL.md" "execution-mode switch" "writing-plans blocks unapproved execution-mode switches"
require_contains "skills/writing-plans/SKILL.md" "fresh explicit approval" "writing-plans requires fresh approval for alternate paths"

require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Approved Path Enforcement" "plan reviewer checks approved path enforcement"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "blocking issue" "plan reviewer treats approved path violations as blocking"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "docs-only substitute" "plan reviewer rejects docs-only substitutes"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "stub substitute" "plan reviewer rejects stub substitutes"
require_contains "skills/subagent-driven-development/SKILL.md" "Approved Path Enforcement" "SDD documents approved path enforcement"
require_contains "skills/subagent-driven-development/SKILL.md" "fresh explicit approval" "SDD requires fresh approval for alternate paths"
require_contains "skills/subagent-driven-development/SKILL.md" "backup plan" "SDD blocks backup plans"
require_contains "skills/subagent-driven-development/SKILL.md" "escape plan" "SDD blocks escape plans"
require_contains "skills/subagent-driven-development/SKILL.md" "execution-mode switch" "SDD blocks unapproved execution-mode switches"
require_contains "skills/subagent-driven-development/SKILL.md" "Implied Write-Scope Corrections" "SDD documents implied write-scope corrections"
require_contains "skills/subagent-driven-development/SKILL.md" "implied-scope omission" "SDD classifies implied-scope omissions"
require_contains "skills/subagent-driven-development/SKILL.md" "true scope expansion" "SDD classifies true scope expansions"
require_contains "skills/subagent-driven-development/SKILL.md" "update the plan's File Ownership entry for that task" "SDD lets coordinator correct implied omissions"
require_contains "skills/subagent-driven-development/SKILL.md" "If the missing file or strategy is not already implied" "SDD stops for true scope expansion approval"
require_contains "skills/subagent-driven-development/SKILL.md" "Interface Contract" "SDD requires Interface Contract"
require_contains "skills/subagent-driven-development/SKILL.md" "Contract inputs" "SDD requires Contract inputs"
require_contains "skills/subagent-driven-development/SKILL.md" "Serialization required" "SDD requires Serialization required"
require_contains "skills/subagent-driven-development/SKILL.md" "aggregate parallel dispatch" "SDD requires aggregate parallel dispatch"

require_contains "skills/subagent-driven-development/implementer-prompt.md" "Approved Path Enforcement" "implementer prompt documents approved path enforcement"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "BLOCKED" "implementer prompt reports blocked substitutions"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "docs-only substitute" "implementer prompt blocks docs-only substitutes"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "stub substitute" "implementer prompt blocks stub substitutes"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "suspected implied-scope omission" "implementer prompt reports suspected implied omissions"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "Do not edit the out-of-scope file yourself" "implementer prompt forbids self-expanding scope"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "Interface Contract" "implementer prompt references the Interface Contract"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "Contract inputs" "implementer prompt references Contract inputs"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "contract mismatches" "implementer prompt reports contract mismatches"

require_contains "skills/subagent-driven-development/SKILL.md" "sp-impl" "SDD references the sp-impl worker"
require_contains "skills/subagent-driven-development/SKILL.md" "aggregate parallel implementation" "SDD documents aggregate parallel implementation"
require_contains "skills/subagent-driven-development/SKILL.md" "quick-verifier-prompt.md" "SDD references quick-verifier-prompt.md"
require_contains "skills/subagent-driven-development/SKILL.md" "review-fix-prompt.md" "SDD references review-fix-prompt.md"
require_contains "skills/subagent-driven-development/SKILL.md" "gpt-5.3-codex-spark" "SDD pins gpt-5.3-codex-spark"
require_contains "skills/subagent-driven-development/SKILL.md" "simplepower:writing-plans" "SDD points at the Simple Power planning skill"
require_contains "skills/subagent-driven-development/SKILL.md" "simplepower:test-driven-development" "SDD points at the Simple Power TDD skill"
require_contains "skills/subagent-driven-development/SKILL.md" "subagent lifecycle checkpoint" "SDD requires subagent lifecycle checkpoints"
require_contains "skills/subagent-driven-development/SKILL.md" "Default lifecycle decision: close" "SDD defaults finished subagents to close"
require_contains "skills/subagent-driven-development/SKILL.md" "written reason" "SDD requires written reasons for keeping finished subagents open"
require_contains "skills/subagent-driven-development/SKILL.md" 'fork_context=false' "SDD defaults subagents to narrow context"
require_contains "skills/subagent-driven-development/SKILL.md" "one BEST-tier review+fix agent" "SDD requires one BEST-tier review+fix agent"
require_contains "skills/subagent-driven-development/SKILL.md" "coordinator checkpoint commit" "SDD requires a coordinator checkpoint commit"
require_contains "skills/subagent-driven-development/SKILL.md" "final commit only if uncommitted changes remain" "SDD keeps the final commit conditional"
require_contains "skills/systematic-debugging/SKILL.md" "parallel investigation escalation" "systematic-debugging documents parallel investigation escalation"
require_contains "skills/systematic-debugging/SKILL.md" "only after initial Phase 1 investigation stalls" "systematic-debugging prevents immediate agent dispatch"
require_contains "skills/systematic-debugging/SKILL.md" "do not dispatch agents" "systematic-debugging skips escalation when root cause is plausible"
require_contains "skills/systematic-debugging/SKILL.md" "investigation brief" "systematic-debugging requires a brief before agent dispatch"
require_contains "skills/systematic-debugging/SKILL.md" "initial Phase 1" "systematic-debugging requires initial Phase 1 work before escalation"
require_contains "skills/systematic-debugging/SKILL.md" "at most six investigation agents" "systematic-debugging caps investigation agents"
require_contains "skills/systematic-debugging/SKILL.md" 'model="gpt-5.4-mini"' "systematic-debugging routes narrow angles to mini"
require_contains "skills/systematic-debugging/SKILL.md" 'model="gpt-5.4"' "systematic-debugging routes difficult angles to full model"
require_contains "skills/systematic-debugging/SKILL.md" 'reasoning_effort="high"' "systematic-debugging requires high effort investigation agents"
require_contains "skills/systematic-debugging/SKILL.md" "fork_context=false" "systematic-debugging defaults investigation agents to narrow context"
require_contains "skills/systematic-debugging/SKILL.md" ".codex-debug/<instance-id>/" "systematic-debugging defines the temporary diagnostics directory"
require_contains "skills/systematic-debugging/SKILL.md" "do not implement fixes" "systematic-debugging forbids fixes by investigation agents"
require_contains "skills/systematic-debugging/SKILL.md" "Assigned angle" "systematic-debugging requires structured investigation-agent output"
require_contains "skills/systematic-debugging/SKILL.md" "synthesize agent reports" "systematic-debugging requires synthesis before implementation"
require_contains "skills/subagent-driven-development/implementer-prompt.md" "sp-impl" "implementer prompt names the sp-impl worker"
require_file "skills/subagent-driven-development/quick-verifier-prompt.md" "quick verifier prompt file exists"
require_file "skills/subagent-driven-development/review-fix-prompt.md" "review+fix prompt file exists"
require_dir_absent "skills/subagent-driven-development/impl-reviewer-prompt.md" "retired inline reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/reviewer-prompt.md" "retired per-wave reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/fixer-prompt.md" "retired per-wave fixer prompt is absent"
require_dir_absent "skills/executing-plans" "retired inline execution skill is absent"
require_contains "skills/subagent-driven-development/SKILL.md" "explicit Simple Power override" "SDD says sp-impl settings override generic same-model defaults"
require_contains "skills/subagent-driven-development/SKILL.md" "same-model defaults" "SDD mentions same-model default conflicts"
require_contains "skills/using-simplepower/references/codex-tools.md" "explicit Simple Power override" "Codex tool mapping says sp-impl settings override generic same-model defaults"
require_contains "skills/using-simplepower/references/codex-tools.md" "sp-impl file-edit worker" "Codex tool mapping includes the sp-impl file-edit worker"
require_contains "skills/using-simplepower/references/codex-tools.md" "quick verifier" "Codex tool mapping includes the quick verifier"
require_contains "skills/using-simplepower/references/codex-tools.md" "review+fix agent" "Codex tool mapping includes the review+fix agent"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_BEST_MODEL" "Codex tool mapping documents the BEST model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_FAST_MODEL" "Codex tool mapping documents the FAST model env var"

require_contains "tests/skill-triggering/run-all.sh" "simplepower" "skill-triggering runner is Codex-focused"

require_contains "tests/explicit-skill-requests/run-all.sh" "simplepower" "explicit skill runner is Codex-focused"

require_contains "tests/skill-triggering/prompts/approved-brainstorming-handoff.txt" "simplepower:writing-plans" "skill-triggering fixture preserves the brainstorming handoff"
require_contains "tests/skill-triggering/prompts/approved-planning-handoff.txt" "simplepower:subagent-driven-development" "skill-triggering fixture preserves the planning handoff"

require_contains "tests/explicit-skill-requests/prompts/after-planning-flow.txt" "docs/simplepower/plans/auth-system.md" "explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/codex-suggested-it.txt" "docs/simplepower/plans/auth-system.md" "follow-up explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt" "docs/simplepower/plans/auth-system.md" "explicit skill prompt uses the Simple Power plan path"

require_contains "tests/brainstorm-server/server.test.js" "Simple Power Brainstorming" "brainstorm server tests cover the Simple Power branding"
require_contains "tests/brainstorm-server/server.test.js" ".simplepower/brainstorm" "brainstorm server tests cover the Simple Power session path"

active_paths=(
    README.md
    AGENTS.md
    .codex/INSTALL.md
    .codex-plugin/plugin.json
    docs/README.codex.md
    docs/testing.md
    package.json
    scripts/bump-version.sh
    scripts/sync-to-codex-plugin.sh
    skills/brainstorming
    skills/requesting-code-review
    skills/subagent-driven-development
    skills/using-simplepower
    skills/writing-plans
    tests/brainstorm-server
    tests/explicit-skill-requests
    tests/skill-triggering
)

active_plan_first_paths=(
    README.md
    AGENTS.md
    .codex-plugin/plugin.json
    docs/README.codex.md
    docs/testing.md
    skills/brainstorming
    skills/subagent-driven-development
    skills/using-simplepower
    skills/writing-plans
    skills/finishing-a-development-branch
    skills/using-git-worktrees
    tests/explicit-skill-requests
    tests/skill-triggering
)

active_plan_visual_paths=(
    README.md
    docs/README.codex.md
    docs/testing.md
    skills/brainstorming/SKILL.md
    skills/brainstorming/visual-companion.md
    skills/writing-plans/SKILL.md
    skills/writing-plans/plan-document-reviewer-prompt.md
)

legacy_skill_namespace='superpowers[:]'
legacy_docs_path='docs[/]superpowers'
legacy_state_path='[.]superpowers'
legacy_tmp_path='/tmp[/]superpowers-tests'
legacy_brainstorm_title='Superpowers[[:space:]]Brainstorming'
old_plan_flow_language='wave-by-wave|wave-based|inline reviewer|separate reviewer|spec review|spec[+]plan|docs/simplepower/specs|simplepower:executing-plans|sp-impl-reviewer|dependency[-[:space:]]staged|Depends on|depends on the other'\''s uncommitted result'
shortcut_language='too[[:space:]]+hard|easier[[:space:]]+alternate|optional[[:space:]]+shortcut|stub[[:space:]]+for[[:space:]]+now|document[[:space:]]+instead'
html_plan_language='(?i)Save plans to:.*[.]html|new plans?.*[.]html|saved as `[.]html`|saved as [.]html|writes? plans?.*[.]html|generated implementation plans .*HTML files'
historical_plan_conversion_language='(?i)historical plans? (must|should|need to|needs to) be converted|must convert historical plans?|should convert historical plans?|convert historical plans? to'

require_no_active_match "$legacy_skill_namespace" "active files do not use the legacy skill namespace" "${active_paths[@]}"
require_no_active_match "$legacy_docs_path" "active files do not point at legacy generated doc paths" "${active_paths[@]}"
require_no_active_match "$legacy_state_path" "active files do not use the legacy brainstorm state path" "${active_paths[@]}"
require_no_active_match "$legacy_tmp_path" "active tests do not use legacy temp output paths" tests/explicit-skill-requests tests/skill-triggering
require_no_active_match "$legacy_brainstorm_title" "active brainstorm tests and assets do not use legacy branding" skills/brainstorming tests/brainstorm-server
stale_context_handoff_language='Context[[:space:]]+Size[[:space:]]+Handoff|current-session-context[.]md|/clear|current Codex context usage|saved plan size|saved plan-size fallback|55%|35840|wc -c[[:space:]]+"\\$PLAN_PATH"|show both commands|handoff choice|which implementation handoff to use|implementation handoff to use|Run after /clear|Continue in current session'
require_no_active_match "$stale_context_handoff_language" "active workflow docs do not retain stale current-session handoff language" README.md docs/README.codex.md skills/writing-plans skills/subagent-driven-development tests/explicit-skill-requests tests/skill-triggering
old_marketplace_repo='prime-radiant-inc/openai-codex''-plugins'
require_no_active_match "$old_marketplace_repo" "active docs and sync scripts do not target the old marketplace repo" README.md AGENTS.md .codex/INSTALL.md .codex-plugin/plugin.json docs/README.codex.md docs/testing.md scripts
require_no_active_match "$old_plan_flow_language" "active plan-first files do not contain old flow routing language" "${active_plan_first_paths[@]}"
require_no_active_match "$shortcut_language" "active plan-first files do not contain shortcut language" "${active_plan_first_paths[@]}"
require_no_active_match "$html_plan_language" "active workflow docs do not say new plans are saved as html files" "${active_plan_visual_paths[@]}"
require_no_active_match "$historical_plan_conversion_language" "active workflow docs do not require historical plan conversion" "${active_plan_visual_paths[@]}"
require_no_active_match "1% chance|Might any skill apply|task matches a skill|Ask for work that matches a skill description" "active docs no longer allow broad semantic skill triggering" skills README.md docs/README.codex.md docs/testing.md
require_no_active_match "^description: Use when|MUST use this before any creative work|Use when implementing any feature or bugfix" "active skill frontmatter avoids broad trigger descriptions" skills/*/SKILL.md
require_contains "skills/writing-plans/SKILL.md" "No per-task commits" "writing-plans still forbids per-task commits"
require_contains "skills/subagent-driven-development/SKILL.md" "No per-task commits" "SDD still forbids per-task commits"
require_contains "AGENTS.md" "Do not add worker-owned or per-task commit requirements" "AGENTS forbids worker-owned and per-task commits"
require_contains "AGENTS.md" "Coordinator-owned commits are allowed only at approved checkpoints" "AGENTS allows coordinator checkpoint commits"
require_contains "skills/writing-plans/SKILL.md" "No worker commits or per-task commits" "writing-plans clarifies the worker commit restriction"
require_contains "skills/subagent-driven-development/SKILL.md" "No worker commits or per-task commits" "SDD clarifies the worker commit restriction"
require_dir_absent "skills/subagent-driven-development/wave-reviewer-fixer-prompt.md" "retired wave reviewer/fixer prompt file is absent"
require_no_active_match "wave-reviewer-fixer-prompt[.]md" "active files do not reference the retired combined reviewer/fixer prompt" "${active_paths[@]}"

require_dir_absent "skills/subagent-driven-development/spec-reviewer-prompt.md" "old spec reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/code-quality-reviewer-prompt.md" "old code quality reviewer prompt is absent"
require_dir_absent "skills/writing-plans/scripts/implementation-handoff-hook" "implementation handoff hook script is absent"
require_dir_absent "tests/implementation-handoff" "implementation handoff hook tests are absent"

legacy_agent_name="clau""de"
legacy_agent_upper="CLAU""DE"

for path in \
    ".$legacy_agent_name-plugin" \
    .cursor-plugin \
    .opencode \
    GEMINI.md \
    gemini-extension.json \
    docs/README.opencode.md \
    docs/windows \
    hooks \
    commands \
    "tests/$legacy_agent_name-code" \
    tests/opencode \
    tests/subagent-driven-dev \
    tests/brainstorm-server/windows-lifecycle.test.sh \
    "$legacy_agent_upper.md"
do
    require_dir_absent "$path" "pruned path is absent: $path"
done

echo ""
if [[ "$failures" -eq 0 ]]; then
    echo "All Simple Power static checks passed."
else
    echo "Simple Power static checks failed: $failures"
    exit 1
fi
