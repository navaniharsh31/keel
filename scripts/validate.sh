#!/bin/sh
# Strict-validate keel. `claude plugin validate .` resolves to marketplace.json when both
# manifests exist and then skips the plugin's skills and hooks, so validate both views.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

claude plugin validate "$root" --strict

mkdir -p "$tmp/keel/.claude-plugin"
cp "$root/.claude-plugin/plugin.json" "$tmp/keel/.claude-plugin/"
for d in skills hooks; do
  [ -d "$root/$d" ] && cp -R "$root/$d" "$tmp/keel/"
done
claude plugin validate "$tmp/keel" --strict
