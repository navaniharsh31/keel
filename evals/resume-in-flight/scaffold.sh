#!/bin/bash
# A repo with an approved spec and 2 of 5 tickets done.
set -eu
git init -q . && git config user.email eval@example.com && git config user.name eval
printf '{ "name": "tip-calc", "scripts": { "test": "vitest run" } }\n' > package.json
mkdir -p docs/specs/tip-calc/tickets
printf '# Spec: Tip calculator\n\nStatus: approved\nBranch:\nBase:\n\n## Problem Statement\n\nSplitting a bill is fiddly.\n' > docs/specs/tip-calc/spec.md
i=1
for t in parse-amount compute-tip split-bill round-up cli-output; do
  s=ready; [ $i -le 2 ] && s=done
  printf '# 0%s: %s\n\nStatus: %s\nBlocked by: None\nType: slice\n\n## What to build\n\n%s\n' "$i" "$t" "$s" "$t" > "docs/specs/tip-calc/tickets/0$i-$t.md"
  i=$((i + 1))
done
git add -A && git commit -q -m init
