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
| Subagent Implementation <br><br> 这就是 SimplePower 快的原因 | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | 多个 subagent 并行处理多个文件 -> <br> FAST-tier 快速验证 subagent -> <br> 单个 REVIEW-tier reviewer + fixer
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

Simple Power 使用四个可配置的模型层级：

```bash
SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"
```

先按这个顺序解析模型设置：显式用户 override、项目根目录 `AGENTS.md` 里的 quoted assignment、进程环境变量、内建默认值。模型赋值只读取 `<repo>/AGENTS.md`；不会扫描嵌套 AGENTS 文件，也不会对整个仓库做 grep。

把每个值按 `<model>-<reasoning_effort>` 解析：最后一个以 dash 分隔的片段作为 `reasoning_effort`，前面的字符串作为 `model`。
例如，`gpt-5.4-mini-high` 会解析为 `model="gpt-5.4-mini"` 和 `reasoning_effort="high"`。

REVIEW 用于 plan reviewer 和 final review+fix。
BEST 用于广泛、跨文件、含糊、会改变行为、高风险、难测试的工作。
NORMAL 用于原来会放进旧 FAST 层的常规低风险实现工作，尤其是局部修改。
FAST 是 Spark 层，用于明显重复的工作、多文件机械性修改、大量静态文本扫改、简单 fixture/assertion 变更，以及快速验证。

## 可选 subagent 配置

Simple Power 可以读取一个可选的 `simplepower.toml`。在 Git 仓库内，配置位置是 `<git-root>/simplepower.toml` 或 `~/.codex/simplepower.toml`；如果项目文件存在，它会完全替代 home 配置，不会合并。在 Git 仓库外只读取 home 配置。当前 session 里用户的显式指示始终优先。

```toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
```

缺少的 key 使用以上默认值。`subagent_model` 按最后一个 dash 拆分 model 和 reasoning effort，所以默认值解析为 `model="gpt-5.6-luna"`、`reasoning_effort="xhigh"`。格式错误的 TOML、未知 key、错误类型或无效值都会停止流程。

`use_subagent` 只控制三种可选派发：brainstorming 开始时的一个只读 explorer、`simplepower:ro` 开始时的一个只读 explorer，以及 systematic debugging 在初始 Phase 1 卡住后的并行调查。它不控制强制的 plan reviewer、implementation、quick verifier 或 review+fix agents；这些仍使用 FAST/NORMAL/BEST/REVIEW 分配。启用可选 subagent 后，如果 multi-agent 支持、指定模型或派发不可用，流程会停止，不会静默降级。每一次 Simple Power agent 派发都使用 `fork_turns="none"` 和自包含上下文。

这个仓库不会提供 tracked 默认 `simplepower.toml`；只有需要改变默认行为时才创建个人或项目配置。

## 实现流程

Simple Power skills 使用 `simplepower:*` namespace。当你想让 Codex 使用某个 skill 时，直接提到它的名字，例如 `simplepower:brainstorming`。

brainstorming skill 可以使用临时的 localhost visual companion 来处理 mockups、diagrams 和其他视觉问题。生成的 implementation plans 会保存到 `docs/simplepower/plans/`。

在 `simplepower:writing-plans` 完成 plan review 之后，Simple Power 会一次性询问你是否批准已审阅的 plan、模型分配，以及立刻在当前 session 里启动 `simplepower:subagent-driven-development`。
你确认后，coordinator 会创建 accepted plan checkpoint commit，并立即调用 `simplepower:subagent-driven-development` 执行已批准的 plan。
为了让 reviewer 更容易对 revised plan 和 review/fix 变化做 diff，coordinator 会在本地创建临时 scratch refs 作为 diff anchors；这些 refs 只是审阅辅助，不是 branch 或 accepted checkpoint，成功后会清理。
如果 REVIEW-tier reviewer 提出问题，coordinator 会修正 plan、重新跑相关自检，再把 revised plan 送回同一个 reviewer。REVIEW-tier reviewer 会一直保持打开，直到通过、发生不可恢复中断，或你明确要求停止。

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
| Subagent Implementation <br><br> this is why SimplePower is fast | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | Many subagents in parallel for multiple files -> <br> FAST-tier quick verifier subagent -> <br> Single REVIEW-tier reviewer + fixer
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

Simple Power uses four configurable model tiers:

```bash
SIMPLEPOWER_REVIEW_MODEL="gpt-5.5-xhigh"
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"
```

Resolve model settings in this order: explicit user override, quoted
assignment in project root `AGENTS.md`, process environment variable, built-in
default. Model assignment lookup only reads `<repo>/AGENTS.md`; nested AGENTS
files and repo-wide grep are not part of this feature.

Parse each value as `<model>-<reasoning_effort>` by taking the final
dash-delimited segment as `reasoning_effort` and the preceding string as
`model`. For example, `gpt-5.4-mini-high` resolves to
`model="gpt-5.4-mini"` and `reasoning_effort="high"`.

REVIEW is for the plan reviewer and final review+fix agent.
BEST is for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test work.
NORMAL is for routine low-risk implementation work that used to fit the old
FAST tier, especially localized edits.
FAST is the Spark tier for obvious repetitive work, mechanical edits across
many files, large static text sweeps, simple fixture/assertion churn, and quick
verification.

## Optional Subagent Configuration

Simple Power can read an optional `simplepower.toml`. Inside a Git repository,
the locations are `<git-root>/simplepower.toml` and
`~/.codex/simplepower.toml`; when the repository file exists, it completely
replaces the home configuration rather than merging with it. Outside Git, only
the home configuration is read. Explicit instructions from the user in the
current session always take precedence.

```toml
use_subagent = false
subagent_model = "gpt-5.6-luna-xhigh"
```

Missing keys use the defaults above. `subagent_model` splits at the final dash
into model and reasoning effort, so the default resolves to
`model="gpt-5.6-luna"` and `reasoning_effort="xhigh"`. Malformed TOML, unknown
keys, wrong types, and invalid values stop the workflow.

`use_subagent` controls only three optional dispatches: one initial read-only
explorer for brainstorming, one initial read-only explorer for
`simplepower:ro`, and parallel investigation after the initial Phase 1 of
systematic debugging stalls. It does not control the mandatory plan reviewer,
implementation, quick verifier, or review+fix agents; those continue to use
the FAST/NORMAL/BEST/REVIEW allocation. When optional subagents are enabled,
missing multi-agent support, an unavailable configured model, or a spawn
failure stops the workflow without silent fallback. Every Simple Power agent
dispatch uses `fork_turns="none"` with self-contained context.

The repository does not provide a tracked default `simplepower.toml`; create a
personal or repository configuration only when you need to change the
defaults.

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
If the REVIEW-tier reviewer reports issues, the coordinator fixes the plan,
reruns focused self-review checks for the changed categories, and sends the
revised plan back to the same reviewer. The REVIEW-tier reviewer stays open
until approval, an unrecoverable interruption, or explicit user direction.

## How To Use Simple Power

Use `simplepower:brainstorming` and start your plan.

`simplepower:systematic-debugging` also follows the Simple Power flow.

## License

MIT License. See `LICENSE` for details.
