#!/bin/sh
# keel context check: runs on UserPromptSubmit and after AskUserQuestion or
# Agent calls, the points where a phase can end. It reads the context size from
# the transcript (the last main-thread assistant message's input + cache tokens)
# and, once per band per session, tells the agent to offer a fresh session.
# Quality drops with length (context rot), so the bands are absolute token
# counts, not a share of the window. Silent below the first band. Always exits 0.
set -eu

soft=${KEEL_CONTEXT_SOFT:-100000}
hard=${KEEL_CONTEXT_HARD:-140000}

main() {
  input=$(cat)
  transcript=$(json_field transcript_path)
  session=$(json_field session_id)
  event=$(json_field hook_event_name)
  [ -f "$transcript" ] || return 0

  used=$(context_tokens "$transcript")
  [ -n "$used" ] || return 0

  band=0
  [ "$used" -ge "$soft" ] && band=1
  [ "$used" -ge "$hard" ] && band=2

  state="${TMPDIR:-/tmp}/keel-context-$(printf '%s' "$session" | tr -cd 'A-Za-z0-9-')"
  last=$(cat "$state" 2>/dev/null || echo 0)
  # After a /compact the size falls: lower the mark so the bands can fire again.
  [ "$band" -lt "$last" ] && echo "$band" >"$state"
  [ "$band" -gt "$last" ] || return 0
  echo "$band" >"$state"

  k=$((used / 1000))
  if [ "$band" -eq 1 ]; then
    note="keel context note: this session holds about ${k}k tokens, and answers get worse as context grows. Don't stop mid-step. At the next boundary (a gate answered, a phase finished, a build's finish question), tell the user in one line and offer a fresh session: call the Skill tool with \\\"keel:handoff\\\", which saves what a new session needs and prints the prompt to start it with. Inside keel:build, keep going: the build resumes from its spec and branch."
  else
    note="keel context note: this session holds about ${k}k tokens, past the point where a fresh session does better work. Finish the current step, then call the Skill tool with \\\"keel:handoff\\\" and tell the user to start a new session with the prompt it prints (or /compact, if they would rather stay). Inside keel:build, keep going: the build resumes from its spec and branch."
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$event" "$note"
}

# The value of a top-level string field in the hook's JSON input.
json_field() {
  printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

# Context size after the last main-thread reply: input + cache creation + cache read.
context_tokens() {
  line=$(tail -n 400 "$1" | grep '"type":"assistant"' | grep '"usage"' | grep -v '"isSidechain":true' | tail -n 1)
  [ -n "$line" ] || return 0
  usage=$(printf '%s' "$line" | sed 's/.*"usage":{//')
  sum=0
  for key in input_tokens cache_creation_input_tokens cache_read_input_tokens; do
    n=$(printf '%s' "$usage" | sed -n "s/^[^{}]*\"$key\":\([0-9]*\).*/\1/p" | head -n 1)
    sum=$((sum + ${n:-0}))
  done
  echo "$sum"
}

main "$@" || true
exit 0
