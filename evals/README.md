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

## Tier 2 smoke tests (manual)

Codex and OpenCode have no eval runner, so they get a manual smoke checklist; results are recorded below with the harness version and date.
