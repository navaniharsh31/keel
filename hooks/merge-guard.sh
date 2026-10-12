#!/bin/sh
# keel merge guard: a PreToolUse hook on Bash. It finds the branches a command would
# merge (git merge), delete (git branch -d/-D/--delete) or push (git push), and denies
# the command when one of them has a ledger (<git common dir>/keel/<branch>) without a
# review line, or with a finding that has no later disposition, unless a waived: line
# exists. The line formats are skills/review/LEDGER.md's, parsed exactly.
# Branches without a ledger, every other command and any parse failure pass: it
# always exits 0, because a hook never breaks a session.
set -eu

tab=$(printf '\t')

main() {
  input=$(cat)
  dir=$PWD
  missing=""
  seen=""
  records=$(printf '%s\n' "$input" | parse) || return 0
  while IFS="$tab" read -r kind a b; do
    case "$kind" in
      cd) dir=$(resolve "$dir" "$a") ;;
      ref) check "$(resolve "$dir" "$a")" "$b" ;;
      cur)
        gdir=$(resolve "$dir" "$a")
        check "$gdir" "$(git -C "$gdir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
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
  grep -q '^waived:' "$ledger" && return 0
  what=""
  grep -Eq '^review [^ :]+:' "$ledger" || what="no review"
  open=$(open_findings "$ledger")
  if [ -n "$open" ]; then
    [ -n "$what" ] && what="$what and "
    what="${what}findings without a disposition: $open"
  fi
  [ -n "$what" ] || return 0
  [ -n "$missing" ] && missing="$missing; "
  missing="$missing$2 has $what"
}

# The finding ids in a ledger with no disposition line after them, comma-separated.
open_findings() {
  awk '
    /^finding [^ :]+:/ {
      id = substr($2, 1, length($2) - 1)
      if (!(id in open)) order[++n] = id
      open[id] = 1
      next
    }
    $2 ~ /^(fixed|refuted|escalated):/ && ($1 in open) { open[$1] = 0 }
    END {
      out = ""
      for (k = 1; k <= n; k++) if (open[order[k]]) out = out (out == "" ? "" : ", ") order[k]
      print out
    }
  ' "$1"
}

# Reads the hook JSON on stdin and prints one record per directory change or branch:
#   cd<TAB><dir>             the command (or the hook's cwd) moves to <dir>
#   ref<TAB><git -C><TAB><b>  a git merge, branch delete or push names branch <b>
#   cur<TAB><git -C>          a git push with no refspec, or HEAD as the source
# Prints nothing when the input isn't JSON with a tool_input.command string.
parse() {
  awk '
    { s = s (NR > 1 ? "\n" : "") $0 }
    END {
      n = length(s); i = 1; key = ""; bad = 0; have = 0; cwd = ""; tool = ""
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\"") {
          v = jstr()
          if (bad) exit
          j = i
          while (substr(s, j, 1) ~ /[ \t\r\n]/) j++
          if (substr(s, j, 1) == ":") { key = v; i = j + 1; continue }
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

    # A JSON string starting at s[i], decoded; leaves i after the closing quote.
    function jstr(   out, c) {
      out = ""; i++
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\"") { i++; return out }
        if (c == "\\") {
          i++; c = substr(s, i, 1)
          if (c == "n") out = out "\n"
          else if (c == "t") out = out "\t"
          else if (c == "r" || c == "b" || c == "f") out = out " "
          else if (c == "u") { out = out uchar(substr(s, i + 1, 4)); i += 4 }
          else out = out c
          i++
          continue
        }
        out = out c; i++
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
    # (2>&1, >file) are dropped with their targets.
    function shell(t,   m, k, c, e, d) {
      m = length(t); nw = 0; w = ""; inw = 0; skip = 0
      for (k = 1; k <= m; k++) {
        c = substr(t, k, 1)
        if (c == "'\''") {
          inw = 1; e = index(substr(t, k + 1), "'\''")
          if (e == 0) { w = w substr(t, k + 1); k = m } else { w = w substr(t, k + 1, e - 1); k += e }
          continue
        }
        if (c == "\"") {
          inw = 1; k++
          while (k <= m && substr(t, k, 1) != "\"") {
            d = substr(t, k, 1)
            if (d == "\\" && k < m && index("\"\\$`", substr(t, k + 1, 1))) { k++; d = substr(t, k, 1) }
            w = w d; k++
          }
          continue
        }
        if (c == "\\") { k++; if (k <= m && substr(t, k, 1) != "\n") { w = w substr(t, k, 1); inw = 1 }; continue }
        if (c == " " || c == "\t") { endword(); continue }
        if (c == "#" && !inw) { while (k < m && substr(t, k + 1, 1) != "\n") k++; continue }
        if (c == ">" || c == "<" || (c == "&" && substr(t, k + 1, 1) == ">")) {
          if (w ~ /^[0-9]+$/) { w = ""; inw = 0 } else endword()
          while (k < m && index("<>&|", substr(t, k + 1, 1))) k++
          skip = 1
          continue
        }
        if (index(";&|()\n", c)) { endword(); endseg(); continue }
        w = w c; inw = 1
      }
      endword(); endseg()
    }

    function endword() {
      if (inw) { if (skip) skip = 0; else words[++nw] = w }
      w = ""; inw = 0
    }

    function endseg() {
      if (nw > 0) segment()
      nw = 0; skip = 0
    }

    function segment(   p, o, d, k, cdir, sub_, dd, del, nb, pos, nref, src) {
      p = 1
      while (p <= nw && words[p] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) p++
      if (p > nw) return
      if (words[p] == "cd") {
        if (words[p + 1] == "--") p++
        if (p + 1 > nw) print "cd\t" ENVIRON["HOME"]
        else if (words[p + 1] != "-") print "cd\t" words[p + 1]
        return
      }
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
          else if (!dd && o ~ /^-/) { if (o ~ /^(-m|-s|-X|-F|--file|--strategy|--strategy-option|--into-name)$/) p++ }
          else ref(cdir, o)
        }
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
        pos = 0; nref = 0
        for (; p <= nw; p++) {
          o = words[p]
          if (!dd && o == "--") dd = 1
          else if (!dd && o ~ /^-/) { if (o ~ /^(-o|--push-option|--repo|--receive-pack|--exec)$/) p++ }
          else if (++pos > 1) {
            nref++
            sub(/^\+/, "", o)
            src = (index(o, ":") ? substr(o, 1, index(o, ":") - 1) : o)
            if (src == "HEAD" || src == "@") print "cur\t" cdir
            else if (src != "") ref(cdir, src)
          }
        }
        if (nref == 0) print "cur\t" cdir
      }
    }

    function ref(cdir, b) {
      sub(/^refs\/heads\//, "", b)
      if (b != "") print "ref\t" cdir "\t" b
    }
  '
}

main "$@" || true
exit 0
