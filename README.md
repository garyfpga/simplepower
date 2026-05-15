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
| Subagent Implementation <br><br> 这就是 SimplePower 快的原因 | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | 多个 subagent 并行处理多个文件 -> <br> 快速测试 runner subagent (spark) -> <br> 单个最终 reviewer + fixer
| Git Commits? | 每一步 | parallel subagent 之后一次性提交 + <br> review 之后最终提交

## 安装

从 Codex plugin marketplace 安装 Simple Power：

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin marketplace upgrade
```

以后只要想拉取 marketplace 更新，就再次运行 `codex plugin marketplace upgrade`。

## 模型分配

Simple Power 使用三个可配置的模型层级：

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"
```

把每个值按 `<model>-<reasoning_effort>` 解析：最后一个以 dash 分隔的片段作为 `reasoning_effort`，前面的字符串作为 `model`。
例如，`gpt-5.4-mini-high` 会解析为 `model="gpt-5.4-mini"` 和 `reasoning_effort="high"`。

BEST 用于广泛、跨文件、含糊、会改变行为、高风险、难测试的工作，以及 plan reviewer 和 final review+fix。
NORMAL 用于原来会放进旧 FAST 层的常规低风险实现工作，尤其是局部修改。
FAST 是 Spark 层，用于明显重复的工作、多文件机械性修改、大量静态文本扫改、简单 fixture/assertion 变更，以及快速验证。

## 实现流程

Simple Power skills 使用 `simplepower:*` namespace。当你想让 Codex 使用某个 skill 时，直接提到它的名字，例如 `simplepower:brainstorming`。

brainstorming skill 可以使用临时的 localhost visual companion 来处理 mockups、diagrams 和其他视觉问题。生成的 implementation plans 会保存到 `docs/simplepower/plans/`。

在 `simplepower:writing-plans` 完成 plan review 之后，Simple Power 会一次性询问你是否批准已审阅的 plan、模型分配，以及立刻在当前 session 里启动 `simplepower:subagent-driven-development`。
你确认后，coordinator 会创建 accepted plan checkpoint commit，并立即调用 `simplepower:subagent-driven-development` 执行已批准的 plan。
如果 reviewer 提出问题，coordinator 会修正 plan、重新跑相关自检，再把 revised plan 送回同一个 reviewer。reviewer 会一直保持打开，直到通过、发生不可恢复中断，或你明确要求停止。

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
| Subagent Implementation <br><br> this is why SimplePower is fast | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | Many subagents in parallel for multiple files -> <br> Quick tests runner subagent (spark) -> <br> Single final reviewer + fixer
| Git Commits? | every steps | all at once after parallel subagent + <br> final after review

## Installation

Install Simple Power from the Codex plugin marketplace:

```bash
codex plugin marketplace add garyfpga/codex-plugins
codex plugin marketplace upgrade
```

Use `codex plugin marketplace upgrade` again whenever you want to pull
marketplace updates.

## Model Allocation

Simple Power uses three configurable model tiers:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_NORMAL_MODEL="gpt-5.4-mini-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.3-codex-spark-high"
```

Parse each value as `<model>-<reasoning_effort>` by taking the final
dash-delimited segment as `reasoning_effort` and the preceding string as
`model`. For example, `gpt-5.4-mini-high` resolves to
`model="gpt-5.4-mini"` and `reasoning_effort="high"`.

BEST is for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test work, plus the plan reviewer and final review+fix.
NORMAL is for routine low-risk implementation work that used to fit the old
FAST tier, especially localized edits.
FAST is the Spark tier for obvious repetitive work, mechanical edits across
many files, large static text sweeps, simple fixture/assertion churn, and quick
verification.

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
If the reviewer reports issues, the coordinator fixes the plan, reruns focused
self-review checks for the changed categories, and sends the revised plan back
to the same reviewer. The reviewer stays open until approval, an unrecoverable
interruption, or explicit user direction.

## How To Use Simple Power

Use `simplepower:brainstorming` and start your plan.

`simplepower:systematic-debugging` also follows the Simple Power flow.

## License

MIT License. See `LICENSE` for details.
