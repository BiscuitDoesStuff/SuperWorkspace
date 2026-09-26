# Decisions

Format: `YYYY-MM-DD: Title (status)`. Newest first. Record no secret values.
The earlier decision logs (ai-environment-foundation, MyMMO) are summarized
here. Their repositories keep the full history.

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

**Known gap:** a prompt-level bypass through `bash -c` is still possible.
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

No metered API spend without explicit approval. Claude runs one month at a
time (about $20). Other access uses free OpenCode/OpenRouter models and local
LM Studio. Roles map to tiers, never to model IDs, in shared config. Each user
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

- Runtime verification of an installed project. What has been checked so far:
  - **Done (2026-09-26):** on OpenCode 2.0.17, `api GET
    /api/agent?location%5Bdirectory%5D=<path>` lists all 8 project roles
    alongside the built-ins.
  - **Done (2026-09-26):** once the service was up, `/api/command` and
    `/api/skill` responded, where they had returned 404 before. They listed all
    8 project commands (plus the built-in `init`) and all 8 unreal-profile
    skills. The first command request for a new directory returned `[]`; a
    repeat returned the full list.
  - **Done (2026-09-26):** OpenCode Desktop UI checks on an unreal-profile
    project, all passed:
    - the Leader is the default agent, and the picker lists the roles;
    - the `/` menu shows the 8 commands;
    - `/validate` passes and `/inbox` runs;
    - the skills load;
    - `git push` is refused.
  - **Done (2026-09-26):** a headless Claude Code session (`claude -p`) in a
    fresh `init -Claude` project. The SessionStart hook made it the Leader, all
    7 pointer agents were listed, and `/inbox` and `/status` ran the project
    bodies (project commands override the built-in `/status`). Deny rules were
    not exercised; destructive commands are never run to prove a denial. From
    Git Bash, set `MSYS_NO_PATHCONV=1`, or the `/cmd` argument gets rewritten
    into a Windows path.
- MyMMO adoption (for the user and Crank). A dry run on 2026-09-26 in a
  throwaway clone of HEAD found no kit bugs. `init -Profile unreal -Adopt`
  backs up and replaces 20 files, adds 19, and `validate` then fails only on
  the startup budget. Before the real adoption:
  - Trim the old MyMMO sections of `AGENTS.md` (startup, validation and git
    rules) that the core block now owns. Keep identity, architecture and the
    invariants.
  - Delete the superseded `mmo-manager`, `mmo-developer` and
    `mmo-world-worker` roles, which have no delegation entries.
  - Delete the old workspace docs and scripts: `docs/{agent-workspace,ai-usage,
    WORKSPACE_USER_GUIDE,HANDOFF}.md`, `docs/collaboration/` and
    `scripts/*Workspace*.ps1`.
  - The `.gitattributes` LFS lines get duplicated inside the managed block.
    This is harmless.
- Off-LAN Tailscale route: unverified until Tailscale is up and HTTPS is
  enabled for the tailnet.
- RTK upstream OpenCode V2 plugin (rtk-ai/rtk#3463): delete the project shim
  when it ships.
- Godot and Unity profiles: add when a project needs them.
