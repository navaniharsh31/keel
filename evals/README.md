# keel evals

Trigger-correctness suite for the router (`hooks/flow.md`) and the skill descriptions, run with `claude plugin eval`.

## Run

```sh
claude plugin eval . --scaffold --ablation none --trust-plugin --no-publish --allow-tools Edit -j 4
```

- `--scaffold` runs each case's `scaffold.sh` (a tiny git repo, an in-flight spec, or an empty directory).
- `--ablation none` scores the `tool_used: Skill` graders. Under the default with/without ablation they are only "plugin fired" indicators, so a trigger suite needs a single arm. Drop the flag to see the delta against a no-plugin baseline.
- `--no-publish` keeps the report local; by default it is published to claude.ai.
- The lane graders are LLM judges over the trace, told to ignore the injected router text (which contains the example "Lane: feature").

## Cases

| Case | Prompt | Expects |
|---|---|---|
| `trivial-explain` | What does splitBill in src/bill.ts do? | Trivial lane, no skill |
| `trivial-typo` | fix the typo in README | Trivial lane, no skill |
| `bug-500s` | login is throwing 500s since yesterday | Bug lane, `keel:debug` |
| `change-dark-mode` | add a dark mode toggle | Change lane, `keel:grill` |
| `feature-billing` | I want to add multi-tenant billing | Feature lane, `keel:grill` |
| `no-repo-talk` | help me plan my conference talk (no repo) | No repo lane, `keel:grill`, writes nothing |
| `resume-in-flight` | Morning. What's next? (approved spec, 2/5 done) | offers to resume with `keel:build` |

## Last run

2026-10-08, Claude Code 2.1.289, flow.md with the rebuild-state line (after a compaction or resume), `--runs 3 --ablation none`: all 7 cases score 1.00 (21/21 runs pass), $3.66.

```
CASE              SCORE PASS% RUNS COST
bug-500s          1.00  100%  3    $0.98
change-dark-mode  1.00  100%  3    $0.57
feature-billing   1.00  100%  3    $0.63
no-repo-talk      1.00  100%  3    $0.41
resume-in-flight  1.00  100%  3    $0.28
trivial-explain   1.00  100%  3    $0.38
trivial-typo      1.00  100%  3    $0.40
```

The with/without baseline for `resume-in-flight` (1 run each): with keel 1.00, without 0.50 (the judge FAILs the no-plugin arm for not offering a resume).

## Tier 2 smoke tests (manual)

Codex and OpenCode have no eval runner, so they get a manual smoke checklist; results are recorded below with the harness version and date.

### OpenCode: pass (2026-10-07, 1.18.30 and 2.0.20, model `opencode/big-pickle`)

Installed with `scripts/install.sh opencode <repo>/.opencode` into a clone of the dogfood repo.

- [x] **Router loads.** On 1.18.30 the plugin injected flow.md: the first text was `Lane: Change`. On 2.0.20, with no AGENTS.md, the model quoted the router line verbatim from its system prompt. After the v2 fix, the TUI's "1 plugin failed" badge was gone.
- [x] **Lane stated:** `Lane: Change` (run mode and TUI).
- [x] **A keel skill fires:** `skill {"name": "keel-grill"}`, then `keel-domain`.
- [x] **A gate asks:** in the 2.0.20 TUI, G1 "Aligned? Next step:" came through the `question` tool, with *Build now (single slice) (Recommended)* / *Spec + tickets* / *Not yet, keep grilling*. In `opencode run` mode the `question` tool errors (no one can answer), so gates need the TUI.
- [x] **AGENTS.md fallback (Tier 3 route):** on 2.0.20 the snippet alone made the model read flow.md, state `Lane: Change`, fire `keel-grill`, and ask an all-closed round through `question` (D5's hybrid rule).

Unrelated environment notes: the default `openai/*` models returned "model service temporarily unavailable" (the same account failure as Codex), and `google/gemini-2.5-pro` rejected one of OpenCode's own tool schemas, so the free `opencode/big-pickle` model was used.

### Codex: pending (0.142.3)

- [x] `codex plugin marketplace add` + `codex plugin add keel@keel` installs all 12 skills.
- [x] `scripts/install.sh codex <repo>/.codex` writes the router hook.
- [ ] A new session states a lane, a keel skill fires, a gate asks: not run yet. Every `codex exec` on the test machine failed on authentication ("Your access token could not be refreshed"). Results from anyone with working Codex auth are welcome.

