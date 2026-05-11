# Current Session Context Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `simplepower:subagent-driven-development` for aggregate parallel implementation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by the approved Interface Contract, run the quick verifier after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent before final verification and final commit.

**Goal:** Change the Simple Power implementation handoff recommendation from plan-size-primary routing to current Codex session context-usage routing, with plan-size fallback.

**Design Summary:** The approved design keeps the logic owned by `simplepower:writing-plans`, adds an internal helper reference at `skills/writing-plans/current-session-context.md`, measures the coordinator session directly in the main agent instead of a subagent, recommends `/clear` at `>= 55%` context usage and current-session execution below `55%`, always shows both handoff commands, always asks the user explicitly, and falls back to the existing `wc -c "$PLAN_PATH"` and `35840` byte proxy if current-session measurement fails.

**Architecture:** `skills/writing-plans/SKILL.md` remains the workflow owner and points to the helper reference only at the post-plan handoff step. The helper reference defines the Codex JSONL discovery and `jq` measurement contract using `CODEX_THREAD_ID` so aggregate workers can update docs, tests, and reviewer criteria in parallel without inventing separate measurement behavior.

**Tech Stack:** Markdown skills and docs, shell commands, `jq`, `find`, `wc`, and the existing `tests/simplepower-static/run-tests.sh` static harness.

**Model Allocation:** FAST/BEST tiers are assigned per task below. FAST defaults to `SIMPLEPOWER_FAST_MODEL` (`gpt-5.4-mini-high` when unset). BEST defaults to `SIMPLEPOWER_BEST_MODEL` (`gpt-5.5-high` when unset). The plan reviewer and final review+fix agent use BEST. The quick verifier uses `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"`.

**Commit Policy:** The coordinator commits after the reviewed plan and allocation are accepted, after all file edits and quick verification complete before final review, and after final review/fix plus final verification. Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. No per-task commits.

---

## Interface Contract

The implementation changes a documentation-driven workflow. The following contract is authoritative for all tasks.

**IC-1: Internal helper file**

- Create `skills/writing-plans/current-session-context.md`.
- The helper is internal to `simplepower:writing-plans`; it is not a public `simplepower:*` skill and must not introduce a new skill directory.
- The helper title should be `# Current Session Context Measurement`.
- It must say the coordinator measures context in the main agent directly and must not spawn a subagent for this measurement.
- It must document the Codex session file pattern:

```text
${CODEX_HOME:-$HOME/.codex}/sessions/YYYY/MM/DD/rollout-*.jsonl
```

**IC-2: Current session discovery**

- The primary session identifier is `CODEX_THREAD_ID`.
- The helper must instruct the coordinator to collect matching session files, validate that exactly one readable JSONL file matched, and only then assign `SESSION_FILE`. Use this command shape:

```bash
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
mapfile -t SESSION_MATCHES < <(find "$CODEX_DIR/sessions" -type f -name "*${CODEX_THREAD_ID}.jsonl" -print)
if [ "${#SESSION_MATCHES[@]}" -ne 1 ] || [ ! -r "${SESSION_MATCHES[0]}" ]; then
  echo "Unable to identify exactly one readable coordinator session JSONL" >&2
  exit 1
fi
SESSION_FILE="${SESSION_MATCHES[0]}"
```

- The helper must state that if `CODEX_THREAD_ID` is unset, empty, or does not resolve to exactly one readable JSONL file, current-session measurement failed and the workflow must use the plan-size fallback.
- The helper must not recommend guessing with a subagent's `CODEX_THREAD_ID`, broad newest-file search, or plan-reviewer session file.

**IC-3: Context usage extraction**

- The helper must read the latest JSONL event with usage metadata:
  `payload.info.last_token_usage.input_tokens` and `payload.info.model_context_window`, allowing `payload.model_context_window` as a context-window fallback.
- It must compute:

```text
context_used_pct = input_tokens / model_context_window * 100
```

- It must state that `cached_input_tokens` must not be subtracted because cached input still occupies context.
- A valid measurement requires a positive `input_tokens` value and a positive `model_context_window` value.
- It must provide a copyable `jq` or shell+`jq` command that returns `context_used_pct`, `input_tokens`, `model_context_window`, and the usage timestamp.

**IC-4: Recommendation thresholds**

- If current-session measurement succeeds and `context_used_pct >= 55`, recommend fresh context and put `Run after /clear (Recommended)` first.
- If current-session measurement succeeds and `context_used_pct < 55`, recommend current-session execution and put `Continue in current session (Recommended)` first.
- If current-session measurement fails, fallback to the existing plan-size proxy:

```bash
wc -c "$PLAN_PATH"
```

- The fallback keeps the existing strict threshold: greater than `35840` bytes recommends `/clear`; `35840` bytes or less recommends current-session execution.

**IC-5: Handoff invariants**

- `skills/writing-plans/SKILL.md` must tell the coordinator to read `skills/writing-plans/current-session-context.md` after the accepted plan checkpoint commit and before presenting the implementation handoff choice.
- The saved plan remains the only handoff artifact. Do not add `.simplepower/implementation-handoff.json` or a hook.
- Always show both current-session and `/clear` handoff commands.
- Always state the recommendation source: measured current context pct, or plan-size fallback when measurement failed.
- Always ask the user explicitly which implementation handoff to use.
- Preserve the existing aggregate parallel implementation command text unless changing surrounding recommendation wording.

**IC-6: Review and docs contract**

- `skills/writing-plans/plan-document-reviewer-prompt.md` must check context-pct-first routing, the `55%` threshold, `CODEX_THREAD_ID`/JSONL measurement through the helper, and `wc -c "$PLAN_PATH"` fallback with the existing `35840` byte threshold.
- `README.md` and `docs/README.codex.md` must describe current context usage as the primary recommendation signal and plan-size as a fallback, while still documenting that both commands are shown and the user chooses.
- `tests/simplepower-static/run-tests.sh` must assert the new helper file and context-pct-first behavior, and must remove or rewrite assertions that describe `wc -c "$PLAN_PATH"` as the primary decision.

## File Ownership

| File | Owner task | Change type | Responsibility | Parallel safety notes |
|------|------------|-------------|----------------|-----------------------|
| `skills/writing-plans/current-session-context.md` | Task 1 | create | Internal helper reference for measuring coordinator session context pct from Codex JSONL | New file; no overlap |
| `skills/writing-plans/SKILL.md` | Task 2 | modify | Replace plan-size-primary Context-Size Handoff guidance with helper-driven context-pct-primary guidance and fallback | Owned by one task |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Task 3 | modify | Update reviewer acceptance criteria to enforce context-pct-primary routing and fallback | Owned by one task |
| `README.md` | Task 4 | modify | Update user-facing Starting Implementation wording | Task 4 owns both user docs |
| `docs/README.codex.md` | Task 4 | modify | Update Codex install guide Starting Implementation wording | Task 4 owns both user docs |
| `tests/simplepower-static/run-tests.sh` | Task 5 | modify | Update static assertions for helper file, JSONL/context pct, 55 percent threshold, fallback, and explicit handoff ask | Owned by one task |

## Implementation Tasks

### Task 1: Add Current Session Context Helper

**Goal:** Create the internal helper reference that defines how the coordinator measures its own Codex session context usage.

**Contract inputs:** IC-1, IC-2, IC-3, IC-4, IC-5.

**Serialization required:** No. This creates a new file whose public contract is already defined.

**Write scope:** `skills/writing-plans/current-session-context.md`.

**Parallel:** Yes. Compatible with Tasks 2, 3, 4, and 5.

**Risk:** Medium, because incorrect session discovery could measure a subagent or unrelated chat.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:** A concise internal Markdown helper with copyable commands and explicit fallback rules.

**Implementation steps:**

1. Create `skills/writing-plans/current-session-context.md`.
2. Start with:

```markdown
# Current Session Context Measurement
```

3. Include a short usage statement:

```markdown
Use this reference only from `simplepower:writing-plans` during the implementation handoff. The coordinator must run this measurement in the main agent session. Do not spawn a subagent for this check, because a subagent's `CODEX_THREAD_ID` and JSONL file describe the subagent session, not the coordinator session.
```

4. Document the session path pattern exactly as IC-1 requires.
5. Add a command block that:
   - sets `CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"`;
   - requires `CODEX_THREAD_ID`;
   - collects session matches by matching `*${CODEX_THREAD_ID}.jsonl`;
   - fails unless exactly one readable match exists;
   - assigns `SESSION_FILE` only after that validation;
   - uses `jq -rs` to select the last usage event;
   - computes a rounded `context_used_pct`;
   - emits JSON with `session_file`, `usage_timestamp`, `input_tokens`, `model_context_window`, and `context_used_pct`;
   - exits non-zero or emits a clear error if measurement is unavailable.
6. State that `cached_input_tokens` is informational only and must not be subtracted.
7. Add a "Decision" section with the `>= 55%`, `< 55%`, and fallback rules from IC-4.
8. Add a "Fallback" section with `wc -c "$PLAN_PATH"` and the strict `35840` byte threshold.

**Verification commands:**

```bash
timeout 30s rg -n "Current Session Context Measurement|CODEX_THREAD_ID|model_context_window|cached_input_tokens|55|wc -c" skills/writing-plans/current-session-context.md
```

Expected result: each required term appears in the helper file.

**Completion report requirements:** Report the created file, whether the helper command is copyable, verification command result, and any ambiguity around JSONL fields.

### Task 2: Update Writing-Plans Handoff Guidance

**Goal:** Make `simplepower:writing-plans` use current context usage as the primary post-plan handoff recommendation.

**Contract inputs:** IC-1 through IC-6.

**Serialization required:** No. The helper filename and routing rules are defined by the Interface Contract.

**Write scope:** `skills/writing-plans/SKILL.md`.

**Parallel:** Yes. Compatible with Tasks 1, 3, 4, and 5.

**Risk:** High, because this is the authoritative workflow text that agents follow.

**Model tier:** BEST, resolved default `model="gpt-5.5"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:** Updated Context-Size Handoff section and Remember checklist entries.

**Implementation steps:**

1. In `## Context-Size Handoff`, replace the paragraph that says to compute only the saved plan size after the accepted plan checkpoint.
2. The new text must say:
   - after user approval and the accepted plan checkpoint commit, read `skills/writing-plans/current-session-context.md`;
   - measure the current coordinator session context pct in the main agent;
   - do not spawn a subagent for this measurement;
   - use `CODEX_THREAD_ID` and the Codex JSONL file through the helper;
   - use `>= 55%` for `/clear`, `< 55%` for current session;
   - fallback to `wc -c "$PLAN_PATH"` and strict greater-than `35840` bytes if measurement fails.
3. Preserve the exact current-session handoff command block.
4. Preserve the exact fresh-context handoff command block.
5. Keep the instruction to always show both implementation handoff commands and ask the user which one to use.
6. Update the Remember checklist at the end from "`wc -c "$PLAN_PATH"` decides the recommended implementation handoff" to context-pct-first wording with plan-size fallback.

**Verification commands:**

```bash
timeout 30s rg -n "current-session-context.md|CODEX_THREAD_ID|55%|wc -c \"\\$PLAN_PATH\"|35840|Always show both implementation handoff commands|ask the user which implementation handoff to use" skills/writing-plans/SKILL.md
```

Expected result: all new routing concepts and preserved handoff invariants are present.

**Completion report requirements:** Report changed sections, whether both handoff command blocks are unchanged, verification command result, and any text that still implies plan-size-primary routing.

### Task 3: Update Plan Reviewer Criteria

**Goal:** Make the BEST-tier plan reviewer reject plans that still use plan-size-primary routing.

**Contract inputs:** IC-4, IC-5, IC-6.

**Serialization required:** No. The reviewer criteria are independent once the Interface Contract defines the new routing rules.

**Write scope:** `skills/writing-plans/plan-document-reviewer-prompt.md`.

**Parallel:** Yes. Compatible with Tasks 1, 2, 4, and 5.

**Risk:** Medium, because stale reviewer criteria would approve old behavior.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:** Updated Context Handoff table row and calibration rejection text.

**Implementation steps:**

1. In the `Context Handoff` table row, replace the old `wc -c "$PLAN_PATH"` primary-routing language.
2. The row must require:
   - current-session context pct drives the primary recommendation;
   - `>= 55%` recommends `/clear`;
   - `< 55%` recommends current-session execution;
   - the measurement is done by the coordinator in the main agent using `skills/writing-plans/current-session-context.md`;
   - fallback to `wc -c "$PLAN_PATH"` and strict greater-than `35840` bytes only when measurement fails;
   - both commands are always shown and the user is explicitly asked.
3. In the calibration/rejection paragraph, replace "omit the size-based recommendation" with wording that rejects omission of the context-usage recommendation, the fallback, either command, or the explicit handoff ask.

**Verification commands:**

```bash
timeout 30s rg -n "current-session context pct|55%|current-session-context.md|wc -c|35840|always shows both current-session and `/clear` commands|implementation handoff ask" skills/writing-plans/plan-document-reviewer-prompt.md
```

Expected result: reviewer prompt requires context-pct-first routing and fallback.

**Completion report requirements:** Report changed reviewer categories, verification command result, and any remaining stale "size-based recommendation" wording.

### Task 4: Update User-Facing Documentation

**Goal:** Make README and Codex install docs describe the new recommendation signal without changing the two handoff commands.

**Contract inputs:** IC-4, IC-5, IC-6.

**Serialization required:** No. The public wording is independent once the routing contract is approved.

**Write scope:** `README.md`, `docs/README.codex.md`.

**Parallel:** Yes. Compatible with Tasks 1, 2, 3, and 5.

**Risk:** Low, because this is wording-only and covered by static checks.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:** Updated `## Starting Implementation` text in both docs.

**Implementation steps:**

1. In `README.md`, replace the paragraph under `## Starting Implementation` that says `writing-plans` checks saved plan size and recommends at or below/above `35840` bytes.
2. Use wording with these facts:
   - after reviewed plan and model/task allocation are approved, `simplepower:writing-plans` checks current Codex context usage when available;
   - it recommends current-session execution below `55%`;
   - it recommends `/clear` at `55%` or higher;
   - if context usage cannot be measured, it falls back to saved plan size;
   - it still shows both commands and asks which handoff to use.
3. Preserve the current-session command block and fresh-context command block.
4. Apply equivalent wording to `docs/README.codex.md`.
5. Keep existing Simple Power namespace, model env var, author, and upstream attribution untouched.

**Verification commands:**

```bash
timeout 30s rg -n "current Codex context usage|55%|saved plan size|both commands|implementation handoff to use|/clear" README.md docs/README.codex.md
```

Expected result: both docs mention context usage, the 55 percent threshold, fallback, both commands, and `/clear`.

**Completion report requirements:** Report changed docs, verification command result, and whether any command text changed.

### Task 5: Update Static Tests

**Goal:** Make the static harness enforce the new context-pct-first workflow and helper file.

**Contract inputs:** IC-1 through IC-6.

**Serialization required:** No. The expected strings are defined by the Interface Contract.

**Write scope:** `tests/simplepower-static/run-tests.sh`.

**Parallel:** Yes. Compatible with Tasks 1, 2, 3, and 4.

**Risk:** Medium, because the tests are the main guard against workflow regressions.

**Model tier:** FAST, resolved default `model="gpt-5.4-mini"` and `reasoning_effort="high"`.

**Worker role:** `sp-impl`.

**Outputs and file-level responsibilities:** Updated static assertions for the new helper and routing rules.

**Implementation steps:**

1. Add `require_file "skills/writing-plans/current-session-context.md" "writing-plans current session context helper exists"` near the other writing-plans assertions.
2. Add helper assertions requiring:
   - `Current Session Context Measurement`;
   - `CODEX_THREAD_ID`;
   - `${CODEX_HOME:-$HOME/.codex}/sessions/YYYY/MM/DD/rollout-*.jsonl`;
   - `model_context_window`;
   - `cached_input_tokens`;
   - `55`;
   - `wc -c "$PLAN_PATH"`.
3. Replace old `skills/writing-plans/SKILL.md` assertions that describe `wc -c "$PLAN_PATH"` as sizing the saved plan file only and `greater than 35840 bytes` as the primary threshold.
4. Add `skills/writing-plans/SKILL.md` assertions requiring:
   - `skills/writing-plans/current-session-context.md`;
   - `CODEX_THREAD_ID`;
   - `55%`;
   - `wc -c "$PLAN_PATH"` as fallback;
   - `35840`;
   - the preserved "Always show both implementation handoff commands" and "ask the user which implementation handoff to use" strings.
5. Replace old reviewer prompt assertions that say reviewer checks wc-based context sizing and strict threshold.
6. Add reviewer prompt assertions requiring:
   - `current-session context pct`;
   - `55%`;
   - `current-session-context.md`;
   - `wc -c`;
   - `35840`;
   - `always shows both current-session and `/clear` commands`.
7. Update README/docs assertions to require current Codex context usage, `55%`, and saved plan-size fallback while preserving `/clear`, both commands, and handoff-choice assertions.

**Verification commands:**

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
```

Expected result: all static checks pass after implementation tasks complete.

**Completion report requirements:** Report changed assertions, static test result, and any intentionally preserved old fallback assertions.

## Model Allocation

| Stage | Role | Model tier | Resolved model | Reasoning effort | Reason |
|-------|------|------------|----------------|------------------|--------|
| Plan review | BEST-tier plan reviewer | BEST | `gpt-5.5` | high | Required by `simplepower:writing-plans`; validates the plan before user approval |
| Task 1 | `sp-impl` helper reference worker | FAST | `gpt-5.4-mini` | high | New Markdown helper with exact contract and low code complexity |
| Task 2 | `sp-impl` writing-plans workflow worker | BEST | `gpt-5.5` | high | Authoritative workflow change that affects future Simple Power execution |
| Task 3 | `sp-impl` reviewer prompt worker | FAST | `gpt-5.4-mini` | high | Localized reviewer criteria update |
| Task 4 | `sp-impl` docs worker | FAST | `gpt-5.4-mini` | high | Localized user-facing wording update |
| Task 5 | `sp-impl` static tests worker | FAST | `gpt-5.4-mini` | high | Localized shell assertion update driven by explicit strings |
| Quick verification | Quick verifier | Fixed | `gpt-5.3-codex-spark` | high | Required quick lint/static verification after file-edit workers complete |
| Final review and fix | BEST-tier review+fix agent | BEST | `gpt-5.5` | high | Required whole-change review and fixes before final verification |

## Plan Review

Self-review checklist:

- Design Summary: Captures the approved internal helper design, main-agent measurement rule, `55%` threshold, explicit user choice, and plan-size fallback.
- Interface Contract: Defines helper file, JSONL path, `CODEX_THREAD_ID` discovery, usage fields, thresholds, handoff invariants, reviewer/docs/test expectations, and fallback.
- File ownership: Every created or modified file is assigned to exactly one task. Parallel workers do not collide.
- Task allocation: Every requirement maps to Tasks 1-5. Every task has `Contract inputs` and `Serialization required`.
- Aggregate parallel readiness: All file-edit workers have non-overlapping write scopes and can rely on the Interface Contract.
- Model allocation: FAST/BEST choices match risk. Plan reviewer and final review+fix use BEST. Quick verifier uses `gpt-5.3-codex-spark` high.
- Review allocation: One BEST-tier review+fix agent is planned after quick verification.
- Commit policy: Exactly three future coordinator checkpoints are present, and no non-coordinator role commits.
- Verification: Quick and final commands are concrete and use `timeout`.
- Approved path enforcement: The plan does not authorize alternate routes, skipped checks, docs-only substitutes, placeholder implementations, or execution-route changes.

Dispatch a BEST-tier plan reviewer with `skills/writing-plans/plan-document-reviewer-prompt.md` after this plan is saved. Provide this plan path and the approved brainstorming design context:

```text
Approved design: Add an internal helper reference under `skills/writing-plans/current-session-context.md`; `simplepower:writing-plans` reads it during post-plan implementation handoff; the main coordinator measures its own Codex JSONL context usage directly, not via subagent; `>= 55%` recommends `/clear`; `< 55%` recommends current session; if measurement fails, fallback to existing `wc -c "$PLAN_PATH"` and `35840` byte proxy; always show both commands, state the recommendation, and ask the user explicitly.
```

After the plan reviewer approves, ask the user to approve both the reviewed plan and model/task allocation. The accepted plan checkpoint commit happens only after that approval. Workers and reviewers must not create this commit.

## Quick Verification

After all file-edit workers complete, dispatch the quick verifier with `model="gpt-5.3-codex-spark"` and `reasoning_effort="high"` before the quick-verified implementation checkpoint.

The quick verifier must run:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
```

Expected result: all Simple Power static checks pass. Failure means some docs, skill text, reviewer prompt, or static assertions disagree with the accepted plan.

The quick verifier must also run:

```bash
timeout 30s rg -n "current-session-context.md|CODEX_THREAD_ID|55%|wc -c \"\\$PLAN_PATH\"|35840" skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md tests/simplepower-static/run-tests.sh README.md docs/README.codex.md skills/writing-plans/current-session-context.md
```

Expected result: the new helper, current-session identifier, threshold, and fallback are present across workflow, reviewer, tests, and docs.

The quick verifier may fix only tiny typo-level errors discovered while running these checks. Any behavior change, structural edit, test rewrite, public interface change, or unclear issue must be reported to the coordinator instead of fixed by the quick verifier.

## Final Review And Fix

After the coordinator checkpoint for the quick-verified implementation, dispatch one BEST-tier review+fix agent. The agent reviews and fixes the whole implementation against this accepted plan, file ownership, approved path enforcement, aggregate parallel dispatch semantics, and verification requirements.

The review+fix agent may edit files within this plan's approved file ownership when fixing issues it finds. It must report changed files, commands run, results, remaining risks, and any unresolved deviations that require user approval. It must not commit.

## Commit Checkpoints

Every plan must define exactly three future coordinator commit checkpoints:

1. Accepted plan checkpoint: after the user approves the reviewed plan and model/task allocation.
2. Quick-verified implementation checkpoint: after all `sp-impl` file edits complete and the quick verifier passes.
3. Final checkpoint: after the BEST-tier review+fix agent completes and final verification passes.

Workers, plan reviewers, quick verifiers, and review+fix agents must not commit. Do not include worker-owned commits or per-task commits.

## Context-Size Handoff

The saved plan is the handoff artifact. Do not write a project-local implementation handoff JSON artifact.

After the user approves the reviewed plan and model/task allocation and the coordinator creates the accepted plan checkpoint commit, the coordinator must read `skills/writing-plans/current-session-context.md` and measure the current coordinator session context usage in the main agent. Do not spawn a subagent for this measurement.

If context measurement succeeds:

- `context_used_pct >= 55`: recommend fresh context. Put this option first and label it `Run after /clear (Recommended)`.
- `context_used_pct < 55`: recommend continuing in the current session. Put this option first and label it `Continue in current session (Recommended)`.

If context measurement fails, fallback to the saved plan size:

```bash
wc -c "$PLAN_PATH"
```

Use bytes from the saved plan file, not characters, lines, combined artifacts, or token estimates. The fallback comparison is strict greater-than `35840`. A byte count greater than 35840 bytes selects the fresh-context recommendation. A byte count of `35840` bytes or less selects the current-session recommendation.

Always show both implementation handoff commands, state whether the recommendation came from measured current context pct or the plan-size fallback, and ask the user which implementation handoff to use. Use Codex's user-question tool, such as `request_user_input`, when available; otherwise ask in plain text.

For current-session handoff, show this exact command text:

```text
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

For fresh-context handoff, show this exact command text:

```text
/clear
Use `simplepower:subagent-driven-development` to execute `<PLAN_PATH>` with aggregate parallel implementation from the approved Interface Contract. Use the approved model allocation. Dispatch all non-conflicting `sp-impl` file-edit workers whose coordination needs are satisfied by their Contract inputs, run the quick `gpt-5.3-codex-spark` high-effort verifier with lint/build/tests and timeouts after all workers finish, commit the quick-verified implementation, then run one BEST-tier review+fix agent, final verification, and final commit.
```

If the user chooses current-session execution, that choice is an authorized handoff to `simplepower:subagent-driven-development`. If the user chooses fresh context, stop after showing the fresh-context command and tell the user to run `/clear` manually before sending the command.

## Verification

Final verification happens after the BEST-tier review+fix agent completes and before the final checkpoint commit.

Run:

```bash
timeout 30s bash tests/simplepower-static/run-tests.sh
```

Expected result: all static checks pass. Failure means the implementation does not satisfy the workflow/doc/test contract.

Run:

```bash
timeout 30s rg -n "current Codex context usage|55%|saved plan size|both commands|implementation handoff to use" README.md docs/README.codex.md
```

Expected result: public docs describe context-usage-primary routing, fallback, both commands, and user choice. Failure means user-facing docs are stale.

Run:

```bash
timeout 30s rg -n "Current Session Context Measurement|CODEX_THREAD_ID|model_context_window|cached_input_tokens|wc -c \"\\$PLAN_PATH\"" skills/writing-plans/current-session-context.md
```

Expected result: the helper documents session discovery, usage fields, cached-token handling, and fallback. Failure means the internal helper is incomplete.

Run:

```bash
timeout 30s rg -n "current-session context pct|55%|current-session-context.md|wc -c|35840|always shows both current-session and `/clear` commands" skills/writing-plans/plan-document-reviewer-prompt.md
```

Expected result: the plan reviewer enforces the new routing and fallback. Failure means future plans may approve old behavior.

The coordinator performs the final checkpoint only after the BEST-tier review+fix agent has completed and all final commands pass.
