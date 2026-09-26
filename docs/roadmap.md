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
- [ ] Checkpoint commits (human), then a Leader handoff.
- [ ] One work package per research topic 1–10.

## Research inputs found during Phase 0

- **Global overlay (topics 1–2):** `global install` rewrites the managed
  block in the user's global rules, so personal lines need an overlay. Plan:
  `~/.config/superworkspace/rules.local.md`, holding model routing per tier,
  the minimal-change tool and a free-first cost rule. Until it exists, do not
  run `global install` on a machine with personal lines in that block.
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

- Personal opinions become opt-in packs.
- The branch model becomes configurable.
- Global rules become a neutral core plus a user overlay.
- Generators, a pack registry, hooks and a spec flow.
