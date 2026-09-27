# Roadmap

SuperWorkspace is a neutral building platform for any user and any project.
Outside research drives the design; kit behavior stays frozen until that
research revises this roadmap.

## Phase 0: structure and research (in progress)

1. [x] Split `product/` (what ships) from the dev workspace at the root.
2. [x] Remove personal names, paths and opinions from `product/`.
3. [x] Dogfood: install the kit into its own repository.
4. [x] Add a core `project-research` role.
5. [x] Research topics 0–10 into `docs/research/NN-topic.md`, one review per
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
- [x] One work package per research topic 1–10.
  - [x] `p0-research-01`: topic 1, `docs/research/01-structure-and-extension.md`
    (R1–R4 adopted 2026-09-27, R2 corrected).
  - [x] `p0-research-02`: topic 2, `docs/research/02-multi-harness.md`
    (reviewed 2026-09-27; R5 revised, option b and R3 deferred).
  - [x] `p0-research-03`: topic 3, `docs/research/03-model-advisor.md`
    (reviewed 2026-09-27; advisor is a skill; `effort` deferred).
  - [x] `p0-research-04`: topic 4, `docs/research/04-context-efficiency.md`
    (reviewed 2026-09-27; R1-R7 adopted).
  - [x] `p0-research-05`: topic 5, `docs/research/05-orchestration-roles.md`
    (reviewed 2026-09-27; R1-R7 adopted, R7 minimal).
  - [x] `p0-research-06`: topic 6, `docs/research/06-upkeep-memory.md`
    (reviewed 2026-09-27; R1-R6 adopted).
  - [x] `p0-research-07`: topic 7, `docs/research/07-lifecycle.md`
    (reviewed 2026-09-27; R1-R7 adopted).
  - [x] `p0-research-08`: topic 8, `docs/research/08-permissions-safety.md`
    (reviewed 2026-09-27; R5 hook not now).
  - [x] `p0-research-09`: topic 9, `docs/research/09-validation-evaluation.md`
    (reviewed 2026-09-27; R1-R8 adopted).
  - [x] `p0-research-10`: topic 10, `docs/research/10-collaboration-branches.md`
    (reviewed 2026-09-27; R1-R6 adopted, R3 text only).

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
  `.agents/skills` (now planned by topic 7; test duplicate skills in OpenCode
  first), and fold commands into user-invocable
  skills (closed by topic 5 R6: OpenCode skills cannot pick an agent, so
  commands stay). Runtime test: do Cursor and Copilot accept Claude
  `model` aliases in `.claude/agents`?
- **Research budget (topic 0 follow-up):** topic 1 used 21 research calls and
  about 30 in total. Proposal: the cap counts research calls only; say whether
  re-verifying from saved fetch output, or from a fetch tool's summary, counts.
  Topic 2 tried the research-only count: 25 calls, at the cap, which forced
  summary-only findings. Topic 3 saved raw page text to the scratchpad: 17
  calls, every finding re-checked from source text. Proposal: make saving raw
  text a research-skill rule and count research calls only.
- **Duplicated subagent list (decided in topic 5, R7):** each command's
  `subagent:` frontmatter owns the flag. Drop the validator's hard-coded list
  (`Sw.Project.psm1` around line 307) and generate the Claude leader
  pointer's dispatch line from the files. The routing pin (`$script:Routes`)
  stays. Tests change with it (topic 9).
- **Lifecycle (decided in topic 7):** keep the hash manifest plus managed
  blocks. The manifest records `kitCommit`, and `update` refuses a downgrade
  unless `-Force` (today `kitVersion` is never read). `skip-modified` splits:
  `kept-local` when the kit did not change the file; otherwise the incoming
  version goes to `.sw/backup/<stamp>/incoming/` with a `git diff` line. The
  `-Adopt` gap is fixed by inserting the template's project sections into an
  existing `AGENTS.md` that lacks `## Project identity`, touching no existing
  text. A kit-side rename map moves files, including edited ones. Tag
  releases in git as the pin; no PowerShell Gallery yet. Fix
  `.sw/workspace.md` "Regenerate after `sw update`" (update already does it).
- **Permissions and safety (decided in topic 8):** safety claims use three
  words: *enforced* (tool lists, file-tool rules), *guardrail* (shell
  patterns, which stop the command as written only), *stated* (role text). A
  small table in `.sw/workspace.md` shows what each harness enforces; today
  the doc overstates Claude. Claude adapter gains: `disallowedTools: Agent`, a
  `.env` read ask, and a `gh alias` deny; its `gh` list is documented as a
  denylist. OpenCode `external_directory` changes from `allow` to `ask`. No
  more `git push` spellings: branch protection on `main` is the real control
  (a human check; the kit's `gh api` deny blocked the Leader's read-only
  check). Owner checked 2026-09-27: `main` is not protected. Sandboxes are documented, never configured (Claude's does not run on
  native Windows). No per-role Claude hook for now. Update the `decisions.md`
  hook lesson with its documented cause (subagent frontmatter hooks need trust
  for the exact folder). Note the shipped third-party MCP server (`context7`).
- **Skills move (topic 7 R7, owner 2026-09-27):** moving canonical skills to
  `.agents/skills` is planned next-phase work, after the rename map; it
  reverses part of the 2026-09-26 "OpenCode is canonical" decision.
- **Orchestration (decided in topic 5):** keep the Leader plus one level of
  subagents; no nesting and no agent teams. Generated Claude agents get
  `disallowedTools: Agent`: today developer, worker and build can nest three
  layers in Claude. Keep all 9 roles and the nine commands. Add one routing
  default to `project-leader.md`: work in-session unless the output is
  verbose, the work is self-contained, or it needs another tier or access.
  Extend the worktree-off note to Claude (desktop worktree option,
  `isolation: worktree`). Runtime tests: does OpenCode V1 honour `subagent:`
  (else three commands run inline; see the `$schema` defect), and OpenCode
  nesting and messaging.
- **Session tier (topic 5 R4, multi-human part topic 10 R5):** ship as an
  optional paragraph in `.sw/collaboration.md`. Records are the truth; "go"
  and "done" use harness messaging where available, else the human relays
  them. No command or code. One Leader per human, never shared; across
  humans, coordination travels as files (inbox message or task event,
  pushed and fetched) or, at tier 1, an issue comment.
- **Upkeep and memory (decided in topic 6):** harness memory is never the
  record; the kit neither uses nor disables it (one sentence in
  `.sw/collaboration.md`). Record bloat: `sw comms event` drops `.sw/comms/`
  paths from the changed line and caps it at 10 (`+N more`); measured at 14%
  of record bytes. `.sw/collaboration.md` "Closing" must say `-Outcome`
  carries the outcome, decisions and follow-ups (the doc promises more than
  `close` writes). Shipped skills hold procedures, not snapshots: the
  `free-models` per-model list moves to dated research, which also fixes the
  GLM defect. One line each in `task-handoff` (records stand without
  transcripts) and `agent-documentation` (date volatile facts). Instructions
  are reviewed on recorded failures, not on a schedule.
- **Validation (decided in topic 9):** CI stays deterministic and
  secret-free (no model runs). `validate` gains: a `## Project identity`
  check, a skill name/description check against the spec, Claude adapter
  structure derived from `roles.json`, and a research lint (six sections,
  header date, a citation per finding) as a warning, shipped, running only
  where `docs/research/*.md` exists. Pester gains: a test that the
  `subagent:` flag drives the leader dispatch line (05 R7), and a staleness
  test on shipped skills (06 R5). No schema validation until OpenCode serves
  a V2 schema (the kit fails the V1 one today). After the rewrite, run a
  manual runtime smoke checklist per harness in a throwaway init (denied
  `git push`, a readonly edit, a `.env` read), recorded in a task record;
  install OpenCode first. Skill evaluation is a practice (three scenarios
  plus a baseline, run by hand), not a tool.
- **Collaboration and branches (decided in topic 10):** the branch model
  stays fixed (`main` plus `<user>/<user>-worktree`); no config field. Solo
  mode is derived from `users: []`: the owner works on `main` directly, which
  is this repository's practice. Once `sw user add` records anyone, everyone,
  the owner included, works on their own branch. `.sw/collaboration.md` and the
  `AGENTS.md` Git rule say so. Agent-made branches (Claude `--worktree`,
  Codex cloud, Copilot cloud agent) stay off, with the reason in one line.
  Text only, no code: a claim is the `assignment` event on `main`, and the
  ff-only push breaks ties. Multi-user task IDs start `<user>-`. Close a task
  only after its last event is on `main`. Run `sw user add` on `main` as the
  owner. `git lfs lock` is optional for binary assets. The owner or a named
  contributor runs `update` as a task. Claude users then re-run
  `sw claude enable`. Protecting `main` is a human action: `.sw/collaboration.md`
  prints the steps, and `sw doctor` adds one reminder line. For a solo repo,
  block force pushes and deletion, with no admin bypass. Teams also require
  the `validate` check. The repository became public on 2026-09-27, so Free
  allows protection, and the owner will set the solo ruleset. Record the
  branch-model rationale in `docs/decisions.md` (none exists).

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
- The branch model becomes configurable: not yet (topic 10 R1; revisit when
  a team asks for task branches or a hosted agent, then list long-lived
  branches rather than add a pattern).
- Global rules become a neutral core plus a user overlay.
- Generators, a pack registry, hooks and a spec flow.
