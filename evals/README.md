# keel evals

Trigger-correctness suite for the router (`hooks/flow.md`) and the skill descriptions, plus regression cases for the steps keel used to skip or aim badly, run with `claude plugin eval`.

## Run

```sh
PATH="$PWD/scripts/eval-bin:$PATH" claude plugin eval . --scaffold --ablation none --trust-plugin --no-publish --allow-tools Edit,Bash,Write -j 4
```

- `--scaffold` runs each case's `scaffold.sh` (a tiny git repo, an in-flight spec, or an empty directory).
- `--ablation none` scores the `tool_used: Skill` graders. Under the default with/without ablation they are only "plugin fired" indicators, so a trigger suite needs a single arm. Drop the flag to see the delta against a no-plugin baseline.
- `--no-publish` keeps the report local; by default it is published to claude.ai.
- `--allow-tools Edit,Bash,Write` gives the regression cases (which also list those tools in `allowed_tools`) a real shell and real writes, so their "no merge" and "no Write" graders aren't trivially true.
- `scripts/eval-bin` goes first on `PATH` for macOS: inside a run's sandbox, `/usr/bin/git` (Xcode's shim) can't reach the developer directory and fails, but a real git can be exec'd by its full path, which the wrapper does. It sits in `scripts/` because a run can't read the eval directory. Elsewhere it's harmless.
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
| `review-after-green` | Go ahead with Phase 7. (debug, the suite just went green) | `keel:review` fires; each reviewer's Agent prompt names its brief (`review/STANDARDS.md`, `review/SPEC.md`); no bundled `/code-review`; no `git merge` |
| `headless-gate` | Go on. (build's Finish, no AskUserQuestion) | the finish options as a numbered list; no merge, branch delete or push |
| `retro-scope` | Before the review, run the retro: what would have prevented this? (a second unclamped site in `src/refund.ts`) | `keel:retro` fires; no Edit or Write outside `CLAUDE.md` or `CODING_STANDARDS.md`; no `git commit` |
| `dispositions` | Go ahead. (build's Fix step, review found `S1`, `P1`, `P2` and one residual risk) | a disposition line for every id in the ledger, and no line for the residual risk |
| `test-probe` | Run the full suite, get it green, and commit. (an existing test catches a real defect) | the code is fixed and the existing test is kept (LLM judge, plus a regex on the test file) |
| `grill-recommendation` | OK, next round. (nearest-cent rounding was just shown to fail a covered case) | a round is asked, and plain nearest-cent isn't the recommendation, even with its shortfall named as the cost |
| `boundary-decision` | Carry on with the debug. (debug, the loop just went red) | a question with lettered options A and B before any Edit, Write or shell write to `src/` |
| `pre-existing-refutation` | Go ahead. (debug Phase 7, review found `P1`: a negative coupon raises the total, against the boundary decision, and the same input gave the same total at the fixed point) | `P1 fixed`, never `P1 refuted`; the reviewer's suggested fix (`clampPercent(percentOff)`) applied; the failing input `applyCoupon(50, -10)` in the test |
| `retro-blanket` | Take your recommendations from here. (debug Phase 7, reviewed fix, finish next) | `keel:retro` doesn't fire; the finish options carry a one-line retro offer (LLM judge); no Write, Edit, `git commit` or `git merge` |

## Regression cases

The last nine cases each resume a session (`context.history_file`): `history.jsonl` is a real Claude Code session, recorded with this plugin on a small checkout-app scaffold and cut just before the decision point. The case prompt is the next user turn, and only that turn is graded.

- **State.** Replay restores no files, so each `scaffold.sh` rebuilds the repo the history saw, with pinned commit dates so every SHA in the history matches.
- **Text under test.** A skill loaded before the cut is frozen in the history (debug, and in `pre-existing-refutation` LEDGER.md, in the four Bug-lane cases; build, tdd or grill in the others). flow.md (re-injected on resume) and any skill loaded in the graded turn (review, retro) are the current text. Re-record a history when the text it froze changes in a way the case depends on.
- **Run leftovers.** Each run writes the resumed session (`<session id>.jsonl`, and subagent transcripts in a `<session id>/` directory) next to the case's `history.jsonl`. They carry the account's details, and `.gitignore` keeps them out.
- **Model.** A resumed case runs on the history's model, Haiku 5.5 here, which is why each run costs cents.
- **Recording.** In a temp copy of the scaffold: `claude -p "<prompt>" --session-id <uuid> --model haiku --setting-sources project,local --plugin-dir <keel> --allowedTools Bash Edit Write Read Glob Grep Skill --disallowedTools AskUserQuestion Agent`, then `--resume <uuid>` for later turns. Copy `~/.claude/projects/<dir>/<uuid>.jsonl` to the case's `history.jsonl` (a plain file), then replace the account's email, `organizationUuid`, home path and user name (an `ls -l` owner too), for example with `sed -i ''`. End a recorded turn with "report only what you did, nothing about what comes next", or the history previews the decision the graded turn should make. Record from a directory and a plugin path that don't name you (for example `/tmp/keel-rec/<case>`), because the history also carries the session's `cwd`, every absolute path its tools touched, and the `~/.claude/projects/<dir>/memory` path.
- **Red first.** Each case was run once with a known-bad next turn (merge now, skip the retro and fix the code, don't touch the ledger, rewrite the test's expected values, recommend nearest-cent with no cost), and each one failed its key graders. `review-after-green` also fails on a history recorded with the pre-change debug text: it commits, then goes to the retro without a review. On the pre-change flow.md and retro text, `headless-gate` and `retro-scope` still passed once on Haiku, so those two guard the behaviour rather than the edit. The lean-boundary cases: `boundary-decision` fails on a history recorded with the pre-change debug text (no lettered question) and on "skip any questions, fix it now"; `review-after-green` fails on the pre-change review text (it calls `/code-review` and pastes the briefs); `retro-blanket` fails on the pre-change retro text (it writes and commits) and, after the lighter-finish change, on a history recorded with the pre-change debug text (it fires keel:retro and offers no retro line); `dispositions` fails on "give the residual risk an id and a disposition"; `grill-recommendation` fails on "recommend nearest-cent and name its cost" (the removed escape hatch); `pre-existing-refutation` fails on "refute it as pre-existing", but its pre-change history (old debug and LEDGER.md) still fixed P1, so it guards the behaviour.

## Last run

2026-10-14, the lighter-finish text: `retro-blanket` re-recorded on the new debug text, then `retro-blanket`, `retro-scope`, `review-after-green` and `headless-gate` each with `--runs 3`: all four score 1.00 (12/12 runs pass), $0.13.

2026-10-13, Claude Code 2.1.296, the lean-boundary text with nine regression cases, the Run command above (`--runs 3`): 14 of 16 cases score 1.00, 46/48 runs pass, $3.46 in 452 s. The two misses were grader artifacts, fixed and re-run alone at 3/3 each ($0.04): `headless-gate`'s no-merge grader matched a read-only `git merge-base` (the three no-merge graders now exclude it), and `retro-blanket`'s judge read only the last message, the finish question, which pointed back to the retro list printed just before it (the judge now accepts that). After review, the `grill-recommendation` and `dispositions` regex graders were tightened (a recommendation by any option label or wording, and a residual risk promoted to a `finding` line, now fail) and the two cases re-run alone with `--runs 3`: 6/6 runs pass, $0.05.

```
CASE                    SCORE PASS% RUNS COST
boundary-decision       1.00  100%  3    $0.03
bug-500s                1.00  100%  3    $0.61
change-dark-mode        1.00  100%  3    $0.50
dispositions            1.00  100%  3    $0.04
feature-billing         1.00  100%  3    $0.73
grill-recommendation    1.00  100%  3    $0.01
headless-gate           0.94  67%  3    $0.01
no-repo-talk            1.00  100%  3    $0.41
pre-existing-refutation 1.00  100%  3    $0.03
resume-in-flight        1.00  100%  3    $0.33
retro-blanket           0.94  67%  3    $0.03
retro-scope             1.00  100%  3    $0.02
review-after-green      1.00  100%  3    $0.07
test-probe              1.00  100%  3    $0.08
trivial-explain         1.00  100%  3    $0.37
trivial-typo            1.00  100%  3    $0.35
```

`boundary-decision` also passed 6/6 alone on the current debug text. Adding the lean-boundary cases spent about $8.90 in all, with two full runs.

2026-10-12, Claude Code 2.1.296, the enforced-review text with the six regression cases, the Run command above (`--runs 3`): all 13 cases score 1.00 (39/39 runs pass), $3.64 in 358 s. The six regression cases cost $0.19 of it.

```
CASE                  SCORE PASS% RUNS COST
bug-500s              1.00  100%  3    $0.69
change-dark-mode      1.00  100%  3    $0.51
dispositions          1.00  100%  3    $0.03
feature-billing       1.00  100%  3    $0.80
grill-recommendation  1.00  100%  3    $0.01
headless-gate         1.00  100%  3    $0.01
no-repo-talk          1.00  100%  3    $0.41
resume-in-flight      1.00  100%  3    $0.36
retro-scope           1.00  100%  3    $0.01
review-after-green    1.00  100%  3    $0.08
test-probe            1.00  100%  3    $0.05
trivial-explain       1.00  100%  3    $0.35
trivial-typo          1.00  100%  3    $0.32
```

Recording the six histories cost $0.08 and the red checks $0.10. With every probe and rerun counted, adding the cases spent about $8.

2026-10-12, after the review fixes (the current retro text) and with the local user name and paths scrubbed from five histories, each case run alone with `--runs 3`: `dispositions`, `grill-recommendation`, `headless-gate`, `retro-scope` and `review-after-green` score 1.00 (15/15 runs pass), $0.18. Scrubbed, `test-probe` passed only 3 of 6 runs (each failure an LLM-judge FAIL on a trace whose evidence elided the code fix), so its history was re-recorded from `/tmp/keel-rec/test-probe` on the current build and tdd text: 1.00 (3/3), $0.07, plus $0.01 to record.

The with/without baseline (from the 2026-10-08 run) for `resume-in-flight` (1 run each): with keel 1.00, without 0.50 (the judge FAILs the no-plugin arm for not offering a resume).

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

