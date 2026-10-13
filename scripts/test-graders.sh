#!/bin/sh
# Free check of the regex graders in evals/: each one must PASS on every fixture named
# evals/<case>/fixtures/<grader>.pass*.txt and FAIL on every <grader>.fail*.txt.
# Python's re stands in for the eval runner's JavaScript RegExp (same syntax for these patterns).
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 - "$root" <<'PY'
import glob, os, re, sys, yaml
root = sys.argv[1]; fail = passed = 0
for fx in sorted(glob.glob(f"{root}/evals/*/fixtures/*.txt")):
    case = os.path.dirname(os.path.dirname(fx)); name = os.path.basename(fx)
    grader, want = name.split(".")[0], name.split(".")[1]
    head = open(f"{case}/graders/{grader}.md").read().split("---")[1]
    g = yaml.safe_load(head)
    flags = re.M if "m" in g.get("flags", "") else 0
    n = len(re.findall(g["pattern"], open(fx).read(), flags))
    m = str(g.get("match", "contains"))
    ok = n == int(m.split(":")[1]) if m.startswith("count:") else (n > 0) == (m == "contains")
    if ok == (want == "pass"): passed += 1; print(f"ok   {os.path.basename(case)}/{name}")
    else: fail += 1; print(f"FAIL {os.path.basename(case)}/{name}: grader says {'pass' if ok else 'fail'}")
print(f"{passed} passed, {fail} failed"); sys.exit(1 if fail else 0)
PY
