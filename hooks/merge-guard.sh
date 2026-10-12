#!/bin/sh
# keel merge guard: a PreToolUse hook on Bash. It finds the branches a command would
# merge (git merge, git pull, gh pr merge), delete (git branch -d/-D/--delete) or push
# (git push, gh pr create), and denies the command when one of them has a ledger
# (<git common dir>/keel/<branch>) without a review line, with a finding that has no
# fixed or refuted line after it, or with a malformed finding line, unless a waived:
# line exists. Only the lines after the last created line count. The line formats are
# skills/review/LEDGER.md's, parsed exactly.
# It backstops skipped steps, not an adversary: branches without a ledger, every other
# command and any parse failure pass, and it always exits 0, because a hook never
# breaks a session.
set -eu

tab=$(printf '\t')

main() {
  input=$(cat)
  case "$input" in *git*|*gh*) ;; *) return 0 ;; esac
  dir=$PWD
  missing=""
  seen=""
  moved=""
  records=$(printf '%s\n' "$input" | parse) || return 0
  while IFS="$tab" read -r kind a b; do
    [ -n "$kind" ] || continue
    [ "$kind" = cd ] && { dir=$(resolve "$dir" "$a"); continue; }
    gdir=$(resolve "$dir" "$a")
    case "$kind" in
      ref) check "$gdir" "$(branch_of "$gdir" "$b")" ;;
      into)
        t=$(branch_of "$gdir" "$b")
        [ "$t" = "$(current "$gdir")" ] || check "$gdir" "$t"
        ;;
      cur) check "$gdir" "$(current "$gdir")" ;;
      all) check_all "$gdir" ;;
      nb) move "$gdir" "$b" ;;
      co)
        case "$b" in '@{-'*) t=$(branch_of "$gdir" "$b") ;; *) t=$b ;; esac
        if git -C "$gdir" show-ref --verify -q "refs/heads/$t" 2>/dev/null ||
          [ -n "$(git -C "$gdir" for-each-ref --count=1 "refs/remotes/*/$t" 2>/dev/null)" ]; then
          move "$gdir" "$t"
        elif git -C "$gdir" rev-parse --verify -q "$b^{commit}" >/dev/null 2>&1; then
          move "$gdir" ""
        fi
        ;;
    esac
  done <<EOF
$records
EOF
  [ -n "$missing" ] || return 0
  reason="keel merge guard: ${missing}. Run keel:review / write the dispositions (skills/review/LEDGER.md). A waived: line is only for the user's own words."
  reason=$(printf '%s' "$reason" | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
}

# resolve <base dir> <dir>: <dir> made absolute against <base dir>.
resolve() {
  case "$2" in
    /*) printf '%s' "$2" ;;
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${2#\~/}" ;;
    *) printf '%s/%s' "$1" "$2" ;;
  esac
}

# top <dir>: the worktree <dir> is in, the key for branch moves earlier in the command.
top() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$1"; }

# moved_at <dir> <field>: field 2 (current) or 3 (previous) of the latest move in <dir>.
moved_at() {
  [ -n "$moved" ] || return 1
  printf '%s' "$moved" | awk -F "$tab" -v k="$(top "$1")" -v f="$2" '$1 == k { v = $f; hit = 1 } END { if (hit) print v; exit !hit }'
}

# move <dir> <branch>: a checkout or switch earlier in the command puts <dir> on <branch>.
move() {
  mv_prev=$(current "$1")
  moved="$moved$(top "$1")$tab$2$tab$mv_prev
"
}

# current <dir>: the branch <dir> is on at this point of the command.
current() {
  moved_at "$1" 2 || git -C "$1" symbolic-ref --short -q HEAD 2>/dev/null || true
}

# branch_of <dir> <ref>: the local branch a ref names: @{-N} resolved, <remote>/ dropped.
branch_of() {
  case "$2" in
    '@{-1}') moved_at "$1" 3 && return 0 ;;
  esac
  case "$2" in
    '@{-'*'}') git -C "$1" rev-parse --symbolic-full-name "$2" 2>/dev/null | sed 's#^refs/heads/##' ; return 0 ;;
  esac
  bo_first=${2%%/*}
  if [ "$bo_first" != "$2" ] && git -C "$1" remote 2>/dev/null | grep -qxF -- "$bo_first"; then
    printf '%s' "${2#*/}"
  else
    printf '%s' "$2"
  fi
}

# check_all <dir>: checks every local branch that has a ledger (git push --all/--mirror).
check_all() {
  ca_common=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 0
  case "$ca_common" in /*) ;; *) ca_common="$1/$ca_common" ;; esac
  [ -d "$ca_common/keel" ] || return 0
  ca_list=$(find "$ca_common/keel" -type f 2>/dev/null) || return 0
  ca_ifs=$IFS
  IFS='
'
  for ca_f in $ca_list; do
    IFS=$ca_ifs
    ca_b=${ca_f#"$ca_common/keel/"}
    git -C "$1" show-ref --verify -q "refs/heads/$ca_b" 2>/dev/null && check "$1" "$ca_b"
  done
  IFS=$ca_ifs
}

# check <dir> <branch>: adds what the branch's ledger is missing to $missing.
check() {
  case "$2" in ''|/*|-*|*..*) return 0 ;; esac
  common=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 0
  [ -n "$common" ] || return 0
  case "$common" in /*) ;; *) common="$1/$common" ;; esac
  ledger="$common/keel/$2"
  [ -f "$ledger" ] || return 0
  key=$(CDPATH= cd -- "$common" 2>/dev/null && pwd -P)"|$2"
  case "$seen" in *"<$key>"*) return 0 ;; esac
  seen="$seen<$key>"
  what=$(ledger_state "$ledger")
  [ -n "$what" ] || return 0
  [ -n "$missing" ] && missing="$missing; "
  missing="$missing$2 has $what"
}

# What a ledger is missing, counting only the lines after its last created line; empty
# when it is complete or waived.
ledger_state() {
  awk '
    /^created / { review = 0; waived = 0; n = 0; nb = 0; split("", open); split("", order); next }
    /^waived:/ { waived = 1; next }
    /^review [^ :]+:/ { review = 1; next }
    /^finding [^ :]+:/ {
      id = substr($2, 1, length($2) - 1)
      if (!(id in open)) order[++n] = id
      open[id] = 1
      next
    }
    /^[-*> \t]*[Ff][Ii][Nn][Dd][Ii][Nn][Gg]/ { bad[++nb] = $0; next }
    ($1 in open) && $2 ~ /^(fixed|refuted):/ { open[$1] = 0; next }
    ($1 in open) && $2 ~ /^escalated:/ { open[$1] = 2; next }
    END {
      if (waived) exit
      out = review ? "" : "no review"
      for (s = 1; s <= 2; s++) {
        ids = ""
        for (k = 1; k <= n; k++) if (open[order[k]] == s) ids = ids (ids == "" ? "" : ", ") order[k]
        if (ids == "") continue
        out = out (out == "" ? "" : " and ") (s == 1 ? "findings without a disposition: " : "escalated findings without a fixed or refuted answer: ") ids
      }
      if (nb) {
        lines = ""
        for (k = 1; k <= nb; k++) lines = lines (k > 1 ? " | " : "") bad[k]
        out = out (out == "" ? "" : " and ") "malformed finding lines (the form is finding <id>: <title>): " lines
      }
      print out
    }
  ' "$1"
}

# Reads the hook JSON on stdin and prints one record per directory change or branch:
#   cd<TAB><dir>              the command (or the hook's cwd) moves to <dir>
#   ref<TAB><git -C><TAB><b>  a git merge, branch delete, push or gh pr names branch <b>
#   into<TAB><git -C><TAB><b> a git pull lands <b> (unless <b> is the current branch)
#   cur<TAB><git -C>          a push or gh pr of the current branch
#   all<TAB><git -C>          git push --all/--mirror: every local branch
#   co<TAB><git -C><TAB><b>   git checkout/switch <b> (a branch, a commit or a path)
#   nb<TAB><git -C><TAB><b>   git checkout -b/switch -c <b>, or a detached HEAD (no <b>)
# Prints nothing when the input isn't JSON with a tool_input.command string.
parse() {
  awk '
    { s = s (NR > 1 ? "\n" : "") $0 }
    END {
      n = split(s, sc, ""); i = 1; key = ""; bad = 0; have = 0; cwd = ""; tool = ""
      while (i <= n) {
        c = sc[i]
        if (c == "\"") {
          v = jstr()
          if (bad) exit
          j = i
          while (sc[j] ~ /[ \t\r\n]/) j++
          if (sc[j] == ":") { key = v; i = j + 1; continue }
          if (key == "command" && !have) { cmd = v; have = 1 }
          else if (key == "cwd" && cwd == "") cwd = v
          else if (key == "tool_name" && tool == "") tool = v
          key = ""
          continue
        }
        if (c == "{" || c == "}" || c == "[" || c == "]" || c == ",") key = ""
        i++
      }
      if (!have || (tool != "" && tool != "Bash")) exit
      if (cwd ~ /^\//) print "cd\t" cwd
      shell(cmd)
    }

    # A JSON string starting at s[i], decoded; leaves i after the closing quote. Plain
    # runs are copied whole, so a long string costs one pass.
    function jstr(   out, c, st) {
      out = ""; i++; st = i
      while (i <= n) {
        c = sc[i]
        if (c == "\"") { out = out substr(s, st, i - st); i++; return out }
        if (c == "\\") {
          out = out substr(s, st, i - st)
          i++; c = sc[i]
          if (c == "n") out = out "\n"
          else if (c == "t") out = out "\t"
          else if (c == "r" || c == "b" || c == "f") out = out " "
          else if (c == "u") { out = out uchar(substr(s, i + 1, 4)); i += 4 }
          else out = out c
          i++; st = i
          continue
        }
        i++
      }
      bad = 1
      return out
    }

    function uchar(h,   k, v, d) {
      v = 0
      for (k = 1; k <= 4; k++) {
        d = index("0123456789abcdef", tolower(substr(h, k, 1)))
        if (d == 0) return "?"
        v = v * 16 + d - 1
      }
      if (v == 10) return "\n"
      if (v >= 32 && v < 127) return sprintf("%c", v)
      return "?"
    }

    # Splits a shell command into segments of words, honouring quotes and escapes, and
    # analyses each segment. Separators: && || ; | & ( ) and newline. Redirections
    # (2>&1, >file) are dropped with their targets, and heredoc bodies are skipped.
    function shell(t,   m, k, c, e, d, st) {
      m = split(t, tc, ""); nw = 0; w = ""; inw = 0; skip = 0; nh = 0; hdw = 0
      for (k = 1; k <= m; k++) {
        c = tc[k]
        if (c == "'\''") {
          inw = 1; e = index(substr(t, k + 1), "'\''")
          if (e == 0) { w = w substr(t, k + 1); k = m } else { w = w substr(t, k + 1, e - 1); k += e }
          continue
        }
        if (c == "\"") {
          inw = 1; k++; st = k
          while (k <= m && tc[k] != "\"") {
            if (tc[k] == "\\" && k < m && index("\"\\$`", tc[k + 1])) { w = w substr(t, st, k - st); k++; st = k }
            k++
          }
          w = w substr(t, st, k - st)
          continue
        }
        if (c == "\\") { k++; if (k <= m && tc[k] != "\n") { w = w tc[k]; inw = 1 }; continue }
        if (c == " " || c == "\t") { endword(); continue }
        if (c == "#" && !inw) { while (k < m && tc[k + 1] != "\n") k++; continue }
        if (c == ">" || c == "<" || (c == "&" && tc[k + 1] == ">")) {
          if (w ~ /^[0-9]+$/) { w = ""; inw = 0 } else endword()
          if (c == "<" && tc[k + 1] == "<" && tc[k + 2] != "<") {
            k++; hstrip = (tc[k + 1] == "-"); if (hstrip) k++
            hdw = 1
          } else while (k < m && index("<>&|", tc[k + 1])) k++
          skip = 1
          continue
        }
        if (index(";&|()\n", c)) {
          endword(); endseg()
          if (c == "\n" && nh) k = bodies(t, k, m)
          continue
        }
        w = w c; inw = 1
      }
      endword(); endseg()
    }

    # Skips the bodies of the heredocs opened on the line ending at t[k]; returns the
    # index of the newline ending the last terminator line.
    function bodies(t, k, m,   h, st, e, line) {
      for (h = 1; h <= nh; h++) {
        while (k < m) {
          st = k + 1; e = st
          while (e <= m && tc[e] != "\n") e++
          line = substr(t, st, e - st)
          if (hs[h]) sub(/^\t+/, "", line)
          k = e
          if (line == hq[h]) break
        }
      }
      nh = 0
      return k
    }

    function endword() {
      if (inw) {
        if (skip) { skip = 0; if (hdw) { hq[++nh] = w; hs[nh] = hstrip; hdw = 0 } }
        else words[++nw] = w
      }
      w = ""; inw = 0
    }

    function endseg() {
      if (nw > 0) segment()
      nw = 0; skip = 0
    }

    function segment(   p, o, d, k, cdir, sub_, dd, del, nb, pos, nref, src, all, tg, nn, newb, det, npos) {
      p = 1
      while (p <= nw) {
        if (words[p] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) p++
        else if (words[p] == "env") {
          p++
          while (p <= nw && words[p] ~ /^-/) { if (words[p] ~ /^(-u|--unset|-C|--chdir)$/) p++; p++ }
        }
        else if (words[p] == "command" || words[p] == "time") { p++; while (p <= nw && words[p] ~ /^-[pvV]$/) p++ }
        else break
      }
      if (p > nw) return
      if (words[p] == "cd") {
        if (words[p + 1] == "--") p++
        if (p + 1 > nw) print "cd\t" ENVIRON["HOME"]
        else if (words[p + 1] != "-") print "cd\t" words[p + 1]
        return
      }
      if (words[p] == "gh" || words[p] ~ /\/gh$/) { gh(p + 1); return }
      if (words[p] != "git" && words[p] !~ /\/git$/) return
      p++; cdir = "."
      while (p <= nw && words[p] ~ /^-/) {
        o = words[p]
        if (o == "-C") { p++; d = words[p]; cdir = (d ~ /^\//) ? d : cdir "/" d }
        else if (o == "-c" || o == "--git-dir" || o == "--work-tree" || o == "--namespace" || o == "--config-env") p++
        p++
      }
      sub_ = words[p++]; dd = 0
      if (sub_ == "merge") {
        for (; p <= nw; p++) {
          o = words[p]
          if (!dd && o == "--") dd = 1
          else if (!dd && o == "-") ref(cdir, "@{-1}")
          else if (!dd && o ~ /^-/) { if (o ~ /^(-m|-s|-X|-F|--file|--strategy|--strategy-option|--into-name)$/) p++ }
          else ref(cdir, o)
        }
      } else if (sub_ == "pull") {
        pos = 0
        for (; p <= nw; p++) {
          o = words[p]
          if (!dd && o == "--") dd = 1
          else if (!dd && o ~ /^-/) { if (o ~ /^(-s|-X|--strategy|--strategy-option|--depth|--upload-pack|-o|--server-option|-j|--jobs)$/) p++ }
          else if (++pos > 1) {
            sub(/^\+/, "", o)
            src = (index(o, ":") ? substr(o, 1, index(o, ":") - 1) : o)
            if (src != "") print "into\t" cdir "\t" src
          }
        }
      } else if (sub_ == "checkout" || sub_ == "switch") {
        tg = ""; nn = ""; newb = 0; det = 0; npos = 0
        for (; p <= nw; p++) {
          o = words[p]
          if (!dd && o == "--") dd = 1
          else if (dd) npos += 2
          else if (o == "-") { npos++; if (tg == "") tg = "@{-1}" }
          else if (o ~ /^-/) {
            if (o ~ /^(-b|-B|-c|-C|--orphan|--create|--force-create)$/) { newb = 1; nn = words[++p] }
            else if (o == "--detach" || (sub_ == "switch" && o == "-d")) det = 1
          }
          else { npos++; if (tg == "") tg = o }
        }
        if (newb) print "nb\t" cdir "\t" nn
        else if (det) print "nb\t" cdir
        else if (npos == 1) print "co\t" cdir "\t" tg
      } else if (sub_ == "branch") {
        del = 0; nb = 0
        for (; p <= nw; p++) {
          o = words[p]
          if (!dd && o == "--") dd = 1
          else if (!dd && o ~ /^-/) {
            if (o == "--delete" || o ~ /^-[^-]*[dD]/) del = 1
            else if (o ~ /^(-u|--set-upstream-to|--contains|--no-contains|--merged|--no-merged|--points-at|--format|--sort)$/) p++
          }
          else names[++nb] = o
        }
        if (del) for (k = 1; k <= nb; k++) ref(cdir, names[k])
      } else if (sub_ == "push") {
        pos = 0; nref = 0; all = 0
        for (; p <= nw; p++) {
          o = words[p]
          if (!dd && o == "--") dd = 1
          else if (!dd && o ~ /^(--all|--mirror|--branches)$/) all = 1
          else if (!dd && o ~ /^-/) { if (o ~ /^(-o|--push-option|--repo|--receive-pack|--exec)$/) p++ }
          else if (++pos > 1) {
            nref++
            sub(/^\+/, "", o)
            src = (index(o, ":") ? substr(o, 1, index(o, ":") - 1) : o)
            if (src ~ /^(HEAD|@)([~^].*)?$/) print "cur\t" cdir
            else if (src != "") ref(cdir, src)
          }
        }
        if (all) print "all\t" cdir
        else if (nref == 0) print "cur\t" cdir
      }
    }

    # gh pr create pushes the current branch (or --head); gh pr merge lands the PR of the
    # branch it names, or of the current branch when it names none. A PR number or URL
    # cannot be mapped to a branch offline, so it is taken as the current branch'\''s PR.
    function gh(p,   sub_, o, tg) {
      while (p <= nw && words[p] ~ /^-/) { if (words[p] ~ /^(-R|--repo)$/) p++; p++ }
      if (words[p] != "pr") return
      p++; sub_ = words[p++]; tg = ""
      if (sub_ == "create") {
        for (; p <= nw; p++) {
          o = words[p]
          if (o == "--head" || o == "-H") tg = words[++p]
          else if (o ~ /^--head=/) tg = substr(o, 8)
          else if (o ~ /^(-t|--title|-b|--body|-B|--base|-F|--body-file|-l|--label|-r|--reviewer|-a|--assignee|-m|--milestone|-p|--project|-R|--repo|-T|--template|--recover)$/) p++
        }
        sub(/^[^:]*:/, "", tg)
      } else if (sub_ == "merge") {
        for (; p <= nw; p++) {
          o = words[p]
          if (o ~ /^(-b|--body|-F|--body-file|-t|--subject|--match-head-commit|-A|--author-email|-R|--repo)$/) p++
          else if (o !~ /^-/ && tg == "") tg = o
        }
        if (tg ~ /^#?[0-9]+$/ || tg ~ /^https?:/) tg = ""
      } else return
      if (tg == "") print "cur\t."
      else ref(".", tg)
    }

    function ref(cdir, b) {
      sub(/^refs\/heads\//, "", b)
      sub(/^refs\/remotes\//, "", b)
      if (b != "") print "ref\t" cdir "\t" b
    }
  '
}

main "$@" || true
exit 0
