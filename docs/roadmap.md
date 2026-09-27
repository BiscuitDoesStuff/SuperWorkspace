# Roadmap

SuperWorkspace is a neutral building platform for any user and any project.
Outside research drives the design; kit behavior stays frozen until that
research revises this roadmap.

## Phase 0: structure and research (in progress)

1. [x] Split `product/` (what ships) from the dev workspace at the root.
2. [x] Remove personal names, paths and opinions from `product/`.
3. [x] Dogfood: install the kit into its own repository.
4. [x] Add a core `project-research` role.
5. [ ] Research topics 0–10 into `docs/research/NN-topic.md`, one review per
   topic:
   0. research-agent design
   1. structure and extension (packs, plugins, manifests, overlays, registries)
   2. multi-harness compatibility from a single source
   3. model advisor (detect providers, recommend tiers, free by default)
   4. context and token efficiency
   5. orchestration and roles
   6. upkeep and memory
   7. lifecycle (install, update, merge, lock files)
   8. permissions and safety across harnesses
   9. validation and evaluation of agent workspaces
   10. collaboration, multi-user work and branch models
6. [ ] Rewrite this roadmap from the reviewed research.

Work packages (records in `.sw/comms/tasks/`; process in
`docs/development.md`):

- [x] `p0-researcher-revision`: apply topic 0's R1–R4 and the user's answers.
- [x] Checkpoint commits `fa7115d`, `65d6b70`, then a Leader handoff
  (`.sw/comms/tasks/p0-leader/`).
- [ ] One work package per research topic 1–10.
  - [x] `p0-research-01`: topic 1, `docs/research/01-structure-and-extension.md`
    (R1–R4 adopted 2026-09-27, R2 corrected).
  - [x] `p0-research-02`: topic 2, `docs/research/02-multi-harness.md`
    (reviewed 2026-09-27; R5 revised, option b and R3 deferred).
  - [x] `p0-research-03`: topic 3, `docs/research/03-model-advisor.md`
    (reviewed 2026-09-27; advisor is a skill; `effort` deferred).
  - [x] `p0-research-04`: topic 4, `docs/research/04-context-efficiency.md`
    (reviewed 2026-09-27; R1-R7 adopted).

## Research inputs found during Phase 0

- **Global overlay (decided in topic 1, R1–R2):** one user-owned
  `~/.config/superworkspace/rules.local.md`, created by `global install` as an
  empty stub if missing and never rewritten. Claude loads it by an `@` line
  after `sw:end global`; OpenCode by an `instructions` entry in the global
  `opencode.json`. `product/global/rules.md` stays as is; personal lines move
  out of the block. Before implementing, test at runtime whether OpenCode's
  `instructions` accepts `~/` paths and whether project arrays replace or
  extend the global one. Until then, do not run `global install` on a machine
  with personal lines in that block.
- **Multi-harness (decided in topic 2):** `AGENTS.md` stays the one shared
  instruction file (all six harnesses read it). The Claude skills copy stays
  (Claude reads only `.claude/skills`). Cursor and Copilot need no adapter:
  they read `.claude/agents` and `.claude/skills` after `sw claude enable`.
  Universality is the goal, so adapters are planned scope; Codex comes first
  (fewest files). The overlay reaches Claude, OpenCode and Gemini only; the
  others are documented as not supported.
- **Model advisor (decided in topic 3):** a skill, no command. It rewrites
  `free-models` to list what the user has (`opencode models`, local Ollama or
  LM Studio), mark free models by a strict $0 filter over public keyless lists
  (OpenRouter, Zen), show data-use terms, and propose one `sw tiers` line
  without running it. `sw tiers` stays the only writer; `#variant` needs no
  code. No ranking data ships. A personal snapshot report is reached through
  `rules.local.md`. Deferred: `effort` in generated Claude agents. Open: the
  Artificial Analysis attribution duty for data read through OpenRouter.
- **Context budget (decided in topic 4):** keep the byte cap as a kit-hygiene
  check. The kit's share is about 2K tokens per role, about 3% of the smallest
  free window (64K). Label tokens a bytes/4 estimate. `sw doctor` states that
  only kit files are counted and points to `/context`. The leader's count adds
  agent descriptions. No model-dependent cap and no tokenizer dependency.
  Docs only: Claude applies instruction edits and `update` output only after
  `/clear`, `/compact` or a restart; switching models mid-session breaks the
  cache; free-endpoint caching is unconfirmed. Later, optional: a doctor warning
  when a tier uses local Ollama (4K default window). Runtime tests: a
  `/context` run in a fresh session (checks bytes/4), and whether OpenCode loads
  AGENTS.md in child sessions.
- **Known defects (topic 3; fix after the rewrite):** the `free-models` skill
  lists GLM 5.2 as free, and it is not (F13). The kit's `$schema` URL
  `https://opencode.ai/config.json` serves the V1 schema, which has no
  `agents` key (F20). Runtime tests: whether OpenCode V2 warns on it, and what
  `opencode models --verbose` prints for free models.
- **Gemini CLI (topic 3 F6):** replaced by Antigravity CLI for unpaid users on
  2026-06-18, which weakens the Gemini adapter case in topic 2 R4. Codex CLI
  and LM Studio are installed on the owner's machine.
- **Deferred to the rewrite (topic 2):** move canonical skills to
  `.agents/skills` (read by five of six harnesses; decide with topic 7, after
  testing duplicate skills in OpenCode), and fold commands into user-invocable
  skills (touches topic 5). Runtime test: do Cursor and Copilot accept Claude
  `model` aliases in `.claude/agents`?
- **Research budget (topic 0 follow-up):** topic 1 used 21 research calls and
  about 30 in total. Proposal: the cap counts research calls only; say whether
  re-verifying from saved fetch output, or from a fetch tool's summary, counts.
  Topic 2 tried the research-only count: 25 calls, at the cap, which forced
  summary-only findings. Topic 3 saved raw page text to the scratchpad: 17
  calls, every finding re-checked from source text. Proposal: make saving raw
  text a research-skill rule and count research calls only.
- **Duplicated subagent list (topics 5, 9):** the validator hard-codes which
  commands run as subagents, duplicating each command's `subagent:` field.
- **`-Adopt` gap (topic 7):** adopting a repo with an existing `AGENTS.md`
  adds no project sections, so the core block's Project identity reference
  dangles until a human adds one.
- **Session tier (topics 5, 10):** the dev process runs a Leader session with
  worker sessions (see `docs/development.md`). Test whether the product
  should ship it.
- **Record bloat (topic 6):** `sw comms event` writes every dirty path into
  the record, which is noise on a large uncommitted tree.
- **Research lint (topic 9):** a `validate` check that each finding has a URL
  and a date, deferred until several research files exist.

## Standing rules

- Models: assume free models until the user declares, or the tool detects,
  their models and providers. Never force a model; recommend the best use of
  what they have.
- Harnesses: OpenCode is canonical and Claude is opt-in; the goal is every
  major AI app, without duplicated files or skills unless cross-harness use
  needs them.

## Hypotheses (unverified; research may overturn them)

- Personal opinions live in `rules.local.md`; packs are deferred and profiles
  stay the extension unit (topic 1, R3; revisit when a second bundle exists).
- The branch model becomes configurable.
- Global rules become a neutral core plus a user overlay.
- Generators, a pack registry, hooks and a spec flow.
