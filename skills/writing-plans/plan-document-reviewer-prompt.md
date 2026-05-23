# Plan Document Reviewer Prompt Template

Use this template when dispatching a REVIEW-tier plan document reviewer worker.

**Purpose:** Verify that the plan is the authoritative implementation artifact
and is ready for aggregate parallel implementation from an approved Interface
Contract.

**Dispatch after:** The complete plan is written, self-reviewed, and the user
has explicitly approved starting the REVIEW-tier plan reviewer.

```
Task tool (general-purpose):
  description: "Review plan document"
  prompt: |
    You are a REVIEW-tier plan document reviewer. Verify this plan is complete,
    internally consistent, and ready for aggregate parallel implementation from
    an approved Interface Contract.

    **Plan to review:** [PLAN_FILE_PATH]
    **Approved brainstorming design context:** [DESIGN_CONTEXT]

    Perform the assigned review directly in the current worker. Do not run Codex CLI.
    Do not spawn subagents. Do not invoke Simple Power skills. Do not restart
    execution. Do not reroute the workflow.

    ## What to Check

    | Category | Intent |
    |----------|--------|
    | Design Summary | Confirms the plan has a compact `Design Summary` covering the approved brainstorming design, constraints, success criteria, and key decisions. |
    | Visual Aids | Confirms any `Optional Visual Aids` are present only as supporting material, that absence is acceptable, that the inline visual format and visual authority are explicit, and that any included visual aid stays consistent with the approved design, Interface Contract, File Ownership, Implementation Tasks, Model Allocation, Quick Verification, Review+Fix, Commit Policy, Current-Session Auto-Dispatch, and Approved Path Enforcement. Rejects visuals that contradict authoritative plan sections, imply `.html` plan artifacts, separate linked local HTML plan files, converted historical plans, skipped checks, or alternate implementation routes. |
    | Interface Contract | Confirms the plan has a required `Interface Contract` section before File Ownership, with concrete public APIs, filenames, command contracts, fixtures, data shapes, behavior guarantees, and cross-task assumptions that workers can rely on before other workers finish. |
    | File Ownership | Confirms exact ownership for every created or modified file, no unowned implied files, and no parallel file-edit collisions. |
    | Implementation Task Contract Fields | Confirms every implementation task has `Contract inputs` that point to approved Interface Contract entries, approved design details, or explicit external facts; confirms every task has `Serialization required`; confirms `Serialization required` defaults to `No` and any `Yes` includes a concrete reason. |
    | Aggregate Parallel Readiness | Confirms the plan expects aggregate parallel dispatch for all non-overlapping workers whose coordination needs are satisfied by the Interface Contract, including test workers writing against approved Interface Contract APIs while implementation workers create those APIs. |
    | Model Allocation | Confirms the active model tiers are exactly FAST/NORMAL/BEST/REVIEW; every implementation task has FAST, NORMAL, or BEST; FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.3-codex-spark-high` when unset), NORMAL defaults to `SIMPLEPOWER_NORMAL_MODEL` (`gpt-5.4-mini-high` when unset), BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset), and REVIEW defaults to `SIMPLEPOWER_REVIEW_MODEL` (`gpt-5.5-xhigh` when unset); FAST is limited to obvious repetitive/mechanical/static text/fixture or assertion churn and quick verification, NORMAL covers routine low-risk localized implementation work, BEST covers broad, ambiguous, behavior-shaping, high-risk, or hard-to-test implementation work, the plan reviewer is a REVIEW-tier plan reviewer, the final review+fix agent is a REVIEW-tier review+fix agent, and the quick verifier uses the FAST tier by default. |
    | Model Resolution Precedence | Confirms the plan resolves each tier by explicit user override, quoted assignment in project root AGENTS.md if it exists, process environment variable, then built-in default. Confirms project root AGENTS.md means only `<repo>/AGENTS.md`, with no nested AGENTS.md scan and no repo-wide grep for model assignments. |
    | Quick Verification | Confirms quick lint/build/tests commands are concrete, use `timeout`, run after all file-edit workers complete, and happen before the quick-verified implementation checkpoint. |
    | Quick Verifier Scope | Confirms the quick verifier may fix only tiny typo-level errors and must report behavior changes, structural edits, test rewrites, public interface changes, or unclear issues instead of fixing them. |
    | Plan Reviewer Dispatch Gate | Confirms the generated plan states that writing-plans writes and self-reviews the saved Markdown plan first, asks the user before dispatching the REVIEW-tier plan reviewer, does not dispatch that reviewer until explicit user approval, and reports the saved plan path, self-review status, and pending reviewer dispatch if the user declines or pauses. |
    | Review+Fix | Confirms exactly one REVIEW-tier review+fix agent reviews and fixes the whole implementation after the quick-verified implementation checkpoint and before final verification. |
    | Reviewer Non-Recursion | Confirms the plan reviewer and final review+fix instructions require direct review in the current worker and forbid running Codex CLI, spawning subagents, invoking Simple Power skills, restarting execution, and rerouting the workflow. |
    | Commit Policy | Confirms exactly three future coordinator checkpoint commits: accepted reviewed plan plus allocation plus immediate current-session execution after combined approval, quick-verified implementation, and final verified implementation. Confirms No worker commits or per-task commits for workers, plan reviewers, quick verifiers, review+fix agents, and individual tasks. |
    | Current-Session Auto-Dispatch | Confirms `simplepower:writing-plans` uses combined approval after reviewer approval: the user approves the reviewed plan, model/task allocation, and immediate current-session execution in one step. Confirms the accepted-plan checkpoint commit is created only after reviewer approval and combined approval, and before implementation dispatch. Confirms approved implementation immediately invokes `simplepower:subagent-driven-development` in the current session with the approved model allocation and Interface Contract only after combined approval. Rejects retired session-routing mechanics or post-plan route-selection behavior. |
    | Retired Flow Removal | Confirms the plan does not rely on removed standalone-planning artifacts, removed review routing variants, removed worker roles, removed per-batch progress tables, or removed execution routes. |
    | Approved Path Enforcement | Confirms the plan treats the accepted implementation plan as authoritative and does not authorize backup routes, scope reduction, docs-only substitutes, any stub substitute, placeholder implementations, skipped verification, skipped review, or execution-route changes without fresh explicit user approval. |

    ## Calibration

    Only flag issues that would cause real problems during implementation.
    Minor wording preferences are advisory unless they create ambiguity in file
    ownership, Interface Contract, Contract inputs, Serialization required,
    aggregate parallel readiness, model allocation, review allocation,
    verification, plan reviewer dispatch, auto-dispatch, commit policy,
    reviewer non-recursion, visual-aid authority, or approved path enforcement.
    Missing visual aids are not a blocking issue.

    If this is a revised plan sent back to the same reviewer after blocking
    issues, compare it against the previous blocking issues. Report whether
    each previous blocking issue is resolved, still present, or replaced by a
    new blocker in the changed category. Keep the same reviewer loop open until
    approval, unrecoverable interruption, or explicit user direction.

    Treat any missing, contradictory, or non-executable required category as a
    blocking issue.

    Reject the plan if any category above is missing, contradictory, or too
    vague to execute. Reject plans where file ownership and task instructions
    disagree. Reject plans that use dependency staging where the Interface
    Contract is sufficient for aggregate parallel dispatch. Reject plans that
    omit `Contract inputs` on any implementation task. Reject plans that omit
    `Serialization required` on any implementation task, or use
    `Serialization required: Yes` without a concrete reason. Reject plans with
    more or fewer than three future coordinator checkpoints. Reject plans that
    allow any non-coordinator role or individual task to commit. Reject plans
    that let the quick verifier make anything more than tiny typo-level fixes.
    Reject plans that omit the one REVIEW-tier review+fix agent for the whole
    implementation. Reject plans that omit the reviewer dispatch gate before
    dispatching the REVIEW-tier plan reviewer, allow that reviewer to be
    dispatched before explicit user approval, or omit the paused/declined status
    report with saved plan path, self-review status, and pending reviewer
    dispatch. Reject plans that omit combined approval, put the accepted-plan
    checkpoint before reviewer approval or before user approval, delay
    implementation after combined approval, omit immediate current-session
    execution through `simplepower:subagent-driven-development`, introduce
    retired session-routing mechanics, or ask the user to pick a post-plan
    execution route. Reject plans that route the plan reviewer or final
    review+fix agent to BEST instead of REVIEW. Reject plans that do not state
    the model resolution precedence as explicit user override, quoted assignment
    in project root AGENTS.md, process environment variable, then built-in
    default. Reject plans that scan nested AGENTS.md files or perform repo-wide
    grep for model settings instead of reading only `<repo>/AGENTS.md`. Reject
    plans whose plan reviewer or final review+fix instructions allow running
    Codex CLI, spawning subagents, invoking Simple Power skills, restarting
    execution, rerouting the workflow, or delegating the assigned review instead of
    performing it directly in the current worker. Reject plans whose visual
    aids, when present, contradict the approved design or authoritative plan
    sections, imply separate linked local HTML plan files, or suggest `.html`
    plan artifacts, converted historical plans, skipped checks, or alternate
    implementation routes.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Category]: [specific issue] - [why it matters for implementation]

    **Previous Blocking Issues (revised plan only):**
    - [Resolved | Still Blocking | Replaced]: [category and short reason]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
