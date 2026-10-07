#!/bin/sh
# Install keel for harnesses without plugin namespaces (OpenCode, and any .agents/skills reader).
#
#   scripts/install.sh opencode <base>   base: ~/.config/opencode (global) or <repo>/.opencode
#   scripts/install.sh agents <dir>      dir: a skills directory such as ~/.agents/skills
#   scripts/install.sh codex <dir>       dir: ~/.codex (global) or <repo>/.codex; writes the router hook
#
# Skills are copied as keel-<name>, with every "keel:<name>" reference rewritten to "keel-<name>".
# Codex gets its skills from the plugin (codex plugin add keel@keel); this only adds the hook.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[ $# -eq 2 ] || usage
mode=$1
target=$2

rename() { sed -e 's/^name: \([a-z-]*\)$/name: keel-\1/' -e 's/keel:\([a-z]\)/keel-\1/g'; }

copy_skills() {
  dest=$1
  mkdir -p "$dest"
  for dir in "$root"/skills/*/; do
    name=$(basename "$dir")
    out="$dest/keel-$name"
    rm -rf "$out"
    mkdir -p "$out"
    for f in "$dir"*; do
      case "$f" in
        *.md) rename < "$f" > "$out/$(basename "$f")" ;;
        *) cp -p "$f" "$out/" ;;
      esac
    done
  done
}

copy_router() {
  dest=$1
  mkdir -p "$dest/hooks"
  rename < "$root/hooks/flow.md" > "$dest/hooks/flow.md"
  cp -p "$root/hooks/session-start.sh" "$dest/hooks/session-start.sh"
  # The in-flight line names the resume skill; spell it the installed way.
  sed -i.bak 's/next=keel:build/next=keel-build/; s/next=keel:tickets/next=keel-tickets/' "$dest/hooks/session-start.sh"
  rm -f "$dest/hooks/session-start.sh.bak"
}

case "$mode" in
  opencode)
    copy_skills "$target/skills"
    mkdir -p "$target/plugins"
    cp "$root/adapters/opencode/keel.js" "$target/plugins/keel.js"
    copy_router "$target/plugins/keel"
    echo "keel installed for OpenCode under $target (skills/keel-*, plugins/keel.js)."
    ;;
  agents)
    copy_skills "$target"
    copy_router "$target/keel-router"
    echo "keel skills installed in $target as keel-<name>."
    echo "Add this to your AGENTS.md so the router loads (no hook needed):"
    echo
    sed "s#<flow.md>#$target/keel-router/hooks/flow.md#" "$root/adapters/AGENTS-snippet.md"
    ;;
  codex)
    hook="$root/hooks/session-start.sh"
    entry=$(printf '{\n  "hooks": {\n    "SessionStart": [\n      {\n        "matcher": "startup|resume|clear|compact",\n        "hooks": [{ "type": "command", "command": "%s" }]\n      }\n    ]\n  }\n}\n' "$hook")
    if [ -e "$target/hooks.json" ]; then
      echo "$target/hooks.json already exists; merge this SessionStart entry into it:"
      echo
      echo "$entry"
      exit 1
    fi
    mkdir -p "$target"
    echo "$entry" > "$target/hooks.json"
    echo "keel router hook written to $target/hooks.json. Run /hooks in Codex once to trust it."
    ;;
  *) usage ;;
esac
