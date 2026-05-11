# GitHub Backed Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Reset Simple Power to version `1.0.0`, publish it through a `garyfpga/codex-plugins` GitHub-backed Codex marketplace, and update user-facing install docs and marketplace sync tooling.

**Design Summary:** The approved design keeps `garyfpga/simplepower` as the source repo and uses a separate marketplace repo, `garyfpga/codex-plugins`, with Simple Power packaged under `plugins/simplepower/` and indexed by `.agents/plugins/marketplace.json`. The README will remove the manual clone/symlink install path, document marketplace install/update, and add back `SIMPLEPOWER_BEST_MODEL` and `SIMPLEPOWER_FAST_MODEL`. The sync tooling will stop targeting `prime-radiant-inc/openai-codex-plugins`, target `garyfpga/codex-plugins`, preserve/create marketplace metadata, and keep tests aligned.

**Architecture:** Local source files remain authoritative. `scripts/sync-to-codex-plugin.sh` copies plugin-safe tracked source content into the marketplace repo path and ensures marketplace metadata exists or is preserved. The Interface Contract below lets documentation, versioning, sync-script, and test workers proceed in aggregate parallel without waiting for each other's file edits.

**Tech Stack:** Markdown docs, Codex plugin manifest JSON, npm package JSON, Bash sync/test scripts, GitHub CLI, Git.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

### Marketplace Identity

- Source repository: `garyfpga/simplepower`.
- Marketplace repository: `garyfpga/codex-plugins`.
- Marketplace plugin path: `plugins/simplepower`.
- Marketplace index path: `.agents/plugins/marketplace.json`.
- Plugin name remains `simplepower`; display name remains `Simple Power`.
- The marketplace entry for Simple Power must use:

```json
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
```

- If the marketplace index does not exist during bootstrap, create it with:

```json
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
```

- If the marketplace index already exists, preserve its top-level metadata and unrelated plugin entries, then add or update only the `simplepower` entry to match the contract above.
- The sync script must not depend on `prime-radiant-inc/openai-codex-plugins`.

### Version Contract

- The release version is `1.0.0`.
- The version must be set in:
  - `.codex-plugin/plugin.json` field `version`
  - `package.json` field `version`
- `.version-bump.json` already owns these two paths and should remain aligned unless implementation discovers drift.
- `scripts/bump-version.sh --check` must report both declared files in sync at `1.0.0`.

### README Contract

- `README.md` documents marketplace install as the only install path.
- `README.md` does not document the old clone/symlink manual install flow.
- Install/update commands are:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin marketplace upgrade
```

- The README documents:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"
```

- The README explains that model tier values are parsed as `<model>-<reasoning_effort>`, using the final dash-delimited segment as `reasoning_effort` and the preceding string as `model`.
- README fork attribution to Superpowers and Prime Radiant remains present.

### Script Contract

- `scripts/sync-to-codex-plugin.sh` defaults to:

```bash
FORK="garyfpga/codex-plugins"
DEFAULT_BASE="main"
DEST_REL="plugins/simplepower"
MARKETPLACE_REL=".agents/plugins/marketplace.json"
```

- Dry run previews do not modify the destination repo.
- Bootstrap mode creates `plugins/simplepower/` when missing and ensures the marketplace index includes the Simple Power entry.
- Normal mode requires `plugins/simplepower/` to exist on the destination base, then updates plugin files and the marketplace index.
- `--local PATH` continues to support testing against an existing local marketplace checkout.
- PR titles and bodies reference `garyfpga/codex-plugins` as the marketplace repo and the upstream source repo as `garyfpga/simplepower`.
- The script continues excluding source-only files/directories from the packaged plugin, including top-level `.git`, `.github`, docs, tests, scripts, and package metadata.

### GitHub Marketplace Creation Contract

- After local implementation is approved and verified, the coordinator creates `garyfpga/codex-plugins` if it does not exist, using GitHub CLI.
- The marketplace repo is public.
- If the repo already exists, the coordinator uses the existing repo rather than recreating it.
- The first publish uses `scripts/sync-to-codex-plugin.sh --bootstrap`.
- Later publishes use `scripts/sync-to-codex-plugin.sh`.

### Verification Contract

- Local verification commands:

```bash
timeout 30s bash scripts/bump-version.sh --check
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check
```

- Focused search checks:

```bash
! timeout 30s rg -n "prime-radiant-inc/openai-codex-plugins" README.md docs/README.codex.md scripts tests .codex-plugin package.json
! timeout 30s rg -n "git clone https://github.com/garyfpga/simplepower.git|ln -s ~/.codex/simplepower/skills|~/.agents/skills/simplepower" README.md
```

- The first search should return no active script/doc target references. Historical plan files under `docs/simplepower/plans/` may contain old references and are not part of the active check.
- The second search should return no matches in `README.md`.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---:|---|---|
| `docs/simplepower/plans/2026-05-12-github-backed-marketplace.md` | Coordinator | create | Authoritative implementation plan | Written before implementation tasks; no worker edits unless review+fix finds a plan mismatch before approval |
| `.codex-plugin/plugin.json` | Task 1 | modify | Set plugin version to `1.0.0`; keep metadata coherent | Isolated JSON metadata |
| `package.json` | Task 1 | modify | Set package version to `1.0.0` | Isolated JSON metadata |
| `README.md` | Task 2 | modify | Replace manual install with marketplace install, add update and env var docs | Documentation-only; do not edit from other tasks |
| `docs/README.codex.md` | Task 2 | modify | Align Codex install guide with marketplace install and env vars | Documentation-only; same owner as README to avoid duplicated wording drift |
| `.codex/INSTALL.md` | Task 2 | modify | Align bundled install guide with marketplace install only | Documentation-only; same owner as README |
| `scripts/sync-to-codex-plugin.sh` | Task 3 | modify | Retarget marketplace repo, generate/preserve marketplace index, update help/PR text | Script owner only |
| `tests/codex-plugin-sync/test-sync-to-codex-plugin.sh` | Task 4 | modify | Update sync tests for new target and marketplace index behavior | Test owner only |
| `tests/simplepower-static/run-tests.sh` | Task 5 | modify | Add active-doc/static assertions for marketplace install, env vars, version, and retired manual install | Test owner only |
| `docs/testing.md` | Task 5 | modify | Update testing docs if test names/coverage wording changes | Same owner as static test doc wording |
| `garyfpga/codex-plugins` remote repository | Coordinator | create/generated | Public GitHub-backed marketplace repo, bootstrapped after local verification | External side effect; coordinator only, after user-approved plan and local checks |
| `garyfpga/codex-plugins/plugins/simplepower/` | Coordinator | generated | Packaged Simple Power plugin produced by the approved bootstrap sync | Remote generated path inside the marketplace repo; coordinator only |
| `garyfpga/codex-plugins/.agents/plugins/marketplace.json` | Coordinator | generated | Marketplace index created or updated by the approved bootstrap sync | Remote generated path inside the marketplace repo; coordinator only |

## Implementation Tasks

### Task 1: Reset Version Metadata

**Goal:** Change Simple Power release metadata from `5.0.7` to `1.0.0`.

**Contract inputs:** Version Contract; Verification Contract.

**Serialization required:** No. JSON version fields are independent of docs, script, and test implementation.

**Write scope:** `.codex-plugin/plugin.json`, `package.json`.

**Parallel:** Yes, compatible with Tasks 2, 3, 4, and 5.

**Risk:** Low, because the change is localized and covered by `scripts/bump-version.sh --check`.

**Model tier:** FAST, resolved default `gpt-5.4-mini` with `high` effort.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:**

- Set `.codex-plugin/plugin.json` `version` to `1.0.0`.
- Set `package.json` `version` to `1.0.0`.
- Do not change plugin name, repository, homepage, author, skills path, assets, or interface text unless required by JSON formatting.

**Implementation steps:**

1. Run `timeout 30s bash scripts/bump-version.sh 1.0.0`.
2. Inspect the diff for `.codex-plugin/plugin.json` and `package.json`.
3. Confirm no unrelated version strings are modified.

**Verification commands:**

```bash
timeout 30s bash scripts/bump-version.sh --check
timeout 30s git diff -- .codex-plugin/plugin.json package.json
```

**Completion report requirements:** List changed files, commands run, results, and any version drift risk.

### Task 2: Update Active Install Documentation

**Goal:** Make marketplace install the only documented install path and restore model allocation environment variable docs.

**Contract inputs:** Marketplace Identity; README Contract; GitHub Marketplace Creation Contract.

**Serialization required:** No. Documentation can rely on the approved marketplace identity and does not need script edits to land first.

**Write scope:** `README.md`, `docs/README.codex.md`, `.codex/INSTALL.md`.

**Parallel:** Yes, compatible with Tasks 1, 3, 4, and 5.

**Risk:** Medium, because user-facing install wording must be consistent across active docs and must not retain the old manual flow.

**Model tier:** BEST, resolved default `gpt-5.5` with `high` effort.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:**

- In `README.md`, replace the clone/symlink install section with marketplace install and update instructions.
- Add a model allocation section to `README.md` documenting `SIMPLEPOWER_BEST_MODEL` and `SIMPLEPOWER_FAST_MODEL`.
- In `docs/README.codex.md` and `.codex/INSTALL.md`, align installation guidance with the marketplace path and remove instructions that present manual clone/symlink install as the normal active path.
- Preserve fork attribution to Superpowers, Prime Radiant, and the Codex-only positioning.

**Implementation steps:**

1. Edit `README.md` `## Installation` to show:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin marketplace upgrade
```

2. Add a brief update note that users can pull marketplace updates with `codex plugin marketplace upgrade`.
3. Add a model allocation section with:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"
```

4. Explain `<model>-<reasoning_effort>` parsing using `gpt-5.4-mini-high` as the example.
5. Update `docs/README.codex.md` and `.codex/INSTALL.md` to stop saying there is no marketplace step and to stop documenting clone/symlink install as the active install flow.

**Verification commands:**

```bash
timeout 30s rg -n "codex plugin marketplace add garyfpga/codex-plugins|SIMPLEPOWER_BEST_MODEL|SIMPLEPOWER_FAST_MODEL" README.md docs/README.codex.md .codex/INSTALL.md
timeout 30s rg -n "codex plugin marketplace add garyfpga/codex-plugins" README.md
timeout 30s rg -n "codex plugin marketplace add garyfpga/codex-plugins" docs/README.codex.md
timeout 30s rg -n "codex plugin marketplace add garyfpga/codex-plugins" .codex/INSTALL.md
timeout 30s rg -n "SIMPLEPOWER_BEST_MODEL|SIMPLEPOWER_FAST_MODEL" README.md
! timeout 30s rg -n "git clone https://github.com/garyfpga/simplepower.git|ln -s ~/.codex/simplepower/skills|there is no marketplace step" README.md docs/README.codex.md .codex/INSTALL.md
timeout 30s git diff -- README.md docs/README.codex.md .codex/INSTALL.md
```

The second command should return no active install-flow matches.

**Completion report requirements:** List changed files, commands run, results, and any wording ambiguity.

### Task 3: Retarget Sync Script and Marketplace Metadata

**Goal:** Make `scripts/sync-to-codex-plugin.sh` publish Simple Power into `garyfpga/codex-plugins` and maintain `.agents/plugins/marketplace.json`.

**Contract inputs:** Marketplace Identity; Script Contract; GitHub Marketplace Creation Contract.

**Serialization required:** No. Script behavior is defined by the Interface Contract and tests can be updated in parallel.

**Write scope:** `scripts/sync-to-codex-plugin.sh`.

**Parallel:** Yes, compatible with Tasks 1, 2, 4, and 5.

**Risk:** High, because the script performs external repo sync, branch creation, push, and PR creation.

**Model tier:** BEST, resolved default `gpt-5.5` with `high` effort.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:**

- Replace the default marketplace target with `garyfpga/codex-plugins`.
- Add `MARKETPLACE_REL=".agents/plugins/marketplace.json"`.
- Update comments, help text, clone directory naming, preview output, PR body, and commit messages to refer to a marketplace repo rather than Prime Radiant or OpenAI plugin fork.
- Add logic to ensure the marketplace index exists and includes the Simple Power entry during preview/apply.
- Preserve existing local checkout support, dry-run safety, dirty destination protection, bootstrap behavior, and existing source excludes.

**Implementation steps:**

1. Change `FORK` to `garyfpga/codex-plugins`.
2. Add functions that use `python3` JSON parsing to create/update `.agents/plugins/marketplace.json`.
3. During preview, apply the marketplace index update in the preview checkout before status/dry-run reporting without modifying the real destination.
4. During apply, update the real destination marketplace index before `git add`.
5. Ensure `git add` includes both `$DEST_REL` and `$MARKETPLACE_REL`.
6. Update no-op detection to include both `$DEST_REL` and `$MARKETPLACE_REL`.
7. Update status/diff messaging to describe both plugin files and marketplace metadata.

**Verification commands:**

```bash
timeout 30s bash -n scripts/sync-to-codex-plugin.sh
timeout 30s rg -n "garyfpga/codex-plugins|MARKETPLACE_REL|marketplace.json" scripts/sync-to-codex-plugin.sh
! timeout 30s rg -n "prime-radiant-inc/openai-codex-plugins|openai-codex-plugins" scripts/sync-to-codex-plugin.sh
```

The final command should return no active target references.

**Completion report requirements:** List changed files, commands run, results, and any external publishing risk.

### Task 4: Update Codex Plugin Sync Tests

**Goal:** Verify the retargeted sync script and marketplace index behavior.

**Contract inputs:** Marketplace Identity; Script Contract; Verification Contract.

**Serialization required:** No. Tests target the approved script contract and can be written in parallel with script changes.

**Write scope:** `tests/codex-plugin-sync/test-sync-to-codex-plugin.sh`.

**Parallel:** Yes, compatible with Tasks 1, 2, 3, and 5.

**Risk:** Medium, because tests must model both bootstrap and existing marketplace index cases without depending on live GitHub.

**Model tier:** BEST, resolved default `gpt-5.5` with `high` effort.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:**

- Update assertions that reference the destination repo name or PR target to expect `garyfpga/codex-plugins`.
- Add fixture support for `.agents/plugins/marketplace.json`.
- Verify bootstrap preview does not write real destination files.
- Verify bootstrap/apply creates or updates the marketplace index with the Simple Power entry.
- Verify existing marketplace metadata and unrelated plugin entries are preserved.
- Verify no-op detection includes marketplace metadata.

**Implementation steps:**

1. Update fixture destination repo naming and expected output strings.
2. Add helper assertions for JSON fields using `python3`.
3. Add or extend tests so `--bootstrap --local` creates `.agents/plugins/marketplace.json` on apply.
4. Add a fixture with an existing marketplace index that includes a different plugin and custom `interface.displayName`, then verify both are preserved after sync.
5. Keep existing dirty destination and no-op protections.

**Verification commands:**

```bash
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 30s git diff -- tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
```

**Completion report requirements:** List changed files, commands run, results, and any untested edge case.

### Task 5: Update Static Tests and Testing Docs

**Goal:** Make repository static checks enforce the new install/version/marketplace expectations.

**Contract inputs:** README Contract; Version Contract; Verification Contract.

**Serialization required:** No. Static assertions can be written from the approved contracts.

**Write scope:** `tests/simplepower-static/run-tests.sh`, `docs/testing.md`.

**Parallel:** Yes, compatible with Tasks 1, 2, 3, and 4.

**Risk:** Medium, because static tests should enforce active docs without flagging historical plan files.

**Model tier:** FAST, resolved default `gpt-5.4-mini` with `high` effort.

**Worker role:** `sp-impl`.

**Outputs and responsibilities:**

- Add static assertions that `README.md` contains marketplace install, update, and env var docs.
- Add static assertions that `README.md` does not contain manual clone/symlink install.
- Add static assertions that active script/docs no longer target `prime-radiant-inc/openai-codex-plugins`.
- Add static assertions that manifest/package version declarations are `1.0.0` or rely on `scripts/bump-version.sh --check` if static test style already has a helper.
- Update `docs/testing.md` if needed to mention marketplace metadata coverage.

**Implementation steps:**

1. Inspect existing helper functions in `tests/simplepower-static/run-tests.sh`.
2. Add assertions scoped to active files only; exclude historical plan docs from retired-reference scans.
3. Keep assertion descriptions concrete so failures explain the expected install behavior.
4. Update `docs/testing.md` coverage wording for the sync test if marketplace metadata is now verified.

**Verification commands:**

```bash
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff -- tests/simplepower-static/run-tests.sh docs/testing.md
```

**Completion report requirements:** List changed files, commands run, results, and any false-positive risk.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---|---|---|---|
| Task 1: Reset Version Metadata | `sp-impl` | FAST | `gpt-5.4-mini` | high | Localized JSON version change with direct verification |
| Task 2: Update Active Install Documentation | `sp-impl` | BEST | `gpt-5.5` | high | User-facing install and model allocation docs must be precise across active docs |
| Task 3: Retarget Sync Script and Marketplace Metadata | `sp-impl` | BEST | `gpt-5.5` | high | External publishing script has high blast radius and JSON metadata behavior |
| Task 4: Update Codex Plugin Sync Tests | `sp-impl` | BEST | `gpt-5.5` | high | Tests must accurately model bootstrap, preservation, and no-op behavior |
| Task 5: Update Static Tests and Testing Docs | `sp-impl` | FAST | `gpt-5.4-mini` | high | Focused test/documentation assertions against approved contracts |
| Plan reviewer | plan reviewer | BEST | `gpt-5.5` | high | Required by writing-plans workflow |
| Quick verifier | quick verifier | fixed | `gpt-5.3-codex-spark` | high | Required quick verification role |
| Final review+fix | review+fix agent | BEST | `gpt-5.5` | high | Whole-implementation review and fixes after quick verification |

## Plan Review

Self-review checklist:

- Design Summary captures the approved separate marketplace repo, version reset, README install/env vars, script retargeting, and tests.
- Interface Contract lists concrete repository names, file paths, marketplace JSON shape, script defaults, version fields, docs commands, and verification commands.
- File Ownership assigns every planned local file and the external marketplace repo side effect to exactly one owner.
- Task allocation maps every requirement to a task with `Contract inputs` and `Serialization required`.
- Aggregate parallel readiness is present: Tasks 1-5 use non-overlapping write scopes and rely on the Interface Contract.
- Visual aids are omitted because they do not reduce ambiguity for this packaging/docs/script change.
- Model allocation uses FAST only for localized version/static-test work and BEST for docs, script, sync tests, reviewer, and final review+fix.
- Review allocation includes one BEST-tier plan reviewer and one BEST-tier final review+fix agent.
- Commit policy defines exactly three future coordinator checkpoints and forbids worker/reviewer/verifier commits.
- Verification commands are concrete and use `timeout`.
- Approved path enforcement does not authorize alternate marketplaces, skipped verification, docs-only substitutes, or publishing without the approved path.

After this self-review, dispatch a BEST-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md` with this plan path and the approved brainstorming design context.

## Quick Verification

The quick verifier runs after all file-edit workers complete and before the coordinator creates the quick-verified implementation checkpoint. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

Quick verifier scope: it may fix only tiny typo-level errors discovered while running the quick checks. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

Quick verification commands:

```bash
timeout 30s bash scripts/bump-version.sh --check
timeout 30s bash -n scripts/sync-to-codex-plugin.sh
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check
```

Expected result: all commands exit 0. Failure means the coordinator must resolve the issue before creating the quick-verified implementation checkpoint.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one BEST-tier review+fix agent. The agent reviews and fixes the whole implementation against this accepted plan, the Interface Contract, File Ownership, approved path enforcement, aggregate parallel dispatch semantics, and verification requirements.

The review+fix agent may edit files within the approved File Ownership when fixing issues it finds. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval. It must not commit.

## Commit Checkpoints

1. Accepted plan checkpoint: after the user approves the reviewed plan and model/task allocation.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No individual task may run `git commit`.

## Context-Size Handoff

The saved plan is the handoff artifact. Do not write a project-local implementation handoff JSON artifact.

After the user approves the reviewed plan and model/task allocation and the coordinator creates the accepted plan checkpoint commit, read `skills/writing-plans/current-session-context.md`. Measure the current coordinator session context pct in the main agent using `CODEX_THREAD_ID` and the Codex JSONL helper. Do not spawn a subagent for this measurement.

If current context measurement succeeds, use `>= 55%` to recommend fresh-context `/clear` execution and `< 55%` to recommend current-session execution. If measurement fails, run:

```bash
wc -c docs/simplepower/plans/2026-05-12-github-backed-marketplace.md
```

For fallback only, a byte count greater than `35840` recommends fresh-context `/clear`; `35840` bytes or less recommends current-session execution.

Always show both implementation handoff commands and ask the user which implementation handoff to use. Show the recommended option first: use `Run after /clear (Recommended)` first when current context is `>= 55%` or fallback plan size is greater than `35840` bytes; use `Continue in current session (Recommended)` first when current context is `< 55%` or fallback plan size is `35840` bytes or less.

Current-session handoff command:

```text
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-12-github-backed-marketplace.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

Fresh-context handoff command:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-12-github-backed-marketplace.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

## Verification

Final verification must run after the BEST-tier review+fix agent completes and before the final checkpoint commit.

Commands:

```bash
timeout 30s bash scripts/bump-version.sh --check
timeout 30s bash -n scripts/sync-to-codex-plugin.sh
timeout 120s bash tests/codex-plugin-sync/test-sync-to-codex-plugin.sh
timeout 120s bash tests/simplepower-static/run-tests.sh
timeout 30s git diff --check
! timeout 30s rg -n "prime-radiant-inc/openai-codex-plugins" README.md docs/README.codex.md .codex/INSTALL.md scripts tests .codex-plugin package.json
! timeout 30s rg -n "git clone https://github.com/garyfpga/simplepower.git|ln -s ~/.codex/simplepower/skills|~/.agents/skills/simplepower" README.md
```

Expected result:

- The first five commands exit 0.
- The `prime-radiant-inc/openai-codex-plugins` active-file search exits 0 because shell negation confirms no matches.
- The README manual-install search exits 0 because shell negation confirms no matches.

Failure means the coordinator must fix the implementation and rerun final verification. The final checkpoint commit happens only after the BEST-tier review+fix agent has completed and all final verification commands pass.

After final local verification, the coordinator may perform the approved external publish setup:

```bash
gh repo view garyfpga/codex-plugins >/dev/null 2>&1 || gh repo create garyfpga/codex-plugins --public --description "Codex plugin marketplace for Simple Power and related plugins"
timeout 120s ./scripts/sync-to-codex-plugin.sh --bootstrap
```

If the GitHub CLI is not authenticated or the repo cannot be created, stop and report the exact blocker. Do not switch to another marketplace repository without fresh explicit user approval.
