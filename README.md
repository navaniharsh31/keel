<h1 align="center">keel</h1>

<p align="center"><strong>A self-routing software development lifecycle for coding agents.</strong><br>
Spec first, tracer-bullet tickets, test-driven builds, two-axis review. You decide at four gates; the agent does the rest.</p>

<p align="center">
<a href="https://github.com/navaniharsh31/keel/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/navaniharsh31/keel/actions/workflows/ci.yml/badge.svg"></a>
<a href="https://github.com/navaniharsh31/keel/releases"><img alt="Release" src="https://img.shields.io/github/v/release/navaniharsh31/keel"></a>
<a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
<img alt="Claude Code plugin" src="https://img.shields.io/badge/Claude_Code-plugin-d97757">
</p>

keel is a Claude Code plugin (with adapters for Codex and OpenCode) that runs a disciplined workflow for solo developers: **align → spec → tracer-bullet tickets → TDD build → two-axis review → retro**. It routes itself. A SessionStart hook loads a short flow map, the agent sorts each request into a lane and moves through the phases on its own, and it stops only where a human decision matters. Its skills are adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills).

## Highlights

- **Self-routing.** Every request gets a lane (Trivial, Bug, Change, Feature, No repo), so a typo fix stays a typo fix and a feature gets a spec.
- **Four human gates.** Alignment, test seams, the spec, and the ticket breakdown. Each is a structured question with the material to decide on in its preview. Between gates, keel keeps moving.
- **Built for parallel work.** Tickets are vertical slices with explicit blocking edges. Each one gets a fresh implementer subagent; independent tickets run side by side in git worktrees.
- **Test-first, then reviewed twice.** Implementers drive red-green TDD at agreed seams, and every build ends with a Standards review and a Spec review, reported separately.
- **State lives in your repo.** Specs, tickets, glossary, and ADRs are plain markdown committed with the code, so work resumes after a crash, `/clear`, or a new day.
- **Context-aware.** G4 offers to start the build in a fresh session, and a hook warns the agent when a session grows long, with a ready-to-paste prompt for the next one.

## Contents

[Install](#install) · [The flow](#the-flow) · [Gates](#gates) · [State](#state-lives-in-your-repo) · [Long sessions](#long-sessions) · [Other harnesses](#other-harnesses) · [Contributing](#contributing) · [Credits](#credits)

## Install

### Claude Code (full support)

```sh
claude plugin marketplace add navaniharsh31/keel
claude plugin install keel@keel
```

Update later with `claude plugin marketplace update keel && claude plugin update keel@keel`.

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
 3. keel:tickets ── G4  Breakdown approved? Build here, or in a fresh session?
      fresh session: prints a one-line prompt → /clear → paste
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
| `keel:handoff` | A portable handoff doc that points at in-flight specs by path, plus the prompt that starts the next session |

## Gates

| Gate | Asked by | Question |
|---|---|---|
| **G1** | keel:grill | Aligned? Next step: spec + tickets / build now / keep grilling |
| **G2** | keel:spec | Are these test seams right? |
| **G3** | keel:spec | Spec approved? |
| **G4** | keel:tickets | Ticket breakdown approved? (granularity and blocking edges) And where should the build run: a fresh session (recommended) or this one? |

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

## Long sessions

Answers get worse as a context window fills ([context rot](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)), so keel watches the session size. A hook runs when you send a message and after each question or subagent returns. It reads the current size from the transcript and sends the agent one note when the session passes 100k tokens, and a firmer one at 140k. The bands are absolute token counts, not a share of the window, because quality drops with length even in a 1M window.

The biggest boundary is planned in: G4 asks whether to build in a fresh session, and recommends it. The spec and tickets on disk are everything a build needs, so the planning conversation (its detours and rejected options) stays behind. keel prints `Call the Skill tool with "keel:build" for docs/specs/<slug>/spec.md.`; run `/clear`, paste it, and the build starts with a clean context. This mirrors Claude Code's own "clear context" option when a plan is accepted, and the plan → implement split in Humanlayer's workflow.

Elsewhere, at the next boundary (never mid-step) the agent offers `keel:handoff`. That writes a handoff file and prints a short prompt to paste into a new session. An autonomous build keeps going, since it resumes from its spec and branch anyway. Set `KEEL_CONTEXT_SOFT` and `KEEL_CONTEXT_HARD` (in tokens) to move the bands. The note is Claude Code only; on other harnesses flow.md tells the agent to offer a handoff past ~100k tokens on its own.

## Other harnesses

The skills are written once, in Claude Code's terms. flow.md carries a short translation table (skill loader, question tool, subagent tool) for everything else.

### Codex (install tested on 0.142.3; end-to-end smoke test pending)

```sh
git clone https://github.com/navaniharsh31/keel ~/keel
codex plugin marketplace add navaniharsh31/keel
codex plugin add keel@keel                 # the skills, as keel:<name>
~/keel/scripts/install.sh codex ~/.codex   # the router hook (or <repo>/.codex)
```

Codex 0.142 plugins can't ship hooks, so the router is a user or repo `hooks.json` that runs keel's `session-start.sh`. Run `/hooks` once in Codex to trust it. Gates fall back to a numbered plain-text list outside Plan mode, because Codex's question tool is Plan-mode only.

### OpenCode (tested on 1.18.30 and 2.0.20)

```sh
git clone https://github.com/navaniharsh31/keel ~/keel
~/keel/scripts/install.sh opencode ~/.config/opencode   # or <repo>/.opencode
```

This installs the skills as `keel-<name>` (OpenCode has no plugin namespaces) and a plugin, `plugins/keel.js`, that adds the router to the system prompt on every request. Gates use OpenCode's `question` tool.

### Anything that reads `.agents/skills` (Cursor, Gemini CLI, Copilot, Amp, Pi: best effort, untested)

```sh
git clone https://github.com/navaniharsh31/keel ~/keel
~/keel/scripts/install.sh agents ~/.agents/skills
```

It prints a short paragraph to paste into your `AGENTS.md`, so the router loads without a hook.

## Contributing

Issues and PRs are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md) for setup, the checks, and the house rules, and [CHANGELOG.md](CHANGELOG.md) for what changed. The short version:

- `scripts/lint.sh`: references resolve, SKILL.md ≤ 120 lines, flow.md ≤ 450 words, no em-dashes.
- `scripts/test-session-start.sh` and `scripts/test-context-check.sh`: the two hooks.
- `scripts/validate.sh`: strict validation of the marketplace and the plugin.
- `evals/`: trigger-correctness suite (`claude plugin eval`); see [evals/README.md](evals/README.md).

keel follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Report vulnerabilities privately, as described in [SECURITY.md](SECURITY.md).

## Credits

- **[Matt Pocock](https://github.com/mattpocock/skills)**: keel's skills are adapted from his `grilling`, `domain-modeling`, `to-spec`, `to-tickets`, `implement-spec`, `implement`, `tdd`, `codebase-design`, `code-review`, `pr`, `retro`, `prototype`, `diagnosing-bugs` and `handoff`, keeping his wording and leading words wherever keel doesn't need to differ. MIT licensed; see [LICENSE](LICENSE).
- **[Dex Horthy](https://github.com/dexhorthy) / [Humanlayer](https://github.com/humanlayer/skills)**: the PR Summary visuals in `keel:pr` come from his `show-me` skill.

## License

[MIT](LICENSE). keel is a derived work of Matt Pocock's skills, also MIT; see [NOTICE](NOTICE).
