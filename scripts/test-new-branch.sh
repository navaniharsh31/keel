#!/bin/sh
# Tests skills/review/new-branch.sh against a temp repo (a main checkout plus one worktree),
# and end to end with hooks/merge-guard.sh: a branch it creates can't merge until reviewed.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$root/skills/review/new-branch.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
work=$(CDPATH= cd -- "$work" && pwd -P)
fail=0 pass=0

repo="$work/repo" wt="$work/wt"
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m one
first=$(git -C "$repo" rev-parse --short HEAD)
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m two
main=$(git -C "$repo" rev-parse --short HEAD)
git -C "$repo" worktree add -q "$wt" -b side "$first"

# check <name> <condition...>: runs the condition as a command.
check() {
  name=$1
  shift
  if "$@"; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name"; fail=$((fail + 1)); fi
}

# nb <dir> <args...>: runs the script from <dir>; its output goes to $work/out, its exit code to $code.
nb() {
  d=$1
  shift
  if (cd "$d" && sh "$script" "$@") >"$work/out" 2>&1; then code=0; else code=$?; fi
}

on() { [ "$(git -C "$1" symbolic-ref --short HEAD)" = "$2" ]; }
at() { [ "$(git -C "$repo" rev-parse --short "refs/heads/$1")" = "$2" ]; }
ledger_is() { [ -f "$repo/.git/keel/$1" ] && [ "$(cat "$repo/.git/keel/$1")" = "$2" ]; }
no_ledger() { [ ! -e "$repo/.git/keel/$1" ]; }
failed() { [ "$code" -ne 0 ]; }
says() { grep -q "$1" "$work/out"; }

# Creates and switches to the branch, and writes its created line.
nb "$repo" feat/one
check "the branch is created at HEAD and checked out" sh -c "[ $code -eq 0 ]"
check "the main checkout is on the new branch" on "$repo" feat/one
check "the new branch starts at HEAD" at feat/one "$main"
check "the ledger holds one created line with HEAD's short sha" ledger_is feat/one "created $main"

# A start point.
nb "$repo" fix/two "$first"
check "a start point is where the branch starts" at fix/two "$first"
check "the created line names the start point" ledger_is fix/two "created $first"
check "the branch from a start point is checked out" on "$repo" fix/two

# From a worktree: the ledger lands in the shared git common dir.
nb "$wt" fix/three
check "a worktree switches to the new branch" on "$wt" fix/three
check "a worktree's ledger is in the common dir with its HEAD" ledger_is fix/three "created $first"
check "a worktree writes no ledger in its own git dir" sh -c "[ ! -e '$repo/.git/worktrees/wt/keel' ]"

# An existing branch is refused, loudly, and nothing changes.
git -C "$repo" checkout -q main
nb "$repo" side
check "an existing branch fails" failed
check "the refusal names the branch" says "side"
check "a refused branch leaves HEAD where it was" on "$repo" main
check "a refused branch gets no ledger" no_ledger side
nb "$repo" feat/one
check "an existing branch with a ledger fails" failed
check "a refused branch keeps its ledger unchanged" ledger_is feat/one "created $main"

# A bad start point fails without a branch or a ledger.
nb "$repo" feat/nowhere no-such-ref
check "an unknown start point fails" failed
check "an unknown start point creates no branch" sh -c "! git -C '$repo' show-ref -q --verify refs/heads/feat/nowhere"
check "an unknown start point writes no ledger" no_ledger feat/nowhere

# No branch name is a usage error.
nb "$repo"
check "no branch name fails" failed
check "no branch name prints the usage" says "usage"

# A ledger path that can't be written fails before the switch, leaving no branch.
git -C "$repo" checkout -q main
mkdir -p "$repo/.git/keel/stale/old"
nb "$repo" stale
check "a directory at the ledger path fails" failed
check "a directory at the ledger path leaves HEAD where it was" on "$repo" main
check "a directory at the ledger path creates no branch" sh -c "! git -C '$repo' show-ref -q --verify refs/heads/stale"
printf 'created %s\n' "$first" >"$repo/.git/keel/fixit"
nb "$repo" fixit/one
check "a ledger file blocking the ledger's directory fails" failed
check "a blocked ledger directory leaves HEAD where it was" on "$repo" main
check "a blocked ledger directory creates no branch" sh -c "! git -C '$repo' show-ref -q --verify refs/heads/fixit/one"
check "a blocked ledger directory keeps the blocking ledger" ledger_is fixit "created $first"

# After scripts/install.sh renames skills to keel-<name>, every ../<skill>/ path a skill names exists.
installed() {
  sh "$root/scripts/install.sh" "$@" >/dev/null
}
paths_resolve() {
  dir=$1
  bad=$(cd "$dir" && for s in keel-*/; do
    [ -f "${s}SKILL.md" ] || continue
    grep -oh '\.\./[a-z-]*/[A-Za-z_.-]*' "$s"*.md | sort -u | while read -r p; do
      [ -e "$s$p" ] || echo "$s$p"
    done
  done)
  [ -z "$bad" ] || { echo "missing: $bad"; return 1; }
}
installed agents "$work/agents"
check "an agents install resolves every ../<skill>/ path" paths_resolve "$work/agents"
installed opencode "$work/opencode"
check "an OpenCode install resolves every ../<skill>/ path" paths_resolve "$work/opencode/skills"

# A reused name appends a fresh created line.
git -C "$repo" checkout -q main
git -C "$repo" branch -q -D fix/two
nb "$repo" fix/two
check "a reused name appends a created line" ledger_is fix/two "created $first
created $main"

# End to end with the merge guard.
guard() {
  printf '{"session_id":"s1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"d"}}' "$repo" "$1" |
    (cd "$repo" && sh "$root/hooks/merge-guard.sh")
}
git -C "$repo" checkout -q main
nb "$repo" fix/guarded
git -C "$repo" checkout -q main
denied() { guard "git merge fix/guarded" | grep -q '"permissionDecision":"deny"'; }
allowed() { [ -z "$(guard "git merge fix/guarded")" ]; }
check "the guard denies merging a new branch with no review" denied
printf '%s\n' "review $main: Standards 0 findings; Spec 0 findings" >>"$repo/.git/keel/fix/guarded"
check "the guard allows the merge once a review line exists" allowed

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
