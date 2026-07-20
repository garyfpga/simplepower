# Codex Tool Mapping

Simple Power skills may mention generic skill tool names. When you encounter these in a skill, use the Codex equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool (dispatch subagent) | `spawn_agent(fork_turns="none", message=...)` (see [Review prompt dispatch](#review-prompt-dispatch)) |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent(fork_turns="none", message=...)` calls |
| Task returns result | `wait` |
| Task completes automatically | `close_agent` to free slot |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |
| sp-impl file-edit worker | `spawn_agent(agent_type="worker", model=<FAST_or_NORMAL_or_BEST_model>, reasoning_effort=<FAST_or_NORMAL_or_BEST_effort>, fork_turns="none", message=...)` |
| quick verifier | `spawn_agent(agent_type="worker", model=<FAST_model>, reasoning_effort=<FAST_effort>, fork_turns="none", message=...)` Default resolves to Spark xhigh unless overridden. |
| primary plan reviewer | `spawn_agent(agent_type="worker", model=<REVIEW_model>, reasoning_effort=<REVIEW_effort>, fork_turns="none", message=...)` |
| conditional secondary plan reviewer | Only when fully resolved `review_model2` is distinct from `review_model`: `spawn_agent(agent_type="worker", model=<review_model2_model>, reasoning_effort=<review_model2_effort>, fork_turns="none", message=...)`; read-only and concurrent with the primary plan reviewer. |
| final review+fix agent | When `skip_final_review=false`, `spawn_agent(agent_type="worker", model=<resolved_final_review_model>, reasoning_effort=<resolved_final_review_effort>, fork_turns="none", message=...)`; it is the only final-review agent and writer. Do not dispatch it when `skip_final_review=true`. |
| multiple independent file-edit tasks | Multiple `spawn_agent(fork_turns="none", message=...)` calls, one per non-conflicting ownership unit, before `wait` |

The role mappings are mandatory Simple Power dispatches and are independent of
`use_subagent`. Before resolving them, validate the seven base keys plus optional
`review_model2` and `final_review_model` by following
`skills/using-simplepower/references/simplepower-config.md`. Every present TOML
file must validate in full before overlays; a higher layer must not hide
malformed TOML, unknown keys, wrong types, or invalid model values in a lower
layer. Resolve model settings by starting with the built-in defaults, then
overlaying `/home/gary/.codex/simplepower.toml`, repository
`<git-root>/simplepower.toml`, the supported non-empty `SIMPLEPOWER_*` process
environment values, and explicit current-session instructions last. Each later
layer replaces only the keys it supplies. Missing higher-layer keys
inherit. Do not read model assignments from any `AGENTS.md` file.

The seven base keys are `use_subagent`, `skip_final_review`, `subagent_model`,
`review_model`, `best_model`, `normal_model`, and `fast_model`. Resolve the optional
`review_model2` and `final_review_model` after the primary `review_model`.
There is no `SIMPLEPOWER_REVIEW_MODEL2`; `final_review_model` supports
`SIMPLEPOWER_FINAL_REVIEW_MODEL`. An absent `final_review_model` uses the fully
resolved `review_model`. When `skip_final_review=false`, dispatch exactly one
final review+fix agent; when true, skip that dispatch but not final verification.
An absent `review_model2`, or an exact match with the fully resolved
primary, disables the optional read-only plan-review secondary; a distinct
value enables it only for plan review.

Scratch refs under `refs/simplepower/scratch/<run-id>/` are coordinator-owned
local refs used to provide concrete `git diff` commands to reviewers. They are
not branches, accepted checkpoints, pushed refs, or subagent commits; workers
and review agents must not create, update, delete, or commit them.

Resolve all four tiers before dispatch:

| Tier | TOML key | Environment value | Built-in default |
|------|----------|-------------------|------------------|
| REVIEW | `review_model` | `SIMPLEPOWER_REVIEW_MODEL` | `gpt-5.6-sol-high` |
| BEST | `best_model` | `SIMPLEPOWER_BEST_MODEL` | `gpt-5.6-sol-high` |
| NORMAL | `normal_model` | `SIMPLEPOWER_NORMAL_MODEL` | `gpt-5.6-luna-max` |
| FAST | `fast_model` | `SIMPLEPOWER_FAST_MODEL` | `gpt-5.3-codex-spark-xhigh` |

Parse the final dash-delimited segment as `reasoning_effort` and the preceding
string as `model`. Valid effort suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`; stop and report an invalid resolved value rather than
guessing. With the built-in defaults, FAST resolves to model
`gpt-5.3-codex-spark` with `xhigh`, NORMAL to model `gpt-5.6-luna` with `max`,
and BEST and REVIEW to model `gpt-5.6-sol` with `high`.

Use the plan's approved FAST/NORMAL/BEST allocation for `sp-impl` file-edit
workers. Always dispatch the primary plan reviewer with REVIEW. Dispatch one
final review+fix agent with resolved `final_review_model` only when effective
`skip_final_review=false`. When the optional
secondary is enabled, dispatch it with the parsed distinct `review_model2`
value only as a read-only plan reviewer; it never replaces the primary or gains
fix authority.

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait`, and `close_agent` for skills like `simplepower:dispatching-parallel-agents` and `simplepower:subagent-driven-development`.

## Review prompt dispatch

Codex does not use a named Simple Power agent registry. When a skill needs a
file-edit worker, quick verifier, plan reviewer, or final review+fix agent, use
the skill-local prompt template and dispatch a generic subagent from a built-in
role (`default`, `explorer`, `worker`).

When a skill says to dispatch a Simple Power worker:

1. Find the skill-local prompt template, such as
   `skills/requesting-code-review/code-reviewer.md` or one of the role prompts
   used by `simplepower:subagent-driven-development`:
   `skills/subagent-driven-development/implementer-prompt.md`,
   `skills/subagent-driven-development/quick-verifier-prompt.md`, or
   `skills/subagent-driven-development/review-fix-prompt.md`
2. Read the prompt content
3. Fill any template placeholders from the current task, working tree status,
   diff, and verification results
4. Spawn a `worker` agent with the filled content as the `message`

For final review, first resolve `skip_final_review`. When false, fill
`review-fix-prompt.md` with the quick-verified snapshot and dispatch exactly one
self-contained review+fix agent using resolved `final_review_model` and
`fork_turns="none"`. When true, omit the prompt and dispatch and continue with
final verification.

| Skill instruction | Codex equivalent |
|-------------------|------------------|
| Code review prompt template | `spawn_agent(agent_type="worker", fork_turns="none", message=...)` with the filled template content |
| `Task tool (general-purpose)` with inline prompt | `spawn_agent(fork_turns="none", message=...)` with the same prompt |

### Message framing

The `message` parameter is user-level input, not a system prompt. Structure it
for maximum instruction adherence:

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]

Task: [exact assigned task]
Scope: [exact read and write boundaries]
Constraints: [approved-path, ownership, and lifecycle constraints]
Evidence and contracts: [relevant plan text, diffs, command output, and Interface Contract entries]
Output: [required structured report]
Verification: [exact commands, timeouts, and expected results]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
- End with an explicit execution directive to prevent summarization of the instructions
- Every Simple Power dispatch must pass `fork_turns="none"`. Its prompt must be
  self-contained with the exact task, scope, constraints, evidence or contracts,
  required output, and verification commands and expectations.
- A secondary plan-review prompt must additionally state its same-snapshot,
  read-only/no-file-creation/no-ref/no-commit/no-subagent/no-skill/no-reroute
  restrictions. When enabled, final review uses one direct review+fix prompt.

### When this workaround can be removed

This approach compensates for Codex's plugin system not yet supporting an `agents`
field in `plugin.json`. When `RawPluginManifest` gains an `agents` field, the
plugin can symlink to `agents/` (mirroring the existing `skills/` symlink) and
skills can dispatch named agent types directly.

## Environment Detection

Skills that inspect repository state should prefer read-only git commands:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree
- `BRANCH` empty → detached HEAD

Simple Power does not automatically commit, merge, push, or open PRs. Use these
signals only to explain repository state and verification limits in the final
handoff.
