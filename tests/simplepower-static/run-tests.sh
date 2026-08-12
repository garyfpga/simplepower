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
require_contains "simplepower.toml.example" '# plan_review_model = "gpt-5.6-luna-max"' "example config documents plan review as commented opt-in"
require_regex_not_contains "simplepower.toml.example" '^[[:space:]]*plan_review_model[[:space:]]*=' "example config does not activate plan review by default"

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
require_contains "README.md" "FAST/NORMAL/BEST" "README documents active FAST/NORMAL/BEST model routing"
require_contains "README.md" "plan_review_model" "README documents optional plan review model"
require_contains "README.md" "SIMPLEPOWER_PLAN_REVIEW_MODEL" "README documents the plan review environment override"
require_contains "README.md" "review_model2" "README documents optional review_model2"
require_contains "README.md" "final_review_model" "README documents optional final_review_model"
require_contains "README.md" "no environment override" "README documents that review_model2 has no environment override"
require_contains "README.md" "skip_final_review = false" "README documents the final-review skip default"
require_contains "README.md" "SIMPLEPOWER_USE_SUBAGENT" "README documents the explorer Boolean env var"
require_contains "README.md" "SIMPLEPOWER_SUBAGENT_MODEL" "README documents the explorer model env var"
require_contains "README.md" "SIMPLEPOWER_FINAL_REVIEW_MODEL" "README documents the final review model env var"
require_contains "README.md" "SIMPLEPOWER_SKIP_FINAL_REVIEW" "README documents the final-review skip env var"
require_contains_all "README.md" "README documents deprecated review compatibility keys" \
    "review_model" \
    "review_model2" \
    "final_review_model" \
    "skip_final_review" \
    "deprecated" \
    "no-op"
require_contains "README.md" "initial triage" "README documents coordinator initial triage"
require_contains "README.md" "one or more" "README documents the on-demand fanout mode"
require_contains "README.md" "permits optional exploration but does" "README treats use_subagent=true as permission rather than a one-explorer instruction"
require_not_contains "README.md" "permits but does not require one" "README does not retain ambiguous exact-one explorer wording"
require_contains_all "README.md" "README documents adaptive route choices" \
    "Implementation Route: Main agent" \
    "Implementation Route: Grouped workers" \
    "cohesive"
require_contains_all 'README.md' "README documents AGENTS model assignment retirement" \
    'Root and nested `AGENTS.md` files do not provide' \
    'model assignments.'
require_contains "README.md" "repository 文件不会整体替代 home 文件" "README documents per-key repo overlay"
require_not_contains "README.md" "Simple Power uses three configurable model tiers" "README no longer documents three model tiers"
require_regex_contains "README.md" '按最后一个 dash 拆成非空 model prefix|parsed at.*final dash.*nonempty model prefix' "README explains final-dash parsing as model-prefix + effort-suffix"
require_contains "README.md" "two mandatory checkpoint types" "README documents two mandatory checkpoint types"
require_contains "README.md" "accepted plan" "README documents the accepted plan checkpoint"
require_contains "README.md" "final-completion checkpoint" "README documents the final completion checkpoint"
require_contains_all "README.md" "README documents original-plan execution summaries and bounded execution commits" \
    "Execution Summary" \
    "original plan" \
    "terminal verification" \
    "committed state" \
    "Convenience, worker, and per-task commits remain" \
    "authorization ends at final handoff"
require_not_contains "README.md" "exactly two coordinator checkpoints" "README does not conflate mandatory checkpoint types with total commit count"
require_contains "README.md" "simplepower:subagent-driven-development" "README documents current-session auto-dispatch"
require_contains "README.md" "temporary localhost visual companion" "README distinguishes the brainstorming visual companion"
require_contains "README.md" "quick-verifier scratch refs as temporary local diff anchors" "README documents local scratch refs as diff anchors"
require_contains "README.md" "quick-verifier" "README scopes scratch refs to quick verifier"
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
require_contains ".codex-plugin/plugin.json" "Main agent" "plugin metadata documents direct main-agent implementation"
require_contains ".codex-plugin/plugin.json" "Grouped workers" "plugin metadata documents grouped worker implementation"
require_contains ".codex-plugin/plugin.json" "FAST quick verifier" "plugin metadata documents the FAST quick verifier"
require_contains ".codex-plugin/plugin.json" "temporary local scratch refs as diff anchors" "plugin metadata documents scratch refs as diff anchors"
require_contains ".codex-plugin/plugin.json" "concise execution summaries in original plans" "plugin metadata documents original-plan summaries"
require_contains ".codex-plugin/plugin.json" "two mandatory coordinator checkpoint types with bounded active-run execution commits" "plugin metadata documents bounded execution commits"
require_contains ".codex-plugin/plugin.json" "deprecated no-op" "plugin metadata documents deprecated review compatibility settings"
require_contains ".codex-plugin/plugin.json" "optional configured single-pass read-only plan reviewer" "plugin metadata documents optional plan review"
require_not_contains ".codex-plugin/plugin.json" "one BEST-tier review+fix pass" "plugin metadata no longer documents BEST-tier review+fix"
require_contains "package.json" '"version": "1.1.0"' "package.json version is 1.1.0"

require_contains "AGENTS.md" "simplepower:*" "AGENTS.md uses the Simple Power namespace"
require_contains "AGENTS.md" "docs/simplepower" "AGENTS.md points generated docs at docs/simplepower"
require_contains "AGENTS.md" 'Root or nested `AGENTS.md` files' "AGENTS.md documents AGENTS-model assignment retirement"
require_contains "AGENTS.md" 'do not provide model assignments' "AGENTS.md documents AGENTS-model assignment retirement"
require_contains "AGENTS.md" "refs/simplepower/scratch/<run-id>/..." "AGENTS.md documents the scratch ref namespace"
require_contains "AGENTS.md" "allowed only as local" "AGENTS.md limits scratch refs to local quick-verifier diff anchors"
require_contains "AGENTS.md" "quick-verifier diff anchors" "AGENTS.md scopes scratch refs to quick-verifier diff anchors"
require_contains "AGENTS.md" "not commits in accepted history" "AGENTS.md keeps scratch refs out of accepted history"
require_contains "AGENTS.md" "reported for manual cleanup on" "AGENTS.md preserves scratch refs for cleanup reporting on blockers"
require_contains_all "AGENTS.md" "AGENTS documents bounded coordinator execution commits" \
    "Coordinator-owned commits require accepted workflow authorization" \
    "two mandatory checkpoint types" \
    "objective technical prerequisite" \
    "original plan's execution summary" \
    "Convenience and history-shaping commits" \
    "authorization ends at final handoff"

require_contains "docs/README.codex.md" "simplepower:*" "Codex install guide uses the Simple Power namespace"
require_contains "docs/README.codex.md" "codex plugin marketplace add garyfpga/codex-plugins" "Codex install guide documents the marketplace install command"
require_contains "docs/README.codex.md" "codex plugin add simplepower@garyfpga-codex-plugins" "Codex install guide documents the plugin install command"
require_contains "docs/README.codex.md" "codex plugin marketplace upgrade garyfpga-codex-plugins" "Codex install guide documents the named marketplace update command"
require_contains "docs/README.codex.md" "sp-impl" "Codex install guide mentions sp-impl"
require_contains "docs/README.codex.md" "docs/simplepower" "Codex install guide points generated docs at docs/simplepower"
require_contains "docs/README.codex.md" "SIMPLEPOWER_REVIEW_MODEL" "Codex install guide documents the REVIEW model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_PLAN_REVIEW_MODEL" "Codex install guide documents the plan-review model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_BEST_MODEL" "Codex install guide documents the BEST model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_NORMAL_MODEL" "Codex install guide documents the NORMAL model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_FAST_MODEL" "Codex install guide documents the FAST Spark model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_USE_SUBAGENT" "Codex install guide documents the explorer Boolean env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_SUBAGENT_MODEL" "Codex install guide documents the explorer model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_FINAL_REVIEW_MODEL" "Codex install guide documents the final-review model env var"
require_contains "docs/README.codex.md" "SIMPLEPOWER_SKIP_FINAL_REVIEW" "Codex install guide documents the final-review skip env var"
require_contains "docs/README.codex.md" "Use FAST for obvious repetitive" "Codex install guide documents FAST as repetitive work"
require_contains "docs/README.codex.md" "FAST/NORMAL/BEST" "Codex install guide documents active model tiers"
require_contains_all "docs/README.codex.md" "Codex install guide documents deprecated review compatibility keys" \
    "review_model" \
    "review_model2" \
    "final_review_model" \
    "skip_final_review" \
    "deprecated" \
    "no-op"
require_contains_all "docs/README.codex.md" "Codex install guide documents adaptive route choices" \
    "Implementation Route: Main agent" \
    "Implementation Route: Grouped workers" \
    "cohesive"
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
require_contains "docs/README.codex.md" "two mandatory checkpoint types" "Codex install guide documents two mandatory checkpoint types"
require_contains_all "docs/README.codex.md" "Codex install guide documents the summary lifecycle" \
    "coordinator-owned execution" \
    "Execution Summary" \
    "terminal verification without further file edits" \
    "committed state" \
    "authorization ends at final handoff"
require_contains "docs/README.codex.md" "quick-verifier" "Codex install guide scopes scratch refs to quick verifier"
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
require_contains "docs/testing.md" "plan_review_model" "testing docs mention optional plan_review_model"
require_contains "docs/testing.md" 'SIMPLEPOWER_PLAN_REVIEW_MODEL' "testing docs cover the plan-review environment override"
require_contains "docs/testing.md" 'SIMPLEPOWER_REVIEW_MODEL2' "testing docs reject a review_model2 environment override"
require_contains "docs/testing.md" "Implementation Route: Main agent" "testing docs cover direct main-agent route"
require_contains "docs/testing.md" "Implementation Route: Grouped workers" "testing docs cover grouped worker route"
require_contains "docs/testing.md" "mandatory FAST quick verifier" "testing docs cover mandatory FAST quick verification"
require_contains "docs/testing.md" "deprecated no-ops" "testing docs cover deprecated review compatibility no-ops"
require_contains_all "docs/testing.md" "testing docs cover execution summaries and bounded commits" \
    "original plan's concise execution summary" \
    "two mandatory" \
    "labeled follow-up entries" \
    "raw logs" \
    "objective committed-state prerequisite" \
    "Convenience, worker, and per-task" \
    "authorization ends at final handoff" \
    "exact reason"

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
require_contains "$config_reference" 'plan_review_model =' "config reference defines optional plan_review_model"
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
require_regex_not_contains "$config_reference" '^[[:space:]]*plan_review_model[[:space:]]*=' "config reference does not assign a default plan_review_model value"
require_regex_not_contains "$config_reference" '^[[:space:]]*review_model2[[:space:]]*=' "config reference does not assign a default review_model2 value"
require_regex_not_contains "$config_reference" '^[[:space:]]*final_review_model[[:space:]]*=' "config reference does not assign an independent default final_review_model value"
require_contains "$config_reference" 'best_model = "gpt-5.6-sol-high"' "config reference gives the default BEST model"
require_contains "$config_reference" 'normal_model = "gpt-5.6-luna-max"' "config reference gives the default NORMAL model"
require_contains "$config_reference" 'fast_model = "gpt-5.3-codex-spark-xhigh"' "config reference gives the default FAST model"
require_contains "$config_reference" '`SIMPLEPOWER_REVIEW_MODEL`' "config reference names the REVIEW environment override"
require_contains "$config_reference" '`SIMPLEPOWER_PLAN_REVIEW_MODEL`' "config reference names the plan-review environment override"
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
require_contains_all "$config_reference" "config reference marks review settings as validated compatibility no-ops" \
    "review_model" \
    "review_model2" \
    "final_review_model" \
    "skip_final_review" \
    "deprecated" \
    "no-op"
require_contains_all "$config_reference" "config reference defines optional single-pass plan review" \
    "Optional Single-Pass Plan Review" \
    "Critical" \
    "Must Fix" \
    "without redispatching" \
    "without retrying" \
    "no built-in default or fallback" \
    "cannot activate plan review by itself"
require_contains "$config_reference" "Do not create a review loop or plan-review scratch refs" "config reference forbids plan-review loops and scratch refs"
require_not_contains "$config_reference" "exactly one final review+fix agent" "config reference removes active final review dispatch"
require_not_contains "$config_reference" "plan-review route" "config reference removes active plan-review secondary routing"
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
require_contains "$config_reference" 'do not govern normal brainstorming-to-implementation execution' "review compatibility config does not alter normal workflow routing"

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
require_contains_all "skills/brainstorming/SKILL.md" "brainstorming hands approved designs to adaptive planning" \
    "cohesion" \
    "specialization" \
    "Implementation Route" \
    "Main agent" \
    "Grouped workers"
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
require_contains "skills/writing-plans/SKILL.md" "Worker Packages" "writing-plans requires cohesive worker packages for grouped routes"
require_contains "skills/writing-plans/SKILL.md" "Quick Verification" "writing-plans requires Quick Verification"
require_contains "skills/writing-plans/SKILL.md" "Final Verification" "writing-plans requires Final Verification"
require_contains "skills/writing-plans/SKILL.md" "Checkpoint Conditions" "writing-plans requires checkpoint conditions"
require_contains "skills/writing-plans/SKILL.md" "Verification" "writing-plans requires Verification"
require_contains "skills/writing-plans/SKILL.md" "FAST/NORMAL/BEST Allocation" "writing-plans requires active model allocation for grouped routes"
require_contains "skills/writing-plans/SKILL.md" "Design Summary" "writing-plans requires Design Summary"
require_contains "skills/writing-plans/SKILL.md" "Implementation Route" "writing-plans requires Implementation Route"
require_contains "skills/writing-plans/SKILL.md" "Interface Contract" "writing-plans requires Interface Contract"
require_contains "skills/writing-plans/SKILL.md" "Contract inputs" "writing-plans requires Contract inputs"
require_contains "skills/writing-plans/SKILL.md" "Serialization required" "writing-plans requires Serialization required"
require_contains "skills/writing-plans/SKILL.md" "Main agent" "writing-plans documents the direct implementation route"
require_contains "skills/writing-plans/SKILL.md" "Grouped workers" "writing-plans documents the grouped implementation route"
require_contains "skills/writing-plans/SKILL.md" "cohesive" "writing-plans requires cohesive packaging"
require_contains "skills/writing-plans/SKILL.md" "docs/simplepower/plans/YYYY-MM-DD-<feature-name>.md" "writing-plans keeps Markdown plan format under docs/simplepower/plans"
require_contains "skills/writing-plans/SKILL.md" "## Visual Aids" "writing-plans documents optional Visual Aids guidance"
require_contains "skills/writing-plans/SKILL.md" "reduce ambiguity" "writing-plans keeps Visual Aids optional"
require_contains "skills/writing-plans/SKILL.md" "workflow flowcharts" "writing-plans names workflow flowchart visual aid cases"
require_contains "skills/writing-plans/SKILL.md" "architecture or data-flow" "writing-plans names architecture or data-flow visual aid cases"
require_contains "skills/writing-plans/SKILL.md" "task ownership matrices" "writing-plans names task ownership matrix visual aid cases"
require_contains "skills/writing-plans/SKILL.md" "state or error-path diagrams" "writing-plans names state or error-path visual aid cases"
require_path_absent "skills/writing-plans/current-session-context.md" "writing-plans current session context helper is absent"
require_contains "skills/writing-plans/SKILL.md" "simplepower-config.md" "writing-plans references the canonical model configuration"
require_contains "skills/writing-plans/SKILL.md" "instead of copying environment-overlay" "writing-plans keeps environment boilerplate out of generated plans"
require_contains "skills/writing-plans/SKILL.md" "FAST/NORMAL/BEST" "writing-plans documents active implementation allocation"
require_contains 'skills/writing-plans/SKILL.md' '`gpt-5.3-codex-spark-xhigh`' "writing-plans defaults FAST to Spark xhigh"
require_contains "skills/writing-plans/SKILL.md" "The quick verifier uses the FAST tier by default" "writing-plans routes quick verifier through FAST"
require_contains "skills/writing-plans/SKILL.md" "final_review_model" "writing-plans documents the final review model"
require_contains "skills/writing-plans/SKILL.md" "deprecated" "writing-plans marks review compatibility settings deprecated"
require_contains "skills/writing-plans/SKILL.md" "no-op" "writing-plans marks review compatibility settings no-op in the normal chain"
require_contains "skills/writing-plans/SKILL.md" "review_model2" "writing-plans documents the optional secondary review model"
require_not_contains "skills/writing-plans/SKILL.md" "both plan reviewers concurrently" "writing-plans removes dual-plan reviewer routing"
require_not_contains "skills/writing-plans/SKILL.md" "Only the final review+fix agent may edit files within" "writing-plans removes final review agent writer"
require_contains "skills/writing-plans/SKILL.md" "main agent" "writing-plans makes the coordinator responsible for review/fixes"
require_contains "skills/writing-plans/SKILL.md" "canonical configuration reference" "writing-plans delegates config precedence and validation to the canonical reference"
require_file "skills/writing-plans/plan-document-reviewer-prompt.md" "optional plan-document reviewer prompt exists"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans defines one-pass optional review" \
    "plan_review_model" \
    "SIMPLEPOWER_PLAN_REVIEW_MODEL" \
    "Critical" \
    "Must Fix" \
    "Do not resend" \
    "Extra sections do not make the report unusable" \
    "factually wrong" \
    "approval message" \
    "only pre-approval reviewer" \
    "without retrying" \
    'fork_turns="none"'
require_contains_all "skills/writing-plans/plan-document-reviewer-prompt.md" "plan reviewer prompt enforces narrow read-only reporting" \
    "single-pass plan review" \
    "Status: <PASS or ISSUES_FOUND>" \
    "Critical" \
    "Must Fix" \
    "Do not report minor issues" \
    "Do not edit or create files" \
    "Do not request a revised plan" \
    'fork_turns="none"'
require_not_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "Recommendations" "plan reviewer prompt has no recommendation section"
require_contains "skills/writing-plans/SKILL.md" "self-review" "writing-plans requires main-agent plan self-review"
require_contains "skills/writing-plans/SKILL.md" "directly implements" "writing-plans allows direct coordinator implementation"
require_contains "skills/writing-plans/SKILL.md" "gpt-5.3-codex-spark" "writing-plans documents the default FAST Spark model"
require_contains "skills/writing-plans/SKILL.md" "current-session auto-dispatch" "writing-plans documents current-session auto-dispatch"
require_contains "skills/writing-plans/SKILL.md" "combined approval" "writing-plans documents combined approval"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans combined approval authorizes mandatory and bounded commits" \
    "accepted-plan checkpoint commit" \
    "final reviewed/verified completion checkpoint commit" \
    "bounded in-scope coordinator execution commits during the active run" \
    "authorization expires at final handoff"
require_contains "skills/writing-plans/SKILL.md" "approved plan" "writing-plans documents the approved plan checkpoint condition"
require_contains "skills/writing-plans/SKILL.md" "final reviewed/verified completion" "writing-plans documents the final completion checkpoint condition"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans defines the original-plan execution record" \
    '`Execution Record`' \
    "saved plan's own path" \
    '`## Execution Summary`' \
    "current status and outcome" \
    "verification overview" \
    "pre-commit HEAD" \
    "unresolved follow-ups" \
    "phase- or date-labeled follow-up entry" \
    "raw logs" \
    "unrelated repository audits" \
    "containing final SHA"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans defines bounded execution commits and terminal verification" \
    "objective technical" \
    "requires committed state" \
    "execution summary must be committed separately" \
    "Convenience and history-shaping commits" \
    "reruns terminal verification after the last summary edit" \
    "without further file edits" \
    "genuinely untracked" \
    "summary write or validation failure blocks completion"
require_not_contains "skills/writing-plans/SKILL.md" "always create a separate summary commit" "writing-plans does not require an unconditional summary commit"
require_not_contains "skills/writing-plans/SKILL.md" "sends the revised plan and the concrete diff to the same original reviewer" "writing-plans removes the reusable reviewer loop"
require_not_contains "skills/writing-plans/SKILL.md" "send the revised plan back" "writing-plans does not resend plans for review"
require_contains "skills/writing-plans/SKILL.md" 'immediately invokes `simplepower:subagent-driven-development`' "writing-plans documents immediate invocation after approval"
require_contains "skills/writing-plans/SKILL.md" "docs/simplepower/plans" "writing-plans writes plans under docs/simplepower/plans"
require_contains_all "skills/writing-plans/SKILL.md" "writing-plans forbids non-coordinator commits" \
    "Workers" \
    "quick verifiers" \
    "must not commit"
require_contains "skills/writing-plans/SKILL.md" "quick-verifier" "writing-plans documents quick-verifier scratch refs"
require_contains "skills/writing-plans/SKILL.md" "refs/simplepower/scratch/<run-id>/" "writing-plans documents the scratch namespace"
require_not_contains "skills/writing-plans/SKILL.md" "refs/simplepower/scratch/<run-id>/plan-review/before" "writing-plans removes plan-review scratch refs"
require_not_contains "skills/writing-plans/SKILL.md" "refs/simplepower/scratch/<run-id>/review-fix/before" "writing-plans removes review-fix scratch refs"
require_contains "skills/writing-plans/SKILL.md" "scratch-ref-workflow.md" "writing-plans delegates scratch mechanics to the canonical execution reference"
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

require_contains "skills/brainstorming/SKILL.md" "Approved Path Enforcement" "brainstorming documents approved path enforcement"
require_contains "skills/brainstorming/SKILL.md" "fresh explicit approval" "brainstorming requires fresh approval for alternate paths"
require_contains "skills/brainstorming/SKILL.md" "backup plan" "brainstorming blocks backup plans"
require_contains "skills/brainstorming/SKILL.md" "escape plan" "brainstorming blocks escape plans"
require_contains_all "skills/brainstorming/SKILL.md" "brainstorming hands execution-record facts to planning" \
    "coordinator-owned execution record" \
    "two mandatory coordinator checkpoint types" \
    "bounded active-run"

require_contains "skills/writing-plans/SKILL.md" "Approved Path Enforcement" "writing-plans documents approved path enforcement"
require_contains "skills/writing-plans/SKILL.md" "docs-only substitute" "writing-plans blocks docs-only substitutes"
require_contains "skills/writing-plans/SKILL.md" "stub substitute" "writing-plans blocks stub substitutes"
require_contains "skills/writing-plans/SKILL.md" "execution-mode switch" "writing-plans blocks unapproved execution-mode switches"
require_contains "skills/writing-plans/SKILL.md" "fresh explicit approval" "writing-plans requires fresh approval for alternate paths"

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
    "Main agent" \
    "Grouped workers" \
    "cohesive" \
    "gpt-5.3-codex-spark" \
    "Do not read model assignments" \
    'fork_turns="none"'
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD keeps review compatibility settings validated but inactive" \
    "plan_review_model" \
    "validation-only during execution" \
    "review_model" \
    "review_model2" \
    "final_review_model" \
    "skip_final_review" \
    "deprecated" \
    "no-op"
require_not_contains "skills/subagent-driven-development/SKILL.md" "exactly one final review+fix agent" "SDD removes the final review agent"
require_not_contains "skills/subagent-driven-development/SKILL.md" "review-fix/before" "SDD removes the review-fix scratch anchor"
require_not_contains "skills/subagent-driven-development/SKILL.md" "secondary-review-prompt.md" "SDD removes the secondary final-review prompt"
require_not_contains "skills/subagent-driven-development/SKILL.md" "dual-mode" "SDD removes dual final review"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD keeps lifecycle, commit, and scratch-ref guardrails" \
    "Default lifecycle decision: close." \
    "written reason" \
    "No worker commits." \
    "No per-task commits." \
    "final reviewed/verified completion" \
    "must create the newest final commit when uncommitted" \
    "refs/simplepower/scratch/<run-id>/" \
    "quick-verifier/before" \
    "quick-verifier/after" \
    "scratch-ref cleanup status or cleanup commands"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD treats accepted combined approval as bounded active-run commit authorization" \
    "combined approval authorizes the two mandatory checkpoint types" \
    "bounded coordinator execution commits during the active run" \
    "without requesting another approval" \
    "do not create an empty commit" \
    "Authorization ends at final handoff"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD defines coordinator-owned execution commits" \
    "## Coordinator Execution Commits" \
    "technical-prerequisite commit" \
    "objectively cannot proceed without committed state" \
    "execution-summary commit" \
    "Convenience, history shaping" \
    "through every committed and uncommitted" \
    "separate user authorization"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD defines original-plan summary and follow-up handling" \
    "## Original Plan Execution Summary" \
    "current status and outcome" \
    "verification overview" \
    "observed branch, pre-commit HEAD" \
    "phase- or date-labeled" \
    "raw logs" \
    "audit unrelated" \
    "later material finding before final handoff reopens" \
    "without further file edits" \
    "genuinely untracked" \
    "exact omission reason"
require_not_contains "skills/subagent-driven-development/SKILL.md" "always create a separate summary commit" "SDD does not require an unconditional summary commit"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD requires coordinator final review and fixes" \
    "main agent" \
    "final diff review" \
    "in-scope fixes" \
    "final verification"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD keeps capacity-aware package queues separate from true serialization" \
    "capacity" \
    "Build the complete ready set" \
    "queued ready package" \
    "queued ready packages" \
    "do not mark them serialized merely" \
    "available slot idle" \
    "dispatch the next queued ready package into the freed slot" \
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
    "inspect, or manage scratch refs" \
    "spawn subagents" \
    "workflow skills"
require_file "skills/subagent-driven-development/quick-verifier-prompt.md" "quick verifier prompt file exists"
require_path_absent "skills/subagent-driven-development/review-fix-prompt.md" "retired review+fix prompt file is absent"
require_path_absent "skills/subagent-driven-development/secondary-review-prompt.md" "secondary final-review prompt is absent"
require_contains_all "skills/subagent-driven-development/quick-verifier-prompt.md" "quick verifier prompt keeps FAST limited-fix guardrails" \
    "FAST quick verifier" \
    "tiny typo-level" \
    "approved changed-file list" \
    "approved File Ownership/write scopes" \
    "NON_TRIVIAL_FAILURES" \
    "quick-verifier/before" \
    "coordinator-owned execution record" \
    "Do not edit it" \
    "report any plan" \
    "spawn subagents" \
    "workflow skills"
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
    "tmp_index" \
    "GIT_INDEX_FILE" \
    "git commit-tree" \
    "git update-ref" \
    "git update-ref -d" \
    "manual cleanup command"
require_contains_all "skills/subagent-driven-development/scratch-ref-workflow.md" "scratch refs survive until newest final completion" \
    "newest final reviewed/verified" \
    "completion checkpoint succeeds" \
    "technical-prerequisite" \
    "earlier execution-summary" \
    "does not trigger cleanup"
require_not_contains "skills/subagent-driven-development/scratch-ref-workflow.md" "review-fix/before" "scratch-ref workflow removes review-fix before refs"
require_not_contains "skills/subagent-driven-development/scratch-ref-workflow.md" "review-fix/after" "scratch-ref workflow removes review-fix after refs"
require_dir_absent "skills/subagent-driven-development/impl-reviewer-prompt.md" "retired inline reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/reviewer-prompt.md" "retired per-wave reviewer prompt is absent"
require_dir_absent "skills/subagent-driven-development/fixer-prompt.md" "retired per-wave fixer prompt is absent"
require_dir_absent "skills/executing-plans" "retired inline execution skill is absent"
require_contains "skills/using-simplepower/references/codex-tools.md" "independent of" "Codex tool mapping says sp-impl settings override generic same-model defaults"
require_contains "skills/using-simplepower/references/codex-tools.md" "sp-impl file-edit worker" "Codex tool mapping includes the sp-impl file-edit worker"
require_contains "skills/using-simplepower/references/codex-tools.md" "quick verifier" "Codex tool mapping includes the quick verifier"
require_contains "skills/using-simplepower/references/codex-tools.md" "Main agent" "Codex tool mapping includes direct main-agent implementation"
require_contains "skills/using-simplepower/references/codex-tools.md" "Grouped workers" "Codex tool mapping includes grouped worker implementation"
require_contains "skills/using-simplepower/references/codex-tools.md" "final_review_model" "Codex tool mapping documents the final review compatibility key"
require_contains "skills/using-simplepower/references/codex-tools.md" "deprecated" "Codex tool mapping marks review compatibility keys deprecated"
require_contains "skills/using-simplepower/references/codex-tools.md" "no-op" "Codex tool mapping marks review compatibility keys no-op"
require_not_contains "skills/using-simplepower/references/codex-tools.md" "secondary-review-prompt.md" "Codex tool mapping removes the secondary final-review prompt"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_BEST_MODEL" "Codex tool mapping documents the BEST model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_REVIEW_MODEL" "Codex tool mapping documents the REVIEW model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_PLAN_REVIEW_MODEL" "Codex tool mapping documents the plan-review model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" 'SIMPLEPOWER_REVIEW_MODEL2' "Codex tool mapping states that review_model2 has no environment variable"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_NORMAL_MODEL" "Codex tool mapping documents the NORMAL model env var"
require_contains "skills/using-simplepower/references/codex-tools.md" "SIMPLEPOWER_FAST_MODEL" "Codex tool mapping documents the FAST model env var"
require_contains_all "skills/using-simplepower/references/codex-tools.md" "Codex tool mapping rejects invalid lower-precedence TOML files" \
    "Every present TOML" \
    "file must validate in full"
require_contains "skills/using-simplepower/references/codex-tools.md" "supported non-empty" "Codex tool mapping applies the supported environment layer"
require_not_contains "skills/using-simplepower/references/codex-tools.md" "resolved_final_review_model" "Codex tool mapping removes the final review model dispatch"
require_contains "skills/using-simplepower/references/codex-tools.md" 'layer replaces only the keys it supplies.' "Codex tool mapping documents per-key overlays"
require_contains "skills/using-simplepower/references/codex-tools.md" 'from any `AGENTS.md` file.' "Codex tool mapping blocks nested AGENTS scanning"
require_contains "skills/using-simplepower/references/codex-tools.md" "refs/simplepower/scratch/<run-id>/" "Codex tool mapping documents the scratch namespace"
require_contains "skills/using-simplepower/references/codex-tools.md" "coordinator-owned" "Codex tool mapping keeps scratch refs coordinator-owned"
require_contains "skills/using-simplepower/references/codex-tools.md" "quick-verifier" "Codex tool mapping scopes scratch refs to the quick verifier"
require_contains "skills/using-simplepower/references/codex-tools.md" "not branches, accepted checkpoints, pushed refs, or subagent commits" "Codex tool mapping excludes branch/checkpoint/pushed/subagent semantics"
require_contains "skills/using-simplepower/references/codex-tools.md" "must not create, update, delete, inspect, or manage them" "Codex tool mapping forbids worker scratch ref ownership"
require_contains "skills/using-simplepower/references/codex-tools.md" "plan's approved FAST/NORMAL/BEST allocation" "Codex tool mapping keeps sp-impl dispatch on the three implementation tiers"
require_not_contains "skills/using-simplepower/references/codex-tools.md" "Dispatch one" "Codex tool mapping removes final review dispatch routing"
require_contains "skills/using-simplepower/references/codex-tools.md" '| FAST | `fast_model` | `SIMPLEPOWER_FAST_MODEL` | `gpt-5.3-codex-spark-xhigh` |' "Codex tool mapping defaults FAST to Spark xhigh"
require_contains "skills/using-simplepower/references/codex-tools.md" "quick verifier" "Codex tool mapping includes the quick verifier"
require_contains "skills/using-simplepower/references/codex-tools.md" "optional plan reviewer" "Codex tool mapping includes optional plan review"
require_contains "skills/using-simplepower/references/codex-tools.md" "plan-document-reviewer-prompt.md" "Codex tool mapping points at the plan-review prompt"
require_contains "skills/using-simplepower/references/codex-tools.md" "Default resolves to Spark xhigh" "Codex tool mapping describes the quick verifier FAST default"
require_contains_all "skills/using-simplepower/references/codex-tools.md" "Codex tool mapping documents the checkpoint commit authorization exception" \
    "combined approval" \
    "two mandatory coordinator checkpoint types" \
    "objectively requires committed state" \
    "original plan's execution summary" \
    "Convenience and history-shaping commits do not qualify" \
    "request another approval" \
    "Authorization ends at final handoff" \
    "does not otherwise automatically create"
require_not_contains "skills/using-simplepower/references/codex-tools.md" "Simple Power does not automatically commit, merge, push, or open PRs." "Codex tool mapping removes the contradictory blanket no-auto-commit rule"

require_contains "tests/skill-triggering/run-all.sh" "simplepower" "skill-triggering runner is Codex-focused"

require_contains "tests/explicit-skill-requests/run-all.sh" "simplepower" "explicit skill runner is Codex-focused"

require_contains "tests/skill-triggering/prompts/approved-brainstorming-handoff.txt" "simplepower:writing-plans" "skill-triggering fixture preserves the brainstorming handoff"
require_contains "tests/skill-triggering/prompts/approved-planning-handoff.txt" "simplepower:subagent-driven-development" "skill-triggering fixture preserves the planning handoff"
require_contains "tests/skill-triggering/prompts/approved-planning-handoff.txt" "Implementation Route" "skill-triggering fixture names the approved route"
require_contains "tests/skill-triggering/prompts/approved-planning-handoff.txt" "FAST/NORMAL/BEST allocation" "skill-triggering fixture names active model allocation"

require_contains "tests/explicit-skill-requests/prompts/after-planning-flow.txt" "docs/simplepower/plans/auth-system.md" "explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/codex-suggested-it.txt" "docs/simplepower/plans/auth-system.md" "follow-up explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt" "docs/simplepower/plans/auth-system.md" "explicit skill prompt uses the Simple Power plan path"
require_contains "tests/explicit-skill-requests/prompts/action-oriented.txt" "approved adaptive route" "action-oriented prompt uses adaptive route wording"
require_contains "tests/explicit-skill-requests/prompts/action-oriented.txt" "mandatory FAST quick verifier" "action-oriented prompt requires FAST quick verification"
require_contains "tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt" "Main agent route" "SDD prompt defines main-agent behavior"
require_contains "tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt" "Grouped workers route" "SDD prompt defines grouped-worker behavior"

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
    skills/subagent-driven-development/SKILL.md
    skills/using-simplepower/references/codex-tools.md
    tests/skill-triggering/prompts/approved-planning-handoff.txt
    tests/explicit-skill-requests/prompts/action-oriented.txt
    tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt
)
stale_model_tier_language='three configurable model[[:space:]]+tiers|four mandatory model[[:space:]]+tiers|FAST[/]NORMAL[/]BEST[/]REVIEW model allocation|BEST-tier plan reviewer|BEST-tier review\+fix|one BEST-tier review\+fix agent|one BEST-tier review\+fix pass|plan reviewer and final review\+fix agent use BEST|final review\+fix agent uses BEST|Always dispatch the review\+fix agent with BEST|review\+fix agent with BEST'
require_no_active_match "$stale_model_tier_language" "active model docs do not retain stale BEST-for-review routing language" "${active_model_tier_paths[@]}"
retired_reviewer_dispatch_language='review-fix-prompt[.]md|secondary-review-prompt[.]md|spawn_agent.*review[+]fix|plan-review/before|plan-review/after|review-fix/before|review-fix/after'
require_no_active_match "$retired_reviewer_dispatch_language" "active workflow files do not reference retired final/secondary reviewers or review scratch refs" "${active_plan_first_paths[@]}"
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
require_contains "skills/writing-plans/SKILL.md" 'fork_turns="none"' "writing-plans isolates every retained dispatch"
require_no_active_match "1% chance|Might any skill apply|task matches a skill|Ask for work that matches a skill description" "active docs no longer allow broad semantic skill triggering" skills README.md docs/README.codex.md docs/testing.md
require_no_active_match "^description: Use when|MUST use this before any creative work|Use when implementing any feature or bugfix" "active skill frontmatter avoids broad trigger descriptions" skills/*/SKILL.md
require_contains "skills/writing-plans/SKILL.md" "No per-task commits" "writing-plans still forbids per-task commits"
require_contains "skills/subagent-driven-development/SKILL.md" "No per-task commits" "SDD still forbids per-task commits"
require_contains "AGENTS.md" "Do not add worker-owned or per-task commit requirements" "AGENTS forbids worker-owned and per-task commits"
require_contains "AGENTS.md" "Coordinator-owned commits require accepted workflow authorization" "AGENTS bounds coordinator commit authorization"
require_contains "skills/writing-plans/SKILL.md" "No worker commits or per-task commits" "writing-plans clarifies the worker commit restriction"
require_contains_all "skills/subagent-driven-development/SKILL.md" "SDD clarifies the worker commit restriction" \
    "No worker commits." \
    "No per-task commits."
unbounded_execution_commit_language='always create a separate summary commit|workers may commit|per-task commits are allowed|commit for convenience|authorization continues after final handoff|audit every repository subsystem|paste full raw logs'
require_no_active_match "$unbounded_execution_commit_language" "active workflow files reject unbounded execution-summary and commit behavior" "${active_plan_first_paths[@]}"
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
