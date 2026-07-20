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

require_path_absent() {
    local path="$1"
    local description="$2"

    if [[ ! -e "$REPO_ROOT/$path" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    unexpected path: $path"
    fi
}

require_path_untracked() {
    local path="$1"
    local description="$2"
    local tracked

    if ! tracked="$(git -C "$REPO_ROOT" ls-files -- "$path")"; then
        fail "$description"
        echo "    unable to inspect tracked paths"
    elif [[ -n "$tracked" ]]; then
        fail "$description"
        echo "    tracked path: $path"
    else
        pass "$description"
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

require_regex_not_contains() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if grep -Eq -- "$pattern" "$REPO_ROOT/$path"; then
        fail "$description"
        echo "    unexpected match pattern: $pattern"
        echo "    in: $path"
    else
        pass "$description"
    fi
}

require_contains_all() {
    local path="$1"
    local description="$2"
    shift 2

    local missing=()
    local needle

    for needle in "$@"; do
        if ! grep -Fq -- "$needle" "$REPO_ROOT/$path"; then
            missing+=("$needle")
        fi
    done

    if [[ "${#missing[@]}" -eq 0 ]]; then
        pass "$description"
    else
        fail "$description"
        for needle in "${missing[@]}"; do
            echo "    missing: $needle"
        done
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

require_no_active_multiline_match() {
    local pattern="$1"
    local description="$2"
    shift 2

    local matches
    matches="$(
        cd "$REPO_ROOT"
        rg -n -U -- "$pattern" "$@" || true
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
require_file "skills/using-simplepower/references/simplepower-config.md" "shared Simple Power config reference exists"
require_dir_absent "skills/using-superpowers" "using-superpowers skill directory is absent"
require_path_untracked "simplepower.toml" "repository does not track a default Simple Power config"
require_file "simplepower.toml.example" "simplepower.toml.example exists as a copyable example config"

require_contains "README.md" "simplepower:*" "README uses the Simple Power namespace"
require_not_contains "README.md" "author =" "README does not include an author line"
require_not_contains "README.md" "Gary Chow" "README does not name a personal author"
require_contains "README.md" "Thanks to Jesse Vincent / Prime Radiant for the upstream project this fork is" "README credits the upstream project"
require_contains "README.md" "codex plugin marketplace add garyfpga/codex-plugins" "README documents the marketplace install command"
require_contains "README.md" "codex plugin add simplepower@garyfpga-codex-plugins" "README documents the plugin install command"
require_contains "README.md" "codex plugin marketplace upgrade garyfpga-codex-plugins" "README documents the named marketplace update command"
require_contains "README.md" "best_model = \"gpt-5.6-sol-high\"" "README documents the BEST model default key"
require_contains "README.md" "review_model = \"gpt-5.6-sol-high\"" "README documents the REVIEW model default key"
require_contains "README.md" "normal_model = \"gpt-5.6-luna-max\"" "README documents the NORMAL model default key"
require_contains "README.md" "fast_model = \"gpt-5.3-codex-spark-xhigh\"" "README documents the FAST model default key"
require_contains "README.md" "FAST is the Spark tier" "README documents FAST as the Spark tier"
require_contains "README.md" "four mandatory model tiers" "README documents four model tiers"
require_contains "README.md" "review_model2" "README documents optional review_model2"
require_contains "README.md" "final_review_model" "README documents optional final_review_model"
require_contains "README.md" "no environment override" "README documents that review_model2 has no environment override"
require_contains "README.md" "skip_final_review = false" "README documents the final-review skip default"
require_contains "README.md" "SIMPLEPOWER_USE_SUBAGENT" "README documents the explorer Boolean env var"
require_contains "README.md" "SIMPLEPOWER_SUBAGENT_MODEL" "README documents the explorer model env var"
require_contains "README.md" "SIMPLEPOWER_FINAL_REVIEW_MODEL" "README documents the final review model env var"
require_contains "README.md" "SIMPLEPOWER_SKIP_FINAL_REVIEW" "README documents the final-review skip env var"
require_contains_all "README.md" "README documents final review model fallback" \
    "final_review_model" \
    "falling back to REVIEW" \
    "false dispatches exactly one review+fix agent"
require_contains_all "README.md" "README documents configured final-review skipping" \
    "skip_final_review" \
    "omits final-review scratch refs and dispatch" \
    "retains final verification"
require_contains "README.md" "initial triage" "README documents coordinator initial triage"
require_contains "README.md" "one or more" "README documents the on-demand fanout mode"
require_contains "README.md" "permits optional exploration but does" "README treats use_subagent=true as permission rather than a one-explorer instruction"
require_not_contains "README.md" "permits but does not require one" "README does not retain ambiguous exact-one explorer wording"
require_contains "README.md" "plan-review secondary" "README documents optional plan-review secondary"
require_contains_all "README.md" "README keeps the secondary out of final review" \
    "never writes files" \
    "participates in final review"
require_contains_all 'README.md' "README documents AGENTS model assignment retirement" \
    'Root and nested `AGENTS.md` files do not provide' \
    'model assignments.'
require_contains "README.md" "repository 文件不会整体替代 home 文件" "README documents per-key repo overlay"
require_not_contains "README.md" "Simple Power uses three configurable model tiers" "README no longer documents three model tiers"
require_regex_contains "README.md" '按最后一个 dash 拆成非空 model prefix|parsed at.*final dash.*nonempty model prefix' "README explains final-dash parsing as model-prefix + effort-suffix"
require_contains "README.md" "批准已审阅的 plan、模型分配，以及立刻在当前 session 里启动" "README documents combined approval and immediate current-session execution"
require_contains "README.md" "accepted plan checkpoint commit" "README documents the accepted plan checkpoint"
require_contains "README.md" "simplepower:subagent-driven-development" "README documents current-session auto-dispatch"
require_contains "README.md" "temporary localhost visual companion" "README distinguishes the brainstorming visual companion"
require_contains "README.md" "temporary local scratch refs as diff anchors" "README documents local scratch refs as diff anchors"
require_contains "README.md" "artifacts, not branches or accepted checkpoints" "README says scratch refs are review-only artifacts"
require_contains "README.md" "and they are cleaned up after" "README documents scratch cleanup after success"
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

require_contains ".codex-plugin/plugin.json" '"version": "1.1.0"' "plugin manifest version is 1.1.0"
require_contains ".codex-plugin/plugin.json" "configurable final-review model" "plugin metadata documents configurable final review"
require_contains ".codex-plugin/plugin.json" "optional distinct read-only secondary plan reviewer" "plugin metadata documents optional plan-review secondary"
require_contains ".codex-plugin/plugin.json" "temporary local scratch refs as diff anchors" "plugin metadata documents scratch refs as diff anchors"
require_contains ".codex-plugin/plugin.json" "review/fix passes" "plugin metadata scopes scratch refs to revised plans and review/fix passes"
require_not_contains ".codex-plugin/plugin.json" "one BEST-tier review+fix pass" "plugin metadata no longer documents BEST-tier review+fix"
require_contains "package.json" '"version": "1.1.0"' "package.json version is 1.1.0"

require_contains "AGENTS.md" "simplepower:*" "AGENTS.md uses the Simple Power namespace"
require_contains "AGENTS.md" "docs/simplepower" "AGENTS.md points generated docs at docs/simplepower"
require_contains "AGENTS.md" 'Root or nested `AGENTS.md` files' "AGENTS.md documents AGENTS-model assignment retirement"
require_contains "AGENTS.md" 'do not provide model assignments' "AGENTS.md documents AGENTS-model assignment retirement"
require_contains "AGENTS.md" "refs/simplepower/scratch/<run-id>/..." "AGENTS.md documents the scratch ref namespace"
require_contains "AGENTS.md" "allowed only as local review diff" "AGENTS.md limits scratch refs to local review diff anchors"
require_contains "AGENTS.md" "not commits in accepted history" "AGENTS.md keeps scratch refs out of accepted history"
require_contains "AGENTS.md" "reported for manual cleanup on" "AGENTS.md preserves scratch refs for cleanup reporting on blockers"

require_contains "docs/README.codex.md" "simplepower:*" "Codex install guide uses the Simple Power namespace"
require_contains "docs/README.codex.md" "codex plugin marketplace add garyfpga/codex-plugins" "Codex install guide documents the marketplace install command"
require_contains "docs/README.codex.md" "codex plugin add simplepower@garyfpga-codex-plugins" "Codex install guide documents the plugin install command"
require_contains "docs/README.codex.md" "codex plugin marketplace upgrade garyfpga-codex-plugins" "Codex install guide documents the named marketplace update command"
require_contains "docs/README.codex.md" "sp-impl" "Codex install guide mentions sp-impl"
require_contains "docs/README.codex.md" "docs/simplepower" "Codex install guide points generated docs at docs/simplepower"
require_contains "docs/README.codex.md" "SIMPLEPOWER_REVIEW_MODEL" "Codex install guide documents the REVIEW model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_BEST_MODEL" "Codex install guide documents the BEST model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_NORMAL_MODEL" "Codex install guide documents the NORMAL model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_FAST_MODEL" "Codex install guide documents the FAST Spark model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_USE_SUBAGENT" "Codex install guide documents the explorer Boolean env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_SUBAGENT_MODEL" "Codex install guide documents the explorer model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_FINAL_REVIEW_MODEL" "Codex install guide documents the final-review model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_SKIP_FINAL_REVIEW" "Codex install guide documents the final-review skip env var"
require_contains "docs/README.codex.md" "Use FAST for obvious repetitive" "Codex install guide documents FAST as repetitive work"
require_contains "docs/README.codex.md" "four mandatory model tiers" "Codex install guide documents four model tiers"
require_contains_all "docs/README.codex.md" "Codex install guide documents final review model fallback" \
    "final_review_model" \
    "falling back to REVIEW" \
    "false runs one review+fix agent"
require_contains_all "docs/README.codex.md" "Codex install guide documents optional plan-review secondary" \
    "read-only plan-review secondary" \
    "never writes files" \
    "participates" \
    "in final review"
require_contains "docs/README.codex.md" "initial triage" "Codex install guide documents coordinator first triage"
require_contains "docs/README.codex.md" "one or more" "Codex install guide documents on-demand fanout"
require_not_contains "docs/README.codex.md" "two initial read-only final-review reports" "Codex install guide removes dual final review"
require_contains_all 'docs/README.codex.md' "Codex install guide documents AGENTS model assignment retirement" \
    'Root and nested `AGENTS.md` files do not provide' \
    'model assignments.'
require_contains "docs/README.codex.md" "per key" "Codex install guide documents per-key TOML key overlay"
require_not_contains "docs/README.codex.md" "Simple Power uses three configurable model tiers" "Codex install guide no longer documents three model tiers"
require_contains "docs/README.codex.md" "after combined approval in the current session" "Codex install guide documents combined approval in the current session"
require_contains "docs/README.codex.md" "simplepower:subagent-driven-development" "Codex install guide documents current-session auto-dispatch"
require_contains "docs/README.codex.md" "Git scratch refs as diff anchors" "Codex install guide documents scratch refs as diff anchors"
require_contains "docs/README.codex.md" "accepted checkpoint history stays at the usual three coordinator commits" "Codex install guide preserves the three coordinator checkpoints"
require_contains "docs/README.codex.md" "scratch refs are cleaned up after success" "Codex install guide documents scratch cleanup after success"
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

require_contains ".codex/INSTALL.md" "codex plugin marketplace add garyfpga/codex-plugins" "bundled install guide documents the marketplace install command"
require_contains ".codex/INSTALL.md" "codex plugin add simplepower@garyfpga-codex-plugins" "bundled install guide documents the plugin install command"
require_contains ".codex/INSTALL.md" "codex plugin marketplace upgrade garyfpga-codex-plugins" "bundled install guide documents the named marketplace update command"

require_contains "docs/testing.md" "bash tests/simplepower-static/run-tests.sh" "testing docs cover the static test harness"
require_contains "docs/testing.md" "npm --prefix tests/brainstorm-server test" "testing docs cover brainstorm server tests"
require_contains "docs/testing.md" "bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" "testing docs cover Codex plugin sync tests"
require_contains "docs/testing.md" "simplepower:brainstorming" "testing docs mention the Codex smoke test skill trigger"
require_contains "docs/testing.md" "docs/simplepower" "testing docs point generated artifacts at docs/simplepower"
require_contains "docs/testing.md" "optional plan visual guidance" "testing docs cover optional plan visual guidance"
require_contains "docs/testing.md" "companion behavior" "testing docs cover brainstorming visual companion behavior"
require_contains "docs/testing.md" "marketplace metadata" "testing docs mention marketplace metadata coverage"
require_contains "docs/testing.md" "review_model2" "testing docs mention review_model2"
require_contains "docs/testing.md" "final_review_model" "testing docs mention final_review_model"
require_contains "docs/testing.md" 'SIMPLEPOWER_REVIEW_MODEL2' "testing docs reject a review_model2 environment override"
require_contains "docs/testing.md" "two concurrent read-only reviewers" "testing docs mention dual plan review"
require_contains "docs/testing.md" "exactly one review+fix" "testing docs require one final review agent"
require_contains "docs/testing.md" "skip_final_review=true" "testing docs cover configured final-review skipping"

require_contains "skills/using-simplepower/SKILL.md" "simplepower:*" "using-simplepower skill uses the Simple Power namespace"
require_contains "skills/using-simplepower/SKILL.md" "docs/simplepower" "using-simplepower skill points generated docs at docs/simplepower"
require_not_contains "skills/using-simplepower/SKILL.md" "using-superpowers" "using-simplepower skill no longer references using-superpowers"
require_contains "skills/using-simplepower/SKILL.md" "Explicit user request required" "using-simplepower requires explicit invocation"
require_contains "skills/using-simplepower/SKILL.md" "authorized Simple Power chain handoff" "using-simplepower preserves approved chain handoffs"
require_contains "skills/using-simplepower/SKILL.md" "Do not invoke Simple Power skills from semantic task matching alone" "using-simplepower blocks semantic auto-triggering"

config_reference="skills/using-simplepower/references/simplepower-config.md"
require_contains "$config_reference" '<git-root>/simplepower.toml' "config reference names the exact repository config filename"
require_contains "$config_reference" 'use_subagent =' "config reference defines use_subagent"
require_contains "$config_reference" 'skip_final_review =' "config reference defines skip_final_review"
require_contains "$config_reference" 'subagent_model =' "config reference defines subagent_model"
require_contains "$config_reference" 'review_model =' "config reference defines review_model"
require_contains "$config_reference" 'review_model2 =' "config reference defines the optional review_model2"
require_contains "$config_reference" 'final_review_model =' "config reference defines the optional final_review_model"
require_contains "$config_reference" 'best_model =' "config reference defines best_model"
require_contains "$config_reference" 'normal_model =' "config reference defines normal_model"
require_contains "$config_reference" 'fast_model =' "config reference defines fast_model"
require_contains "$config_reference" 'use_subagent = false' "config reference gives the disabled-by-default Boolean"
require_contains "$config_reference" 'skip_final_review = false' "config reference gives the final-review skip default"
require_contains "$config_reference" 'subagent_model = "gpt-5.6-luna-xhigh"' "config reference gives the optional subagent model default"
require_contains "$config_reference" 'review_model = "gpt-5.6-sol-high"' "config reference gives the default REVIEW model"
require_contains "$config_reference" "no built-in default" "config reference marks review_model2 as optional with no built-in default"
require_regex_not_contains "$config_reference" '^[[:space:]]*review_model2[[:space:]]*=' "config reference does not assign a default review_model2 value"
require_regex_not_contains "$config_reference" '^[[:space:]]*final_review_model[[:space:]]*=' "config reference does not assign an independent default final_review_model value"
require_contains "$config_reference" 'best_model = "gpt-5.6-sol-high"' "config reference gives the default BEST model"
require_contains "$config_reference" 'normal_model = "gpt-5.6-luna-max"' "config reference gives the default NORMAL model"
require_contains "$config_reference" 'fast_model = "gpt-5.3-codex-spark-xhigh"' "config reference gives the default FAST model"
require_contains "$config_reference" '`SIMPLEPOWER_REVIEW_MODEL`' "config reference names the REVIEW environment override"
require_contains "$config_reference" '`SIMPLEPOWER_BEST_MODEL`' "config reference names the BEST environment override"
require_contains "$config_reference" '`SIMPLEPOWER_NORMAL_MODEL`' "config reference names the NORMAL environment override"
require_contains "$config_reference" '`SIMPLEPOWER_FAST_MODEL`' "config reference names the FAST environment override"
require_contains "$config_reference" '`SIMPLEPOWER_USE_SUBAGENT`' "config reference names the explorer Boolean environment override"
require_contains "$config_reference" '`SIMPLEPOWER_SUBAGENT_MODEL`' "config reference names the explorer model environment override"
require_contains "$config_reference" '`SIMPLEPOWER_SKIP_FINAL_REVIEW`' "config reference names the final-review skip environment override"
require_contains "$config_reference" 'SIMPLEPOWER_REVIEW_MODEL2' "config reference states that review_model2 has no environment variable"
require_contains "$config_reference" 'SIMPLEPOWER_FINAL_REVIEW_MODEL' "config reference names the final-review model environment override"
require_contains "$config_reference" 'final dash' "config reference splits model and effort on the final dash"
require_contains "$config_reference" '`low`, `medium`, `high`, `xhigh`, `max`, and `ultra`' "config reference lists every supported reasoning effort"
require_contains "$config_reference" 'It does not replace the home file as a' "config reference documents per-key overlay"
require_contains "$config_reference" 'missing repository keys retain home or default values.' "config reference documents per-key overlay"
require_contains "$config_reference" 'case-insensitive `true` or `false`' "config reference defines Boolean environment parsing"
require_contains "$config_reference" 'empty supported environment variables are ignored' "config reference ignores empty environment values"
require_contains "$config_reference" '`~/.codex/simplepower.toml`' "config reference defines home config fallback"
require_contains "$config_reference" 'Apply explicit current-session instructions last.' "config reference enforces current-session override precedence"
require_contains "$config_reference" 'inherits the value already resolved' "config reference documents missing-key inheritance"
require_contains "$config_reference" 'Malformed TOML' "config reference rejects malformed TOML"
require_contains "$config_reference" 'unknown top-level key' "config reference rejects unknown keys"
require_contains "$config_reference" 'wrong types' "config reference rejects wrong value types"
require_contains "$config_reference" 'missing model prefixes' "config reference rejects invalid model syntax"
require_contains "$config_reference" 'unknown effort suffixes' "config reference rejects unknown effort suffixes"
require_contains "$config_reference" 'source plus the precise problem' "config errors report the selected path and precise problem"
require_contains "$config_reference" 'Every present file, every explicit' "config reference validates present-file overrides before dispatch"
require_regex_contains "$config_reference" 'absent.*exactly equal|exactly equal.*absent|absent.*exact match|exact match.*absent' "config reference documents single-route fallback when review_model2 is absent or equal"
require_regex_contains "$config_reference" 'absent.*exactly equal|exactly equal.*absent' "config reference documents single-route fallback when review_model2 is equal"
require_contains_all "$config_reference" "config reference documents plan-review activation for distinct review_model2" \
    'Any distinct valid `review_model2` enables that read-only' \
    "plan-review route."
require_contains_all "$config_reference" "config reference documents final-review fallback" \
    'absent, use the fully' \
    "exactly one final review+fix agent"
require_contains_all "$config_reference" "config reference documents configured final-review skipping" \
    '`skip_final_review=true`' \
    "skip final-review scratch-ref creation" \
    "still run final verification"
require_contains "$config_reference" "never uses" "config reference keeps review_model2 out of final review"
require_contains "$config_reference" "coordinator-owned read-only initial triage" "config reference documents coordinator-led triage before optional exploration"
require_contains "$config_reference" "must not dispatch explorers" "config reference blocks startup dispatch for optional explorers"
require_contains "$config_reference" "coordinator synthesizes all explorer reports" "config reference documents coordinator synthesis across optional-explorer dispatch"
require_contains_all "$config_reference" "config reference documents stop-on-failure for selected batches" \
    "stop the affected workflow and report the" \
    "precise blocker"
require_contains "$config_reference" "one or more" "config reference documents on-demand fanout"
require_contains "$config_reference" "distinct" "config reference documents distinct optional angles"
require_contains "$config_reference" "runtime capacity" "config reference documents runtime-capacity practical limits"
require_contains "$config_reference" "self-contained" "config reference documents self-contained optional-explorer briefs"
require_contains_all "$config_reference" "config reference stops on blocker before accepting partial optional-explorer fanout" \
    "If any explorer in a" \
    "selected batch cannot dispatch because multi-agent support, the configured" \
    "model, or spawning is unavailable, stop the affected workflow and report the" \
    "precise blocker; a partial batch is not a substitute."
require_contains "$config_reference" "a partial batch is not a substitute" "config reference enforces all-or-nothing optional-explorer batches"
require_contains "$config_reference" "precise blocker" "config reference requires explicit blocker reporting for optional-explorer failure"
require_contains "$config_reference" 'do not govern mandatory plan reviewers' "optional config does not alter mandatory tier roles"

require_not_contains "skills/brainstorming/SKILL.md" "docs/simplepower/specs" "brainstorming no longer writes standalone specs"
require_not_contains "skills/brainstorming/SKILL.md" "User reviews written spec" "brainstorming no longer has a written spec review gate"
require_dir_absent "skills/brainstorming/spec-document-reviewer-prompt.md" "old brainstorming spec reviewer prompt is absent"
require_file "skills/brainstorming/visual-companion.md" "brainstorming visual companion guide exists"
require_contains_all "skills/brainstorming/SKILL.md" "brainstorming keeps the hard gate, approved path, and planning handoff contract" \
    "<HARD-GATE>" \
    "Approved Path Enforcement" \
    "fresh explicit approval" \
    "simplepower-config.md" \
    'fork_turns="none"' \
    "visual-companion.md" \
    "simplepower:writing-plans"
require_contains_all "skills/brainstorming/SKILL.md" "brainstorming keeps coordinator-led read-only fanout boundaries" \
    "coordinator performs read-only initial triage" \
    "initial triage" \
    "one or more" \
    "distinct" \
    "because runtime" \
    "capacity and non-overlapping useful angles limit the batch." \
    "read-only" \
    "self-contained" \
    "temporary browser aid"
require_contains "skills/brainstorming/SKILL.md" "never dispatch explorers automatically" "brainstorming does not auto-dispatch optional explorers"
require_contains "skills/brainstorming/SKILL.md" "large, cross-cutting, complex, or stalled context investigation" "brainstorming gates fan-out to large/cross-cutting/complex/stalled contexts"
require_contains "skills/brainstorming/SKILL.md" "Do not continue through coordinator-only work, another model, or" "brainstorming blocks silent fallback when a selected explorer batch fails"
require_contains "skills/brainstorming/SKILL.md" "a partial batch is not a substitute" "brainstorming enforces all-or-nothing optional-explorer selection"
require_contains "skills/brainstorming/visual-companion.md" ".simplepower/brainstorm" "visual companion uses the Simple Power brainstorming session path"
require_contains "skills/brainstorming/visual-companion.md" "temporary localhost aid for brainstorming" "visual companion guide documents localhost behavior"
require_contains "skills/brainstorming/visual-companion.md" "distinct from optional inline visuals in saved Markdown implementation plans" "visual companion guide distinguishes saved Markdown plan visuals"
require_contains "skills/brainstorming/scripts/start-server.sh" ".simplepower/brainstorm" "brainstorm server startup script uses the Simple Power session path"
require_contains "skills/brainstorming/scripts/frame-template.html" "Simple Power Brainstorming" "brainstorm frame shows Simple Power branding"

require_contains "skills/ro/SKILL.md" "simplepower-config.md" "RO reads the shared optional-subagent config"
require_contains 'skills/ro/SKILL.md' 'With effective `use_subagent=false`, explorer dispatch is prohibited.' "RO explorer is prohibited without optional-subagent permission"
require_contains "skills/ro/SKILL.md" "coordinator performs read-only initial triage of the request and" "RO starts with coordinator-owned initial triage"
require_contains "skills/ro/SKILL.md" "Never dispatch explorers automatically" "RO does not auto-dispatch optional explorers"
require_contains "skills/ro/SKILL.md" "initial triage identifies" "RO explorer starts from coordinator triage"
require_contains "skills/ro/SKILL.md" "one or more" "RO explorer allows practical multi-angle fan-out"
require_contains "skills/ro/SKILL.md" "distinct useful angle." "RO explorer supports distinct read-only angles"
require_contains "skills/ro/SKILL.md" "runtime capacity" "RO explorer respects runtime capacity limits"
require_contains "skills/ro/SKILL.md" "Every selected explorer uses the model and reasoning effort parsed from" "RO explorer dispatch model uses parsed subagent model"
require_contains "skills/ro/SKILL.md" "partial batch is not a substitute" "RO marks selected explorer batch failure as all-or-nothing"
require_contains "skills/ro/SKILL.md" "Do not continue coordinator-only, use a" "RO blocks silent fallback when explorer fan-out cannot be dispatched"
require_contains "skills/ro/SKILL.md" "They cannot edit or create any files" "RO explorer cannot edit tracked files"
require_contains "skills/ro/SKILL.md" 'cannot create `.codex-ro`' "RO explorer cannot create coordinator-owned artifacts"
require_contains "skills/ro/SKILL.md" 'fork_turns="none"' "RO explorer receives no inherited turns"
require_no_active_match "spawn exactly one read-only|optionally dispatch one read-only|initial explorer only" "active explorer policy does not keep retired exact-one wording" \
    "skills/brainstorming/SKILL.md" \
    "skills/ro/SKILL.md"
require_no_active_match "select one read-only explorer|one read-only explorer|exactly one read-only|optionally dispatch one read-only" "active optional-explorer policy does not use obsolete exact-one wording" \
    "$config_reference" \
    "skills/brainstorming/SKILL.md" \
    "skills/ro/SKILL.md" \
    "skills/writing-plans/SKILL.md" \
    "docs/README.codex.md" \
    "README.md"

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
require_path_absent "skills/writing-plans/current-session-context.md" "writing-plans current session context helper is absent"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_BEST_MODEL" "writing-plans documents the BEST model env var"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_REVIEW_MODEL" "writing-plans documents the REVIEW model env var"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_NORMAL_MODEL" "writing-plans documents the NORMAL model env var"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_FAST_MODEL" "writing-plans documents the FAST model env var"
require_contains "skills/writing-plans/SKILL.md" "FAST/NORMAL/BEST/REVIEW" "writing-plans documents four-tier allocation"
require_contains 'skills/writing-plans/SKILL.md' '`gpt-5.3-codex-spark-xhigh`' "writing-plans defaults FAST to Spark xhigh"
require_contains "skills/writing-plans/SKILL.md" "The quick verifier uses the FAST tier by default" "writing-plans routes quick verifier through FAST"
require_contains "skills/writing-plans/SKILL.md" "REVIEW-tier plan reviewer" "writing-plans dispatches a REVIEW-tier plan reviewer"
require_contains "skills/writing-plans/SKILL.md" "final_review_model" "writing-plans documents the final review model"
require_contains "skills/writing-plans/SKILL.md" "exactly one final review+fix agent" "writing-plans dispatches one final review agent"
require_contains "skills/writing-plans/SKILL.md" "skip_final_review=true" "writing-plans supports configured final-review skipping"
require_contains "skills/writing-plans/SKILL.md" "SIMPLEPOWER_FINAL_REVIEW_MODEL" "writing-plans documents final-review model environment routing"
require_contains "skills/writing-plans/SKILL.md" "review_model2" "writing-plans documents the optional secondary review model"
require_contains "skills/writing-plans/SKILL.md" "both plan reviewers concurrently" "writing-plans documents dual-plan reviewer routing when review_model2 is distinct"
require_contains "skills/writing-plans/SKILL.md" 'An absent `review_model2`, or an exact match' "writing-plans documents single-review fallback when review_model2 is absent or equal"
require_not_contains "skills/writing-plans/SKILL.md" "collect and synthesize both reports" "writing-plans removes dual final review synthesis"
require_contains "skills/writing-plans/SKILL.md" "Only the final review+fix agent may edit files within" "writing-plans preserves one final fixer"
require_contains 'skills/writing-plans/SKILL.md' 'Do not read model assignments from any `AGENTS.md` file.' "writing-plans documents AGENTS model assignment retirement"
require_contains "skills/writing-plans/SKILL.md" "layer replaces only the keys it supplies" "writing-plans documents per-key TOML overlay"
require_contains "skills/writing-plans/SKILL.md" "Every present TOML" "writing-plans rejects invalid lower-precedence TOML files"
require_contains "skills/writing-plans/SKILL.md" "higher layer must not hide" "writing-plans prevents higher layers from hiding invalid config"
require_contains "skills/writing-plans/SKILL.md" "supported non-empty" "writing-plans applies the supported environment layer"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "seven base TOML keys are" "plan reviewer checks the complete configuration schema"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "review_model2" "plan reviewer checks the optional review_model2 key"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "final_review_model" "plan reviewer checks the optional final_review_model key"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "SIMPLEPOWER_FINAL_REVIEW_MODEL" "plan reviewer checks final-review model environment routing"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "supported non-empty" "plan reviewer checks environment precedence"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "fatal if invalid even when a higher layer" "plan reviewer rejects hidden invalid TOML files"
require_contains "skills/writing-plans/SKILL.md" "run Codex CLI" "writing-plans reviewer dispatch forbids Codex CLI"
require_contains "skills/writing-plans/SKILL.md" "spawn subagents" "writing-plans reviewer dispatch forbids subagents"
require_contains "skills/writing-plans/SKILL.md" "invoke Simple Power skills" "writing-plans reviewer dispatch forbids skill recursion"
require_contains "skills/writing-plans/SKILL.md" "restart execution" "writing-plans reviewer dispatch forbids restart routing"
require_contains "skills/writing-plans/SKILL.md" "reroute" "writing-plans reviewer dispatch forbids rerouting"
require_contains "skills/writing-plans/SKILL.md" "aggregate parallel implementation" "writing-plans emits aggregate implementation handoff"
require_contains "skills/writing-plans/SKILL.md" "gpt-5.3-codex-spark" "writing-plans documents the default FAST Spark model"
require_contains "skills/writing-plans/SKILL.md" "review+fix" "writing-plans uses review+fix"
require_contains "skills/writing-plans/SKILL.md" "current-session auto-dispatch" "writing-plans documents current-session auto-dispatch"
require_contains "skills/writing-plans/SKILL.md" "combined approval" "writing-plans documents combined approval"
require_contains "skills/writing-plans/SKILL.md" "accepted plan checkpoint commit" "writing-plans documents the accepted plan checkpoint"
require_contains "skills/writing-plans/SKILL.md" "sends the revised plan and the concrete diff to the same original reviewer" "writing-plans documents the reusable reviewer loop"
require_contains "skills/writing-plans/SKILL.md" 'immediately invokes `simplepower:subagent-driven-development`' "writing-plans documents immediate invocation after approval"
require_contains "skills/writing-plans/SKILL.md" "docs/simplepower/plans" "writing-plans writes plans under docs/simplepower/plans"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans forbids non-coordinator commits" \
    "Workers, primary and secondary plan reviewers, quick verifiers, and final" \
    "review+fix agents must not commit"
require_contains "skills/writing-plans/SKILL.md" "Planning and execution also use coordinator-owned temporary scratch refs as" "writing-plans documents scratch refs as review aids"
require_contains "skills/writing-plans/SKILL.md" "refs/simplepower/scratch/<run-id>/" "writing-plans documents the scratch namespace"
require_contains "skills/writing-plans/SKILL.md" "refs/simplepower/scratch/<run-id>/plan-review/before" "writing-plans names the plan-review before ref"
require_contains "skills/writing-plans/SKILL.md" "refs/simplepower/scratch/<run-id>/plan-review/after-<n>" "writing-plans names the plan-review after ref"
require_contains "skills/writing-plans/SKILL.md" 'git update-ref "$SP_REF" "$SP_COMMIT"' "writing-plans uses git update-ref for scratch refs"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans sends revised plans with a concrete diff command" \
    "send the revised plan back to the same original reviewer" \
    'concrete scratch-ref `git diff` command'
require_contains "skills/writing-plans/SKILL.md" "git diff refs/simplepower/scratch/<run-id>/<phase>/<before-label> refs/simplepower/scratch/<run-id>/<phase>/<after-label> -- <approved-files>" "writing-plans documents the scratch diff command"
require_contains "skills/writing-plans/SKILL.md" "git update-ref -d" "writing-plans documents scratch cleanup with git update-ref -d"
require_contains "skills/writing-plans/SKILL.md" "cleanup command instead of deleting them" "writing-plans preserves scratch refs on blockers"
require_contains "skills/writing-plans/SKILL.md" "not accepted history commits" "writing-plans keeps scratch refs out of accepted history"
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
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "REVIEW-tier plan document reviewer" "plan reviewer is REVIEW-tier"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "SIMPLEPOWER_REVIEW_MODEL" "plan reviewer checks the REVIEW model env var"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "FAST/NORMAL/BEST/REVIEW" "plan reviewer checks four-tier model allocation"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "SIMPLEPOWER_NORMAL_MODEL" "plan reviewer checks the NORMAL model env var"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "SIMPLEPOWER_FAST_MODEL" "plan reviewer checks the FAST model env var"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "quick verifier uses FAST by default" "plan reviewer checks quick verifier FAST routing"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Quick Verification" "plan reviewer checks quick verification"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Quick Verifier Scope" "plan reviewer checks quick verifier scope"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Review+Fix" "plan reviewer checks review+fix"
require_contains 'skills/writing-plans/plan-document-reviewer-prompt.md' 'model assignments are not read from `AGENTS.md`' "plan reviewer checks AGENTS model assignment retirement"
require_contains_all 'skills/writing-plans/plan-document-reviewer-prompt.md' "plan reviewer checks the optional model keys" \
    "seven base TOML keys are" \
    "review_model2" \
    "final_review_model"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "both plan reviewers concurrently" "plan reviewer checks dual-plan-review routing"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "both plan reviewers approve the same revision" "plan reviewer checks both-plan reviewer reports"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Do not run Codex CLI" "plan reviewer prompt forbids Codex CLI"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Do not spawn subagents" "plan reviewer prompt forbids subagents"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "not invoke Simple Power skills" "plan reviewer prompt forbids skill recursion"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Do not restart" "plan reviewer prompt forbids restart routing"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Do not reroute" "plan reviewer prompt forbids rerouting"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Perform the assigned review directly in the current worker" "plan reviewer prompt requires direct review"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "coordinator checkpoint commits" "plan reviewer checks coordinator checkpoint commits"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "No worker commits or per-task commits" "plan reviewer checks the worker commit restriction"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Commit Policy" "plan reviewer checks commit policy"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Current-Session Auto-Dispatch" "plan reviewer checks current-session auto-dispatch"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "combined approval" "plan reviewer checks combined approval"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "accepted reviewed plan plus allocation plus immediate current-session execution after combined approval" "plan reviewer checks the combined approval checkpoint policy"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "same original reviewer" "plan reviewer checks the same reviewer loop"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "accepted-plan checkpoint commit" "plan reviewer checks the accepted plan checkpoint"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "primary reviewer loop open" "plan reviewer checks the reusable reviewer loop"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" 'immediately invokes `simplepower:subagent-driven-development`' "plan reviewer checks immediate invocation after approval"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Scratch Ref Review Anchors" "plan reviewer checks scratch ref anchors"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "refs/simplepower/scratch/<run-id>/" "plan reviewer checks the scratch namespace"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" 'plan-review refs use `plan-review/before` before first review and `plan-review/after-<n>` after coordinator revisions' "plan reviewer checks plan-review before/after refs"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" 'revised-plan review loops provide a concrete `git diff` command or explicit diff summary' "plan reviewer checks revised-plan diff commands"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "quick-verifier and final review+fix edits are inspectable with the same scratch-ref diff command shape" "plan reviewer checks quick-verifier and review-fix scratch anchors"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "cleanup after successful checkpoints" "plan reviewer checks scratch cleanup after success"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "preservation and manual cleanup reporting on blockers or failed checkpoints" "plan reviewer preserves scratch refs on blockers"
require_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "never changing the exactly-three-checkpoint commit policy" "plan reviewer preserves the three-checkpoint policy"
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
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD keeps approved-path, contract, and model-routing anchors" \
    "## Approved Path" \
    "fresh explicit approval" \
    "backup plan" \
    "escape plan" \
    "execution-mode switch" \
    "Implied Write-Scope Corrections" \
    "implied-scope omission" \
    "true scope expansion" \
    "Interface Contract" \
    "File Ownership" \
    "Contract inputs" \
    "Serialization required" \
    "sp-impl" \
    "simplepower-config.md" \
    "supported non-empty" \
    "Quick verifier: use FAST" \
    'Final review+fix: when `skip_final_review=false`, use the effective' \
    "gpt-5.3-codex-spark" \
    "Do not read model assignments" \
    'fork_turns="none"'
require_contains "skills/subagent-driven-development/SKILL.md" "review_model2" "SDD documents the optional plan-review secondary model contract"
require_contains "skills/subagent-driven-development/SKILL.md" "final_review_model" "SDD documents the final review model contract"
require_contains "skills/subagent-driven-development/SKILL.md" "exactly one final review+fix agent" "SDD dispatches exactly one final reviewer"
require_contains "skills/subagent-driven-development/SKILL.md" "skip_final_review=true" "SDD supports configured final-review skipping"
require_contains "skills/subagent-driven-development/SKILL.md" "review-fix/before" "SDD uses the review-fix scratch anchor"
require_not_contains "skills/subagent-driven-development/SKILL.md" "secondary-review-prompt.md" "SDD removes the secondary final-review prompt"
require_not_contains "skills/subagent-driven-development/SKILL.md" "dual-mode" "SDD removes dual final review"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD keeps lifecycle, commit, and scratch-ref guardrails" \
    "Default lifecycle decision: close." \
    "written reason" \
    "No worker commits." \
    "No per-task commits." \
    "quick-verified implementation checkpoint" \
    "Create a final commit only if uncommitted" \
    "refs/simplepower/scratch/<run-id>/" \
    "quick-verifier/before" \
    "quick-verifier/after" \
    "review-fix/before" \
    "review-fix/after" \
    "scratch-ref cleanup status or cleanup commands"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD keeps capacity-aware rolling dispatch separate from true serialization" \
    "capacity-aware rolling" \
    "build the complete ready set" \
    "queued ready task" \
    "queued ready tasks" \
    "do not mark them serialized merely because capacity is full" \
    "available slot idle" \
    "dispatch the next queued ready task into the freed slot" \
    "Do not treat capacity limits as serialization" \
    "as soon as a slot opens" \
    "overlapping write scopes" \
    "missing or ambiguous contract" \
    "required generated artifact" \
    "sequential runtime/migration"
require_file "skills/subagent-driven-development/scratch-ref-workflow.md" "scratch-ref workflow reference file exists"
require_contains "skills/subagent-driven-development/SKILL.md" "scratch-ref-workflow.md" "SDD references the scratch-ref workflow guide"
require_contains "skills/subagent-driven-development/SKILL.md" "simplepower:writing-plans" "SDD points at the Simple Power planning skill"
require_contains "skills/subagent-driven-development/SKILL.md" "simplepower:test-driven-development" "SDD points at the Simple Power TDD skill"
require_contains_all "skills/subagent-driven-development/implementer-prompt.md" "implementer prompt keeps self-contained sp-impl boundaries" \
    "sp-impl" \
    "Interface Contract" \
    "Contract inputs" \
    "BLOCKED" \
    "implied-scope omission" \
    "do not edit the out-of-scope file" \
    "make docs-only" \
    "create stubs" \
    "spawn subagents" \
    "workflow skills"
require_file "skills/subagent-driven-development/quick-verifier-prompt.md" "quick verifier prompt file exists"
require_file "skills/subagent-driven-development/review-fix-prompt.md" "review+fix prompt file exists"
require_path_absent "skills/subagent-driven-development/secondary-review-prompt.md" "secondary final-review prompt is absent"
require_contains_all "skills/subagent-driven-development/quick-verifier-prompt.md" "quick verifier prompt keeps FAST limited-fix guardrails" \
    "FAST quick verifier" \
    "tiny typo-level" \
    "approved changed-file list" \
    "approved File Ownership/write scopes" \
    "NON_TRIVIAL_FAILURES" \
    "quick-verifier/before" \
    "spawn subagents" \
    "workflow skills"
require_contains_all "skills/subagent-driven-development/review-fix-prompt.md" "review+fix prompt keeps direct final-review guardrails" \
    "one final review+fix agent" \
    'effective `final_review_model`' \
    "Perform the assigned review directly in this worker" \
    "Do not run Codex CLI" \
    "do not restart execution" \
    "not spawn subagents" \
    "workflow skills" \
    "reroute execution" \
    "review-fix/before" \
    "Do not create, update, delete, inspect, or manage scratch refs."
require_not_contains "skills/subagent-driven-development/review-fix-prompt.md" "unless the coordinator explicitly asks" "primary review+fix prompt does not allow ad hoc scratch-ref inspection"
require_file "skills/systematic-debugging/parallel-investigation.md" "parallel investigation reference file exists"
require_contains "skills/systematic-debugging/SKILL.md" "parallel-investigation.md" "systematic-debugging main skill references the parallel investigation guide"
require_contains_all "skills/systematic-debugging/SKILL.md" "systematic-debugging keeps the four-phase root-cause workflow" \
    "Root Cause" \
    "Phase 1" \
    "Phase 2" \
    "Phase 3" \
    "Phase 4" \
    "simplepower-config.md" \
    'fork_turns="none"' \
    ".codex-debug/<instance-id>/" \
    "After three failed fixes, stop." \
    "architecture with the human partner"
require_contains_all "skills/systematic-debugging/SKILL.md" "systematic-debugging keeps bounded Phase 1 escalation gates" \
    "stalled without a plausible root cause" \
    "use_subagent=false" \
    'If `use_subagent=true`, read' \
    "at most six distinct read-only angles" \
    "investigator fixes" \
    "synthesize all reports before fixes"
require_contains_all "skills/systematic-debugging/parallel-investigation.md" "parallel investigation keeps bounded read-only investigator rules" \
    "investigation brief" \
    "plausible root cause" \
    "at most six distinct angles" \
    "read-only angle" \
    "do not implement fixes" \
    ".codex-debug/<instance-id>/" \
    "Assigned angle" \
    "Coordinator Synthesis"
require_contains_all "skills/subagent-driven-development/scratch-ref-workflow.md" "scratch-ref workflow keeps exact coordinator mechanics" \
    "refs/simplepower/scratch/<run-id>/" \
    "quick-verifier/before" \
    "quick-verifier/after" \
    "review-fix/before" \
    "review-fix/after" \
    "tmp_index" \
    "GIT_INDEX_FILE" \
    "git commit-tree" \
    "git update-ref" \
    "git update-ref -d" \
    "manual cleanup command"
require_dir_absent "skills/subagent-driven-development/impl-reviewer-prompt.md" "retired inline reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/reviewer-prompt.md" "retired per-wave reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/fixer-prompt.md" "retired per-wave fixer prompt is absent"
require_dir_absent "skills/executing-plans" "retired inline execution skill is absent"
require_contains "skills/using-simplepower/references/codex-tools.md" "independent of" "Codex tool mapping says sp-impl settings override generic same-model defaults"
require_contains "skills/using-simplepower/references/codex-tools.md" "sp-impl file-edit worker" "Codex tool mapping includes the sp-impl file-edit worker"
require_contains "skills/using-simplepower/references/codex-tools.md" "quick verifier" "Codex tool mapping includes the quick verifier"
require_contains "skills/using-simplepower/references/codex-tools.md" "review+fix agent" "Codex tool mapping includes the review+fix agent"
require_contains "skills/using-simplepower/references/codex-tools.md" "final_review_model" "Codex tool mapping documents the final review model"
require_contains "skills/using-simplepower/references/codex-tools.md" "plan-review secondary" "Codex tool mapping scopes the secondary to plan review"
require_not_contains "skills/using-simplepower/references/codex-tools.md" "secondary-review-prompt.md" "Codex tool mapping removes the secondary final-review prompt"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_BEST_MODEL" "Codex tool mapping documents the BEST model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_REVIEW_MODEL" "Codex tool mapping documents the REVIEW model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" 'SIMPLEPOWER_REVIEW_MODEL2' "Codex tool mapping states that review_model2 has no environment variable"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_NORMAL_MODEL" "Codex tool mapping documents the NORMAL model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_FAST_MODEL" "Codex tool mapping documents the FAST model env var"
require_contains_all "skills/using-simplepower/references/codex-tools.md" "Codex tool mapping rejects invalid lower-precedence TOML files" \
    "Every present TOML" \
    "file must validate in full"
require_contains "skills/using-simplepower/references/codex-tools.md" "supported non-empty" "Codex tool mapping applies the supported environment layer"
require_contains "skills/using-simplepower/references/codex-tools.md" "skip_final_review=true" "Codex tool mapping supports configured final-review skipping"
require_contains "skills/using-simplepower/references/codex-tools.md" "resolved_final_review_model" "Codex tool mapping includes the final review model dispatch"
require_contains "skills/using-simplepower/references/codex-tools.md" 'layer replaces only the keys it supplies.' "Codex tool mapping documents per-key overlays"
require_contains "skills/using-simplepower/references/codex-tools.md" 'from any `AGENTS.md` file.' "Codex tool mapping blocks nested AGENTS scanning"
require_contains "skills/using-simplepower/references/codex-tools.md" "refs/simplepower/scratch/<run-id>/" "Codex tool mapping documents the scratch namespace"
require_contains "skills/using-simplepower/references/codex-tools.md" "coordinator-owned" "Codex tool mapping keeps scratch refs coordinator-owned"
require_contains "skills/using-simplepower/references/codex-tools.md" 'concrete `git diff` commands to reviewers' "Codex tool mapping frames scratch refs as reviewer diff anchors"
require_contains "skills/using-simplepower/references/codex-tools.md" "not branches, accepted checkpoints, pushed refs, or subagent commits" "Codex tool mapping excludes branch/checkpoint/pushed/subagent semantics"
require_contains "skills/using-simplepower/references/codex-tools.md" "must not create, update, delete, or commit them" "Codex tool mapping forbids worker and review agent scratch ref ownership"
require_contains "skills/using-simplepower/references/codex-tools.md" "Use the plan's approved FAST/NORMAL/BEST allocation for \`sp-impl\` file-edit" "Codex tool mapping keeps sp-impl dispatch on the three implementation tiers"
require_contains "skills/using-simplepower/references/codex-tools.md" "Dispatch one" "Codex tool mapping routes final review through its configured model"
require_contains "skills/using-simplepower/references/codex-tools.md" '| FAST | `fast_model` | `SIMPLEPOWER_FAST_MODEL` | `gpt-5.3-codex-spark-xhigh` |' "Codex tool mapping defaults FAST to Spark xhigh"
require_contains "skills/using-simplepower/references/codex-tools.md" "quick verifier" "Codex tool mapping includes the quick verifier"
require_contains "skills/using-simplepower/references/codex-tools.md" "Default resolves to Spark xhigh" "Codex tool mapping describes the quick verifier FAST default"

require_contains "tests/skill-triggering/run-all.sh" "simplepower" "skill-triggering runner is Codex-focused"

require_contains "tests/explicit-skill-requests/run-all.sh" "simplepower" "explicit skill runner is Codex-focused"

require_contains "tests/skill-triggering/prompts/approved-brainstorming-handoff.txt" "simplepower:writing-plans" "skill-triggering fixture preserves the brainstorming handoff"
require_contains "tests/skill-triggering/prompts/approved-planning-handoff.txt" "simplepower:subagent-driven-development" "skill-triggering fixture preserves the planning handoff"
require_contains "tests/skill-triggering/prompts/approved-planning-handoff.txt" "FAST/NORMAL/BEST/REVIEW model allocation" "skill-triggering fixture names the four-tier model allocation"

require_contains "tests/explicit-skill-requests/prompts/after-planning-flow.txt" "docs/simplepower/plans/auth-system.md" "explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/codex-suggested-it.txt" "docs/simplepower/plans/auth-system.md" "follow-up explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt" "docs/simplepower/plans/auth-system.md" "explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/action-oriented.txt" "configured final review+fix pass" "action-oriented prompt uses configured final-review wording"
require_contains "tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt" "configured final review+fix pass" "SDD prompt uses configured final-review wording"

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
    skills/dispatching-parallel-agents
    skills/requesting-code-review
    skills/ro
    skills/subagent-driven-development
    skills/systematic-debugging
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
obsolete_fork_parameter='fork_''context'
nonisolated_fork_turns='fork_turns="(all|[1-9][0-9]*)"'

require_no_active_match "$legacy_skill_namespace" "active files do not use the legacy skill namespace" "${active_paths[@]}"
require_no_active_match "$legacy_docs_path" "active files do not point at legacy generated doc paths" "${active_paths[@]}"
require_no_active_match "$legacy_state_path" "active files do not use the legacy brainstorm state path" "${active_paths[@]}"
require_no_active_match "$legacy_tmp_path" "active tests do not use legacy temp output paths" tests/explicit-skill-requests tests/skill-triggering
require_no_active_match "$legacy_brainstorm_title" "active brainstorm tests and assets do not use legacy branding" skills/brainstorming tests/brainstorm-server
stale_context_handoff_language='Context[[:space:]]+Size[[:space:]]+Handoff|current-session-context[.]md|/clear|current Codex context usage|saved plan size|55%|35840|wc -c[[:space:]]+"\\$PLAN_PATH"|show both commands|handoff choice|which implementation handoff to use|implementation handoff to use|Run after /clear|Continue in current session'
stale_context_handoff_multiline='saved[ -]plan[ -]size[[:space:]]+fallback|context[ -]usage[[:space:]]+measurement|context[[:space:]]+helper|context[[:space:]]+measurement[[:space:]]+helper|context[ -]size[[:space:]]+checking|context[ -]window[[:space:]]+checking|clear-session[[:space:]]+command|post-plan[[:space:]]+handoff-choice'
require_no_active_match "$stale_context_handoff_language" "active workflow docs do not retain stale current-session handoff language" README.md docs/README.codex.md skills/writing-plans skills/subagent-driven-development tests/explicit-skill-requests tests/skill-triggering
require_no_active_multiline_match "$stale_context_handoff_multiline" "active workflow docs do not retain multiline or hyphenated stale current-session handoff language" README.md docs/README.codex.md skills/writing-plans skills/subagent-driven-development tests/explicit-skill-requests tests/skill-triggering
active_model_tier_paths=(
    README.md
    docs/README.codex.md
    AGENTS.md
    .codex-plugin/plugin.json
    skills/writing-plans/SKILL.md
    skills/writing-plans/plan-document-reviewer-prompt.md
    skills/subagent-driven-development/SKILL.md
    skills/subagent-driven-development/review-fix-prompt.md
    skills/using-simplepower/references/codex-tools.md
    tests/skill-triggering/prompts/approved-planning-handoff.txt
    tests/explicit-skill-requests/prompts/action-oriented.txt
    tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt
)
stale_model_tier_language='three configurable model[[:space:]]+tiers|FAST[/]NORMAL[/]BEST model allocation|BEST-tier plan reviewer|BEST-tier review\+fix|one BEST-tier review\+fix agent|one BEST-tier review\+fix pass|plan reviewer and final review\+fix agent use BEST|final review\+fix agent uses BEST|Always dispatch the review\+fix agent with BEST|review\+fix agent with BEST'
require_no_active_match "$stale_model_tier_language" "active model docs do not retain stale BEST-for-review routing language" "${active_model_tier_paths[@]}"
old_marketplace_repo='prime-radiant-inc/openai-codex''-plugins'
require_no_active_match "$old_marketplace_repo" "active docs and sync scripts do not target the old marketplace repo" README.md AGENTS.md .codex/INSTALL.md .codex-plugin/plugin.json docs/README.codex.md docs/testing.md scripts
require_no_active_match "$old_plan_flow_language" "active plan-first files do not contain old flow routing language" "${active_plan_first_paths[@]}"
require_no_active_match "$shortcut_language" "active plan-first files do not contain shortcut language" "${active_plan_first_paths[@]}"
require_no_active_match "$html_plan_language" "active workflow docs do not say new plans are saved as html files" "${active_plan_visual_paths[@]}"
require_no_active_match "$historical_plan_conversion_language" "active workflow docs do not require historical plan conversion" "${active_plan_visual_paths[@]}"
require_no_active_match "$obsolete_fork_parameter" "active sources do not use the obsolete fork context parameter" "${active_paths[@]}"
require_no_active_match "$nonisolated_fork_turns" "active sources do not request inherited conversation turns" "${active_paths[@]}"
require_contains "skills/using-simplepower/references/codex-tools.md" 'fork_turns="none"' "Codex tool mappings isolate every Simple Power spawn"
require_contains "skills/dispatching-parallel-agents/SKILL.md" 'fork_turns="none"' "parallel dispatch isolates every spawned agent"
require_contains "skills/requesting-code-review/SKILL.md" 'fork_turns="none"' "code review dispatch isolates the reviewer"
require_contains "skills/writing-plans/SKILL.md" 'fork_turns="none"' "plan review dispatch isolates the reviewer"
require_no_active_match "1% chance|Might any skill apply|task matches a skill|Ask for work that matches a skill description" "active docs no longer allow broad semantic skill triggering" skills README.md docs/README.codex.md docs/testing.md
require_no_active_match "^description: Use when|MUST use this before any creative work|Use when implementing any feature or bugfix" "active skill frontmatter avoids broad trigger descriptions" skills/*/SKILL.md
require_contains "skills/writing-plans/SKILL.md" "No per-task commits" "writing-plans still forbids per-task commits"
require_contains "skills/subagent-driven-development/SKILL.md" "No per-task commits" "SDD still forbids per-task commits"
require_contains "AGENTS.md" "Do not add worker-owned or per-task commit requirements" "AGENTS forbids worker-owned and per-task commits"
require_contains "AGENTS.md" "Coordinator-owned commits are allowed only at approved checkpoints" "AGENTS allows coordinator checkpoint commits"
require_contains "skills/writing-plans/SKILL.md" "No worker commits or per-task commits" "writing-plans clarifies the worker commit restriction"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD clarifies the worker commit restriction" \
    "No worker commits." \
    "No per-task commits."
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
