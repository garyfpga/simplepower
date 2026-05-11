# RO Skill And README Positioning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Move the personal `ro` skill into Simple Power as `simplepower:ro`, remove the old standalone `~/.codex` copy, and update the README to explain how to use Simple Power and how it differs from upstream Superpowers.

**Design Summary:** Add `skills/ro/` to Simple Power using the current personal read-only skill behavior, remove tracked `skills/ro` files from `/home/gary/.codex`, and rewrite the README positioning in a humble, practical tone. The README must teach the three most common usage paths in a table with example prompts: feature work via `simplepower:brainstorming` -> `simplepower:writing-plans` -> `simplepower:subagent-driven-development`, debugging via `simplepower:systematic-debugging`, and read-only code discussion via `simplepower:ro`. It must also include a respectful "Simple Power vs Superpowers" section with embedded HTML flow diagrams comparing the broader Superpowers flow to Simple Power's Codex-only aggregate-parallel flow. Mention Codex-only scope, Codex Pro subscribers, aggressive subagent parallelism, configurable `SIMPLEPOWER_BEST_MODEL` / `SIMPLEPOWER_FAST_MODEL`, and the pragmatic philosophy of getting useful work done quickly without insulting Superpowers.

**Architecture:** This is a documentation and skill-packaging change across two git repositories. The Interface Contract below supplies the exact skill behavior, README messaging constraints, comparison facts, and two-repo git boundaries so the Simple Power repo updates and `/home/gary/.codex` cleanup can proceed in aggregate parallel without relying on another worker's uncommitted changes.

**Tech Stack:** Markdown README, Codex skill `SKILL.md` frontmatter, YAML agent metadata, JSON plugin metadata, git.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Because this approved work spans `/home/gary/git/simplepower` and `/home/gary/.codex`, a checkpoint may create one scoped commit in each repository that has in-scope changes at that checkpoint. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

- **IC-1 Simple Power `ro` skill identity:** Simple Power exposes a skill at `skills/ro/SKILL.md` with frontmatter `name: ro`. Users invoke it as `simplepower:ro` because the Simple Power plugin exposes repo skills under the `simplepower:*` namespace. The skill is explicit-invocation only.
- **IC-2 Simple Power `ro` activation:** Activate only when the user explicitly invokes `simplepower:ro` or asks to use the Simple Power `ro`/read-only skill. Keep `simplepower:ro` active for the current task or discussion until the user explicitly disables it or asks for implementation outside read-only mode. When RO first needs a temp artifact, announce the active instance id and temp root.
- **IC-3 Simple Power `ro` write rules:** `simplepower:ro` is a read-only code discussion mode. It may read/search files, inspect git history, run existing commands, and create session-scoped temporary artifacts under `<repo>/.codex-ro/<instance-id>/` with a manifest. It must never edit, overwrite, rename, delete, format, migrate, or code-generate over existing repo files. It must not use `apply_patch` against existing files and must not run commands whose purpose is to modify existing repo files. Before writing a path, it must verify the path does not already exist unless the path is already recorded in the current RO manifest. If the user asks for a code change while in RO mode, it should provide a proposed patch, diff, or explanation instead of applying changes. If a command unexpectedly modifies existing repo files, stop, report what changed, and do not try to revert without explicit user confirmation.
- **IC-4 Simple Power `ro` allowed actions:** The skill may read and search files, configs, schemas, tests, docs, and git history; run existing files, tests, builds, checks, and scripts when useful for discussion; create temp scripts, fixtures, notes, logs, or command outputs under the RO temp root; execute temp scripts from the RO temp root; and write cache/build outputs only when they are normal side effects of a command and are not repo-tracked source changes.
- **IC-5 Temp artifact contract:** The RO temp root is `<repo>/.codex-ro/<instance-id>/`. The instance id uses `$CODEX_THREAD_ID` when available, otherwise `YYYYMMDD-HHMMSS-<short-random>`. The manifest path is `<repo>/.codex-ro/<instance-id>/manifest.json`. Create the manifest before or with the first temp artifact. The manifest must contain `instance_id`, `repo_root`, `created_at`, and an `artifacts` array whose entries include `path`, `kind`, `purpose`, `created_at`, and `last_touched_at`. Artifact `kind` values include `script`, `fixture`, `note`, `log`, `output`, or `other`. When adding or editing a temp artifact, update its manifest entry in the same turn. Paths may be absolute or repo-relative, but use one style consistently within the manifest. Temporary files outside `.codex-ro/<instance-id>/` are allowed only when the user explicitly asks for that location, and they must be recorded in the same manifest.
- **IC-6 Cleanup contract:** When the user says "clean up", "cleanup", "revert", or asks to remove RO temp files, the skill reads the current manifest, lists the recorded artifacts that would be removed, asks for confirmation, deletes only manifest-listed artifacts after confirmation, and removes empty `.codex-ro/<instance-id>` directories. It must not use broad deletion, `git checkout`, `git reset`, or other destructive repo-wide commands for cleanup.
- **IC-7 RO communication contract:** Be explicit when a requested action is blocked by RO. Prefer concrete findings, file references, command outputs, and proposed diffs. When temp files are created, mention the temp root and manifest path briefly.
- **IC-8 RO agent metadata:** `skills/ro/agents/openai.yaml` sets `display_name: "RO"`, `short_description: "Read-only code discussion mode"`, `default_prompt: "Use simplepower:ro to discuss this code without editing existing repo files."`, and `allow_implicit_invocation: false`.
- **IC-9 Plugin metadata:** `.codex-plugin/plugin.json` remains valid JSON. It should mention read-only code discussion in `description` or `interface.longDescription`, and add discoverability keywords such as `read-only` and `ro` without changing version or install paths.
- **IC-10 README usage table:** `README.md` includes a practical usage table with columns equivalent to `Use case`, `Start with`, `Example prompt`, and `What happens`. Rows must cover feature/larger change flow, systematic debugging, and read-only code understanding.
- **IC-11 README positioning tone:** The README keeps upstream attribution to Jesse Vincent / Prime Radiant and Superpowers. It must not say Superpowers is bad, slow, wrong, obsolete, or inferior. Use language such as "alternative", "better fit for", "broader and more conservative", and "smaller Codex-only fork".
- **IC-12 README audience and philosophy:** The README states that Simple Power is Codex-only and aimed at Codex Pro subscribers who want high-throughput agent work. It may describe the philosophy as preferring a useful 90% quickly over spending much more time chasing a theoretical 95%, but must present that as a workflow preference rather than a measured benchmark.
- **IC-13 README model environment variables:** The README keeps and clearly explains `SIMPLEPOWER_BEST_MODEL` and `SIMPLEPOWER_FAST_MODEL`, including the `<model>-<reasoning_effort>` parsing rule and FAST/BEST usage.
- **IC-14 README comparison facts:** The Superpowers comparison may rely on these checked facts from upstream sources on 2026-05-10:
  - Superpowers supports multiple harnesses including Claude Code, Codex CLI/App, Factory Droid, Gemini CLI, OpenCode, Cursor, and GitHub Copilot CLI.
  - Upstream Superpowers brainstorming writes a design/spec document under `docs/superpowers/specs/`, self-reviews it, asks the user to review the written spec, and then invokes writing-plans.
  - Upstream Superpowers subagent-driven development uses a fresh subagent per task with two-stage review after each task: spec compliance then code quality.
  - Sources: https://github.com/obra/superpowers, https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md, and https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md.
- **IC-15 README embedded HTML diagrams:** The comparison section includes two embedded Markdown-compatible HTML diagrams inside `README.md`, not separate linked local HTML files. Diagram 1 shows the Superpowers-style flow. Diagram 2 shows the Simple Power flow. The diagrams support the text and must not imply skipped design, skipped verification, skipped review, or unsupported claims.
- **IC-16 `/home/gary/.codex` cleanup boundary:** Remove only the tracked standalone RO files `/home/gary/.codex/skills/ro/SKILL.md` and `/home/gary/.codex/skills/ro/agents/openai.yaml`. Do not remove unrelated files, `.codex` plugin data, generated caches, or other skills.
- **IC-17 Two-repo git boundary:** Before committing, inspect both repositories with `git status --short`. Stage only approved files in `/home/gary/git/simplepower` and only the two approved deleted files in `/home/gary/.codex`. Push `/home/gary/git/simplepower` to `origin html-plan-visual-aids` and `/home/gary/.codex` to `origin master` after final verification and final checkpoint handling.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|---|---|---:|---|---|
| `docs/simplepower/plans/2026-05-10-ro-skill-and-readme-positioning.md` | Planning coordinator | create | Authoritative implementation plan; may be edited only by coordinator during plan review before user approval. | Not part of worker write scope. |
| `skills/ro/SKILL.md` | Task A - Add Simple Power RO skill | create | Add the Simple Power read-only skill with `simplepower:ro` invocation language and current RO behavior. | No other task edits this path. |
| `skills/ro/agents/openai.yaml` | Task A - Add Simple Power RO skill | create | Add Codex/OpenAI agent metadata for the RO skill. | No other task edits this path. |
| `.codex-plugin/plugin.json` | Task A - Add Simple Power RO skill | modify | Update plugin description/keywords so read-only mode is discoverable. | No other task edits this path. |
| `README.md` | Task B - Update README positioning and usage | modify | Add usage table, Codex-only/Codex Pro positioning, environment variable explanation polish, Superpowers comparison, and embedded HTML flow diagrams. | No other task edits this path. |
| `/home/gary/.codex/skills/ro/SKILL.md` | Task C - Remove standalone Codex RO skill | delete | Remove the old tracked personal RO skill file after its behavior is represented by IC-1 through IC-7. | Absolute path in separate git repo; no other task edits this path. |
| `/home/gary/.codex/skills/ro/agents/openai.yaml` | Task C - Remove standalone Codex RO skill | delete | Remove the old tracked personal RO metadata file after its behavior is represented by IC-8. | Absolute path in separate git repo; no other task edits this path. |

## Visual Aids

`README.md` should include embedded HTML diagrams shaped like this, with final wording/style adjusted to match the README:

```html
<div>
  <table>
    <tr><th colspan="5">Superpowers-style feature flow</th></tr>
    <tr>
      <td>Brainstorm</td>
      <td>Written spec</td>
      <td>User spec review</td>
      <td>Plan</td>
      <td>Per-task implementation + review loops</td>
    </tr>
  </table>
</div>
```

```html
<div>
  <table>
    <tr><th colspan="5">Simple Power feature flow</th></tr>
    <tr>
      <td>Brainstorm</td>
      <td>Approved conversational design</td>
      <td>Plan with Interface Contract</td>
      <td>Aggregate parallel workers</td>
      <td>Quick verifier + one review/fix + final verification</td>
    </tr>
  </table>
</div>
```

The actual README diagrams should be readable in plain GitHub Markdown, use inline styles sparingly, and avoid external assets or local linked HTML files.

## Implementation Tasks

### Task A - Add Simple Power RO Skill

**Goal:** Create `simplepower:ro` in the Simple Power repo and update plugin metadata for discoverability.

**Contract inputs:** IC-1, IC-2, IC-3, IC-4, IC-5, IC-6, IC-7, IC-8, IC-9.

**Serialization required:** No. The task has a unique write scope and uses the Interface Contract instead of reading `/home/gary/.codex/skills/ro` at runtime.

**Write scope:**
- `skills/ro/SKILL.md`
- `skills/ro/agents/openai.yaml`
- `.codex-plugin/plugin.json`

**Parallel:** Yes, compatible with Task B and Task C.

**Risk:** Low. This is a localized skill packaging and JSON metadata change with concrete source behavior.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- `skills/ro/SKILL.md` contains the read-only workflow instructions and uses `simplepower:ro` in activation and communication language.
- `skills/ro/agents/openai.yaml` contains metadata from IC-8.
- `.codex-plugin/plugin.json` remains valid JSON and mentions read-only mode.

**Implementation steps:**
1. Create `skills/ro/` and `skills/ro/agents/`.
2. Create `skills/ro/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: ro
   description: Use only when the user explicitly requests simplepower:ro or asks to use the Simple Power ro/read-only skill. Provides a read-only code discussion mode where Codex may inspect, discuss, run commands, and create tracked temporary files, but must not edit existing repo files.
   ---
   ```
3. Fill the body with the sections from IC-2 through IC-7: Purpose, Activation, Write Rules, Allowed Actions, Temp Workspace, Cleanup And Revert, and Communication.
4. Create `skills/ro/agents/openai.yaml` exactly according to IC-8.
5. Update `.codex-plugin/plugin.json` without changing `version`, `skills`, repository, homepage, or license. Add `read-only` and `ro` keywords and mention read-only code discussion in the plugin long description.

**Verification commands:**
- `timeout 30s test -f skills/ro/SKILL.md`
- `timeout 30s test -f skills/ro/agents/openai.yaml`
- `timeout 30s node -e "JSON.parse(require('fs').readFileSync('.codex-plugin/plugin.json','utf8')); console.log('plugin json ok')"`
- `timeout 30s rg -n "simplepower:ro|Read-only code discussion mode|allow_implicit_invocation: false" skills/ro .codex-plugin/plugin.json`

**Completion report requirements:** List changed files, commands run, command results, and any unresolved risks. Do not commit.

### Task B - Update README Positioning And Usage

**Goal:** Make `README.md` explain how to use Simple Power, who it is for, model environment variables, and how it differs from Superpowers with embedded HTML flow diagrams.

**Contract inputs:** IC-10, IC-11, IC-12, IC-13, IC-14, IC-15.

**Serialization required:** No. The README uses the approved Interface Contract and does not depend on Task A's uncommitted files.

**Write scope:**
- `README.md`

**Parallel:** Yes, compatible with Task A and Task C.

**Risk:** Medium. Public-facing wording must be accurate, humble, and not overclaim comparison or performance.

**Model tier:** BEST, resolved default `model="gpt-5.5"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- Add a concise positioning introduction after the attribution/opening paragraphs.
- Add a "How To Use Simple Power" table covering the three common paths and example prompts.
- Keep and clarify the "Model Allocation" section with environment variable examples.
- Add "Simple Power vs Superpowers" with a comparison table and two embedded HTML flow diagrams.
- Preserve existing installation and core workflow content, editing only where needed for clarity and non-duplication.

**Implementation steps:**
1. Keep the first heading and attribution. Preserve the link to `https://github.com/obra/superpowers`.
2. Add a short audience paragraph: Simple Power is Codex-only, aimed at Codex Pro subscribers and developers who want high-throughput workflows with explicit skill invocation.
3. Add a humble philosophy paragraph based on IC-12. Avoid measured claims unless clearly phrased as a preference.
4. Add a "How To Use Simple Power" table with at least these rows:
   - Feature/larger change: `simplepower:brainstorming`; example prompt `$simplepower:brainstorming I want to add ...`; outcome design -> plan -> aggregate parallel implementation.
   - Debugging: `simplepower:systematic-debugging`; example prompt `$simplepower:systematic-debugging These tests fail ...`; outcome root-cause investigation and focused subagent escalation when useful.
   - Read-only questions: `simplepower:ro`; example prompt `$simplepower:ro Explain how auth works here`; outcome code discussion without editing existing repo files.
5. Add a "Simple Power vs Superpowers" section:
   - Start with respectful attribution and "alternative" framing.
   - Add a comparison table for target harnesses, invocation style, design artifact, implementation execution, review strategy, model allocation, and best fit.
   - Add the two embedded HTML flow diagrams from IC-15, expanded enough to be readable.
6. Keep the install instructions accurate for this repo and the `~/.agents/skills/simplepower` symlink.
7. Ensure every active skill reference uses `simplepower:*`, including `simplepower:ro`.

**Verification commands:**
- `timeout 30s rg -n "How To Use Simple Power|simplepower:brainstorming|simplepower:systematic-debugging|simplepower:ro" README.md`
- `timeout 30s rg -n "Simple Power vs Superpowers|Codex Pro|SIMPLEPOWER_BEST_MODEL|SIMPLEPOWER_FAST_MODEL|<table|</table>" README.md`
- `timeout 30s git diff --check -- README.md`

**Completion report requirements:** List changed files, commands run, command results, and any wording risks. Do not commit.

### Task C - Remove Standalone Codex RO Skill

**Goal:** Remove the old tracked personal `ro` skill from `/home/gary/.codex` so Simple Power is the canonical home for RO mode.

**Contract inputs:** IC-16, IC-17, and approved design decision "use `simplepower:ro` only".

**Serialization required:** No. The files to delete are fully identified by IC-16, and Task A does not need to read them at runtime.

**Write scope:**
- `/home/gary/.codex/skills/ro/SKILL.md`
- `/home/gary/.codex/skills/ro/agents/openai.yaml`

**Parallel:** Yes, compatible with Task A and Task B.

**Risk:** Medium. This edits a separate personal config git repository and must not touch unrelated files.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:**
- Delete exactly the two tracked files in IC-16.
- Leave `/home/gary/.codex` otherwise unchanged.
- Do not commit or push.

**Implementation steps:**
1. Run `timeout 30s git -C /home/gary/.codex status --short` before editing. If there are unrelated dirty changes, report `BLOCKED` and do not delete anything.
2. Delete `/home/gary/.codex/skills/ro/SKILL.md`.
3. Delete `/home/gary/.codex/skills/ro/agents/openai.yaml`.
4. If the now-empty `/home/gary/.codex/skills/ro/agents` or `/home/gary/.codex/skills/ro` directories remain empty, they may be removed. Do not remove any non-empty directory.

**Verification commands:**
- `timeout 30s test ! -e /home/gary/.codex/skills/ro/SKILL.md`
- `timeout 30s test ! -e /home/gary/.codex/skills/ro/agents/openai.yaml`
- `timeout 30s git -C /home/gary/.codex status --short -- skills/ro`

**Completion report requirements:** List deleted files, commands run, command results, and confirmation that no other `/home/gary/.codex` files were intentionally modified. Do not commit.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|---|---|---|---|---|---|
| Task A - Add Simple Power RO skill | `sp-impl` | FAST | `gpt-5.4-mini` | high | Localized skill and metadata creation with exact contract. |
| Task B - Update README positioning and usage | `sp-impl` | BEST | `gpt-5.5` | high | Public-facing comparison and positioning requires judgment and careful tone. |
| Task C - Remove standalone Codex RO skill | `sp-impl` | FAST | `gpt-5.4-mini` | high | Narrow deletion in a separate repo with exact file boundaries. |
| Plan document review | reviewer | BEST | `gpt-5.5` | high | Must validate plan completeness, cross-repo ownership, and aggregate readiness. |
| Quick verification | verifier | fixed | `gpt-5.3-codex-spark` | high | Required quick verifier model for lint/build/tests and typo-level fixes only. |
| Final review+fix | review+fix agent | BEST | `gpt-5.5` | high | Whole-diff review across README, skill packaging, plugin metadata, and separate config cleanup. |

## Plan Review

Self-review checklist:
- Design Summary covers moving RO into Simple Power, README usage/positioning, comparison diagrams, `/home/gary/.codex` cleanup, and commit/push requirements.
- Interface Contract lists exact skill behavior, metadata, README requirements, comparison facts, diagram requirements, and two-repo git boundaries.
- File Ownership assigns every created, modified, or deleted file to exactly one task, with no parallel collisions.
- Task allocation maps each requirement to a task and every task has `Contract inputs` and `Serialization required`.
- Aggregate parallel readiness is explicit: Tasks A, B, and C have disjoint write scopes and shared coordination is supplied by the Interface Contract.
- Visual aids are inline Markdown-compatible HTML examples for the README and do not imply separate local HTML plan files.
- Model allocation uses FAST for narrow tasks, BEST for the public README wording, plan reviewer, and final review+fix agent, and fixed Spark high effort for quick verification.
- Review allocation has one BEST-tier review+fix agent after quick verification.
- Commit policy has exactly three coordinator checkpoints and no worker commits.
- Verification commands are concrete and use `timeout`.
- Approved path enforcement does not authorize backup routes, skipped checks, docs-only substitutes, or execution-route changes.

After this self-review, dispatch a BEST-tier plan reviewer using `skills/writing-plans/plan-document-reviewer-prompt.md`. Provide this plan path and the approved brainstorming design context. If the reviewer reports issues, the coordinator fixes the plan and reruns focused self-review for the changed categories before asking the user.

After the plan reviewer approves, ask the user to approve both the reviewed plan and model/task allocation. The accepted plan checkpoint commit happens only after that approval. Workers and reviewers must not create this commit.

## Quick Verification

Run these after all file-edit workers complete and before the quick-verified implementation checkpoint:

- `timeout 30s git -C /home/gary/git/simplepower diff --check`
  - Expected result: exits 0 with no whitespace errors. Failure means README, JSON-adjacent, YAML, or skill Markdown whitespace must be inspected.
- `timeout 30s node -e "JSON.parse(require('fs').readFileSync('/home/gary/git/simplepower/.codex-plugin/plugin.json','utf8')); console.log('plugin json ok')"`
  - Expected result: prints `plugin json ok`. Failure means plugin metadata JSON is invalid.
- `timeout 30s test -f /home/gary/git/simplepower/skills/ro/SKILL.md`
  - Expected result: exits 0. Failure means the Simple Power RO skill was not created.
- `timeout 30s test -f /home/gary/git/simplepower/skills/ro/agents/openai.yaml`
  - Expected result: exits 0. Failure means RO metadata was not created.
- `timeout 30s rg -n "simplepower:brainstorming|simplepower:systematic-debugging|simplepower:ro|Simple Power vs Superpowers|Codex Pro|SIMPLEPOWER_BEST_MODEL|SIMPLEPOWER_FAST_MODEL" /home/gary/git/simplepower/README.md`
  - Expected result: finds all named strings. Failure means README requirements are missing.
- `timeout 30s test ! -e /home/gary/.codex/skills/ro/SKILL.md`
  - Expected result: exits 0. Failure means the old standalone RO skill remains.
- `timeout 30s test ! -e /home/gary/.codex/skills/ro/agents/openai.yaml`
  - Expected result: exits 0. Failure means the old standalone RO metadata remains.
- `timeout 30s git -C /home/gary/.codex status --short -- skills/ro`
  - Expected result: shows only deletions for `skills/ro/SKILL.md` and `skills/ro/agents/openai.yaml`. Failure means the config cleanup is incomplete or out of scope.

The quick verifier may fix only tiny typo-level errors discovered while running these checks. Any behavior change, structural edit, README rewrite, public interface change, JSON schema uncertainty, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

## Final Review And Fix

After the quick-verified implementation checkpoint, dispatch one BEST-tier review+fix agent with:
- This accepted plan.
- The full diff for `/home/gary/git/simplepower`.
- The scoped diff/status for `/home/gary/.codex`.
- Worker completion reports.
- Quick verification results.

The review+fix agent may edit only files in File Ownership. It must verify that README claims are humble and accurate, embedded HTML diagrams render as readable Markdown-compatible HTML, `simplepower:ro` is discoverable and explicit-only, `/home/gary/.codex` cleanup is limited to IC-16, and no unrelated changes are staged or committed. It must not commit or push.

## Commit Checkpoints

Exactly three future coordinator checkpoints are approved:

1. **Accepted plan checkpoint:** After the user approves the reviewed plan and model/task allocation, the coordinator commits the accepted plan in `/home/gary/git/simplepower`. Stage only `docs/simplepower/plans/2026-05-10-ro-skill-and-readme-positioning.md`. Do not modify or commit `/home/gary/.codex` at this checkpoint.
2. **Quick-verified implementation checkpoint:** After Tasks A, B, and C complete and quick verification passes, the coordinator creates scoped commit(s) for repos with in-scope changes:
   - `/home/gary/git/simplepower`: stage only `README.md`, `.codex-plugin/plugin.json`, `skills/ro/SKILL.md`, and `skills/ro/agents/openai.yaml`.
   - `/home/gary/.codex`: stage only deletions of `skills/ro/SKILL.md` and `skills/ro/agents/openai.yaml`.
3. **Final checkpoint:** After the BEST-tier review+fix agent completes and final verification passes, the coordinator creates scoped final commit(s) only in repos that still have uncommitted in-scope changes. Do not create empty commits.

Workers, plan reviewers, quick verifiers, review+fix agents, and individual tasks must not commit. Push both repositories only after the final checkpoint decision and final verification:
- `git -C /home/gary/git/simplepower push origin html-plan-visual-aids`
- `git -C /home/gary/.codex push origin master`

If a push fails because of auth, network, or non-fast-forward state, stop and report the exact failing command and local commit SHAs. Do not force-push without fresh explicit user approval.

## Context-Size Handoff

After the user approves the reviewed plan and model/task allocation and the coordinator creates the accepted plan checkpoint commit, read `skills/writing-plans/current-session-context.md`. Measure current coordinator session context pct in the main agent using `CODEX_THREAD_ID` and the Codex JSONL helper. Do not spawn a subagent for this measurement.

If current-session context measurement succeeds:
- Recommend fresh context with `/clear` when context is `>= 55%`.
- Recommend continuing in current session when context is `< 55%`.

If measurement fails, use the saved plan size fallback:

```bash
wc -c "docs/simplepower/plans/2026-05-10-ro-skill-and-readme-positioning.md"
```

For fallback only, a byte count greater than `35840` recommends fresh context with `/clear`; `35840` bytes or less recommends current-session execution.

Always show both implementation handoff commands, state whether the recommendation came from current context pct or plan-size fallback, and ask the user which implementation handoff to use. Put the recommended option first:
- If continuing in the current session is recommended, show `Continue in current session (Recommended)` first, then `Run after /clear`.
- If fresh context is recommended, show `Run after /clear (Recommended)` first, then `Continue in current session`.

Current-session handoff command:

```text
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-10-ro-skill-and-readme-positioning.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

Fresh-context handoff command:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `docs/simplepower/plans/2026-05-10-ro-skill-and-readme-positioning.md` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

If the user chooses current-session execution, that choice is an authorized handoff to `simplepower:subagent-driven-development`. If the user chooses fresh context, stop after showing the fresh-context command and tell the user to run `/clear` manually before sending the command.

## Verification

Run these after the final review+fix agent completes and before the final checkpoint and push:

- `timeout 30s git -C /home/gary/git/simplepower diff --check`
  - Expected result: exits 0. Failure means final whitespace or Markdown-adjacent formatting must be fixed before commit.
- `timeout 30s node -e "JSON.parse(require('fs').readFileSync('/home/gary/git/simplepower/.codex-plugin/plugin.json','utf8')); console.log('plugin json ok')"`
  - Expected result: prints `plugin json ok`. Failure means plugin metadata JSON must be fixed before commit.
- `timeout 30s rg -n "simplepower:brainstorming|simplepower:writing-plans|simplepower:subagent-driven-development|simplepower:systematic-debugging|simplepower:ro|Simple Power vs Superpowers|Codex Pro|SIMPLEPOWER_BEST_MODEL|SIMPLEPOWER_FAST_MODEL" /home/gary/git/simplepower/README.md`
  - Expected result: finds all required README terms. Failure means README content is incomplete.
- `timeout 30s rg -n "name: ro|simplepower:ro|read-only|manifest.json|allow_implicit_invocation: false" /home/gary/git/simplepower/skills/ro /home/gary/git/simplepower/.codex-plugin/plugin.json`
  - Expected result: finds RO skill identity, behavior, manifest, and explicit-invocation metadata. Failure means the skill or metadata is incomplete.
- `timeout 30s test ! -e /home/gary/.codex/skills/ro/SKILL.md`
  - Expected result: exits 0. Failure means the old personal RO skill still exists.
- `timeout 30s test ! -e /home/gary/.codex/skills/ro/agents/openai.yaml`
  - Expected result: exits 0. Failure means old RO metadata still exists.
- `timeout 30s git -C /home/gary/git/simplepower status --short`
  - Expected result before final commit: only approved in-scope Simple Power files are modified/untracked, or clean if already committed. Failure means unrelated files need investigation before staging.
- `timeout 30s git -C /home/gary/.codex status --short`
  - Expected result before final commit: only approved RO deletions are present, or clean if already committed. Failure means unrelated config changes need investigation before staging.

The coordinator performs the final checkpoint only after the BEST-tier review+fix agent has completed and all final commands pass. After final checkpoint handling, push both repositories as specified in Commit Checkpoints.

## Approved Path Enforcement

The accepted implementation plan is authoritative. Do not authorize backup routes, scope reduction, docs-only substitutes, placeholder implementations, skipped verification, skipped review, or execution-route changes unless the user gives fresh explicit approval at the moment the deviation is needed.

If implementation discovers that `/home/gary/.codex` has unrelated dirty changes, the README comparison facts are contradicted by current upstream sources, plugin metadata has an unexpected schema requirement, or git push requires force, stop and ask the user. Diagnostic investigation is allowed; alternate implementation work is not.
