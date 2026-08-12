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
| Spec / Plan | brainstorming -> <br> approve spec -> <br> spec.md (commit) -> <br> plan.md (approve and commit) | brainstorming -> <br> approve spec -> <br> plan.md -> <br> optional configured single-pass review -> <br> approve and commit <br> 懒得同时检查 spec.md 和 plan.md
| Subagent Implementation <br><br> 这就是 SimplePower 快的原因 | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | Main agent 直接处理一个 cohesive package；或者只在有清晰价值时使用 Grouped workers -> <br> mandatory FAST-tier quick verifier -> <br> main agent final diff review + in-scope fixes
| Git Commits? | 每一步 | 两个 mandatory checkpoint types + <br> 必要时 bounded coordinator execution commits

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

Simple Power 的正常 brainstorming-to-implementation chain 使用三个主动模型层级：BEST、NORMAL 和 FAST。可选的 `plan_review_model` 在显式配置时提供一次 single-pass plan review。旧的 REVIEW 配置仍被识别和严格验证，方便已有配置继续工作，但在正常流程里已经是 deprecated compatibility/no-op。

```toml
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
# Optional; no built-in default:
# plan_review_model = "gpt-5.6-luna-max"
# Deprecated compatibility/no-op in the normal chain:
review_model = "gpt-5.6-sol-high"
```

最终主动分配为 BEST = `gpt-5.6-sol`/`high`、NORMAL = `gpt-5.6-luna`/`max`、FAST = `gpt-5.3-codex-spark`/`xhigh`。

环境变量可以覆盖 `use_subagent`、`subagent_model`、三个主动模型层级、可选 `plan_review_model`、deprecated compatibility `review_model`、`final_review_model` 和 `skip_final_review`，对应 `SIMPLEPOWER_USE_SUBAGENT`、`SIMPLEPOWER_SUBAGENT_MODEL`、`SIMPLEPOWER_REVIEW_MODEL`、`SIMPLEPOWER_PLAN_REVIEW_MODEL`、`SIMPLEPOWER_BEST_MODEL`、`SIMPLEPOWER_NORMAL_MODEL`、`SIMPLEPOWER_FAST_MODEL`、`SIMPLEPOWER_FINAL_REVIEW_MODEL` 和 `SIMPLEPOWER_SKIP_FINAL_REVIEW`。不存在 `SIMPLEPOWER_REVIEW_MODEL2`。根目录或嵌套的 `AGENTS.md` 都不再提供模型赋值。

`plan_review_model` 没有内建默认值，也不会 fallback 到 `review_model`。只有 home/repository `simplepower.toml` 中存在该 key，或 `SIMPLEPOWER_PLAN_REVIEW_MODEL` 为 non-empty 时才会启用一次 read-only plan review。Current-session 指示只能覆盖已经启用的 model，不能单独启用 review。Reviewer 只返回 Critical 和 Must Fix；main agent 修复或明确驳回这些 findings 后直接视为 reviewed，不会重新发送 plan，也不会创建 plan-review scratch refs。Reviewer 无法启动或返回 usable report 时，记录失败并继续使用 main-agent self-review，不重试。

`review_model`、`review_model2`、`final_review_model` 和 `skip_final_review` 是 deprecated compatibility settings。它们继续被支持、按原环境变量行为解析并严格验证，但不会启用上述 optional plan reviewer 或 final review+fix agent，也不再根据 `skip_final_review` 改变 final verification。`final_review_model` 缺失时仍按兼容规则等于已解析的 `review_model`；`skip_final_review` 默认仍是 `false`，但在正常 chain 中是 no-op。

`review_model2` 是可选的兼容配置；它没有内建默认值，也没有环境变量覆盖。缺失或与已解析的 `review_model` 完全相等时保持兼容解析结果；distinct 的值仍必须是有效模型字符串，但正常 chain 中不会创建 secondary plan reviewer。

BEST 用于广泛、跨文件、含糊、会改变行为、高风险、难测试的工作。
NORMAL 用于原来会放进旧 FAST 层的常规低风险实现工作，尤其是局部修改。
FAST 是 Spark 层，用于明显重复的工作、多文件机械性修改、大量静态文本扫改、简单 fixture/assertion 变更，以及 mandatory quick verifier。

## 配置

Simple Power 按 key 独立解析配置：先使用内建默认值，再 overlay `~/.codex/simplepower.toml` 中出现的 key；在 Git 仓库内，再 overlay `<git-root>/simplepower.toml` 中出现的 key；然后 overlay 上述非空环境变量；最后应用当前 session 的显式指示。较高层缺失的 key 会继承较低层的值，因此 repository 文件不会整体替代 home 文件。在 Git 仓库外跳过 repository 文件这一层。

可复制的完整示例见 [simplepower.toml.example](simplepower.toml.example)；该文件本身不是 active repository configuration。

支持的 TOML 顶层 key 仍是以下七个 base keys，加上没有独立默认值的可选 `plan_review_model`、`review_model2` 和 `final_review_model`。七个 base key 的精确默认值如下；legacy review key 是正常 chain 的 deprecated compatibility/no-op：

```toml
use_subagent = false
skip_final_review = false
subagent_model = "gpt-5.6-luna-xhigh"
review_model = "gpt-5.6-sol-high"
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
```

`use_subagent` 和 `skip_final_review` 必须是 TOML Boolean。对应的环境变量仅接受不区分大小写的 `true` 或 `false`，所以 `true`、`True`、`TRUE` 等价；其他非空值是 fatal error。每个存在的模型 key（包括可选的 `plan_review_model`、`review_model2` 和 `final_review_model`）都必须是非空 TOML string，并按最后一个 dash 拆成非空 model prefix 与 reasoning-effort suffix；合法 suffix 只有 `low`、`medium`、`high`、`xhigh`、`max` 和 `ultra`。格式错误的 TOML、未知 key、错误类型、空模型字符串、缺失 model prefix 或非法 effort 都是 fatal error。每个存在的文件、每个显式 current-session 配置值，以及每个非空环境 override 都必须验证，即使更高层随后会覆盖同一 key；缺失文件或 key 则继承。`final_review_model` 缺失时使用完全解析后的 `review_model`。所有空的受支持环境变量都会被忽略，也不会启用 plan review。只有 `review_model2` 没有环境变量覆盖。

`use_subagent` 是 brainstorming 和 `simplepower:ro` 的硬 gate：`false` 禁止所有可选 explorer；`true` 只是 permission，不是启动指令。两个 workflow 都先由 coordinator 进行 initial triage，不会在启动时自动 dispatch explorer。只有 triage 判断 investigation 属于 large、cross-cutting、complex 或 stalled 时，coordinator 才能在 runtime capacity 内 fan-out 一个或多个具有 distinct investigation angles 的 read-only explorers。每个 explorer 都使用自包含 brief 和 `fork_turns="none"`，只能读取和运行只读命令；coordinator 会综合所有报告。选定的 explorer batch 如果无法完整派发，流程会停止，不会用 partial batch 静默替代。

正常 implementation route 是自适应的：`Implementation Route: Main agent` 用于一个 cohesive package 且没有实质 specialization benefit 的工作；`Implementation Route: Grouped workers` 只用于至少两个 independent non-overlapping packages，或确实因专业化 delegation 明显受益的工作。Main-agent plans 保持紧凑，包含 design summary、route、exact files、implementation steps、risks、timed quick/final verification、原始 plan execution record，以及两个 mandatory checkpoint types。Grouped-worker plans 额外包含 Interface Contract、File Ownership、cohesive Worker Packages、serialization decisions，以及 FAST/NORMAL/BEST allocation。Closely related code and tests stay in one package；capacity 只能 queue package，不能造成 tiny-task splitting。

这次变更不会创建或 track repository-level `simplepower.toml`；如果该文件存在，系统会支持它并按 key overlay home 文件。

## 实现流程

Simple Power skills 使用 `simplepower:*` namespace。当你想让 Codex 使用某个 skill 时，直接提到它的名字，例如 `simplepower:brainstorming`。

brainstorming skill 可以使用临时的 localhost visual companion 来处理 mockups、diagrams 和其他视觉问题。生成的 implementation plans 会保存到 `docs/simplepower/plans/`。

在 `simplepower:writing-plans` 完成 main-agent plan self-review 之后，如果 optional `plan_review_model` 已启用，Simple Power 会 dispatch 一次 read-only reviewer，只处理 Critical 和 Must Fix findings。Main agent 做一次 fix pass 后不会 re-review；review dispatch 失败或 report unusable 时继续使用已完成的 self-review。之后 Simple Power 会一次性询问你是否批准最终 plan、route/model allocation、两个 mandatory checkpoint types、active run 内受限的 coordinator execution commits，以及立刻在当前 session 里启动 `simplepower:subagent-driven-development`。
你确认后，coordinator 会创建 accepted plan checkpoint commit，并立即调用 `simplepower:subagent-driven-development` 执行已批准的 plan。
如果 route 是 Main agent，coordinator 直接编辑一个 cohesive package，不 dispatch `sp-impl` worker。如果 route 是 Grouped workers，coordinator 只把相关 design/contract/scope/verification context 发送给各个 cohesive package worker，而不是完整 plan 和重复的全局 boilerplate；每个 grouped `sp-impl` dispatch 都必须使用 `fork_turns="none"`。
所有 route 都必须运行 mandatory FAST quick verifier。Quick verifier 只能做 tiny typo-level fixes；non-trivial failures 回到 main agent 诊断和 in-scope 修复。正常 workflow 只保留 quick-verifier scratch refs；optional plan review 和 final review 都没有 scratch phase。Main agent 做 final diff review、in-scope fixes 和第一次 final verification，然后在原始 plan 中写入精简的 `Execution Summary`，最后一次 summary edit 后不再修改文件并重新运行 terminal verification。只有 approved test/work 客观要求 committed state，或 summary 必须单独/再次更新时，active run 才允许额外 coordinator commit；convenience、worker 和 per-task commits 仍然禁止。最新 verified commit 是 final completion checkpoint，authorization 在 final handoff 结束。

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
| Spec / Plan | brainstorming -> <br> approve spec -> <br> spec.md (commit) -> <br> plan.md (approve and commit) | brainstorming -> <br> approve spec -> <br> plan.md -> <br> optional configured single-pass review -> <br> approve and commit <br> too lazy to check spec.md and plan.md
| Subagent Implementation <br><br> this is why SimplePower is fast | Task1 impl agent -> <br> Task1 planning check -> <br> Task1 quality agent -> <br> Task2 impl agent -> <br> Task2 planning check -> <br> Task2 quality agent -> <br>  .... | Main agent directly edits one cohesive package; or Grouped workers only when delegation has clear value -> <br> mandatory FAST-tier quick verifier -> <br> main agent final diff review + in-scope fixes
| Git Commits? | every steps | two mandatory checkpoint types + <br> bounded coordinator execution commits when required

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

The normal Simple Power brainstorming-to-implementation chain actively uses
three model tiers: BEST, NORMAL, and FAST. Optional `plan_review_model` adds one
single-pass plan review when explicitly configured. The legacy REVIEW
configuration is still recognized and strictly validated for existing configs,
but it is a deprecated compatibility/no-op setting in the normal chain.

```toml
best_model = "gpt-5.6-sol-high"
normal_model = "gpt-5.6-luna-max"
fast_model = "gpt-5.3-codex-spark-xhigh"
# Optional; no built-in default:
# plan_review_model = "gpt-5.6-luna-max"
# Deprecated compatibility/no-op in the normal chain:
review_model = "gpt-5.6-sol-high"
```

The active assignments are BEST = `gpt-5.6-sol`/`high`, NORMAL =
`gpt-5.6-luna`/`max`, and FAST =
`gpt-5.3-codex-spark`/`xhigh`.

The environment can override `use_subagent`, `subagent_model`, the three active
model tiers, optional `plan_review_model`, deprecated compatibility
`review_model`, `final_review_model`, and `skip_final_review` through
`SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SUBAGENT_MODEL`,
`SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_PLAN_REVIEW_MODEL`,
`SIMPLEPOWER_BEST_MODEL`,
`SIMPLEPOWER_NORMAL_MODEL`, `SIMPLEPOWER_FAST_MODEL`,
`SIMPLEPOWER_FINAL_REVIEW_MODEL`, and `SIMPLEPOWER_SKIP_FINAL_REVIEW`. There is
no `SIMPLEPOWER_REVIEW_MODEL2`. Root and nested `AGENTS.md` files do not provide model assignments.

`plan_review_model` has no built-in default and does not fall back to
`review_model`. A key in the home or repository `simplepower.toml`, or a
non-empty `SIMPLEPOWER_PLAN_REVIEW_MODEL`, activates one read-only plan review.
A current-session instruction can override only an active model. The reviewer
returns only Critical and Must Fix findings. The main agent fixes or explicitly
dismisses them once, then treats the plan as reviewed without redispatch or
plan-review scratch refs. A launch failure or unusable report falls back to the
completed main-agent self-review without retrying.

`review_model`, `review_model2`, `final_review_model`, and `skip_final_review`
are deprecated compatibility settings. They remain supported, preserve their
environment behavior, and are strictly validated so existing configs keep
working, but they do not activate the optional plan reviewer or a final
review+fix agent, and `skip_final_review` no longer changes final verification.
When absent, `final_review_model` still resolves to `review_model` for
compatibility; `skip_final_review` still defaults to `false` but is a no-op in
the normal chain.

`review_model2` is an optional compatibility key. It has no built-in default
and no environment override. If present and distinct from `review_model`, it
must still be a valid model string, but the normal chain does not create a
secondary plan reviewer.

BEST is for broad, cross-cutting, ambiguous, behavior-shaping, high-risk, or
hard-to-test work.
NORMAL is for routine low-risk implementation work that used to fit the old
FAST tier, especially localized edits.
FAST is the Spark tier for obvious repetitive work, mechanical edits across
many files, large static text sweeps, simple fixture/assertion churn, and the
mandatory quick verifier.

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

The supported TOML schema is still these seven base keys plus optional
`plan_review_model`, `review_model2`, and `final_review_model`. The seven base
keys have the following exact defaults; legacy review keys are deprecated
compatibility no-ops in the normal chain:

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
model key, including optional `plan_review_model`, `review_model2`, and
`final_review_model`, must be a nonempty TOML
string and is parsed at its final dash into a nonempty model prefix and a
reasoning-effort suffix. Valid suffixes are `low`, `medium`, `high`, `xhigh`,
`max`, and `ultra`. Malformed TOML, unknown keys, wrong types, empty model
strings, missing model prefixes, and invalid effort suffixes are fatal. Every
present file, every explicit current-session configuration value, and every
non-empty environment override is validated even if a higher layer would
replace its value; missing files and keys inherit instead of failing. An absent
`final_review_model` uses the fully resolved `review_model`. Empty supported
environment variables are ignored and do not activate plan review. Only
`review_model2` has no environment
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
dispatch stops the workflow rather than silently using a partial batch. This is
separate from the active implementation and verification model tiers.

The normal implementation route is adaptive. `Implementation Route: Main
agent` is for one cohesive package with no material specialization benefit.
`Implementation Route: Grouped workers` is only for at least two independent,
non-overlapping packages or specialized work that materially benefits from
delegation. Main-agent plans stay compact with design summary, route, exact
files, implementation steps, risks, timed quick/final verification, the
original-plan execution record, and two mandatory checkpoint types.
Grouped-worker plans add Interface Contract, File
Ownership, cohesive Worker Packages, serialization decisions, and
FAST/NORMAL/BEST allocation. Closely related code and tests stay in one
package; capacity queues packages but must not create tiny-task splitting.

This change does not create or track a repository-level `simplepower.toml`.
When one is present, it is supported and overlays the home file per key.

## Implementation Flow

Simple Power skills use the `simplepower:*` namespace. Mention a skill by name,
such as `simplepower:brainstorming`, when you want Codex to use it.

The brainstorming skill can use a temporary localhost visual companion for
mockups, diagrams, and other visual questions. Generated implementation plans
are saved under `docs/simplepower/plans/`.

After `simplepower:writing-plans` finishes main-agent plan self-review, it runs
one read-only reviewer when optional `plan_review_model` is active. The main
agent handles only Critical and Must Fix findings in one fix pass and never
resends the plan; launch or report failures fall back to the completed
self-review. Simple Power then asks for combined approval of the final plan,
route/model allocation, two mandatory checkpoint types, bounded coordinator
execution commits during the active run, and
immediate execution in the current session with
`simplepower:subagent-driven-development`.
Once you approve, the coordinator creates the accepted plan checkpoint commit
and immediately invokes `simplepower:subagent-driven-development` in the
current session.
For `Implementation Route: Main agent`, the coordinator directly edits the one
cohesive package and does not dispatch an `sp-impl` worker. For
`Implementation Route: Grouped workers`, each worker receives only the relevant
design, contract, scope, and verification context for its cohesive package, not
the complete plan or repeated global boilerplate; every grouped `sp-impl`
dispatch passes `fork_turns="none"`.
Every route runs the mandatory FAST quick verifier. The quick verifier may make
only tiny typo-level fixes; non-trivial failures return to the main agent for
diagnosis and in-scope repair. The normal workflow keeps only quick-verifier scratch refs as temporary local diff anchors,
and they are cleaned up after the successful final checkpoint. Optional plan
review and final review have no scratch phase. The main agent performs the final
diff review, applies in-scope fixes, and runs the first final-verification pass.
It then writes a concise `Execution Summary` into the original plan and reruns
terminal verification without further file edits. An additional coordinator
commit is allowed only when approved testing/work objectively requires committed
state or when the summary must be committed separately or refreshed after a
later in-run finding. Convenience, worker, and per-task commits remain
forbidden. The newest verified commit is the final-completion checkpoint, and
commit authorization ends at final handoff.

## How To Use Simple Power

Use `simplepower:brainstorming` and start your plan.

`simplepower:systematic-debugging` also follows the Simple Power flow.

## License

MIT License. See `LICENSE` for details.
