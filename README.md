# SimplePower

[简体中文](#simplepower) | [English](#simplepower-english)

## 告别 /fast，用 SimplePower 也能快起来
SimplePower 的设计目标是：即使没有 /fast，也能让你的工作更快完成。

## SimplePower 是给真正写代码的 coder / engineer 用的，不是给 vibe coder 用的
使用 SimplePower，代表你接受更快的 AI-Human 往返节奏，同时你也需要投入更多精力来引导 AI。

***

## 理念

SimplePower 是 Jesse Vincent / Prime Radiant 的 [Superpowers](https://github.com/obra/superpowers) 的 Codex-only fork。
感谢 Jesse Vincent / Prime Radiant 提供了这个 fork 所基于的上游项目。
对他们致以非常大的感谢和尊重。SimplePower 不是想取代 SuperPower，它只是作为一个替代选择存在。
目前我只维护 Codex 版本，因为一开始我想让这个项目保持专注。

这张表说明 SimplePower 想达到的目标（时间只是我经验中的估计）：

| 目标 | Superpowers-style 路径 | SimplePower 路径 |
|---|---:|---:|
| AI 时间 | 3x | 0.3x |
| 往返时间 | 慢 | 快 |
| 人类输入 | 更少 | 更多 |
| Token 用量 | 3x | 2x |
| 结果准确度和质量 | 95% | 90% |

***

## 和 SuperPower 的相同点与不同点

| 阶段 | SuperPower | SimplePower |
|---|---:|---:|
| Spec / Plan | brainstorming -> <br> approve spec -> <br> spec.md (commit) -> <br> plan.md (approve and commit) | brainstorming -> <br> approve spec -> <br> plan.md (approve and commit) <br> 懒得同时检查 spec.md 和 plan.md
| Subagent Implementation <br><br> 这就是 SimplePower 快的原因 | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | 多个 subagent 并行处理多个文件 -> <br> FAST-tier 快速验证 subagent -> <br> primary REVIEW-tier reviewer + fixer；可选 distinct read-only secondary reviewer
| Git Commits? | 每一步 | parallel subagent 之后一次性提交 + <br> review 之后最终提交

## 安装

从 Codex plugin marketplace 安装 Simple Power：

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin add simplepower@garyfpga-codex-plugins
```

以后只要想拉取 marketplace 更新，就运行：

```bash
codex plugin marketplace upgrade garyfpga-codex-plugins
```

更新后如果想让 Codex 立刻重新扫描 installed skills，请重启 Codex。

## 模型分配

Simple Power 使用四个强制模型层级（four mandatory model tiers）。它们的内建默认值也是当前 session 已批准的值：

```toml
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

最终分配为 REVIEW = `gpt-5.6-sol`/`high`、BEST = `gpt-5.6-sol`/`high`、NORMAL = `gpt-5.6-luna`/`max`、FAST = `gpt-5.3-codex-spark`/`xhigh`。

环境变量可以覆盖 `use_subagent`、`subagent_model`、四个模型层级、`final_review_model` 和 `skip_final_review`，对应 `SIMPLEPOWER_USE_SUBAGENT`、`SIMPLEPOWER_SUBAGENT_MODEL`、`SIMPLEPOWER_REVIEW_MODEL`、`SIMPLEPOWER_BEST_MODEL`、`SIMPLEPOWER_NORMAL_MODEL`、`SIMPLEPOWER_FAST_MODEL`、`SIMPLEPOWER_FINAL_REVIEW_MODEL` 和 `SIMPLEPOWER_SKIP_FINAL_REVIEW`。不存在 `SIMPLEPOWER_REVIEW_MODEL2`。根目录或嵌套的 `AGENTS.md` 都不再提供模型赋值。

`final_review_model` 是可选的 final review+fix 配置，不是第五个强制层级；它没有独立内建默认值。缺失时它等于已解析的 `review_model`；存在时 final review 使用它。`skip_final_review` 默认是 `false`：为 `false` 时 final review 只 dispatch 一个 review+fix agent；为 `true` 时不创建 final-review scratch refs，也不 dispatch 该 agent，但仍执行 final verification 和 final checkpoint/commit condition。

`review_model2` 是可选的 read-only plan-review secondary 配置；它没有内建默认值，也没有环境变量覆盖。缺失或与已解析的 `review_model` 完全相等时保持一个 primary plan reviewer。只有 distinct 的值才让 plan review 使用两个 read-only reviewers；secondary 永远不写文件，也不参加 final review。

REVIEW 用于 primary plan reviewer。final review+fix 使用 `final_review_model`，缺失时回退到 REVIEW。
BEST 用于广泛、跨文件、含糊、会改变行为、高风险、难测试的工作。
NORMAL 用于原来会放进旧 FAST 层的常规低风险实现工作，尤其是局部修改。
FAST 是 Spark 层，用于明显重复的工作、多文件机械性修改、大量静态文本扫改、简单 fixture/assertion 变更，以及快速验证。

## 配置

Simple Power 按 key 独立解析配置：先使用内建默认值，再 overlay `~/.codex/simplepower.toml` 中出现的 key；在 Git 仓库内，再 overlay `<git-root>/simplepower.toml` 中出现的 key；然后 overlay 上述非空环境变量；最后应用当前 session 的显式指示。较高层缺失的 key 会继承较低层的值，因此 repository 文件不会整体替代 home 文件。在 Git 仓库外跳过 repository 文件这一层。

可复制的完整示例见 [simplepower.toml.example](simplepower.toml.example)；该文件本身不是 active repository configuration。

支持的 TOML 顶层 key 是以下七个 base keys，加上没有独立默认值的可选 `review_model2` 和 `final_review_model`。七个 base key 的精确默认值如下：

```toml
use_subagent = false
skip_final_review = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent` 和 `skip_final_review` 必须是 TOML Boolean。对应的环境变量仅接受不区分大小写的 `true` 或 `false`，所以 `true`、`True`、`TRUE` 等价；其他非空值是 fatal error。每个存在的模型 key（包括可选的 `review_model2` 和 `final_review_model`）都必须是非空 TOML string，并按最后一个 dash 拆成非空 model prefix 与 reasoning-effort suffix；合法 suffix 只有 `low`、`medium`、`high`、`xhigh`、`max` 和 `ultra`。格式错误的 TOML、未知 key、错误类型、空模型字符串、缺失 model prefix 或非法 effort 都是 fatal error。每个存在的文件、每个显式 current-session 配置值，以及每个非空环境 override 都必须验证，即使更高层随后会覆盖同一 key；缺失文件或 key 则继承。`final_review_model` 缺失时使用完全解析后的 `review_model`。所有空的受支持环境变量都会被忽略。只有 `review_model2` 没有环境变量覆盖。

`use_subagent` 是 brainstorming 和 `simplepower:ro` 的硬 gate：`false` 禁止所有可选 explorer；`true` 只是 permission，不是启动指令。两个 workflow 都先由 coordinator 进行 initial triage，不会在启动时自动 dispatch explorer。只有 triage 判断 investigation 属于 large、cross-cutting、complex 或 stalled 时，coordinator 才能在 runtime capacity 内 fan-out 一个或多个具有 distinct investigation angles 的 read-only explorers。每个 explorer 都使用自包含 brief 和 `fork_turns="none"`，只能读取和运行只读命令；coordinator 会综合所有报告。选定的 explorer batch 如果无法完整派发，流程会停止，不会用 partial batch 静默替代。

当 `review_model2` distinct 时，plan review 会并行运行两个 read-only reviewers，并要求两者都批准；如果任一 reviewer 无法派发，plan-review checkpoint 会停止，不会降级为单 reviewer。`skip_final_review=false` 时，final review 在 verified snapshot 上只使用一个由 `final_review_model` 解析出的 review+fix agent；为 `true` 时跳过该阶段。

这次变更不会创建或 track repository-level `simplepower.toml`；如果该文件存在，系统会支持它并按 key overlay home 文件。

## 实现流程

Simple Power skills 使用 `simplepower:*` namespace。当你想让 Codex 使用某个 skill 时，直接提到它的名字，例如 `simplepower:brainstorming`。

brainstorming skill 可以使用临时的 localhost visual companion 来处理 mockups、diagrams 和其他视觉问题。生成的 implementation plans 会保存到 `docs/simplepower/plans/`。

在 `simplepower:writing-plans` 完成 plan review 之后，Simple Power 会一次性询问你是否批准已审阅的 plan、模型分配，以及立刻在当前 session 里启动 `simplepower:subagent-driven-development`。最终 review 使用由 `final_review_model` 解析出的一个 review+fix agent；缺失时使用 REVIEW。
你确认后，coordinator 会创建 accepted plan checkpoint commit，并立即调用 `simplepower:subagent-driven-development` 执行已批准的 plan。
为了让 reviewer 更容易对 revised plan 和 review/fix 变化做 diff，coordinator 会在本地创建临时 scratch refs 作为 diff anchors；这些 refs 只是审阅辅助，不是 branch 或 accepted checkpoint，成功后会清理。
如果 REVIEW-tier reviewer 提出问题，coordinator 会修正 plan、重新跑相关自检，再把 revised plan 送回原 reviewer；distinct `review_model2` 启用时，会把同一份 concrete diff 送回两个原 read-only reviewers。reviewer 会一直保持打开，直到通过、发生不可恢复中断，或你明确要求停止。

## 如何使用 Simple Power

使用 `simplepower:brainstorming` 并开始你的 plan。

`simplepower:systematic-debugging` 也遵循 Simple Power flow。

## 许可证

MIT 许可证。详情见 `LICENSE`。

# SimplePower English

## Say goodbye to /fast with SimplePower
SimplePower is designed to get your work done a lot faster even without /fast.

## SimplePower is for true coders / engineers, not for vibe coders
By using SimplePower, you accept a faster AI-Human turn around time, and you are expected to put more effort to guide the AI.

***

## Philosopy

SimplePower is a Codex-only fork of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent / Prime Radiant.
Thanks to Jesse Vincent / Prime Radiant for the upstream project this fork is based on.
Huge thanks and respect for them, SimplePower is not trying to replace SuperPower, it is here just as an alternative.
Right now I am only maintaining a codex version as I wanna keep this project focus for start.

This table explains what SimplePower is trying to achieve (times are just estimate from my experience):

| Goal | Superpowers-style path | SimplePower path |
|---|---:|---:|
| AI Time | 3x | 0.3x |
| Turnaround Time | Slow | Fast |
| Human Input | Less | More |
| Tokens | 3x | 2x |
| Result Accuracy and Quality | 95% | 90% |

***

## Same and difference to SuperPower

| Pharse | SuperPower | SimplePower |
|---|---:|---:|
| Spec / Plan | brainstorming -> <br> approve spec -> <br> spec.md (commit) -> <br> plan.md (approve and commit) | brainstorming -> <br> approve spec -> <br> plan.md (approve and commit) <br> too lazy to check spec.md and plan.md
| Subagent Implementation <br><br> this is why SimplePower is fast | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | Many subagents in parallel for multiple files -> <br> FAST-tier quick verifier subagent -> <br> Primary REVIEW-tier reviewer + fixer, with an optional distinct read-only secondary reviewer
| Git Commits? | every steps | all at once after parallel subagent + <br> final after review

## Installation

Install Simple Power from the Codex plugin marketplace:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin add simplepower@garyfpga-codex-plugins
```

Use this whenever you want to pull marketplace updates:

```bash
codex plugin marketplace upgrade garyfpga-codex-plugins
```

Restart Codex after install or update if you want it to rescan installed skills
immediately.

## Model Allocation

Simple Power uses four mandatory model tiers. Their built-in defaults are also
the approved current-session values:

```toml
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

The resulting assignments are REVIEW = `gpt-5.6-sol`/`high`, BEST =
`gpt-5.6-sol`/`high`, NORMAL = `gpt-5.6-luna`/`max`, and FAST =
`gpt-5.3-codex-spark`/`xhigh`.

The environment can override `use_subagent`, `subagent_model`, all four model
tiers, `final_review_model`, and `skip_final_review` through
`SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SUBAGENT_MODEL`,
`SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`,
`SIMPLEPOWER_NORMAL_MODEL`, `SIMPLEPOWER_FAST_MODEL`,
`SIMPLEPOWER_FINAL_REVIEW_MODEL`, and `SIMPLEPOWER_SKIP_FINAL_REVIEW`. There is
no `SIMPLEPOWER_REVIEW_MODEL2`. Root and nested `AGENTS.md` files do not provide model assignments.

`final_review_model` is optional and is not a fifth mandatory tier. It has no
independent built-in default. When absent, it uses the resolved `review_model`;
when present, it selects the final review+fix agent. `skip_final_review`
defaults to `false`: false dispatches exactly one review+fix agent, while true
omits final-review scratch refs and dispatch but retains final verification and
the final checkpoint/commit condition.

`review_model2` is an optional read-only plan-review secondary. It has no
built-in default and no environment override. If it is absent or exactly equal
to the resolved `review_model`, Simple Power keeps one primary plan reviewer.
A distinct value enables an additional read-only plan reviewer. The secondary
never writes files or participates in final review.

REVIEW is for the primary plan reviewer. Final review+fix uses
`final_review_model`, falling back to REVIEW when it is absent.
BEST is for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test work.
NORMAL is for routine low-risk implementation work that used to fit the old
FAST tier, especially localized edits.
FAST is the Spark tier for obvious repetitive work, mechanical edits across
many files, large static text sweeps, simple fixture/assertion churn, and quick
verification.

## Configuration

Simple Power resolves every configuration key independently. Start with the
built-in defaults, overlay keys from `~/.codex/simplepower.toml`, overlay keys
from `<git-root>/simplepower.toml` when inside a Git repository, overlay the
supported non-empty environment variables named above, then apply
explicit current-session instructions last. Missing higher-layer keys inherit
the lower-layer value. In particular, a repository file overlays the home file
per key; it does not replace it as a whole. Outside Git, the repository layer
is skipped.

See [simplepower.toml.example](simplepower.toml.example) for a copyable full
example; the example itself is not active repository configuration.

The supported TOML schema is these seven base keys plus optional `review_model2`
and `final_review_model`. The seven base keys have the following exact defaults:

```toml
use_subagent = false
skip_final_review = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent` and `skip_final_review` must be TOML Booleans. Their environment
values accept only case-insensitive `true` or `false`, so `true`, `True`, and
`TRUE` are equivalent; every other non-empty value is fatal. Every present
model key, including optional `review_model2` and `final_review_model`, must be a nonempty TOML
string and is parsed at its final dash into a nonempty model prefix and a
reasoning-effort suffix. Valid suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`. Malformed TOML, unknown keys, wrong types, empty model
strings, missing model prefixes, and invalid effort suffixes are fatal. Every
present file, every explicit current-session configuration value, and every
non-empty environment override is validated even if a higher layer would
replace its value; missing files and keys inherit instead of failing. An absent
`final_review_model` uses the fully resolved `review_model`. Empty supported
environment variables are ignored. Only `review_model2` has no environment
override.

`use_subagent` is a hard gate for brainstorming and `simplepower:ro`: `false`
prohibits every optional explorer; `true` permits optional exploration but does
not require any dispatch.
Both workflows begin with coordinator-owned initial triage, and neither
automatically dispatches an explorer at startup. Only when triage identifies a
large, cross-cutting, complex, or stalled investigation may the coordinator
fan-out one or more distinct read-only explorers within runtime capacity. Each
explorer receives a self-contained brief and uses `fork_turns="none"`; the
coordinator synthesizes the reports. A selected batch that cannot fully
dispatch stops the workflow rather than silently using a partial batch. This
is separate from the four mandatory model tiers and does not control the
mandatory plan reviewer, implementation, quick verifier, or review+fix agents;
those continue to use the FAST/NORMAL/BEST/REVIEW allocation.

When `review_model2` is distinct, plan review runs two read-only reviewers
concurrently and requires both approvals. If either reviewer cannot dispatch,
the plan-review checkpoint stops instead of downgrading to one reviewer. An
absent or equal `review_model2` keeps the single primary plan-reviewer path.
With `skip_final_review=false`, final review uses exactly one review+fix agent
with the resolved `final_review_model` (or `review_model` when absent). With
`true`, Simple Power omits that phase but still runs final verification and the
final checkpoint condition.

This change does not create or track a repository-level `simplepower.toml`.
When one is present, it is supported and overlays the home file per key.

## Implementation Flow

Simple Power skills use the `simplepower:*` namespace. Mention a skill by name,
such as `simplepower:brainstorming`, when you want Codex to use it.

The brainstorming skill can use a temporary localhost visual companion for
mockups, diagrams, and other visual questions. Generated implementation plans
are saved under `docs/simplepower/plans/`.

After `simplepower:writing-plans` finishes reviewing a plan, Simple Power asks
for combined approval of the reviewed plan, the model allocation, and
immediate execution in the current session with
`simplepower:subagent-driven-development`.
Once you approve, the coordinator creates the accepted plan checkpoint commit
and immediately invokes `simplepower:subagent-driven-development` in the
current session.
To make revised plans and review/fix changes easier to diff, the coordinator
creates temporary local scratch refs as diff anchors; they are review-only
artifacts, not branches or accepted checkpoints, and they are cleaned up after
success.
If a REVIEW-tier reviewer reports issues, the coordinator fixes the plan,
reruns focused self-review checks for the changed categories, and sends the
revised plan back to the original reviewer. When a distinct `review_model2` is
enabled, the same concrete diff goes to both original read-only reviewers.
The reviewers stay open until approval, an unrecoverable interruption, or
explicit user direction.

## How To Use Simple Power

Use `simplepower:brainstorming` and start your plan.

`simplepower:systematic-debugging` also follows the Simple Power flow.

## License

MIT License. See `LICENSE` for details.
