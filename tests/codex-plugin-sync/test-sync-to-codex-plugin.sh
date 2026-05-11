#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_SCRIPT_SOURCE="$REPO_ROOT/scripts/sync-to-codex-plugin.sh"
BASH_UNDER_TEST="/bin/bash"
PACKAGE_VERSION="1.2.3"
MANIFEST_VERSION="9.8.7"
MARKETPLACE_REL=".agents/plugins/marketplace.json"
OLD_MARKETPLACE_REPO="prime-radiant-inc/openai-codex""-plugins"

FAILURES=0
TEST_ROOT=""

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    local description="$3"

    if [[ "$actual" == "$expected" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"

    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        pass "$description"
    else
        fail "$description"
        echo "    expected to find: $needle"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"

    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        fail "$description"
        echo "    did not expect to find: $needle"
    else
        pass "$description"
    fi
}

assert_matches() {
    local haystack="$1"
    local pattern="$2"
    local description="$3"

    if printf '%s' "$haystack" | grep -Eq -- "$pattern"; then
        pass "$description"
    else
        fail "$description"
        echo "    expected to match: $pattern"
    fi
}

assert_path_absent() {
    local path="$1"
    local description="$2"

    if [[ ! -e "$path" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    did not expect path to exist: $path"
    fi
}

assert_branch_absent() {
    local repo="$1"
    local pattern="$2"
    local description="$3"
    local branches

    branches="$(git -C "$repo" branch --list "$pattern")"

    if [[ -z "$branches" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "    did not expect matching branches:"
        echo "$branches" | sed 's/^/      /'
    fi
}

assert_current_branch() {
    local repo="$1"
    local expected="$2"
    local description="$3"
    local actual

    actual="$(git -C "$repo" branch --show-current)"
    assert_equals "$actual" "$expected" "$description"
}

assert_file_equals() {
    local path="$1"
    local expected="$2"
    local description="$3"
    local actual

    actual="$(cat "$path")"
    assert_equals "$actual" "$expected" "$description"
}

json_value() {
    local path="$1"
    local query="$2"

    python3 - "$path" "$query" <<'PY'
import json
import sys

path, query = sys.argv[1:3]
with open(path, encoding="utf-8") as handle:
    value = json.load(handle)

for part in query.split("."):
    if isinstance(value, list):
        if part.isdigit():
            value = value[int(part)]
        else:
            matches = [
                item for item in value
                if isinstance(item, dict) and item.get("name") == part
            ]
            if not matches:
                raise KeyError(part)
            value = matches[0]
    else:
        value = value[part]

if isinstance(value, (dict, list)):
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))
elif value is None:
    print("null")
else:
    print(value)
PY
}

assert_json_value() {
    local path="$1"
    local query="$2"
    local expected="$3"
    local description="$4"
    local actual
    local status

    set +e
    actual="$(json_value "$path" "$query")"
    status=$?
    set -e

    if [[ $status -ne 0 ]]; then
        fail "$description"
        echo "    could not read JSON query '$query' from: $path"
        echo "$actual" | sed 's/^/      /'
        return
    fi

    assert_equals "$actual" "$expected" "$description"
}

assert_marketplace_simplepower_entry() {
    local path="$1"
    local prefix="$2"

    assert_json_value "$path" "plugins.simplepower.name" "simplepower" "$prefix has Simple Power entry"
    assert_json_value "$path" "plugins.simplepower.source.source" "local" "$prefix uses local source"
    assert_json_value "$path" "plugins.simplepower.source.path" "./plugins/simplepower" "$prefix points at packaged plugin path"
    assert_json_value "$path" "plugins.simplepower.policy.installation" "AVAILABLE" "$prefix marks Simple Power available"
    assert_json_value "$path" "plugins.simplepower.policy.authentication" "ON_INSTALL" "$prefix sets install-time authentication"
    assert_json_value "$path" "plugins.simplepower.category" "Coding" "$prefix sets Coding category"
}

cleanup() {
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

configure_git_identity() {
    local repo="$1"

    git -C "$repo" config user.name "Test Bot"
    git -C "$repo" config user.email "test@example.com"
}

init_repo() {
    local repo="$1"

    git init -q -b main "$repo"
    configure_git_identity "$repo"
}

commit_fixture() {
    local repo="$1"
    local message="$2"

    git -C "$repo" commit -q -m "$message"
}

checkout_fixture_branch() {
    local repo="$1"
    local branch="$2"

    git -C "$repo" checkout -q -b "$branch"
}

add_push_remote() {
    local repo="$1"
    local remote="$2"

    git init -q --bare "$remote"
    git -C "$repo" remote add origin "$remote"
}

write_upstream_fixture() {
    local repo="$1"
    local with_pure_ignored="${2:-1}"

    mkdir -p \
        "$repo/.codex-plugin" \
        "$repo/.private-journal" \
        "$repo/assets" \
        "$repo/scripts" \
        "$repo/skills/example"

    if [[ "$with_pure_ignored" == "1" ]]; then
        mkdir -p "$repo/ignored-cache/tmp"
    fi

    cp "$SYNC_SCRIPT_SOURCE" "$repo/scripts/sync-to-codex-plugin.sh"

    cat > "$repo/package.json" <<EOF
{
  "name": "fixture-upstream",
  "version": "$PACKAGE_VERSION"
}
EOF

    cat > "$repo/.gitignore" <<'EOF'
.private-journal/
EOF

    if [[ "$with_pure_ignored" == "1" ]]; then
        cat >> "$repo/.gitignore" <<'EOF'
ignored-cache/
EOF
    fi

    cat > "$repo/.codex-plugin/plugin.json" <<EOF
{
  "name": "simplepower",
  "version": "$MANIFEST_VERSION"
}
EOF

    cat > "$repo/assets/simplepower-small.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>
EOF

    printf 'png fixture\n' > "$repo/assets/app-icon.png"

    cat > "$repo/skills/example/SKILL.md" <<'EOF'
# Example Skill

Fixture content.
EOF

    printf 'tracked keep\n' > "$repo/.private-journal/keep.txt"
    printf 'ignored leak\n' > "$repo/.private-journal/leak.txt"
    if [[ "$with_pure_ignored" == "1" ]]; then
        printf 'ignored cache state\n' > "$repo/ignored-cache/tmp/state.json"
    fi

    git -C "$repo" add \
        .codex-plugin/plugin.json \
        .gitignore \
        assets/app-icon.png \
        assets/simplepower-small.svg \
        package.json \
        scripts/sync-to-codex-plugin.sh \
        skills/example/SKILL.md
    git -C "$repo" add -f .private-journal/keep.txt

    commit_fixture "$repo" "Initial upstream fixture"
}

write_destination_fixture() {
    local repo="$1"

    mkdir -p "$repo/plugins/simplepower/skills/example"
    printf 'fixture keep\n' > "$repo/plugins/simplepower/.fixture-keep"
    cat > "$repo/plugins/simplepower/skills/example/SKILL.md" <<'EOF'
# Example Skill

Fixture content.
EOF
    git -C "$repo" add plugins/simplepower/.fixture-keep
    git -C "$repo" add plugins/simplepower/skills/example/SKILL.md

    commit_fixture "$repo" "Initial destination fixture"
}

write_synced_marketplace_index_fixture() {
    local repo="$1"

    mkdir -p "$repo/.agents/plugins"
    cat > "$repo/$MARKETPLACE_REL" <<'EOF'
{
  "name": "garyfpga-codex-plugins",
  "interface": {
    "displayName": "Simple Power Codex Plugins"
  },
  "plugins": [
    {
      "name": "simplepower",
      "source": {
        "source": "local",
        "path": "./plugins/simplepower"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Coding"
    }
  ]
}
EOF
}

write_existing_marketplace_index_fixture() {
    local repo="$1"

    mkdir -p "$repo/.agents/plugins"
    cat > "$repo/$MARKETPLACE_REL" <<'EOF'
{
  "name": "custom-marketplace",
  "interface": {
    "displayName": "Custom Plugin Shelf",
    "summary": "Preserve this metadata"
  },
  "plugins": [
    {
      "name": "other-plugin",
      "source": {
        "source": "local",
        "path": "./plugins/other-plugin"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "NONE"
      },
      "category": "Productivity"
    },
    {
      "name": "simplepower",
      "source": {
        "source": "local",
        "path": "./plugins/old-simplepower"
      },
      "policy": {
        "installation": "UNAVAILABLE",
        "authentication": "NONE"
      },
      "category": "Legacy"
    }
  ]
}
EOF
}

dirty_tracked_destination_skill() {
    local repo="$1"

    cat > "$repo/plugins/simplepower/skills/example/SKILL.md" <<'EOF'
# Example Skill

Locally modified fixture content.
EOF
}

write_synced_destination_fixture() {
    local repo="$1"

    mkdir -p \
        "$repo/plugins/simplepower/.codex-plugin" \
        "$repo/plugins/simplepower/.private-journal" \
        "$repo/plugins/simplepower/assets" \
        "$repo/plugins/simplepower/skills/example"

    cat > "$repo/plugins/simplepower/.codex-plugin/plugin.json" <<EOF
{
  "name": "simplepower",
  "version": "$MANIFEST_VERSION"
}
EOF

    cat > "$repo/plugins/simplepower/assets/simplepower-small.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>
EOF

    printf 'png fixture\n' > "$repo/plugins/simplepower/assets/app-icon.png"

    cat > "$repo/plugins/simplepower/skills/example/SKILL.md" <<'EOF'
# Example Skill

Fixture content.
EOF

    printf 'tracked keep\n' > "$repo/plugins/simplepower/.private-journal/keep.txt"
    write_synced_marketplace_index_fixture "$repo"

    git -C "$repo" add \
        "$MARKETPLACE_REL" \
        plugins/simplepower/.codex-plugin/plugin.json \
        plugins/simplepower/assets/app-icon.png \
        plugins/simplepower/assets/simplepower-small.svg \
        plugins/simplepower/skills/example/SKILL.md \
        plugins/simplepower/.private-journal/keep.txt

    commit_fixture "$repo" "Initial synced destination fixture"
}

write_stale_ignored_destination_fixture() {
    local repo="$1"

    mkdir -p "$repo/plugins/simplepower/.private-journal"
    printf 'fixture keep\n' > "$repo/plugins/simplepower/.fixture-keep"
    printf 'stale ignored leak\n' > "$repo/plugins/simplepower/.private-journal/leak.txt"
    git -C "$repo" add plugins/simplepower/.fixture-keep

    commit_fixture "$repo" "Initial stale ignored destination fixture"
}

write_fake_gh() {
    local bin_dir="$1"

    mkdir -p "$bin_dir"

    cat > "$bin_dir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
    exit 0
fi

if [[ "${1:-}" == "pr" && "${2:-}" == "create" ]]; then
    repo=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo)
                repo="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ "$repo" != "garyfpga/codex-plugins" ]]; then
        echo "unexpected PR repo: $repo" >&2
        exit 1
    fi

    echo "https://github.com/garyfpga/codex-plugins/pull/123"
    exit 0
fi

echo "unexpected gh invocation: $*" >&2
exit 1
EOF

    chmod +x "$bin_dir/gh"
}

run_preview() {
    local upstream="$1"
    local dest="$2"
    local fake_bin="$3"

    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" -n --local "$dest" 2>&1
}

run_bootstrap_preview() {
    local upstream="$1"
    local dest="$2"
    local fake_bin="$3"

    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" -n --bootstrap --local "$dest" 2>&1
}

run_bootstrap_apply() {
    local upstream="$1"
    local dest="$2"
    local fake_bin="$3"

    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" -y --bootstrap --local "$dest" 2>&1
}

run_preview_without_manifest() {
    local upstream="$1"
    local dest="$2"
    local fake_bin="$3"

    rm -f "$upstream/.codex-plugin/plugin.json"
    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" -n --local "$dest" 2>&1
}

run_preview_with_stale_ignored_destination() {
    local upstream="$1"
    local dest="$2"
    local fake_bin="$3"

    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" -n --local "$dest" 2>&1
}

run_apply() {
    local upstream="$1"
    local dest="$2"
    local fake_bin="$3"

    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" -y --local "$dest" 2>&1
}

run_help() {
    local upstream="$1"
    local fake_bin="$2"

    PATH="$fake_bin:$PATH" "$BASH_UNDER_TEST" "$upstream/scripts/sync-to-codex-plugin.sh" --help 2>&1
}

write_bootstrap_destination_fixture() {
    local repo="$1"

    printf 'bootstrap fixture\n' > "$repo/README.md"
    git -C "$repo" add README.md

    commit_fixture "$repo" "Initial bootstrap destination fixture"
}

main() {
    local upstream
    local mixed_only_upstream
    local dest
    local dest_branch
    local mixed_only_dest
    local stale_dest
    local dirty_apply_dest
    local dirty_apply_dest_branch
    local noop_apply_dest
    local noop_apply_dest_branch
    local marketplace_update_dest
    local marketplace_update_dest_branch
    local bootstrap_apply_dest
    local bootstrap_apply_dest_branch
    local fake_bin
    local bootstrap_dest
    local bootstrap_dest_branch
    local preview_status
    local preview_output
    local preview_section
    local bootstrap_status
    local bootstrap_output
    local missing_manifest_status
    local missing_manifest_output
    local mixed_only_status
    local mixed_only_output
    local stale_preview_status
    local stale_preview_output
    local stale_preview_section
    local dirty_apply_status
    local dirty_apply_output
    local noop_apply_status
    local noop_apply_output
    local marketplace_update_status
    local marketplace_update_output
    local bootstrap_apply_status
    local bootstrap_apply_output
    local help_output
    local script_source
    local dirty_skill_path
    local bootstrap_marketplace_path
    local marketplace_update_path
    local noop_marketplace_path

    echo "=== Test: sync-to-codex-plugin dry-run regression ==="

    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT

    upstream="$TEST_ROOT/upstream"
    mixed_only_upstream="$TEST_ROOT/mixed-only-upstream"
    dest="$TEST_ROOT/destination"
    mixed_only_dest="$TEST_ROOT/mixed-only-destination"
    stale_dest="$TEST_ROOT/stale-destination"
    dirty_apply_dest="$TEST_ROOT/dirty-apply-destination"
    dirty_apply_dest_branch="fixture/dirty-apply-target"
    noop_apply_dest="$TEST_ROOT/noop-apply-destination"
    noop_apply_dest_branch="fixture/noop-apply-target"
    marketplace_update_dest="$TEST_ROOT/marketplace-update-destination"
    marketplace_update_dest_branch="fixture/marketplace-update-target"
    bootstrap_apply_dest="$TEST_ROOT/bootstrap-apply-destination"
    bootstrap_apply_dest_branch="fixture/bootstrap-apply-target"
    bootstrap_dest="$TEST_ROOT/bootstrap-destination"
    dest_branch="fixture/preview-target"
    bootstrap_dest_branch="fixture/bootstrap-preview-target"
    fake_bin="$TEST_ROOT/bin"

    init_repo "$upstream"
    write_upstream_fixture "$upstream"

    init_repo "$mixed_only_upstream"
    write_upstream_fixture "$mixed_only_upstream" 0

    init_repo "$dest"
    write_destination_fixture "$dest"
    checkout_fixture_branch "$dest" "$dest_branch"
    dirty_tracked_destination_skill "$dest"

    init_repo "$mixed_only_dest"
    write_destination_fixture "$mixed_only_dest"

    init_repo "$stale_dest"
    write_stale_ignored_destination_fixture "$stale_dest"

    init_repo "$dirty_apply_dest"
    write_synced_destination_fixture "$dirty_apply_dest"
    checkout_fixture_branch "$dirty_apply_dest" "$dirty_apply_dest_branch"
    dirty_tracked_destination_skill "$dirty_apply_dest"

    init_repo "$noop_apply_dest"
    write_synced_destination_fixture "$noop_apply_dest"
    checkout_fixture_branch "$noop_apply_dest" "$noop_apply_dest_branch"

    init_repo "$marketplace_update_dest"
    write_synced_destination_fixture "$marketplace_update_dest"
    write_existing_marketplace_index_fixture "$marketplace_update_dest"
    git -C "$marketplace_update_dest" add "$MARKETPLACE_REL"
    commit_fixture "$marketplace_update_dest" "Add existing marketplace index fixture"
    add_push_remote "$marketplace_update_dest" "$TEST_ROOT/marketplace-update-origin.git"
    checkout_fixture_branch "$marketplace_update_dest" "$marketplace_update_dest_branch"

    init_repo "$bootstrap_dest"
    write_bootstrap_destination_fixture "$bootstrap_dest"
    checkout_fixture_branch "$bootstrap_dest" "$bootstrap_dest_branch"

    init_repo "$bootstrap_apply_dest"
    write_bootstrap_destination_fixture "$bootstrap_apply_dest"
    add_push_remote "$bootstrap_apply_dest" "$TEST_ROOT/bootstrap-apply-origin.git"
    checkout_fixture_branch "$bootstrap_apply_dest" "$bootstrap_apply_dest_branch"

    write_fake_gh "$fake_bin"

    # This regression test is about dry-run content, so capture the preview
    # output even if the current script exits nonzero in --local mode.
    set +e
    preview_output="$(run_preview "$upstream" "$dest" "$fake_bin")"
    preview_status=$?
    bootstrap_output="$(run_bootstrap_preview "$upstream" "$bootstrap_dest" "$fake_bin")"
    bootstrap_status=$?
    mixed_only_output="$(run_preview "$mixed_only_upstream" "$mixed_only_dest" "$fake_bin")"
    mixed_only_status=$?
    stale_preview_output="$(run_preview_with_stale_ignored_destination "$upstream" "$stale_dest" "$fake_bin")"
    stale_preview_status=$?
    dirty_apply_output="$(run_apply "$upstream" "$dirty_apply_dest" "$fake_bin")"
    dirty_apply_status=$?
    noop_apply_output="$(run_apply "$upstream" "$noop_apply_dest" "$fake_bin")"
    noop_apply_status=$?
    marketplace_update_output="$(run_apply "$upstream" "$marketplace_update_dest" "$fake_bin")"
    marketplace_update_status=$?
    bootstrap_apply_output="$(run_bootstrap_apply "$upstream" "$bootstrap_apply_dest" "$fake_bin")"
    bootstrap_apply_status=$?
    missing_manifest_output="$(run_preview_without_manifest "$upstream" "$dest" "$fake_bin")"
    missing_manifest_status=$?
    set -e
    help_output="$(run_help "$upstream" "$fake_bin")"
    script_source="$(cat "$upstream/scripts/sync-to-codex-plugin.sh")"
    preview_section="$(printf '%s\n' "$preview_output" | sed -n '/^=== Preview (rsync --dry-run) ===$/,/^=== End preview ===$/p')"
    stale_preview_section="$(printf '%s\n' "$stale_preview_output" | sed -n '/^=== Preview (rsync --dry-run) ===$/,/^=== End preview ===$/p')"
    dirty_skill_path="$dirty_apply_dest/plugins/simplepower/skills/example/SKILL.md"
    bootstrap_marketplace_path="$bootstrap_apply_dest/$MARKETPLACE_REL"
    marketplace_update_path="$marketplace_update_dest/$MARKETPLACE_REL"
    noop_marketplace_path="$noop_apply_dest/$MARKETPLACE_REL"

    echo ""
    echo "Preview assertions..."
    assert_equals "$preview_status" "0" "Preview exits successfully"
    assert_contains "$preview_output" "Version:  $MANIFEST_VERSION" "Preview uses manifest version"
    assert_contains "$preview_output" "Market:   garyfpga/codex-plugins" "Preview targets Codex plugin marketplace repository"
    assert_not_contains "$preview_output" "Version:  $PACKAGE_VERSION" "Preview does not use package.json version"
    assert_contains "$preview_section" ".codex-plugin/plugin.json" "Preview includes manifest path"
    assert_contains "$preview_section" "assets/simplepower-small.svg" "Preview includes SVG asset"
    assert_contains "$preview_section" "assets/app-icon.png" "Preview includes PNG asset"
    assert_contains "$preview_section" ".private-journal/keep.txt" "Preview includes tracked ignored file"
    assert_not_contains "$preview_section" ".private-journal/leak.txt" "Preview excludes ignored untracked file"
    assert_not_contains "$preview_section" "ignored-cache/" "Preview excludes pure ignored directories"
    assert_not_contains "$preview_output" "Overlay file (.codex-plugin/plugin.json) will be regenerated" "Preview omits overlay regeneration note"
    assert_not_contains "$preview_output" "Assets (simplepower-small.svg, app-icon.png) will be seeded from" "Preview omits assets seeding note"
    assert_contains "$preview_section" "skills/example/SKILL.md" "Preview reflects dirty tracked destination file"
    assert_current_branch "$dest" "$dest_branch" "Preview leaves destination checkout on its original branch"
    assert_branch_absent "$dest" "sync/simplepower-*" "Preview does not create sync branch in destination checkout"

    echo ""
    echo "Mixed-directory assertions..."
    assert_equals "$mixed_only_status" "0" "Mixed ignored directory preview exits successfully under /bin/bash"
    assert_contains "$mixed_only_output" ".private-journal/keep.txt" "Mixed ignored directory preview still includes tracked ignored file"
    assert_not_contains "$mixed_only_output" "ignored-cache/" "Mixed ignored directory preview has no pure ignored directory fixture"

    echo ""
    echo "Convergence assertions..."
    assert_equals "$stale_preview_status" "0" "Stale ignored destination preview exits successfully"
    assert_matches "$stale_preview_section" "\\*deleting +\\.private-journal/leak\\.txt" "Preview deletes stale ignored destination file"

    echo ""
    echo "Bootstrap assertions..."
    assert_equals "$bootstrap_status" "0" "Bootstrap preview exits successfully"
    assert_contains "$bootstrap_output" "Mode:     BOOTSTRAP (creating plugins/simplepower/ when absent and ensuring marketplace metadata)" "Bootstrap preview describes directory and marketplace creation"
    assert_not_contains "$bootstrap_output" "Assets:" "Bootstrap preview omits external assets path"
    assert_contains "$bootstrap_output" "Dry run only. Nothing was changed or pushed." "Bootstrap preview remains dry-run only"
    assert_path_absent "$bootstrap_dest/plugins/simplepower" "Bootstrap preview does not create destination plugin directory"
    assert_path_absent "$bootstrap_dest/$MARKETPLACE_REL" "Bootstrap preview does not create destination marketplace index"
    assert_current_branch "$bootstrap_dest" "$bootstrap_dest_branch" "Bootstrap preview leaves destination checkout on its original branch"
    assert_branch_absent "$bootstrap_dest" "bootstrap/simplepower-*" "Bootstrap preview does not create bootstrap branch in destination checkout"

    echo ""
    echo "Apply assertions..."
    assert_equals "$dirty_apply_status" "1" "Dirty local apply exits with failure"
    assert_contains "$dirty_apply_output" "ERROR: local checkout has uncommitted changes under 'plugins/simplepower'" "Dirty local apply reports protected destination path"
    assert_current_branch "$dirty_apply_dest" "$dirty_apply_dest_branch" "Dirty local apply leaves destination checkout on its original branch"
    assert_branch_absent "$dirty_apply_dest" "sync/simplepower-*" "Dirty local apply does not create sync branch in destination checkout"
    assert_file_equals "$dirty_skill_path" "# Example Skill

Locally modified fixture content." "Dirty local apply preserves tracked working-tree file content"
    assert_equals "$noop_apply_status" "0" "Clean no-op local apply exits successfully"
    assert_contains "$noop_apply_output" "No changes — plugin files and marketplace metadata were already in sync" "Clean no-op local apply reports no changes"
    assert_current_branch "$noop_apply_dest" "$noop_apply_dest_branch" "Clean no-op local apply leaves destination checkout on its original branch"
    assert_branch_absent "$noop_apply_dest" "sync/simplepower-*" "Clean no-op local apply does not create sync branch in destination checkout"
    assert_marketplace_simplepower_entry "$noop_marketplace_path" "Clean no-op marketplace index"

    echo ""
    echo "Bootstrap apply marketplace assertions..."
    assert_equals "$bootstrap_apply_status" "0" "Bootstrap local apply exits successfully"
    assert_contains "$bootstrap_apply_output" "Market:   garyfpga/codex-plugins" "Bootstrap local apply targets Codex plugin marketplace repository"
    assert_contains "$bootstrap_apply_output" "PR opened: https://github.com/garyfpga/codex-plugins/pull/123" "Bootstrap local apply opens PR against marketplace repository"
    assert_json_value "$bootstrap_marketplace_path" "name" "garyfpga-codex-plugins" "Bootstrap local apply creates marketplace root name"
    assert_json_value "$bootstrap_marketplace_path" "interface.displayName" "Simple Power Codex Plugins" "Bootstrap local apply creates marketplace display name"
    assert_marketplace_simplepower_entry "$bootstrap_marketplace_path" "Bootstrap local apply marketplace index"

    echo ""
    echo "Marketplace preservation assertions..."
    assert_equals "$marketplace_update_status" "0" "Marketplace metadata-only local apply exits successfully"
    assert_not_contains "$marketplace_update_output" "No changes — plugin files and marketplace metadata were already in sync" "Marketplace metadata changes prevent false no-op"
    assert_contains "$marketplace_update_output" "PR opened: https://github.com/garyfpga/codex-plugins/pull/123" "Marketplace metadata update opens PR against marketplace repository"
    assert_json_value "$marketplace_update_path" "name" "custom-marketplace" "Marketplace update preserves root name"
    assert_json_value "$marketplace_update_path" "interface.displayName" "Custom Plugin Shelf" "Marketplace update preserves custom display name"
    assert_json_value "$marketplace_update_path" "interface.summary" "Preserve this metadata" "Marketplace update preserves extra interface metadata"
    assert_json_value "$marketplace_update_path" "plugins.other-plugin.source.path" "./plugins/other-plugin" "Marketplace update preserves unrelated plugin source"
    assert_json_value "$marketplace_update_path" "plugins.other-plugin.policy.authentication" "NONE" "Marketplace update preserves unrelated plugin policy"
    assert_marketplace_simplepower_entry "$marketplace_update_path" "Marketplace update"

    echo ""
    echo "Missing manifest assertions..."
    assert_equals "$missing_manifest_status" "1" "Missing manifest exits with failure"
    assert_contains "$missing_manifest_output" "ERROR: committed Codex manifest missing at" "Missing manifest reports committed manifest path"

    echo ""
    echo "Help assertions..."
    assert_not_contains "$help_output" "--assets-src" "Help omits --assets-src"

    echo ""
    echo "Source assertions..."
    assert_contains "$script_source" 'FORK="garyfpga/codex-plugins"' "Source targets Codex plugin marketplace repository"
    assert_contains "$script_source" 'MARKETPLACE_REL=".agents/plugins/marketplace.json"' "Source declares marketplace index path"
    assert_not_contains "$script_source" "$OLD_MARKETPLACE_REPO" "Source drops old destination repository"
    assert_not_contains "$script_source" "regenerated inline" "Source drops regenerated inline phrasing"
    assert_not_contains "$script_source" "Brand Assets directory" "Source drops Brand Assets directory phrasing"
    assert_not_contains "$script_source" "--assets-src" "Source drops --assets-src"

    if [[ $FAILURES -ne 0 ]]; then
        echo ""
        echo "FAILED: $FAILURES assertion(s) failed."
        exit 1
    fi

    echo ""
    echo "PASS"
}

main "$@"
