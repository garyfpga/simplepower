# Codex Tool Mapping

Simple Power skills may mention generic skill tool names. When you encounter these in a skill, use the Codex equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
| Task returns result | `wait` |
| Task completes automatically | `close_agent` to free slot |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |
| sp-impl file-edit worker | `spawn_agent(agent_type="worker", model=<FAST_or_NORMAL_or_BEST_model>, reasoning_effort=<FAST_or_NORMAL_or_BEST_effort>, fork_context=false, message=...)` |
| quick verifier | `spawn_agent(agent_type="worker", model=<FAST_model>, reasoning_effort=<FAST_effort>, fork_context=false, message=...)` Default resolves to Spark high unless overridden. |
| review+fix agent | `spawn_agent(agent_type="worker", model=<BEST_model>, reasoning_effort=<BEST_effort>, fork_context=false, message=...)` |
| multiple independent file-edit tasks | Multiple `spawn_agent` calls, one per non-conflicting ownership unit, before `wait` |

The role mappings are an explicit Simple Power override to generic same-model
defaults from AGENTS.md or other ambient instructions. Resolve
`SIMPLEPOWER_BEST_MODEL`, `SIMPLEPOWER_NORMAL_MODEL`, and
`SIMPLEPOWER_FAST_MODEL` before dispatch. If unset, use
`SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"`,
`SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"`, and
`SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"`. The final
dash-delimited segment is `reasoning_effort`; the preceding string is `model`.

Use the plan's approved FAST/NORMAL/BEST allocation for `sp-impl` file-edit
workers. Always dispatch the review+fix agent with BEST.

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait`, and `close_agent` for skills like `simplepower:dispatching-parallel-agents` and `simplepower:subagent-driven-development`.

## Review prompt dispatch

Codex does not use a named Simple Power agent registry. When a skill needs a
file-edit worker, quick verifier, or review+fix agent, use the skill-local
prompt template and dispatch a generic
subagent from a built-in role (`default`, `explorer`, `worker`).

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

| Skill instruction | Codex equivalent |
|-------------------|------------------|
| Code review prompt template | `spawn_agent(agent_type="worker", message=...)` with the filled template content |
| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the same prompt |

### Message framing

The `message` parameter is user-level input, not a system prompt. Structure it
for maximum instruction adherence:

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
- End with an explicit execution directive to prevent summarization of the instructions
- Default Simple Power subagents to `fork_context=false`; paste the exact task,
  write scope, relevant context, and diff into the prompt instead of relying on
  inherited conversation history

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
