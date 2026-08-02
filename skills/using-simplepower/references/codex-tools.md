# Codex Tool Mapping

Simple Power skills may mention generic skill tool names. When you encounter these in a skill, use the Codex equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool (dispatch subagent) | `spawn_agent(fork_turns="none", message=...)` (see [Prompt dispatch](#prompt-dispatch)) |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent(fork_turns="none", message=...)` calls |
| Task returns result | `wait` |
| Task completes automatically | `close_agent` to free slot |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |
| Main agent direct implementation | No spawn. The main agent edits the cohesive package directly, then runs the mandatory quick verifier and final diff review. |
| sp-impl file-edit worker | `spawn_agent(agent_type="worker", model=<FAST_or_NORMAL_or_BEST_model>, reasoning_effort=<FAST_or_NORMAL_or_BEST_effort>, fork_turns="none", message=...)` |
| quick verifier | `spawn_agent(agent_type="worker", model=<FAST_model>, reasoning_effort=<FAST_effort>, fork_turns="none", message=...)` Default resolves to Spark xhigh unless overridden. |
| Grouped workers with independent file-edit packages | Multiple `spawn_agent(fork_turns="none", message=...)` calls, one per cohesive non-conflicting worker package whose delegation has clear value, before `wait` |

The grouped worker and quick verifier mappings are normal Simple Power
dispatches and are independent of `use_subagent`. Before resolving them,
validate the seven base keys plus optional
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
resolved `review_model` for compatibility. In the normal chain,
`review_model`, `review_model2`, `final_review_model`, and `skip_final_review`
are deprecated compatibility/no-op settings: they are recognized and strictly
validated, but do not dispatch plan reviewers or final review+fix agents.
An absent `review_model2`, or an exact match with the fully resolved
primary, preserves the single-reviewer compatibility result; a distinct value
preserves the legacy secondary-reviewer compatibility result.

Scratch refs under `refs/simplepower/scratch/<run-id>/` are coordinator-owned
local refs used to provide concrete quick-verifier diff anchors. They are
not branches, accepted checkpoints, pushed refs, or subagent commits; workers
and quick verifiers must not create, update, delete, inspect, or manage them.

Resolve the active tiers and validate the deprecated compatibility REVIEW value
before dispatch:

| Tier | TOML key | Environment value | Built-in default |
|------|----------|-------------------|------------------|
| REVIEW (deprecated compatibility/no-op) | `review_model` | `SIMPLEPOWER_REVIEW_MODEL` | `gpt-5.6-sol-high` |
| BEST | `best_model` | `SIMPLEPOWER_BEST_MODEL` | `gpt-5.6-sol-high` |
| NORMAL | `normal_model` | `SIMPLEPOWER_NORMAL_MODEL` | `gpt-5.6-luna-max` |
| FAST | `fast_model` | `SIMPLEPOWER_FAST_MODEL` | `gpt-5.3-codex-spark-xhigh` |

Parse the final dash-delimited segment as `reasoning_effort` and the preceding
string as `model`. Valid effort suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`; stop and report an invalid resolved value rather than
guessing. With the built-in defaults, FAST resolves to model
`gpt-5.3-codex-spark` with `xhigh`, NORMAL to model `gpt-5.6-luna` with `max`,
and BEST and REVIEW to model `gpt-5.6-sol` with `high`.

Use the plan's approved FAST/NORMAL/BEST allocation for grouped `sp-impl`
file-edit workers. Main agent direct implementation has no spawn. Do not
dispatch plan reviewers or final review+fix agents in the normal chain; the
main agent performs plan self-review, final diff review, and in-scope fixes.

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait`, and `close_agent` for skills like `simplepower:dispatching-parallel-agents` and `simplepower:subagent-driven-development`.

## Prompt dispatch

Codex does not use a named Simple Power agent registry. When a skill needs a
grouped file-edit worker or quick verifier, use the skill-local prompt template
and dispatch a generic subagent from a built-in role (`default`, `explorer`,
`worker`). Main agent direct implementation, plan self-review, final diff
review, and in-scope fixes use no spawn.

When a skill says to dispatch a Simple Power worker:

1. Find the skill-local prompt template, such as
   `skills/requesting-code-review/code-reviewer.md` or one of the role prompts
   used by `simplepower:subagent-driven-development`:
   `skills/subagent-driven-development/implementer-prompt.md` or
   `skills/subagent-driven-development/quick-verifier-prompt.md`
2. Read the prompt content
3. Fill any template placeholders from the current task, working tree status,
   diff, and verification results
4. Spawn a `worker` agent with the filled content as the `message`

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
- Grouped implementation prompts include only the relevant design, contract,
  scope, verification, and package context for that cohesive worker package,
  not the complete plan or repeated global boilerplate.

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

An accepted normal Simple Power plan uses one combined approval to authorize
its two coordinator checkpoint commits: the accepted-plan commit and the final
reviewed/verified implementation commit. After compliant in-scope execution and
successful final verification, the coordinator creates the final commit when
uncommitted changes remain without requesting another approval; it does not
create an empty commit. Simple Power does not otherwise automatically create
commits, merge, push, or open PRs. Those operations require a separate user
request unless they are explicitly included in the accepted plan. Use the
repository signals above only to explain state and verification limits in the
final handoff.
