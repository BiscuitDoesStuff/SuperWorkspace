# Roadmap

SuperWorkspace is a neutral building platform for any user and any project.
Outside research drives the design. Findings live in `docs/research/NN-*.md`;
this file cites them as `NN Rk` (topic NN, recommendation k).

## Phase 0: structure and research (done 2026-09-27)

1. [x] Split `product/` (what ships) from the dev workspace at the root.
2. [x] Remove personal names, paths and opinions from `product/`.
3. [x] Dogfood: install the kit into its own repository.
4. [x] Add a core `project-research` role (revised by topic 0).
5. [x] Research topics 0–10, one owner review per topic (all reviewed
   2026-09-26/27; records in `.sw/comms/archive/p0-research-NN/`).
6. [x] Rewrite this roadmap from the reviewed research (`p0-roadmap-rewrite`,
   accepted by the owner 2026-09-27).

What Phase 0 settled, in one line each:
- **Structure (01):** profiles stay the extension unit; no pack format yet.
- **Harnesses (02):** `AGENTS.md` is the one shared instruction file; the
  Claude skills copy stays; Codex is the next adapter.
- **Models (03):** the advisor is a skill; `sw tiers` stays the only writer;
  no ranking data ships.
- **Context (04):** the kit's share is about 2K tokens per role; keep the byte
  cap, label it an estimate.
- **Orchestration (05):** the Leader plus one level of subagents; 9 roles and
  9 commands stay.
- **Upkeep (06):** records, not harness memory; summaries must stand alone.
- **Lifecycle (07):** hash manifest plus managed blocks; record the kit commit.
- **Safety (08):** say *enforced*, *guardrail* or *stated*; branch protection
  is the real push control.
- **Validation (09):** deterministic, secret-free CI; a manual runtime smoke
  checklist after changes ship.
- **Collaboration (10):** the branch model stays fixed, with a solo mode when
  `users` is empty.

## Phase 1: apply the research (approved 2026-09-27, in progress)

The owner approved this plan and its order on 2026-09-27. Kit behavior changes
only here, one work package at a time, in this order, with an owner review
after each. Records: `.sw/comms/tasks/p1-NN-*/`.
Each package that installed projects receive bumps `product/VERSION` and adds
a `product/CHANGELOG.md` entry, and adds Pester coverage for new code (09 R2).

1. **Shipped text (docs and role bodies only, no code).**
   - `.sw/collaboration.md`:
     - Solo mode: with `users` empty the owner works on `main` directly; once
       `sw user add` records anyone, everyone works on their own branch
       (10 R1). `AGENTS.md` template Git rule: "(solo projects: `main` only)".
     - Agent-made branches stay off, with the reason (Claude `--worktree`,
       Codex cloud, Copilot cloud agent; 10 R2, 05 R5).
     - Claims are the `assignment` event on `main`; the ff-only push breaks
       ties; multi-user task IDs start `<user>-`; close only after the last
       event is on `main`; run `sw user add` on `main`; `git lfs lock` is
       optional (10 R3).
     - Who runs `update`: the owner or a named contributor, as a task; Claude
       users re-run `sw claude enable` (10 R4).
     - Multi-session paragraph: records are the truth; one Leader per human;
       across humans, files or tier-1 issue comments (05 R4, 10 R5).
     - "Protect main (human, once)": solo = block force pushes and deletion,
       no admin bypass; team = add the required `validate` check (10 R6).
     - Harness memory is never the record (06 R1). "Closing": `-Outcome`
       carries the outcome, decisions and follow-ups (06 R3).
   - `.sw/workspace.md`:
     - A table of what each harness *enforces*, is *guarded* by, or only
       *states*; stop overstating Claude (08 R1).
     - Sandboxes documented, never configured (08 R4). Note the shipped
       third-party MCP server `context7` (08).
     - Worktree-off note extended to Claude (05 R5).
     - Fix "Regenerate after `sw update`" (update already does it; 07).
     - Caching: Claude applies instruction edits and `update` output only
       after `/clear`, `/compact` or a restart; keep one model per session
       (04 R6). Document `#variant` (03 R2).
   - `project-leader.md`: one routing default: work in-session unless the
     output is verbose, the work is self-contained, or it needs another tier
     or access (05 R3).
   - Skills:
     - One line each in `task-handoff` (records stand without transcripts)
       and `agent-documentation` (date volatile facts) (06 R4).
     - `research`: save raw page text, count research calls only (topic 0
       follow-up, confirmed by topics 3-10).
2. **Known defects.**
   - `free-models` lists GLM 5.2 as free, and it is not. Move the per-model
     list into dated research; the skill keeps the procedure (03 R3, 06 R5).
   - The `$schema` URL `https://opencode.ai/config.json` serves the V1
     schema, which has no `agents` key (03-F20). Fix after runtime test 3.
3. **Claude adapter and OpenCode permissions** (`Get-SwClaudeFiles`,
   `opencode.base.json`).
   - `disallowedTools: Agent` in every generated agent (05 R1, 08 R2).
   - `Read(**/.env)` and `Read(**/.env.*)` ask; `Bash(gh alias:*)` deny; the
     Claude `gh` list is documented as a denylist (08 R2).
   - OpenCode `external_directory`: `allow` becomes `ask` (08 R8).
   - The `subagent:` frontmatter owns the flag: drop the validator's
     hard-coded list, generate the leader dispatch line from the files, keep
     `$script:Routes`; add a Pester test that the flag drives the line
     (05 R7, 09 R4).
4. **`validate`, `doctor` and `comms`.**
   - `validate`: `## Project identity` present; skill name/description
     against the spec; Claude structure from `roles.json` (09 R2). Research
     lint (six sections, header date, a citation per finding) as a shipped
     warning, only where `docs/research/*.md` exists (09 R3).
   - Pester: a staleness test on shipped skills (09 R5).
   - Budget: label tokens a bytes/4 estimate (04 R1). `sw doctor` says only
     kit files are counted and points to `/context`; the leader's count adds
     agent descriptions (04 R2, R5). Doctor line for branch protection:
     "not checked; see `.sw/collaboration.md`" (10 R6).
   - `sw comms event`: drop `.sw/comms/` paths from the changed line and cap
     it at 10 (`+N more`) (06 R2).
   - No schema validation until OpenCode serves a V2 schema (09 R6).
5. **Lifecycle** (`Sync-SwProject`, manifest).
   - Record `kitCommit`; refuse a downgrade unless `-Force`; print
     "kit A -> B" (07 R2).
   - Split `skip-modified`: `kept-local` when the kit did not change the
     file; otherwise put the incoming version in
     `.sw/backup/<stamp>/incoming/` with a `git diff` line (07 R3).
   - `-Adopt`: insert the template's project sections into an `AGENTS.md`
     that lacks `## Project identity`, touching no existing text (07 R4).
   - A kit-side rename map that also moves edited files (07 R5).
   - Tag releases in git; no PowerShell Gallery yet (07 R6).
6. **Skills move to `.agents/skills`** (07 R7, 02 option b). After the rename
   map. Runtime test 4 first. It reverses part of the 2026-09-26 "OpenCode is
   canonical" decision; record that in `docs/decisions.md`.
7. **Global overlay** (01 R1-R2, 02 R6). `global install` creates an empty
   `~/.config/superworkspace/rules.local.md` if missing and never rewrites
   it. Claude loads it by an `@` line after `sw:end global`; OpenCode by an
   `instructions` entry in the global `opencode.json`; Gemini by its import.
   The other harnesses are documented as not supported. Runtime test 5
   first. Until this ships, do not run `global install` on a machine with
   personal lines in that block.
8. **Model advisor skill** (03 R1, R2, R7). It lists what the user has
   (`opencode models`, local Ollama or LM Studio), marks free models with a
   strict $0 filter over public keyless lists (OpenRouter, Zen), shows
   data-use terms, and proposes one `sw tiers` line without running it. It
   ships no ranking data. Open: the Artificial Analysis attribution duty for
   data read through OpenRouter.
9. **Codex adapter** (02 R4-R5). `.codex/agents/<role>.toml` (generated,
   git-ignored) pointing at the canonical role files; `AGENTS.md` is native.
   Cursor and Copilot need no adapter (they read `.claude/`); runtime test 6.
10. **Runtime smoke checklist** (09 R7), after packages 1-5. A human runs it
    per harness in a throwaway init: a denied `git push`, a readonly edit, a
    `.env` read. Results go in a task record. Install OpenCode first. Skill
    evaluation stays a practice: three scenarios plus a baseline, by hand
    (09 R8).

### Runtime tests (manual; each gates the package named)

1. A `/context` run in a fresh Claude session checks the bytes/4 estimate
   (04, package 4).
2. OpenCode: does it load `AGENTS.md` in child sessions, honour
   `subagent:` in V1, nest, and message between sessions? (04, 05;
   package 3.)
3. Does OpenCode V2 warn on the V1 `$schema`, and what does
   `opencode models --verbose` print for free models? (03; packages 2, 8.)
4. Duplicate skills in OpenCode when both `.opencode/skills` and
   `.agents/skills` exist (07; package 6).
5. Does OpenCode's `instructions` accept `~/` paths, and do project arrays
   replace or extend the global one? (01; package 7.)
6. Do Cursor and Copilot accept Claude `model` aliases in `.claude/agents`?
   (02; package 9.)

### Deferred (revisit on the named trigger)

- Gemini adapter (02 R4): Antigravity CLI replaced Gemini CLI for unpaid
  users on 2026-06-18 (03-F6); revisit on demand.
- `effort` in generated Claude agents (03 R5).
- Per-role Claude hooks (08 R5); update the `decisions.md` hook lesson with
  its documented cause when touched.
- Doctor warning for a small local context window, such as Ollama's 4K
  default (04 R3).
- Configurable branches (10 R1): when a team asks for task branches or a
  hosted agent, list long-lived branches (option d), not a pattern.
- Pack format (01 R3): when a second bundle exists.
- The optional `sw comms event` refusal on a task-ID collision (10 R3).

### Human actions (the kit prints, never runs)

- Set the solo ruleset on `main` (10 R6). The repository is public since
  2026-09-27; `main` was unprotected when checked that day.
- Fast-forward `main` from reviewed work; publish.

## Standing rules

- Models: assume free models until the user declares, or the tool detects,
  their models and providers. Never force a model; recommend the best use of
  what they have.
- Harnesses: OpenCode is canonical and Claude is opt-in; the goal is every
  major AI app, without duplicated files or skills unless cross-harness use
  needs them (package 6 changes where canonical skills live, not this rule).
- Instructions are reviewed on recorded failures, not on a schedule (06 R6).

## Hypotheses

Resolved by Phase 0:
- Personal opinions live in `rules.local.md`; packs are deferred and profiles
  stay the extension unit (01 R1-R3).
- The branch model becomes configurable: not yet (10 R1).
- Global rules become a neutral core plus a user overlay: yes (01 R1-R2;
  package 7).

Open:
- Generators, a pack registry, hooks and a spec flow.
