---
name: brainstorming
description: Use only when the user explicitly requests simplepower:brainstorming or an authorized Simple Power chain invokes it.
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a
time to refine the idea. Once you understand what you are building, present the
design and get user approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Approved Path Enforcement

The approved design is authoritative. Do not design backup plans, escape plans,
fallback implementations, reduced scope, docs-only substitutes, stub
substitutes, skipped verification, skipped review, execution-mode switches, or
lower-effort path variants as authorized work.

If the approved design path may be blocked, unsafe, underspecified, or
mismatched with the codebase, describe the blocker or decision point. Do not
authorize alternate implementation work. Any alternate path requires fresh explicit approval
from the user at the moment the deviation is needed.

## Authoritative Procedure

Create a task for each numbered item and complete them in order. Every project
uses this flow, including a todo list, a single-function utility, or a config
change. The design may be only a few sentences for simple work, but approval is
still mandatory before implementation.

1. **Resolve configuration, then explore context.** Before inspecting project
   context, resolve and validate the shared configuration by following
   `skills/using-simplepower/references/simplepower-config.md`. Then inspect
   relevant files, docs, and recent commits.
   - With effective `use_subagent=false`, explorer dispatch is prohibited; do
     all read-only inspection yourself.
   - With effective `use_subagent=true`, optionally dispatch one read-only
     context explorer only if repository context or task complexity makes it
     necessary. If not necessary, do not spawn one.
   - If you dispatch, use the model and reasoning effort parsed from
     `subagent_model`, not a model tier; pass exactly `fork_turns="none"`; give
     a self-contained read-only brief; forbid edits and file creation; and
     require a report with inspected files and commands, architecture and
     conventions, relevant recent changes, risks, and explicit no-edit
     confirmation.
   - If selected dispatch fails because multi-agent support is missing, the
     configured model is unavailable, or spawning fails, stop and report that
     blocker. Do not continue through coordinator-only work, another model, or
     an alternate route.
   - Synthesize any explorer report yourself. The explorer gathers context
     only; you retain every question, approach comparison, design approval, and
     handoff responsibility.
2. **Offer the visual companion only when visual questions are likely.** The
   companion is a temporary browser aid, not a mode and not an implementation
   artifact. If upcoming questions would benefit from mockups, wireframes,
   layout comparisons, diagrams, or other visual treatment, send exactly this
   offer as its own message with no other content:

   > "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

   Wait for the response. If the user accepts, read
   `skills/brainstorming/visual-companion.md` before using the companion. Decide
   per question whether the browser helps: use it for genuinely visual choices;
   use the terminal for requirements, scope, tradeoffs, conceptual options, and
   text decisions. Optional inline visuals in saved Markdown plans belong to
   `simplepower:writing-plans`, not brainstorming.
3. **Assess scope before detailed questions.** If the request spans multiple
   independent subsystems, flag that immediately instead of refining details for
   an oversized plan. Help decompose the project into sub-projects, explain how
   they relate and what order to build them, then brainstorm the first
   sub-project through this same procedure. Each sub-project gets its own plan
   and implementation cycle.
4. **Ask clarifying questions one at a time.** Understand purpose, constraints,
   success criteria, and user priorities. Prefer multiple-choice questions when
   useful, but use open-ended questions when the answer needs room. If a topic
   needs more exploration, split it across messages.
5. **Compare approaches before designing.** Propose 2-3 approaches with
   tradeoffs, lead with the recommended option, and explain why. Apply YAGNI:
   remove unnecessary features from every option.
6. **Present the design for approval, scaled to complexity.** Use short sections
   for simple work and up to 200-300 words for nuanced sections. Ask after each
   section whether it looks right so far, revise when needed, and do not move to
   implementation until the user approves the complete design. Cover the
   relevant architecture, components, data flow, error handling, and testing.
   In existing codebases, follow current patterns; include targeted cleanup only
   when it serves the approved goal; avoid unrelated refactors. Design units
   with clear purposes, interfaces, dependencies, and testable boundaries.
7. **Hand off only to implementation planning.** After approval, invoke
   `simplepower:writing-plans` and pass the approved design summary,
   constraints, decisions, and success criteria forward in the current
   conversation. The plan file is the authoritative implementation artifact.

The terminal state is invoking `simplepower:writing-plans`. Do not write a
standalone spec document, ask the user to review a written spec, create a
spec-review loop, invoke frontend-design, invoke mcp-builder, or take any
implementation action from brainstorming. The only skill you invoke after
brainstorming is `simplepower:writing-plans`.
