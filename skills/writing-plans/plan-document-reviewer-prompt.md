# Plan Document Reviewer Prompt Template

Use this template when dispatching a primary REVIEW-tier plan document reviewer
or a distinct optional read-only secondary plan document reviewer.

**Purpose:** Verify that the plan is the authoritative implementation artifact
and is ready for aggregate parallel implementation from an approved Interface
Contract.

**Dispatch after:** The complete plan is written and self-reviewed.

```
Task tool (general-purpose):
  description: "Review plan document"
  prompt: |
    You are a [PRIMARY REVIEW-TIER | OPTIONAL SECONDARY READ-ONLY] plan document
    reviewer. Verify this plan is complete, internally consistent, and ready for
    aggregate parallel implementation from an approved Interface Contract.

    **Plan to review:** [PLAN_FILE_PATH]
    **Approved brainstorming design context:** [DESIGN_CONTEXT]
    **Review route and current revision:** [SINGLE PRIMARY | DISTINCT DUAL; REVISION]
    **Scratch evidence:** [RUN ID, `plan-review/before` OR CONCRETE REVISION DIFF]

    Perform the assigned review directly in the current worker. This is
    read-only: do not edit or create files, stage, commit, or create, update,
    delete, or manage refs. Do not run Codex CLI. Do not spawn subagents. Do
    not invoke Simple Power skills. Do not restart execution. Do not reroute
    the workflow.

    ## What to Check

    | Category | Intent |
    |----------|--------|
    | Design Summary | Confirms the plan has a compact `Design Summary` covering the approved brainstorming design, constraints, success criteria, and key decisions. |
    | Visual Aids | Confirms any `Optional Visual Aids` are present only as supporting material, that absence is acceptable, that the inline visual format and visual authority are explicit, and that any included visual aid stays consistent with the approved design, Interface Contract, File Ownership, Implementation Tasks, Model Allocation, Quick Verification, Review+Fix, Commit Policy, Current-Session Auto-Dispatch, and Approved Path Enforcement. Rejects visuals that contradict authoritative plan sections, imply `.html` plan artifacts, separate linked local HTML plan files, converted historical plans, skipped checks, or alternate implementation routes. |
    | Interface Contract | Confirms the plan has a required `Interface Contract` section before File Ownership, with concrete public APIs, filenames, command contracts, fixtures, data shapes, behavior guarantees, and cross-task assumptions that workers can rely on before other workers finish. |
    | File Ownership | Confirms exact ownership for every created or modified file, no unowned implied files, and no parallel file-edit collisions. |
    | Implementation Task Contract Fields | Confirms every implementation task has `Contract inputs` that point to approved Interface Contract entries, approved design details, or explicit external facts; confirms every task has `Serialization required`; confirms `Serialization required` defaults to `No` and any `Yes` includes a concrete reason. |
    | Aggregate Parallel Readiness | Confirms the plan expects aggregate parallel dispatch for all non-overlapping workers whose coordination needs are satisfied by the Interface Contract, including test workers writing against approved Interface Contract APIs while implementation workers create those APIs. |
    | Model Allocation | Confirms the active mandatory model tiers are exactly FAST/NORMAL/BEST/REVIEW and independent of `use_subagent`; every implementation task has FAST, NORMAL, or BEST; FAST defaults to `gpt-5.3-codex-spark-xhigh`, NORMAL defaults to `gpt-5.6-luna-max`, and BEST and REVIEW default to `gpt-5.6-sol-high`; FAST is limited to obvious repetitive/mechanical/static text/fixture or assertion churn and quick verification, NORMAL covers routine low-risk localized implementation work, BEST covers broad, ambiguous, behavior-shaping, high-risk, or hard-to-test implementation work, the primary plan reviewer is REVIEW-tier, and the quick verifier uses FAST by default. Confirms effective `skip_final_review=false` runs one final review+fix agent with effective `final_review_model` (falling back to REVIEW), while `true` skips that phase but retains final verification. Confirms an optional distinct `review_model2` is only a read-only plan-review secondary route, never a fifth mandatory tier or a second final reviewer. |
    | Model Resolution Precedence | Confirms the plan follows the seven base keys plus optional `review_model2` and `final_review_model` in `skills/using-simplepower/references/simplepower-config.md`: built-in defaults, per-key overlays from `/home/gary/.codex/simplepower.toml`, repository `<git-root>/simplepower.toml`, the supported non-empty `SIMPLEPOWER_USE_SUBAGENT`, `SIMPLEPOWER_SKIP_FINAL_REVIEW`, `SIMPLEPOWER_SUBAGENT_MODEL`, `SIMPLEPOWER_REVIEW_MODEL`, `SIMPLEPOWER_FINAL_REVIEW_MODEL`, `SIMPLEPOWER_BEST_MODEL`, `SIMPLEPOWER_NORMAL_MODEL`, and `SIMPLEPOWER_FAST_MODEL` process environment values, and explicit current-session instructions last. Confirms the seven base TOML keys are `use_subagent`, `skip_final_review`, `subagent_model`, `review_model`, `best_model`, `normal_model`, and `fast_model`; `review_model2` has no environment variable, `final_review_model` falls back to resolved `review_model` when absent, and `review_model2` enables a plan-review secondary only when distinct from the resolved primary. Missing higher-layer keys inherit; every present TOML file is validated in full and is fatal if invalid even when a higher layer overrides its values; model assignments are not read from `AGENTS.md`; and each final dash suffix is one of `low`, `medium`, `high`, `xhigh`, `max`, or `ultra`. |
    | Quick Verification | Confirms quick lint/build/tests commands are concrete, use `timeout`, run after all file-edit workers complete, and happen before the quick-verified implementation checkpoint. |
    | Quick Verifier Scope | Confirms the quick verifier may fix only tiny typo-level errors and must report behavior changes, structural edits, test rewrites, public interface changes, or unclear issues instead of fixing them. |
    | Conditional Review Routing | Confirms an absent `review_model2` or exact match retains one primary plan reviewer, while a distinct secondary dispatches both plan reviewers concurrently, read-only, from self-contained evidence; both plan reviewers approve the same revision, and each revision's concrete scratch diff returns to both original reviewers. Confirms a launch failure stops the checkpoint instead of accepting a partial review. |
    | Review+Fix | Confirms `skip_final_review=false` runs exactly one final review+fix agent that owns all final edits after the quick-verified implementation checkpoint and before final verification. It uses effective `final_review_model`, directly receives in-scope fix authority, and does not create a concurrent reviewer or extra checkpoint. Confirms `skip_final_review=true` omits review+fix scratch refs and dispatch while retaining final verification and the final checkpoint condition. |
    | Reviewer Non-Recursion | Confirms every Simple Power dispatch uses `fork_turns="none"`, and plan-review and final-review instructions require direct review in the current worker and forbid running Codex CLI, spawning subagents, invoking Simple Power skills, restarting execution, and rerouting the workflow. |
    | Commit Policy | Confirms exactly three future coordinator checkpoint commits: accepted reviewed plan plus allocation plus immediate current-session execution after combined approval, quick-verified implementation, and final verified implementation. Confirms No worker commits or per-task commits for workers, plan reviewers, quick verifiers, review+fix agents, and individual tasks. |
    | Scratch Ref Review Anchors | Confirms the plan requires scratch refs to be coordinator-owned local review diff anchors under `refs/simplepower/scratch/<run-id>/` with run id format `YYYYMMDD-HHMMSS-<short-head>`, not branches or accepted checkpoint commits, not pushed, merged, or rebased, and never changing the exactly-three-checkpoint commit policy. Confirms plan-review refs use `plan-review/before` before first review and `plan-review/after-<n>` after coordinator revisions; revised-plan review loops provide a concrete `git diff` command or explicit diff summary for the same original reviewer, or both original reviewers when the secondary route is distinct. Confirms quick-verifier and final review+fix edits are inspectable with the same scratch-ref diff command shape before the next accepted checkpoint. Confirms cleanup after successful checkpoints, preservation and manual cleanup reporting on blockers or failed checkpoints, and a final cleanup check. |
    | Current-Session Auto-Dispatch | Confirms `simplepower:writing-plans` uses combined approval after reviewer approval: the user approves the reviewed plan, model/task allocation, and immediate current-session execution in one step. Confirms the accepted-plan checkpoint commit is created only after combined approval and before implementation dispatch. Confirms approved implementation immediately invokes `simplepower:subagent-driven-development` in the current session with the approved model allocation and Interface Contract. Rejects retired session-routing mechanics or post-plan route-selection behavior. |
    | Retired Flow Removal | Confirms the plan does not rely on removed standalone-planning artifacts, removed review routing variants, removed worker roles, removed per-batch progress tables, or removed execution routes. |
    | Approved Path Enforcement | Confirms the plan treats the accepted implementation plan as authoritative and does not authorize backup routes, scope reduction, docs-only substitutes, any stub substitute, placeholder implementations, skipped verification, final review skipped without effective `skip_final_review=true`, or execution-route changes without fresh explicit user approval. |

    ## Calibration

    Only flag issues that would cause real problems during implementation.
    Minor wording preferences are advisory unless they create ambiguity in file
    ownership, Interface Contract, Contract inputs, Serialization required,
    aggregate parallel readiness, model allocation, review allocation,
    verification, auto-dispatch, commit policy, reviewer non-recursion,
    scratch-ref review anchors, visual-aid authority, or approved path
    enforcement. Missing visual aids are not a blocking issue.

    Scratch refs are local review artifacts, not permanent commits. Do not
    count scratch refs as extra accepted checkpoint commits. Do treat missing,
    contradictory, non-coordinator, or cleanup-free scratch-ref instructions as
    blocking because they can erase the concrete diff trail needed for revised
    plan review.

    If this is a revised plan sent back after blocking issues, compare it
    against the previous blocking issues and the provided scratch-ref diff
    command or explicit diff summary. Report whether each previous blocking
    issue is resolved, still present, or replaced by a new blocker in the
    changed category. In a distinct-secondary route, both original reviewers
    must receive every revision and both must approve it; otherwise keep the
    primary reviewer loop open until approval, unrecoverable interruption, or
    explicit user direction.

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
    that omit required scratch-ref review anchor guidance, treat scratch refs as
    accepted checkpoint commits, add extra accepted commits for review diffs,
    allow non-coordinator scratch refs, omit the
    `refs/simplepower/scratch/<run-id>/` namespace, omit revised-plan concrete
    diff anchors after blocking issues, omit scratch cleanup after successful
    checkpoints, or delete scratch refs instead of preserving and reporting
    cleanup on blockers or failed checkpoints. Reject plans
    that let the quick verifier make anything more than tiny typo-level fixes.
    Reject plans that omit the configured final-review branch, route a running agent anywhere other than effective
    `final_review_model`, or introduce a concurrent final reviewer, writer, or
    extra checkpoint. Reject plans that omit combined approval, put the
    accepted-plan checkpoint before reviewer approval or before user approval,
    delay implementation after combined approval, omit immediate current-session
    execution through `simplepower:subagent-driven-development`, introduce
    retired session-routing mechanics, or ask the user to pick a post-plan
    execution route. Reject plans that route the primary plan reviewer away
    from REVIEW or the final review+fix agent away from effective
    `final_review_model`. Reject plans that do not state
    the model resolution order as built-in defaults, home
    `/home/gary/.codex/simplepower.toml`, repository
    `<git-root>/simplepower.toml`, the supported non-empty `SIMPLEPOWER_*`
    process environment values, then explicit current-session instructions.
    Reject plans that let a higher layer hide an invalid present TOML file,
    treat a missing higher-layer key as replacement instead of inheritance, or
    omit the seven-base-key plus optional `review_model2` and
    `final_review_model` schema contract, define `SIMPLEPOWER_REVIEW_MODEL2`,
    omit `SIMPLEPOWER_FINAL_REVIEW_MODEL`, treat an absent `final_review_model` as
    anything other than fallback to `review_model`, or treat an absent or
    exact-match plan-review secondary as enabled. Reject
    plans that read model assignments from `AGENTS.md`; removing old AGENTS
    model assignments or lookup instructions is correct and must not be
    rejected. Reject plans that use a final reasoning-effort suffix other than
    `low`, `medium`, `high`, `xhigh`, `max`, or `ultra`. Reject
    plans that omit `fork_turns="none"` from any Simple Power dispatch. Reject
    plans whose plan reviewer, secondary plan reviewer, or final review+fix
    instructions allow running Codex CLI, spawning subagents, invoking Simple
    Power skills, restarting execution, rerouting the workflow, or delegating
    the assigned review instead of performing it directly in the current worker.
    Reject plans whose visual
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

    **Scratch Ref Review:**
    - [Not Applicable | Anchor Present | Missing/Invalid]: [run id, ref names, diff command or summary status, cleanup status]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Previous Blocking Issues for
revised plans, Scratch Ref Review, Recommendations
