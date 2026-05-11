# Current Session Context Measurement

Use this reference only from `simplepower:writing-plans` during the implementation handoff. The coordinator must run this measurement in the main agent session. Do not spawn a subagent for this check, because a subagent's `CODEX_THREAD_ID` and JSONL file describe the subagent session, not the coordinator session.

Codex session files live under:

`${CODEX_HOME:-$HOME/.codex}/sessions/YYYY/MM/DD/rollout-*.jsonl`

## Measurement

Run this in the coordinator session after the plan is saved and before you present the implementation handoff choice:

```bash
set -euo pipefail

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
: "${CODEX_THREAD_ID:?CODEX_THREAD_ID is required to measure the coordinator session}"

mapfile -t SESSION_MATCHES < <(find "$CODEX_DIR/sessions" -type f -name "*${CODEX_THREAD_ID}.jsonl" -print)
if [ "${#SESSION_MATCHES[@]}" -ne 1 ] || [ ! -r "${SESSION_MATCHES[0]}" ]; then
  echo "Unable to identify exactly one readable coordinator session JSONL" >&2
  exit 1
fi
SESSION_FILE="${SESSION_MATCHES[0]}"

jq -rs --arg session_file "$SESSION_FILE" '
  def usage_event:
    map(select(.payload.info.last_token_usage.input_tokens? != null)) | last;

  def usage_timestamp:
    .timestamp // .created_at // .payload.timestamp // .payload.created_at // .payload.info.timestamp // .payload.info.created_at;

  usage_event as $event
  | if $event == null then
      error("No usage event with payload.info.last_token_usage.input_tokens found")
    else
      ($event.payload.info.last_token_usage.input_tokens) as $input_tokens
      | ($event.payload.info.model_context_window // $event.payload.model_context_window) as $model_context_window
      | ($event | usage_timestamp) as $usage_timestamp
      | if ($input_tokens|type) != "number" or ($model_context_window|type) != "number" or $input_tokens <= 0 or $model_context_window <= 0 then
          error("Invalid measurement: input_tokens and model_context_window must be positive numbers")
        else
          {
            session_file: $session_file,
            usage_timestamp: $usage_timestamp,
            input_tokens: $input_tokens,
            model_context_window: $model_context_window,
            context_used_pct: ((((($input_tokens / $model_context_window) * 100) * 100) | round) / 100)
          }
        end
    end
' "$SESSION_FILE"
```

`cached_input_tokens` is informational only and must not be subtracted. Cached input still occupies context.

If `CODEX_THREAD_ID` is unset or empty, or if the find command does not resolve to exactly one readable JSONL file, current-session measurement failed and the workflow must use the plan-size fallback.

## Decision

- `context_used_pct >= 55`: recommend fresh context and put `Run after /clear (Recommended)` first. State that the recommendation came from measured current context pct.
- `context_used_pct < 55`: recommend the current session and put `Continue in current session (Recommended)` first. State that the recommendation came from measured current context pct.
- Measurement unavailable: use the plan-size fallback below, state that the recommendation came from plan-size fallback, and still show both handoff commands before asking the user which implementation handoff to use.

## Fallback

If current-session measurement is unavailable, run:

```bash
wc -c "$PLAN_PATH"
```

Apply the strict byte threshold:

- `> 35840`: recommend `Run after /clear (Recommended)`.
- `<= 35840`: recommend `Continue in current session (Recommended)`.

Always keep the saved plan as the only handoff artifact, show both implementation handoff commands, and ask the user explicitly which one to use.
