# Contributing to keel

Thanks for helping. keel is small on purpose: twelve skills, one router, two hooks. Most good changes are a sharper sentence in a skill, not a new file.

## Setup

```sh
git clone https://github.com/navaniharsh31/keel
cd keel
claude plugin marketplace add "$PWD"
claude plugin install keel@keel
```

`scripts/lint.sh` needs `python3` with PyYAML (`pip install pyyaml`).

Edits to skills or `hooks/flow.md` take effect only in a **new** session: Claude Code reads them when a session starts. Disable superpowers (or any other SessionStart router) while you test, because two routers fight over every request.

## Checks

Run these before opening a PR. CI runs the first four.

| Command | What it checks |
|---|---|
| `scripts/lint.sh` | every `keel:<name>` reference resolves, SKILL.md frontmatter parses with PyYAML `safe_load`, SKILL.md ≤ 120 lines, descriptions ≤ 2 sentences, flow.md ≤ 450 words, no em-dashes |
| `scripts/test-session-start.sh` | the router and its in-flight line |
| `scripts/test-context-check.sh` | the context note's bands |
| `scripts/validate.sh` | `claude plugin validate --strict` on the marketplace and the plugin |
| `claude plugin eval . ...` | trigger correctness; costs about $4 per full run, see [evals/README.md](evals/README.md) |

Run the eval suite whenever you change `hooks/flow.md` or a skill's `description`, and paste its summary table into the PR.

## House rules

- Skills live flat under `skills/<name>/`. Every one is model-invoked, and cross-skill calls read `Call the Skill tool with "keel:<name>"`.
- Adding, removing, or renaming a skill means updating `hooks/flow.md` and the README flow diagram in the same commit.
- Much of the text is adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills). Keep his wording and leading words unless keel needs to differ, and diff against his originals when you change adapted text.
- Skill bodies are written once, in Claude Code's terms. Other harnesses are handled by the translation table in `flow.md` and by `adapters/`, never by forking a skill.
- Prose: no em-dashes, short sentences, concrete "Done when" lines.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat(build): ...`, `fix(hooks): ...`, `docs: ...`).
- Add a line to `CHANGELOG.md` under "Unreleased".

`GLOSSARY.md` defines keel's own terms (lane, gate, frontier, ...); use them.

## Reporting bugs

Open an issue with your harness and version, the keel version, and the relevant part of the transcript (the lane line, the skill calls, the gate). For security issues, see [SECURITY.md](SECURITY.md).
