#!/bin/sh
# keel: create a branch and its ledger in one step (skills/review/LEDGER.md).
# usage: new-branch.sh <branch> [<start-point>]
# Creates <branch> at <start-point> (default HEAD), switches to it, and appends
# "created <short sha of the start point>" to <git common dir>/keel/<branch>, so every
# worktree shares it. Refuses, changing nothing, a branch that already exists.
set -eu

[ $# -ge 1 ] && [ $# -le 2 ] && [ -n "$1" ] || {
  echo "usage: new-branch.sh <branch> [<start-point>]" >&2
  exit 2
}
branch=$1 start=${2:-HEAD}

sha=$(git rev-parse --verify -q --short "$start^{commit}") || {
  echo "new-branch.sh: start point '$start' is not a commit" >&2
  exit 1
}
if git show-ref --verify -q "refs/heads/$branch"; then
  echo "new-branch.sh: branch '$branch' already exists; pick another name or check it out" >&2
  exit 1
fi
common=$(git rev-parse --git-common-dir)

git switch -q -c "$branch" "$start"
ledger="$common/keel/$branch"
mkdir -p "$(dirname "$ledger")"
printf 'created %s\n' "$sha" >>"$ledger"
echo "on $branch at $sha; ledger $ledger"
