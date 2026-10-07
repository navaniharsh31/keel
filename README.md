# keel

A Claude Code plugin that runs a disciplined SDLC for solo devs: **align → spec → tracer-bullet tickets → TDD build → two-axis review → retro**. keel routes itself. A SessionStart hook loads a short flow map, the agent picks a lane and moves through the phases on its own, and it stops only at four human gates.

Adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills) (MIT).

## Install

### Claude Code (full support)

```sh
claude plugin marketplace add /path/to/keel
claude plugin install keel@keel
```

Start a new session in a repo. The first reply to any request names its lane (`Lane: feature`).

**Disable superpowers while using keel.** Both plugins inject a SessionStart router, and two routers fight over every request. Disable it per project in `.claude/settings.json`:

```json
{ "enabledPlugins": { "superpowers@claude-plugins-official": false } }
```

(or `claude plugin disable superpowers@claude-plugins-official` to turn it off everywhere).

Other harnesses are covered in [Other harnesses](#other-harnesses).

## The flow

```
user describes work
      │
      ▼  flow.md picks a LANE ("Lane: feature")
 ┌─────────────┬──────────────┬───────────────┬──────────────┬─────────────┐
 Trivial       Bug            Change          Feature        No repo
 just do it    keel:debug     keel:grill      main flow      keel:grill
                              → G1            ↓              (stateless)
                              → keel:build inline
                                ↓
 MAIN FLOW (steps 1–3 in one unbroken context window)
 1. keel:grill  (+ keel:domain: GLOSSARY.md, ADRs)
      detour: unsettleable question → keel:prototype on a prototype/<name> worktree
      ── G1  Aligned?
 2. keel:spec   ── G2  Test seams OK?   (write spec)   ── G3  Spec approved?
 3. keel:tickets ── G4  Breakdown approved?
 ═══════════ autonomous from here ═══════════
 4. keel:build  feat/<slug> → frontier loop → implementer subagents (each drives keel:tdd)
                → merger subagent per parallel ticket → keel:review (two axes) → fixer subagent
                → keel:retro → finish: merge locally / open a PR (keel:pr) / leave the branch
```

| Skill | What it does |
|---|---|
| `keel:grill` | Relentless interview in rounds over the design tree, until the frontier is empty |
| `keel:domain` | Keeps `GLOSSARY.md` and `docs/adr/` current as terms and hard decisions resolve |
| `keel:spec` | Synthesises the conversation into `docs/specs/<slug>/spec.md` |
| `keel:tickets` | Splits the spec into tracer-bullet tickets with blocking edges |
| `keel:build` | Orchestrates: fresh subagent per ticket, worktrees for parallel tickets, review, fixes, commits |
| `keel:tdd` | Red-green at pre-agreed seams, through the public interface |
| `keel:review` | Standards and Spec reviews as parallel sub-agents, reported separately |
| `keel:retro` | Improves the environment (checks, standards, pointers), not the code |
| `keel:debug` | Builds a tight red loop before hypothesising, then fixes with a regression test |
| `keel:prototype` | Throwaway code that answers one design question |
| `keel:pr` | The shape of a PR body: smallest visual, before/after evidence, merge danger |
| `keel:handoff` | A portable handoff doc that points at in-flight specs by path |

## Gates

| Gate | Asked by | Question |
|---|---|---|
| **G1** | keel:grill | Aligned? Next step: spec + tickets / build now / keep grilling |
| **G2** | keel:spec | Are these test seams right? |
| **G3** | keel:spec | Spec approved? |
| **G4** | keel:tickets | Ticket breakdown approved? (granularity and blocking edges) |

Gates are the only planned stops, along with build's finish question (a one-way door) and retro's pick. Each gate is a structured question with the material to decide on in its preview. Between them keel keeps moving. It stops early only for a decision the spec doesn't settle, a one-way door (push, merge to main, delete, migrate real data), a suite it can't turn green, or a dirty working tree when a build starts.

## State lives in your repo

```
GLOSSARY.md                              # keel:domain, created lazily
CODING_STANDARDS.md                      # keel:retro, judgement-call rules only
docs/adr/0001-slug.md                    # keel:domain
docs/specs/<slug>/spec.md                # Status: draft | approved | building | done
docs/specs/<slug>/tickets/01-<slug>.md   # Status: ready | in-progress | done | blocked
```

Because the state is in committed files, keel resumes after a crash, `/clear`, or a new day. The hook reports any in-flight spec (`In flight: tip-calc (2/5 tickets done, status building)`), and `keel:build` picks up from the branch tip.

## Other harnesses

The skills are written once, in Claude Code's terms. flow.md carries a short translation table (skill loader, question tool, subagent tool) for everything else.

### Codex (tested on 0.142.3)

```sh
codex plugin marketplace add /path/to/keel
codex plugin add keel@keel                       # the skills, as keel:<name>
/path/to/keel/scripts/install.sh codex ~/.codex  # the router hook (or <repo>/.codex)
```

Codex 0.142 plugins can't ship hooks, so the router is a user or repo `hooks.json` that runs keel's `session-start.sh`. Run `/hooks` once in Codex to trust it. Gates fall back to a numbered plain-text list outside Plan mode, because Codex's question tool is Plan-mode only.

### OpenCode (tested on 1.18.30 and 2.0.20)

```sh
/path/to/keel/scripts/install.sh opencode ~/.config/opencode   # or <repo>/.opencode
```

This installs the skills as `keel-<name>` (OpenCode has no plugin namespaces) and a plugin, `plugins/keel.js`, that adds the router to the system prompt on every request. Gates use OpenCode's `question` tool.

### Anything that reads `.agents/skills` (Cursor, Gemini CLI, Copilot, Amp, Pi: best effort, untested)

```sh
/path/to/keel/scripts/install.sh agents ~/.agents/skills
```

It prints a short paragraph to paste into your `AGENTS.md`, so the router loads without a hook.

## Developing keel

- `scripts/validate.sh`: strict validation of the marketplace and the plugin.
- `scripts/lint.sh`: references resolve, SKILL.md ≤ 120 lines, flow.md ≤ 450 words, no em-dashes.
- `evals/`: trigger-correctness suite (`claude plugin eval`); see [evals/README.md](evals/README.md).

## Credits

- **[Matt Pocock](https://github.com/mattpocock/skills)**: keel's skills are adapted from his `grilling`, `domain-modeling`, `to-spec`, `to-tickets`, `implement-spec`, `implement`, `tdd`, `codebase-design`, `code-review`, `pr`, `retro`, `prototype`, `diagnosing-bugs` and `handoff`, keeping his wording and leading words wherever keel doesn't need to differ. MIT licensed; see [LICENSE](LICENSE).
- **[Dex Horthy](https://github.com/dexhorthy) / [Humanlayer](https://github.com/humanlayer/skills)**: the PR Summary visuals in `keel:pr` come from his `show-me` skill.
