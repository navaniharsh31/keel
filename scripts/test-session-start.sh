#!/bin/sh
# Tests hooks/session-start.sh against temp repos: no spec, in flight, done, no tickets.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail=0

# spec <repo> <slug> <status> [ticket statuses...]
spec() {
  dir="$1/docs/specs/$2"
  mkdir -p "$dir/tickets"
  printf '# Spec: %s\n\nStatus: %s\n' "$2" "$3" >"$dir/spec.md"
  shift 3
  n=0
  for s in "$@"; do
    n=$((n + 1))
    printf '# Ticket %02d\n\n**Status:** %s\n' "$n" "$s" >"$dir/tickets/0$n-t.md"
  done
}

# expect <name> <repo> <pattern or "none">
expect() {
  out=$(CLAUDE_PROJECT_DIR="$2" sh "$root/hooks/session-start.sh")
  case "$out" in "# keel"*) ;; *) echo "FAIL $1: flow.md missing"; fail=1; return ;; esac
  case "$3" in
    none) case "$out" in *"In flight:"*) ok=0 ;; *) ok=1 ;; esac ;;
    *) case "$out" in *"$3"*) ok=1 ;; *) ok=0 ;; esac ;;
  esac
  if [ "$ok" -eq 1 ]; then echo "ok   $1"; else echo "FAIL $1: $(printf '%s' "$out" | grep 'In flight' || echo 'no In flight line')"; fail=1; fi
}

mkdir -p "$work/none"
expect "no spec prints only the router" "$work/none" none

spec "$work/flight" tip-calc building done done in-progress ready ready
expect "in flight reports 2/5 and keel:build" "$work/flight" "In flight: tip-calc (2/5 tickets done, status building). Offer to resume with keel:build."

spec "$work/done" tip-calc done done done
expect "a done spec is not in flight" "$work/done" none

spec "$work/notickets" dark-mode approved
expect "an approved spec with no tickets offers keel:tickets" "$work/notickets" "In flight: dark-mode (0/0 tickets done, status approved). Offer to resume with keel:tickets."

spec "$work/draft" billing draft
expect "a draft spec is not in flight" "$work/draft" none

exit "$fail"
