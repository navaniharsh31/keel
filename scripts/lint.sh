#!/bin/sh
# Mechanical checks for keel's prose (the judgement checks live in CLAUDE.md).
set -u
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root" || exit 1
fail=0
err() { printf 'FAIL %s\n' "$*"; fail=1; }

# Every keel:<name> reference resolves to a real skill.
for ref in $(grep -rhoE 'keel:[a-z][a-z-]*' hooks skills README.md 2>/dev/null | sort -u); do
  name=${ref#keel:}
  [ -f "skills/$name/SKILL.md" ] || err "unresolved reference $ref"
done

for f in skills/*/SKILL.md; do
  lines=$(wc -l < "$f" | tr -d ' ')
  [ "$lines" -le 120 ] || err "$f has $lines lines (max 120)"
  grep -q '^disable-model-invocation:' "$f" && err "$f is not model-invoked"
  desc=$(sed -n 's/^description: "\{0,1\}\(.*\)/\1/p' "$f" | sed 's/"$//')
  [ -n "$desc" ] || err "$f has no description"
  # 1-2 sentences: count sentence ends (". " or final ".").
  sentences=$(printf '%s\n' "$desc" | grep -oE '[.!?]( |$)' | wc -l | tr -d ' ')
  [ "$sentences" -le 2 ] || err "$f description has $sentences sentences (max 2)"
  dir=$(dirname "$f")
  [ "$(sed -n 's/^name: //p' "$f")" = "$(basename "$dir")" ] || err "$f name does not match its directory"
done

# Every SKILL.md frontmatter parses under a strict YAML parser (strict skill clients skip the skill otherwise).
if python3 -c 'import yaml' 2>/dev/null; then
  python3 - skills/*/SKILL.md <<'EOF' || fail=1
import sys, yaml
bad = 0
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    head, sep, _ = text.partition("\n---\n")
    if not text.startswith("---\n") or not sep:
        print(f"FAIL {path} has no frontmatter block")
        bad = 1
        continue
    try:
        data = yaml.safe_load(head[4:])
    except yaml.YAMLError as e:
        print(f"FAIL {path} frontmatter is not valid YAML: {getattr(e, 'problem', e)}")
        bad = 1
        continue
    if not isinstance(data, dict):
        print(f"FAIL {path} frontmatter is not a mapping")
        bad = 1
sys.exit(bad)
EOF
else
  err "python3 with PyYAML is required to check SKILL.md frontmatter (pip install pyyaml)"
fi

words=$(wc -w < hooks/flow.md | tr -d ' ')
[ "$words" -le 450 ] || err "hooks/flow.md has $words words (max 450)"

# Word budget per path: the files each path always loads. A reference a SKILL.md
# tells the agent to read unconditionally on that path belongs in its list.
budget() {
  name=$1 max=$2
  shift 2
  total=$(cat "$@" | wc -w | tr -d ' ')
  [ "$total" -le "$max" ] || err "$name path loads $total words (max $max): $*"
}
budget Bug 3100 hooks/flow.md skills/debug/SKILL.md skills/tdd/SKILL.md \
  skills/review/SKILL.md skills/review/LEDGER.md
budget Change 3600 hooks/flow.md skills/grill/SKILL.md skills/domain/SKILL.md \
  skills/build/SKILL.md skills/tdd/SKILL.md skills/review/SKILL.md \
  skills/review/LEDGER.md

# No em-dashes in tracked prose (recorded eval sessions excepted).
if git ls-files -- skills hooks scripts evals docs/adr README.md CONTRIBUTING.md CHANGELOG.md NOTICE .claude/CLAUDE.md GLOSSARY.md | grep -v '\.jsonl$' | tr '\n' '\0' | xargs -0 grep -n "$(printf '\342\200\224')" 2>/dev/null; then
  err "em-dash found (lines above)"
fi

[ "$fail" -eq 0 ] && echo "lint: ok"
exit "$fail"
