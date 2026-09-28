# Decisions

Format: `YYYY-MM-DD: Title (status)`. Newest first. Record no secret values.
The earlier decision logs (ai-environment-foundation, MyMMO) are summarized
here. Their repositories keep the full history.

## 2026-09-27: Tiers are light/standard/high, routed per task (accepted)

- **Why:** the owner's model-tier analysis (ModelAnalysis side session,
  kept local, not committed) routes work per task in two lanes, Planning and
  Execution, by a written rubric; calibrated 15/15 on owner-labelled tasks.
- **Decision:** tiers become `light`, `standard`, `high` (no aliases). Planning
  roles default to standard, execution roles and explore to light. The routing
  rules and rubric ship in `.sw/workspace.md`; model IDs and benchmark data
  stay local (03 R7 holds). The Claude adapter emits `model: opus` plus
  `effort` (low/medium/xhigh), taking up 03 R5.
- **Reverses:** 03 R6 ("`roles.json` tiers: no change").
- **Trade-off:** Opus at every Claude tier costs more quota than the old
  opus/sonnet/haiku aliases; the owner accepted it.

## 2026-09-27: Canonical skills live in `.agents/skills` (accepted)

- **Why:** `.agents/skills` is read by OpenCode, Codex, Gemini, Cursor and
  Copilot (research 02, option b); `.opencode/skills` only by OpenCode.
  Universality is the goal, so the move does not wait for a named user (07 R7).
- **Finding (runtime test 4, `p1-06-skills-move`):** OpenCode 2.0.18 reads
  project skills from `.opencode`, `.agents` and `.claude`, lists a shared
  name once, and gives precedence `.opencode` > `.agents` > `.claude`.
- **Decision (package 6):** skills are canonical in `.agents/skills`; agents,
  commands and plugins stay in `.opencode/`. `update` moves edited kit skills
  out of `.opencode/skills` with their edits (rename-map prefix), because a
  copy left there shadows the kit's in OpenCode; `validate` rejects one.
  Claude still gets a generated `.claude/skills` copy, since it reads no other
  folder; in OpenCode the `.agents` copy shadows it.
- **Supersedes:** "OpenCode is canonical" (2026-09-26) for skills only.

## 2026-09-27: OpenCode session rules live in every agent (accepted)

- **Finding (corrected the same day):** the checkpoint concluded that OpenCode
  desktop 2.0.17/2.0.18 ignores the project-level `permissions` list. It does
  not: `opencode debug agents` shows project and agent rules both applied.
  The real cause was the kit's own RTK plugin. In 2.0.18 the shell
  `create.before` hook runs before the permission check, so `git push ...`
  is checked as `rtk git push ...` and no `git ...` or `gh ...` rule matches.
  The solo ruleset on `main` blocks force pushes and deletion, not ordinary
  pushes, so it is not a push control.
- **Decision (package 5a):** one list, `Get-SwSessionRules` in
  `Sw.Project.psm1` (base, profile edit denies, GitHub tier, `.env` asks),
  is rendered at the head of every kit agent's `permissions`, of
  `agents.build`, and into `opencode.jsonc`. The base list moved out of
  `opencode.base.json` into code, because installed projects run `validate`
  from `.sw/lib` without the kit's JSON. `validate` models each agent file
  alone and reports drift. Injection stays as defence in depth. Every
  rendered shell rule gets an `rtk ` twin with the same effect, directly
  after it (`Add-SwRtkTwins`), and `validate` checks every shell case in both
  forms. Any other plugin that rewrites commands would bypass rules the same
  way.
- **Supersedes:** "branch protection on `main` is the real push control" in
  the branch-model entry below.
- **Open:** whether OpenCode enforces the `.env` rule form; the desktop
  re-test decides.

## 2026-09-27: The branch model stays fixed, with a solo mode (accepted)

- **Model:** only `main` and owner-designated `<user>/<user>-worktree`
  branches, integrated by fast-forward. No task, feature or agent-made
  branches. Until now no rationale was recorded (research 10-F21).
- **Why it stays:** research found no need to change it. One long-lived
  branch per contributor matches the one-checkout rule (10-F15) and the
  ff-only integrate flow. Agent tools (Claude `--worktree`, Codex cloud,
  Copilot cloud agent) name their own branches per task, so a configurable
  pattern would not make them fit (10-F5, 10-F7). The original reason for
  "no task branches" is still unrecorded (10 Q2, open with the owner).
- **Solo mode:** `users: []` in `.sw/config.json` already marks a one-person
  project. There the owner works on `main` directly, like trunk-based
  development's direct-commit case for small teams. Once `sw user add`
  records anyone, everyone, the owner included, works on their own branch.
  This repository's practice is that mode, not a violation.
- **Not configurable yet:** a config field would duplicate `users`. Revisit
  when a team asks for task branches or a hosted agent; then list the
  long-lived branches (option d) rather than add a pattern (10 R1).
- **Protection:** branch protection on `main` is the real push control
  (08 R3), set by a human; the kit prints the steps (10 R6).
- **Cloud sessions:** a cloud Leader pushes only to its harness-assigned
  transport branch; the owner fast-forwards `main` (`docs/development.md`).

## 2026-09-26: Phase 0, a universal platform built research-first (accepted)

- **Layout:** `product/` is what ships; the repository root is the kit's own
  dev workspace, installed by the kit itself (dogfooding). Product text
  carries no personal names, paths or opinions; a Pester guard enforces it.
- **Research first:** kit behavior stays frozen until sourced research
  (`docs/research/`) revises `docs/roadmap.md`. The only exceptions are the
  split, the leak cleanup, the dogfood install and the researcher.
- **Core researcher:** `project-research` ships in core, bootstrapped from
  mattpocock/skills `research` plus the Anthropic claude-cookbooks research
  subagent rules (both MIT), then revised by research topic 0.
- **Dev process:** a Leader session owns the whole plan and reviews; worker
  sessions each run one work package. Task records in `.sw/comms/` are the
  durable channel; see `docs/development.md`. Whether the product ships this
  model is left to research topics 5 and 10.

## 2026-09-26: v0.2.0 hardening and contributor onboarding (accepted)

**Runtime verification of 0.1.0 is complete.** On OpenCode 2.0.17:
- `/api/agent`, `/api/command` and `/api/skill` list every role, command and
  skill;
- the Desktop UI checks pass;
- a headless Claude Code session loads the Leader hook, the agents and the
  commands.

The verification ladder in `.sw/workspace.md` records the gotcha that the
first request can return `[]`. From Git Bash, headless Claude tests need
`MSYS_NO_PATHCONV=1`.

**What an Opus review of 0.1.0 found and fixed:**
- **Data loss:**
  - comms names allowed path traversal;
  - `comms close` dropped files that were not `.md`;
  - `claude enable` and `claude disable` overwrote or deleted your own
    `.claude/` files.
- **Security:**
  - one of the two broad `gh` allows survived `global install`;
  - the Claude deny list was missing several `gh` write verbs;
  - backups copied `opencode.json`, which can hold API keys.
- **Linux and macOS:**
  - dotfiles were hidden;
  - the Windows-only `remote` calls failed.

Every fix has a regression test.

**Contributors:** they check their own setup with `sw doctor`. It only reads,
and it prints the fix for each problem instead of installing anything. The
kit writes files; humans make installs and account changes.

## 2026-09-26: SuperWorkspace replaces both predecessors (accepted)

MyMMO's workspace layer was rich but welded to one game. The ai-foundation repo
was thin. SuperWorkspace keeps what worked in MyMMO and makes it generic:

- one owning source per rule;
- tracked role and command bodies that don't depend on a particular harness;
- a strict validator that fails loudly;
- task records reconciled with git.

It also adds install and update tooling. The old locations were harvested once
and then stripped:
- **MyMMO:** stripped locally only. Its owner re-pulls from git when needed.
- **ai-foundation:** the local copy is deleted and the GitHub repo gets archived.

## 2026-09-26: OpenCode is canonical, Claude is an opt-in adapter (accepted)

**Why:** a collaborator uses OpenCode only, and Claude stays optional.

**What changed:** the Claude adapter is now generated from `.opencode/` sources
instead of being kept in step by hand and checked with a parity script. This
removes a whole class of drift. Skills are copied into `.claude/skills/`.
MyMMO used absolute-path junctions there, and those broke whenever the
checkout moved.

## 2026-09-26: PowerShell 7 for tooling (accepted)

**Why:** it runs on every platform. It avoids the Windows PowerShell 5.1
problems that MyMMO documented: the `&&` parse errors, and stderr under `Stop`
throwing errors.

**Cost:** pwsh has to be installed (winget). The OpenCode shell tool still uses
PS 5.1 on Windows unless pwsh is present, so agent-facing docs keep the `;`
guidance.

## 2026-09-26: Tiered GitHub access (accepted)

- **Tier 0 (default):** read-only.
- **Tier 1 (per-project opt-in):** agents may create issues, comment, and open
  draft PRs.
- **At every tier:** agents never merge, push, release or change settings.

**Enforcement:**
- In OpenCode: deny `gh *`, then allow listed commands (the last match wins).
- In Claude: deny always beats allow, so the write verbs are enumerated one by
  one.
- `gh pr create` is set to "ask" at tier 1, because Claude can't require
  `--draft`.

**Known gap:** a prompt-level bypass through `bash -c` is still possible, and
so are `git -C . push`, `git -c k=v push`, quoted verbs, an absolute path to
`git`, other shell wrappers and git aliases (research 08-F26). Branch
protection is the real control (08 R3).
Permissions are guardrails, not a sandbox.

## 2026-09-26: In-repo comms over a separate service (accepted)

Messages and task records are plain files in `.sw/comms/`, and git carries
them. There is no server and no second repository. Closing a task writes a
one-page `SUMMARY.md` and archives the events, because MyMMO's records grew to
20+ files of 20 KB per task. Messages carry no authority. Approval stays in
task events or with the human.

## 2026-09-26: Remote access through `tailscale serve` (accepted)

OpenCode binds to loopback and is published to the tailnet over HTTPS. That
removes the LAN-wide `0.0.0.0` bind and the firewall rules pinned to one
version.

**Caveat:** the second computer is browser-only and cannot install Tailscale.
For it, `sw remote setup -KeepLan` keeps the password-protected LAN bind.
`sw remote setup` is never run by an agent, because it changes network
exposure. Firewall rule removal is printed for the human to run.

## 2026-09-26: Free-first cost guardrail (carried over, accepted)

No metered API spend without explicit approval. Access defaults to free
models (OpenCode/OpenRouter free tiers, local models). Roles map to tiers, never to model IDs, in shared config. Each user
keeps their own tier map, and it is git-ignored.

## 2026-09-26: Stay file-based, with no config-manager app (carried over, accepted)

CC Switch was trialed and rejected for three reasons:
- its database becomes the source of truth;
- it writes the legacy `provider` key;
- it imports credential values into its database and exports.

SuperWorkspace follows the same rule. It uses native config files, adds
managed blocks, and keeps nothing in a database.

## Lessons carried forward (from predecessor records)

- **Rule order matters.** The read-only roles re-allow `git log --oneline -10`
  and `git ls-files --others` after denying `git *--o*`. It looks like
  duplication but it is required. The validator catches its removal.
- **`gh pr create` bypasses a `git push` deny,** because the PR path pushes
  for you. Tier rules deny it explicitly.
- **Claude frontmatter PreToolUse hooks were skipped** as "folder not trusted"
  on Windows (Claude Code 2.1.281), so role limits in Claude are prompt-level
  plus the generated deny list.
- **OpenCode V2 on Windows uses PowerShell 5.1** unless pwsh is present. RTK
  passes `&&` through unchanged.
- **Turn off OpenCode Desktop automatic worktrees.** They create detached
  branches outside the branch policy.
- **`opencode.jsonc` stays strict JSON** so the validator can parse it.
- **Dotfiles are hidden on Linux and macOS.** Without `-Force`, `Get-ChildItem`
  skips `.sw/`, `.claude/` and `.opencode/`, and `Remove-Item` refuses them. The
  v0.1.0 CI failed on ubuntu for this reason. Windows only hides items that
  have the Hidden attribute.
- **Backups must exclude credential files.** The old backup script copied
  `service.json` and `.claude.json`. SuperWorkspace filters them out by name.

## Open items

- MyMMO adoption: see [case-studies/mymmo.md](case-studies/mymmo.md).
- Off-LAN Tailscale route: unverified until Tailscale is up and HTTPS is
  enabled for the tailnet.
- RTK upstream OpenCode V2 plugin (rtk-ai/rtk#3463): delete the project shim
  when it ships.
- Godot and Unity profiles: add when a project needs them.
