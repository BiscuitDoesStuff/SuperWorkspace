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
- **Skills location (topic 2):** OpenCode also reads `.claude/skills/` and
  `.agents/skills/` (topic 1, F7); weigh this against generating Claude copies.
- **Research budget (topic 0 follow-up):** topic 1 used 21 research calls and
  about 30 in total. Proposal: the cap counts research calls only; say whether
  re-verifying from saved fetch output, or from a fetch tool's summary, counts.
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
