#!/bin/sh
# Tests hooks/context-check.sh against synthetic transcripts.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TMPDIR="$work/"
t="$work/t.jsonl"
fail=0 pass=0

# An assistant entry with the given sidechain flag and cache-read tokens. Its text
# quotes a usage key, which the hook must not mistake for the real one.
reply() {
  printf '{"type":"assistant","isSidechain":%s,"message":{"content":[{"type":"text","text":"\\"input_tokens\\":999999"}],"usage":{"input_tokens":2,"cache_creation_input_tokens":1000,"cache_read_input_tokens":%s,"output_tokens":5,"cache_creation":{"ephemeral_1h_input_tokens":1000}}}}\n' "$1" "$2" >>"$t"
}

# expect <name> <pattern or "silent">
expect() {
  out=$(printf '{"session_id":"s1","transcript_path":"%s","hook_event_name":"PostToolUse"}' "$t" | sh "$root/hooks/context-check.sh")
  case "$2" in
    silent) [ -z "$out" ] && ok=1 || ok=0 ;;
    *) case "$out" in *"$2"*) ok=1 ;; *) ok=0 ;; esac ;;
  esac
  if [ "$ok" -eq 1 ]; then echo "ok   $1"; pass=$((pass + 1)); else echo "FAIL $1: $out"; fail=$((fail + 1)); fi
}

reply false 40000;  expect "41k is silent" silent
reply false 104000; expect "105k sends the soft note" "about 105k tokens, and answers get worse"
expect "105k again is silent" silent
reply true 190000;  expect "a sidechain entry is ignored" silent
reply false 141000; expect "142k sends the hard note" "about 142k tokens, past the point"
expect "142k again is silent" silent
reply false 30000;  expect "after /compact, 31k is silent" silent
reply false 110000; expect "111k after /compact sends the soft note again" "about 111k tokens"
out=$(printf '{"session_id":"s2","transcript_path":"/nope"}' | sh "$root/hooks/context-check.sh"; echo "exit $?")
[ "$out" = "exit 0" ] && { echo "ok   a missing transcript is silent, exit 0"; pass=$((pass + 1)); } || { echo "FAIL missing transcript: $out"; fail=$((fail + 1)); }
out=$(echo 'not json' | sh "$root/hooks/context-check.sh"; echo "exit $?")
[ "$out" = "exit 0" ] && { echo "ok   bad input is silent, exit 0"; pass=$((pass + 1)); } || { echo "FAIL bad input: $out"; fail=$((fail + 1)); }

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
