#!/bin/sh
# Tests hooks/merge-guard.sh against a temp repo (a main checkout plus one worktree) with ledgers.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
work=$(CDPATH= cd -- "$work" && pwd -P)
fail=0 pass=0

repo="$work/repo" wt="$work/wt"
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
for b in feat/none feat/new feat/done feat/open feat/early feat/latest feat/waived feat/bad1 feat/bad2 feat/bad3 feat/reused feat/renewed feat/asked; do
  git -C "$repo" branch "$b"
done
git -C "$repo" worktree add -q "$wt" -b feat/wt
# A remote-tracking copy of feat/new, and feat/new as the previous branch (@{-1}) of the main checkout.
git -C "$repo" remote add origin "$work/remote.git"
git -C "$repo" update-ref refs/remotes/origin/feat/new main
git -C "$repo" checkout -q feat/new && git -C "$repo" checkout -q main
mkdir -p "$work/elsewhere"

# ledger <branch> <lines...>: writes the branch's ledger in the shared git common dir.
ledger() {
  f="$repo/.git/keel/$1"
  mkdir -p "$(dirname "$f")"
  shift
  printf '%s\n' "$@" >"$f"
}
ledger feat/new 'created abc1234'
ledger feat/done 'created abc1234' 'review def5678: 2 findings' 'finding S1: magic number' 'finding P1: misses a case' \
  'S1 fixed: 9a8b7c6' 'P1 refuted: `pytest -k case` passes, output quoted'
ledger feat/open 'created abc1234' 'review def5678: 3 findings' 'finding S1: x' 'finding S2: y' 'finding P1: z' 'S1 fixed: 9a8b7c6'
ledger feat/early 'created abc1234' 'S1 fixed: before the review' 'review def5678: 1 finding' 'finding S1: x'
ledger feat/latest 'created abc1234' 'review def5678: 1 finding' 'finding C1: x' 'C1 escalated: keep the old port rule?' 'C1 fixed: 1234abc'
ledger feat/waived 'created abc1234' 'waived: "skip the review, I checked it myself"'
ledger feat/wt 'created abc1234'
ledger feat/bad1 'created abc1234' 'review def5678: 1 finding' 'finding S1 (hard): x'
ledger feat/bad2 'created abc1234' 'review def5678: 1 finding' 'Finding P1: y'
ledger feat/bad3 'created abc1234' 'review def5678: 1 finding' '- finding S1: bad'
ledger feat/reused 'created abc1234' 'review def5678: 0 findings' 'waived: "skip it"' 'created 1111111'
ledger feat/renewed 'created abc1234' 'review def5678: 1 finding' 'finding S1: x' 'created 1111111' 'review 2222222: 0 findings'
ledger feat/asked 'created abc1234' 'review def5678: 1 finding' 'finding C1: x' 'C1 escalated: keep the old port rule?'

# run <cwd> <command>: the hook's stdout, then "exit <code>".
run() {
  cmd=$(printf '%s' "$2" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"session_id":"s1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"d"}}' "$1" "$cmd" >"$work/in"
  guard "$work/in"
}

# guard <input file>: the hook's stdout, then "exit <code>", run from the main checkout.
guard() {
  if (cd "$repo" && sh "$root/hooks/merge-guard.sh" <"$1"); then echo "exit 0"; else echo "exit $?"; fi
}

# expect <name> <cwd> <command> allow|deny [patterns the reason must contain...]
expect() {
  name=$1 out=$(run "$2" "$3") want=$4
  shift 4
  ok=1
  case "$out" in *"exit 0") ;; *) ok=0 ;; esac
  if [ "$want" = allow ]; then
    [ "$out" = "exit 0" ] || ok=0
  else
    case "$out" in *'"permissionDecision":"deny"'*) ;; *) ok=0 ;; esac
    for p in "$@"; do case "$out" in *"$p"*) ;; *) ok=0 ;; esac; done
  fi
  if [ "$ok" -eq 1 ]; then echo "ok   $name"; pass=$((pass + 1)); else echo "FAIL $name: $out"; fail=$((fail + 1)); fi
}

waiver="A waived: line is only for the user's own words."

# The ledger rules.
expect "merging a branch with no ledger passes" "$repo" "git merge feat/none" allow
expect "merging a branch with no review line is denied" "$repo" "git merge feat/new" deny "feat/new has no review" "$waiver" "skills/review/LEDGER.md"
expect "merging a branch with a complete ledger passes" "$repo" "git merge feat/done" allow
expect "a finding without a disposition is denied and named" "$repo" "git merge feat/open" deny "feat/open has findings without a disposition: S2, P1." "$waiver"
expect "a disposition written before its finding does not count" "$repo" "git merge feat/early" deny "findings without a disposition: S1."
expect "the latest disposition for an id wins" "$repo" "git merge feat/latest" allow
expect "a waived line passes" "$repo" "git merge feat/waived" allow
expect "an escalated finding stays open until its answer" "$repo" "git merge feat/asked" deny "feat/asked has" "C1"
expect "a finding line with extra words is malformed" "$repo" "git merge feat/bad1" deny "malformed" "finding S1 (hard): x"
expect "a capitalised finding line is malformed" "$repo" "git merge feat/bad2" deny "malformed" "Finding P1: y"
expect "a bulleted finding line is malformed" "$repo" "git merge feat/bad3" deny "malformed"
expect "a branch created again ignores the old review and waiver" "$repo" "git merge feat/reused" deny "feat/reused has no review"
expect "only lines after the last created line count" "$repo" "git merge feat/renewed" allow

# The three one-way doors.
expect "git branch -d is denied" "$repo" "git branch -d feat/new" deny "feat/new has no review"
expect "git branch -D is denied" "$repo" "git branch -D feat/open" deny "S2, P1"
expect "git branch --delete is denied" "$repo" "git branch --delete --force feat/new" deny "feat/new"
expect "deleting a no-ledger branch passes" "$repo" "git branch -D feat/none" allow
expect "git branch without delete passes" "$repo" "git branch -m feat/new feat/renamed" allow
expect "git push remote branch is denied" "$repo" "git push -u origin feat/new" deny "feat/new has no review"
expect "a forced refspec takes its source side" "$repo" "git push origin +feat/open:refs/heads/other" deny "feat/open"
expect "pushing main passes" "$repo" "git push origin main" allow
expect "bare git push on a ledger branch is denied" "$wt" "git push" deny "feat/wt has no review"
expect "bare git push on main passes" "$repo" "git push" allow
expect "every branch named is checked" "$repo" "git merge feat/done feat/new" deny "feat/new has no review"

# Command shapes.
expect "a chained merge is denied" "$repo" "git checkout main && git merge --no-ff feat/new" deny "feat/new"
expect "a merge after ; or || is denied" "$repo" "git fetch || true; git merge -m 'msg' feat/new" deny "feat/new"
expect "a piped push is denied" "$repo" "git push origin feat/new 2>&1 | tail -1" deny "feat/new"
expect "a redirection is not a remote or refspec" "$wt" "git push 2>&1 >/dev/null | tail -3" deny "feat/wt has no review"
expect "a quoted branch is denied" "$repo" "git merge \"feat/new\"" deny "feat/new"
expect "a separator inside a quoted message does not split" "$repo" "git merge -m \"a && b; c\" feat/new" deny "feat/new"
expect "git merge in a quoted message passes" "$repo" "git commit -m \"then git merge feat/new && git push\"" allow
expect "git -C names the repo" "$work/elsewhere" "git -C $repo merge feat/new" deny "feat/new"
expect "cd in the chain names the repo" "$work/elsewhere" "cd $repo && git merge feat/new" deny "feat/new"
expect "a worktree finds the ledger through the common dir" "$wt" "git merge feat/open" deny "S2, P1"
expect "unrelated commands pass" "$repo" "ls -la && git log feat/new && git status" allow
expect "outside a repo passes" "$work/elsewhere" "git merge feat/new" allow

# Ref spellings an honest agent types.
expect "a remote-tracking ref names its branch" "$repo" "git merge origin/feat/new" deny "feat/new has no review"
expect "a refs/remotes ref names its branch" "$repo" "git merge refs/remotes/origin/feat/new" deny "feat/new has no review"
expect "git merge - is the previous branch" "$repo" "git merge -" deny "feat/new has no review"
expect "git merge @{-1} is the previous branch" "$repo" "git merge --no-ff @{-1}" deny "feat/new has no review"
expect "git push --all checks every branch" "$repo" "git push --all origin" deny "feat/new has no review" "feat/open has"
expect "git push --mirror checks every branch" "$repo" "git push --mirror" deny "feat/new has no review"
expect "a HEAD~N refspec is the current branch" "$wt" "git push origin HEAD~0:main" deny "feat/wt has no review"
expect "an @~N refspec is the current branch" "$wt" "git push origin @~2:refs/heads/main" deny "feat/wt has no review"
expect "a checkout in the chain moves the current branch" "$repo" "git checkout feat/new && git push" deny "feat/new has no review"
expect "a switch in the chain moves HEAD for a push" "$repo" "git switch feat/new && git push -u origin HEAD" deny "feat/new has no review"
expect "a checkout back to main passes" "$repo" "git checkout feat/new && git checkout main && git push" allow
expect "a file checkout keeps the current branch" "$wt" "git checkout -- README.md && git push" deny "feat/wt has no review"
expect "merge - after checkouts in the chain" "$repo" "git checkout feat/open && git checkout main && git merge -" deny "feat/open has"
expect "env before git is skipped" "$repo" "env GIT_TRACE=0 git merge feat/new" deny "feat/new"
expect "command before git is skipped" "$repo" "command git push origin feat/new" deny "feat/new"
expect "time before git is skipped" "$repo" "time -p git merge feat/new" deny "feat/new"
expect "git pull . x merges x" "$repo" "git pull . feat/new" deny "feat/new has no review"
expect "git pull remote x merges x" "$repo" "git pull --no-rebase origin feat/new" deny "feat/new has no review"
expect "git pull of main passes" "$repo" "git pull origin main" allow
expect "gh pr create checks the current branch" "$wt" "gh pr create --fill" deny "feat/wt has no review"
expect "gh pr create --head checks that branch" "$repo" "gh pr create --head feat/new --title t" deny "feat/new has no review"
expect "gh pr create on main passes" "$repo" "gh pr create --fill" allow
expect "gh pr merge checks the current branch" "$wt" "gh pr merge --squash" deny "feat/wt has no review"
expect "gh pr merge with a branch checks it" "$repo" "gh pr merge feat/new --merge" deny "feat/new has no review"
expect "gh pr merge with a number checks the current branch" "$wt" "gh pr merge 42 --squash" deny "feat/wt has no review"
expect "gh pr view passes" "$wt" "gh pr view --web" allow
expect "pulling the current branch into itself passes" "$wt" "git pull origin feat/wt" allow

# Heredocs.
expect "a heredoc body is not a command" "$repo" "cat <<EOF > notes.md
git push origin feat/new
EOF" allow
expect "a quoted heredoc body is not a command" "$repo" "cat <<'EOF' | wc -l
git merge feat/new
EOF
ls" allow
expect "a command after a heredoc is parsed" "$repo" "cat <<-EOF >x
	git merge feat/none
	EOF
git merge feat/new" deny "feat/new has no review"

# Fail open.
echo 'not json' >"$work/in"; out=$(guard "$work/in")
[ "$out" = "exit 0" ] && { echo "ok   garbage input passes"; pass=$((pass + 1)); } || { echo "FAIL garbage input: $out"; fail=$((fail + 1)); }
: >"$work/in"; out=$(guard "$work/in")
[ "$out" = "exit 0" ] && { echo "ok   empty input passes"; pass=$((pass + 1)); } || { echo "FAIL empty input: $out"; fail=$((fail + 1)); }
printf '{"tool_input":{"command":"git merge feat/new' >"$work/in"; out=$(guard "$work/in")
[ "$out" = "exit 0" ] && { echo "ok   truncated JSON passes"; pass=$((pass + 1)); } || { echo "FAIL truncated JSON: $out"; fail=$((fail + 1)); }

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
