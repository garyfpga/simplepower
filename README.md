# SimplePower

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

Simple Power uses two configurable model tiers:

```bash
SIMPLEPOWER_BEST_MODEL="gpt-5.5-high"
SIMPLEPOWER_FAST_MODEL="gpt-5.4-mini-high"
```

Parse each value as `<model>-<reasoning_effort>` by taking the final
dash-delimited segment as `reasoning_effort` and the preceding string as
`model`. For example, `gpt-5.4-mini-high` resolves to
`model="gpt-5.4-mini"` and `reasoning_effort="high"`.

## Implementation Flow

Simple Power skills use the `simplepower:*` namespace. Mention a skill by name,
such as `simplepower:brainstorming`, when you want Codex to use it.

The brainstorming skill can use a temporary localhost visual companion for
mockups, diagrams, and other visual questions. Generated implementation plans
are saved under `docs/simplepower/plans/`.

After `simplepower:writing-plans` saves and reviews a plan, it asks which
implementation handoff to use. The recommendation comes from current Codex context usage
when available: below `55%` continues in the current session, and
`55%` or higher recommends a fresh session. If context measurement is
unavailable, Simple Power falls back to saved plan size. The handoff still shows
both commands; for fresh context, run `/clear` first.

## How To Use Simple Power

Use `simplepower:brainstorming` and start your plan.

`simplepower:systematic-debugging` also follows the Simple Power flow.

## License

MIT License. See `LICENSE` for details.
