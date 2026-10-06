#!/bin/sh
# keel SessionStart hook: prints the flow map, then one line per in-flight spec.
# Plain stdout reaches the model's context. Always exits 0: a hook never breaks a session.
set -eu

main() {
  here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  plugin_root=${CLAUDE_PLUGIN_ROOT:-$(dirname -- "$here")}
  project=${CLAUDE_PROJECT_DIR:-$PWD}

  cat "$plugin_root/hooks/flow.md"

  for spec in "$project"/docs/specs/*/spec.md; do
    [ -f "$spec" ] || continue
    status=$(header_status "$spec")
    case "$status" in
      approved|building) ;;
      *) continue ;;
    esac
    dir=$(dirname -- "$spec")
    slug=$(basename -- "$dir")
    total=0
    done_count=0
    for ticket in "$dir"/tickets/*.md; do
      [ -f "$ticket" ] || continue
      total=$((total + 1))
      [ "$(header_status "$ticket")" = done ] && done_count=$((done_count + 1))
    done
    next=keel:build
    [ "$total" -eq 0 ] && next=keel:tickets
    printf '\nIn flight: %s (%s/%s tickets done, status %s). Offer to resume with %s.\n' \
      "$slug" "$done_count" "$total" "$status" "$next"
  done
}

# First "Status:" header line, value lowercased, markdown bold tolerated.
header_status() {
  sed -n 's/^\**Status:\**[[:space:]]*\([A-Za-z-]*\).*/\1/p' "$1" | head -n 1 | tr 'A-Z' 'a-z'
}

main "$@" || true
exit 0
