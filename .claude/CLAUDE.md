# keel

- Skills live flat under `skills/<name>/`. Every one is model-invoked, and cross-skill calls use `Call the Skill tool with "keel:<name>"`.
- `hooks/flow.md` is the router. Whenever a skill is added, removed, or renamed, update flow.md and the README flow diagram in the same commit.
- Run `scripts/validate.sh` (strict validation of the marketplace and the plugin) after touching `.claude-plugin/`, `hooks/`, or `skills/`, and `scripts/lint.sh` after touching any prose.
- No em-dashes in prose. Keep SKILL.md ≤ 120 lines and flow.md ≤ 450 words.
- Matt Pocock's originals are at `/Users/robo/Codes/skills`. Diff against them when changing adapted text.
- Claude Code reads skill bodies and flow.md when a session starts: test an edited skill in a new session.
- `PLAN.md` is the v1 build plan; its §11 logs every deviation from it.
