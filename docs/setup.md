# Setup and adoption

SuperWorkspace is installed **from a kit clone into a project root**. Keep the
clone separate so you can update the kit without mixing it with your application.
In this guide `sw` means
`powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1` inside an installed
project; `init`, `update` and `global` run from the kit's root `sw.ps1` instead.

## Prerequisites

Install these yourself; the kit does not install tools or authenticate accounts:

- [Git](https://git-scm.com/downloads), on PATH. Configure your identity before
  committing (prefer project-local `git config user.name` / `user.email`).
- Windows PowerShell 5.1, built into Windows (`powershell`). PowerShell 7
  (`pwsh`) works too; every command below runs the same with `pwsh` in place of
  `powershell`. The kit is Windows-only. `-ExecutionPolicy Bypass` applies to
  that one process only and changes no machine or user setting; Group Policy can
  still forbid it. A Group Policy execution policy overrides `-ExecutionPolicy`
  ([about_Execution_Policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)):
  if `Get-ExecutionPolicy -List` shows `MachinePolicy` or `UserPolicy` set to
  `Restricted` or `AllSigned`, the kit's scripts cannot run and only your
  administrator can change that policy.
- For agent sessions: [T3 Code](https://t3.codes) (required app; desktop
  `winget install T3Tools.T3Code`, or the `t3`
  CLI), plus Claude Code and/or the Codex CLI, each with your own login and
  provider access. T3 Code is early-stage software ("expect bugs" in its
  README). Do not put credentials in shared project files.
- Optional: GitHub CLI (`gh`) for GitHub helpers, RTK >= 0.48 for output
  reduction, Git LFS for an Unreal project's actual LFS workflow. Pester is only
  a kit-development requirement.

```powershell
git clone https://github.com/BiscuitDoesStuff/SuperWorkspace.git
cd SuperWorkspace
git status --short --branch
git rev-parse HEAD
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 help
```

Select a reviewed revision; `main` is moving development, not a stable release
channel. Check its hosted CI at that exact SHA. `VERSION` alone cannot reproduce
an install; `.sw/manifest.json` records kit version and commit, but a dirty clone
can contain code not represented by that commit. Use a clean clone for adoption.

## Choose a profile

| Option | Intended use |
| --- | --- |
| `-Profile generic` | Application/code projects, project-discovered build/test commands |
| `-Profile research` | Research/evidence projects, cited findings and evidence checks |
| `-Profile unreal` | Unreal projects, engine/build constraints and managed LFS patterns; does not install the engine or initialize LFS |
| `-Capabilities research` | Add the outside-research skill and checks to another preset |
| `-Name <name>` | Project name recorded in `.sw/config.json` (default: the folder name) |
| `-NoGitHub` | Omit kit GitHub workflows/templates; existing project-owned GitHub files are not deleted |
| `-GitHubTier 0\|1\|2` | Stated GitHub access for agents (default 0, read-only); see [Git flow](../.sw/workspace.md#git-flow) |
| `-GitPolicy host` | Default for new installs; host owns branches, worktrees and integration |
| `-GitPolicy workspace` | Explicit kit workflow: T3 Code worktree threads and the [Git flow](../.sw/workspace.md#git-flow) |
| `-Records local` / `tracked` | Default new records local; tracking is an explicit opt-in |

Fresh installs use selection v1. Older configs without `selection` stay legacy
(all base components) until explicit `update -SelectionV1`; capabilities are
additive to the preset. Never migrate a real project merely to test an option.

## What init writes

Into the target project, each listed in `.sw/manifest.json` as a whole-file
managed copy unless noted:

- `AGENTS.md`: core rules and profile blocks; the project-owned sections are
  yours to fill.
- `.sw/`: the project CLI (`sw.ps1`, `lib/`), `workspace.md`,
  `collaboration.md`, `onboarding.md`, `config.json` (your choices),
  `profile.json`, `selection.json`, license notices and `comms/` placeholders.
- `.agents/skills/`: workflow and method skills (Codex loads these). Each
  user-invoked workflow skill also has `agents/openai.yaml`
  (`policy.allow_implicit_invocation: false`), so Codex runs it only when
  named explicitly (`$work`).
- `.claude/CLAUDE.md` (imports `AGENTS.md`), `.claude/settings.json` (hard-limit
  `permissions.deny` rules) and `.claude/skills/` (generated copies of
  `.agents/skills/`). These are tracked, generated files; there is no adapter
  step.
- `.codex/rules/workspace.rules`: the same hard limits as Codex `forbidden`
  rules. Codex loads them only after you trust the project in Codex.
- `t3.json`: T3 Code project scripts (validate, doctor, context report), to
  import as project actions. It sets no permissions, models or branch prefix.
- GitHub workflow and templates unless `-NoGitHub`.
- Managed blocks in `.gitignore` and `.gitattributes`. The `.gitignore` block
  ignores per-user and local files: `.claude/settings.local.json`,
  `.sw/models.local.md`, `.sw/backup/`, `.env*` and, with `records: local`,
  `.sw/comms/`.

No commit, remote, push, model choice or user-global configuration is created.
Models are chosen per thread in T3 Code; an optional, ignored
`.sw/models.local.md` may hold your own tier table. `global install` is a
separate, optional user-level setup for Claude Code and Codex, never a
prerequisite.

### Optional user-level setup

From the kit clone, `global install|check|backup` manage a `sw:begin global`
rules block in each provider home: `CLAUDE.md` in a Claude Code config
directory and `AGENTS.md` in a Codex home. T3 Code provider instances can run
Claude Code with their own `CLAUDE_CONFIG_DIR` and Codex with their own
`CODEX_HOME`; name every home those threads use:

```powershell
# several homes as one quoted list separated by ';'
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global check -ClaudeConfigDir 'C:\one;C:\two' -CodexHome 'C:\codex'
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global install -ClaudeConfigDir 'C:\one;C:\two' -CodexHome 'C:\codex' -WhatIf
```

Homes must be absolute paths. With `-File`, each option arrives as one string,
which is read as a list separated by `;`; a string
that holds the separator and is itself an existing directory is refused as
ambiguous. Elements of a PowerShell array
(`-ClaudeConfigDir 'C:\one','C:\two'` when `sw.ps1` is called from a
PowerShell session) are always single paths. Without the option, the
`CLAUDE_CONFIG_DIR` or `CODEX_HOME` of the running shell is used the same way,
else `~/.claude` or `~/.codex`. A named home must already exist, or nothing is
written and no backup is taken. `install` first backs up every file it may
edit, in every targeted home, under
`~/.sw/backups/<UTC>-<id>/` (homes outside your user profile under
`external/`), and keeps earlier unmanaged text above the block.

`install` records the hash of each block it delivers in `~/.sw/global.json`
and never overwrites or deletes a block that was edited locally or cannot be
shown unedited; there is no switch to override this. A block is unedited when
it matches its recorded hash, or, in a home set up before these records
existed, when it is byte-identical (line endings aside) to a version the kit
has shipped. A kept block makes `install` exit 1 (`PARTIAL`) while other homes
are still updated; the version it would have written is saved under the
backup's `incoming/` folder for `git diff --no-index`. To resolve one, move the
edit to the central source (personal lines outside the block, rule changes into
the kit's `global/rules.md`), delete the block from `<!-- sw:begin global -->`
through `<!-- sw:end global -->`, and run `install` again. Broken markers, a
directory where the file should be, or an invalid record stop `install` before
anything is written. Each block is compared and written through one exclusive
file handle, so an edit cannot land in between.

`install` does not change `settings.json` or `~/AGENTS.md`. `check` reports
each home's rules block as OK, missing, outdated, edited or unverified (all but
OK are warnings), a broad `Bash(gh *)` allow in each Claude `settings.json`,
and an `@RTK.md` include in `~/AGENTS.md` that points at a missing file, each
with the suggested change; it never writes. `check` and `backup` report each
home. `doctor -CodexHome <dir>` checks Codex trust in that home instead of the
shell's.

`install` does not install tools. When RTK is missing or older than 0.48 it
prints how to install it; `-InstallRtk` (Windows) runs
`winget install --id rtk-ai.rtk` instead.

### Central skill links (central-v1)

`global ... -Delivery central-v1 -Component skills` links each selected skill
from one central source into each harness: product skills from the kit's
`project/base/.agents/skills/<id>`, personal skills from
`~/.sw/skills/<id>` (a `SKILL.md` whose `name` is `<id>`). Each skill gets one
Windows junction at `<claude home>/skills/<id>` for every Claude home, and at
`~/.agents/skills/<id>` for Codex (shared, whatever `-CodexHome` says). Nothing
is copied, no whole directory is linked and nothing is elevated or installed.
Each link's owner is recorded in `~/.sw/global.json`:

```powershell
# preview, then apply; the first install names its skills explicitly
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global install -Delivery central-v1 -Harness both -Component skills -Skills 'work,review' -PersonalSkills 'mine' -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global install -Delivery central-v1 -Harness both -Component skills -Skills 'work,review' -PersonalSkills 'mine'
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global check -Delivery central-v1 -Harness both -Component skills
# remove every owned link, or only one harness's claim
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global remove -Delivery central-v1 -Harness both -Component skills
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 global remove -Delivery central-v1 -Harness claude -Component skills -ClaudeConfigDir 'C:\one'
```

A repeat `install` of a current owned link changes nothing. When one leaf is
shared by two scopes (a Claude home that is also `~/.agents`), a scoped
`remove` drops only that scope's claim; the link is deleted once no owner
remains. `remove` deletes only a recorded junction that still points at its
recorded source, re-checked just before the unlink, and never deletes or
follows into the source.

`install` refuses, writes nothing there and exits 1 for:

- a real folder or file at the skill leaf: it is kept; move it yourself if you
  want the link;
- a link not recorded as yours (`Unowned link cannot be adopted`), including
  one created by a run whose receipt failed: if it is yours, remove only that
  link with `cmd /c rmdir "<leaf>"` (never `/s`), then run `install` again;
- a recorded link whose type or target changed (`Recorded link type/target
  changed`): fix or remove that link by hand;
- a recorded link whose source is missing or moved (`Owned link is broken`;
  `check` reports it the same way): it is kept and never re-pointed by name;
  clear it with `global remove` (the moved source survives) or
  `cmd /c rmdir "<leaf>"`, then run `install` again;
- a product and personal skill with the same ID (`collision`), naming both
  sources and the target; IDs are compared case-insensitively, and a
  case-only duplicate in one list is a usage error (exit 2);
- a selected source that is missing, or that moved between the plan and the
  write: it is never retargeted by name;
- a skills directory or home reached through a link, or a source and target
  that overlap.

A failure to record a receipt after the link was created exits 1 and names
the unrecorded link; later runs keep it and report it as unowned.

Verification limits (2026-10-26, Claude Code 2.1.302 and Codex CLI 0.164.0,
disposable homes): Claude Code listed the linked skills as user skills, but
invoking one was not tested. Codex was checked at repository scope only: it
does not follow a redirected home, so whether it loads the links in
`~/.agents/skills` is not yet verified natively. `/review` and `/status` are
also Claude Code built-in command names; which one typing them runs was not
tested.

### Project migration (skill delivery)

A project's `.sw/config.json` field `skillDelivery` picks how its selected kit
skills physically arrive: `project-copy` (the default when the field is
missing) generates copies in `.agents/skills` and `.claude/skills`;
`central-v1` stops generating the copies of the selected shared skills and
relies on the central links above. Values are exact-case. Only physical
delivery changes: the logical selection, `AGENTS.md` guidance, validation
checks, project-specific skills, profile skills (such as
`unreal-validation`, which stay copies) and a kit checkout's `project/` tree
are left as they are. Projects that never set the field keep working
unchanged.

Prerequisites: the project uses selection v1 (`update <path> -SelectionV1`
first; a legacy project is refused with that instruction), and
`global install -Delivery central-v1 -Harness both -Component skills` has
linked every selected skill for both Claude and Codex skills. The update reads
only the local record `~/.sw/global.json` and its links; it never scans the
machine and never installs anything. A missing record or link reports
`central prerequisites missing`, `central link missing` or
`central source missing`, and nothing is written. Each link must be the
recorded junction to the product skill: a personal skill of the same name does
not count (`central source is not the product skill`), and a source reached
through another link or junction is refused (`central source redirected`).

```powershell
# From the kit clone, with the project's absolute root; preview, then apply.
# Without -SkillDelivery the current mode is kept.
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update 'C:\path\to\project' -SkillDelivery central-v1 -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update 'C:\path\to\project' -SkillDelivery central-v1
powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\path\to\project\.sw\sw.ps1' validate
# return path: regenerate the project copies
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update 'C:\path\to\project' -SkillDelivery project-copy
```

Both skill trees are checked before anything is removed. A copy converts only
when every file is in the ownership record and unchanged; each converted copy
is backed up under `.sw/backup/<operation>/` before removal, and
`.sw/profile.json`, `.sw/config.json` and the ownership record are written
last, after every removal. If any removal, restore or other effect does not
complete (a file changed while its prompt was open, or the run is
interrupted), the managed blocks, profile, configuration and ownership record
are not written, the affected files are left as found, and the run exits 1
with `PARTIAL` and the next safe step. The managed blocks and profile are
rechecked together and written only when every one is still as it was when
its prompt was answered; otherwise none of them is written. After that
recheck they are written one at a time: `AGENTS.md`, `.gitignore`,
`.gitattributes`, then `.sw/profile.json`. If one of those writes fails, the
earlier ones stay written, the configuration and ownership record are not
written, and the run exits 1 with `PARTIAL`. A delivery change is refused
before any effect, with nothing written, when `.sw/profile.json` or
`.sw/selection.json` was edited locally and so would not reach its planned
content; keep a copy of your edits, remove the file so the kit writes it
afresh, then re-run. In a delivery
change, or an update that removes retained copies, every prompt (removals,
restorations, updates, additions and managed blocks) is answered before the
first write; declining any of them writes nothing (no backup, removal,
restore, ownership record or configuration). The run is
refused, with nothing written, when a copy is edited (`changed baseline`),
holds a file the record does not own (`extra`), is a link (`ownerless link`)
or contains one (`nested link`), or is a project-owned skill with the same
name. `-Adopt` and `-Force` cannot bypass this; resolve the named paths
yourself, then re-run. The return path refuses the same way when a
project-owned entry already sits where a copy would be restored
(`collision`), even when that entry is byte-identical to what the kit would
write: identical content does not prove the kit wrote it. Such a collision
says so; if an earlier return to `project-copy` was interrupted, remove the
named skill directory yourself and re-run, otherwise it is project-owned. The
`PARTIAL` message of an interrupted return names the same step.

The two routes are not equivalent. With `project-copy`, a skill that is also
linked centrally exists twice, as a user skill and a project skill
(`duplicate risk`, reported by the update); avoid that overlap. In a
listing-only check (2026-10-26, Claude Code 2.1.302), Claude Code listed the
user-level link and not the same-name project copy; which copy an invocation
runs, and how Codex treats the pair, are not verified. With `central-v1`,
availability depends on the central links, which `validate` re-checks.
`validate` also fails on a kit copy retained under `central-v1`
(`Stray kit copy retained`); an explicit
`update <path> -SkillDelivery central-v1` converts owned copies with a backup.
Any update that would remove such copies, including one that keeps the
current mode, runs the same central prerequisite checks first and is refused
with nothing written if they fail. Its `-WhatIf` preview lists each such copy
as one that would be backed up and removed on apply, then the next safe step.

An interrupted change exits 1, prints `PARTIAL`, writes neither the
configuration nor the ownership record and claims no central availability.
If only the final configuration write fails, the removals and the ownership
record are already committed but the mode is still the old one; the
`PARTIAL` line says so, and the same preview then apply finishes the change.
Re-run the preview: it names each copy already removed (`missing copy`),
each retained copy and any link or source problem, then the next safe step.
There is no automatic cleanup and no background service; empty skill folders
left behind are yours to remove.

## New project

From the kit clone, use a target outside that clone. These relative examples
work in PowerShell on each supported platform; quote paths containing spaces.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../MyProject -Profile generic -Name MyProject -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../MyProject -Profile generic -Name MyProject
```

Preview first; `-WhatIf` creates no target, Git repository, config or records.
Apply creates the directory and, if absent, a Git repository starting at `main`.
The new `gitPolicy: host` does not require staying on that branch: document your
chosen workflow. Continue with [bootstrap](#bootstrap-and-first-session).

## Existing project

First installation is **init**, even if the repository already exists. Ask its
owner to approve adoption; start from a known, coordinated checkout and run
the application's existing tests before and after. Existing changes are not
stashed or discarded. Use the repository root (including a worktree's root),
not a package underneath another repository.

```powershell
# From the kit clone; replace the example with the actual project root.
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../ExistingProject -Profile generic -WhatIf
# Apply only after reviewing the preview and any conflicts.
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../ExistingProject -Profile generic
```

Existing Git branches/remotes/configuration are left alone. A non-Git folder
is supported too: after successful preflight the kit runs `git init -b main`.
Unknown whole-file conflicts and kit downgrades refuse before Git initialization
or file writes. Permissions/I/O failures during an applied operation can still
leave partial effects; this is not an atomic transaction.

### Ownership and conflicts

| Surface | Behavior |
| --- | --- |
| `AGENTS.md` | Project identity/invariants and text outside `sw` blocks remain project-owned. Core/profile blocks are refreshed, not deep-merged. Review contradictory existing instructions before agent work. |
| `.gitignore`, `.gitattributes` | Kit only inserts/refreshes its named blocks; existing text remains. Managed LFS removal is refused even with `-Force`/`-Adopt`. |
| Files listed in `.sw/manifest.json` | Whole-file managed copies; updates refresh unedited files, keep local edits and supply incoming comparisons when the kit also changed. |
| `.claude/settings.json`, `.claude/CLAUDE.md`, `.claude/skills/`, `.codex/rules/workspace.rules`, `t3.json` | Generated, tracked kit files. An existing differing file at one of these paths is a conflict, including your own Claude or Codex settings. |
| Other host agents, skills, settings and GitHub files | Noncolliding extras (for example `.claude/settings.local.json`, other `.codex/rules` files, other skills) remain project-owned. Matching kit paths conflict. Runtime compatibility is not inferred from file preservation. |
| `.sw/backup/`, `.sw/models.local.md`, `.claude/settings.local.json` | Recovery data and per-user files are ignored. Never publish their private settings or backup contents. |

There is **no transparent merge** of Claude or Codex settings, skills, GitHub
workflows or policy. Resolve conflicts with the owner. You can integrate
settings manually in a separately reviewed change or decline adoption. Personal
Claude settings belong in the ignored `.claude/settings.local.json`, not in the
shared `.claude/settings.json`.

Only when the owner explicitly chooses to replace the conflicting whole files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../ExistingProject -Profile generic -Adopt -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../ExistingProject -Profile generic -Adopt
```

`-Adopt` backs those files up under `.sw/backup/<UTC>-<id>/` and replaces them;
it does **not** preserve their active settings. Backup failure stops its
replacement. Credential-like filenames are excluded by name, not by content;
settings/backup files can still contain secrets. Review them privately. Never
make `-Adopt` an unconditional onboarding command.

## Upgrading from 0.3

Kit 0.4.0-dev drops OpenCode, the agent roles, the opt-in Claude adapter and
the multi-project manager (owner decision D7 in the
[design register](workspace-outline.md)). Upgrade like any other update, from a
clean 0.4 kit clone, previewing first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update ../ExistingProject -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update ../ExistingProject
```

- **Local Claude adapter first.** If the 0.3 adapter is installed
  (`.claude/.sw-generated` exists), `update` refuses and writes nothing. Remove
  it with the installed 0.3 copy, which needs PowerShell 7
  (`pwsh -NoProfile -File .sw/sw.ps1 claude disable`)
  or remove its generated `.claude` files yourself, then re-run.
- **Retired outputs.** Kit files that 0.4 no longer generates (the root
  OpenCode configuration, `.opencode/agents/`, `.opencode/commands/`, the RTK
  plugin, `.sw/roles.json`, the manager module and the merged
  `project-planning`, `focused-review`, `task-handoff` and `free-models`
  skills) are removed when unedited. An edited one is reported as `released`:
  its bytes stay, and it becomes your own file, no longer owned or generated
  by the kit. A released skill under `.agents/skills/` or `.claude/skills/` is
  still discoverable, so Codex or Claude can still load it: delete it or move
  it out of those directories to stop it loading.
- **Retired choices.** The `context7` and `watcherIgnore` config keys and the
  `provider-setup` capability are removed from `.sw/config.json`, with a note.
  Configure MCP servers in Claude Code or Codex yourself.
- **Local model map.** The old per-user `.opencode/opencode.jsonc` (or
  `.opencode/opencode.json`) is left in place and reported, but is no longer
  ignored by the kit's `.gitignore` block. Delete it when unused; never commit
  it.
- **New tracked files.** `.claude/`, `.codex/rules/workspace.rules` and
  `t3.json` are added. Review and commit them like other generated files; an
  unmanaged file already at one of those paths is a [conflict](#ownership-and-conflicts).
- Commands `tiers`, `claude`, `session`, `manager` and `remote` are gone; the
  former OpenCode [remote access](remote-access.md) page is a retirement notice.

Then revalidate the installation and the application, as for any
[update](#updates-and-recovery).

## Supported boundaries

- Project/repository-root setup and non-Git folders; not monorepo subpackages
  or auto-created nested repositories. Submodules/nested setups need a separate
  owner decision. Lifecycle sources, records, targets and backups must have
  ordinary physical paths: participating links/junctions, including roots and
  ancestors, are refused. Unrelated host links are left alone. Ownership keys
  must be exact trusted current/known historical outputs, not arbitrary
  manifest claims. Hard links and hostile concurrent swaps have no general
  safety guarantee; preflight is not an atomic transaction.
- Existing extra files remain, but must satisfy the validator's metadata,
  portability and permission rules. Host policy does not disable safety checks.
  User-global instructions, settings, plugins and MCP servers may change actual
  runtime behavior; installation does not edit them or prove their
  compatibility.
- The Git hard limits in `.claude/settings.json` and `.codex/rules` match
  command prefixes: guardrails, **not a sandbox**. Codex applies them only in a
  project you trust in Codex. Static validation does not prove runtime
  enforcement. Known gaps (aliases and configuration, scripts and APIs,
  run-time-built commands, abbreviated options, some quoting, spelling and
  target forms, commands the limits do not name, and Codex wrapper and
  argument-order forms) and over-blocks are listed in the
  [Git flow](../.sw/workspace.md#git-flow).
- Windows CI is defined. Local offline checks are not hosted or fresh-user
  proof. Provider access, live T3 Code threads,
  second-user handoffs and runtime permissions need separate checks.

## Bootstrap and first session

From the target project:

1. Replace `AGENTS.md`'s project-owned placeholders. State what the application
   is, its boundaries and existing build/tests. Name the current state file and
   document the host Git workflow, or explicitly choose workspace policy.
2. Reuse the project's state source if present; otherwise create, for example,
   `docs/project-state.md` with a `## Startup` section: implemented baseline,
   current authorized task, assigned owner/checkout, protected work and next
   check. State "no work approved" until the owner approves a bounded task.
3. Record the first approved task under `.sw/comms/tasks/<task-id>/` (approval,
   scope, acceptance, ownership and checks). A roadmap, template or T3 Code
   thread is not approval. Local records require explicit handoff to other
   users rather than assuming Git transports them.
4. Validate the installation and your tools:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate
powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 doctor
```

Solo owners omit `-User`. For contributors the owner runs `sw user <you>`;
follow the host's branch setup before `doctor -User <you>`. Under workspace
policy contributors work in T3 Code worktree threads (`t3/<name>`); doctor
accepts `main` or such a branch. Under host policy it reports the branch and that
the project workflow is **not checked**. Doctor also checks for `t3`, `claude`,
`codex`, `gh` and `rtk` and whether Codex trusts the project. Warnings are not
proof of readiness; required-tool failures are errors. `doctor` never installs
or authenticates.

### T3 Code project setup

1. In T3 Code, add the target as a project and enable Claude Code and/or Codex
   in **Settings > Providers**.
2. Apply the [project settings](../.sw/workspace.md#project-settings-human-once):
   new-thread permissions **Auto** or **Full access**, not **Supervised**,
   worktree branch prefix `t3/` under workspace policy, automatic pull,
   merge-based worktree cleanup that keeps worktrees with local changes, and
   **Auto-resume limited threads** off. `doctor` and `validate` cannot detect
   these settings.
3. If you use Codex, trust the project in Codex so `.codex/rules` loads.
4. Import the scripts in `t3.json` as project actions (Settings, Project
   category, actions: import from `t3.json`). The file follows T3 Code's
   published schema (`https://t3.codes/schema/t3.json`). Leave scheduled tasks
   and webhook automations off unless the owner approves one. T3 Code sends
   product usage events to PostHog by default; set
   `T3CODE_TELEMETRY_ENABLED=false` for the server to opt out.

Open a **new thread in the project** with a model you choose, then use the
`work` skill on the approved task. Under host policy, follow the host project's
workflow; T3 worktree threads require explicit host-owner approval. Under
workspace policy, the main thread coordinates: it plans, records and dispatches
independent packages to T3 worktree threads (one `t3/<name>` branch and checkout
each); task records stay in the main checkout, and worktree threads report in
their final message. Commits, pull requests, review (Codex by default) and
auto-merge under workspace policy follow the
[Git flow](../.sw/workspace.md#git-flow). Check loaded rules, skills and
effective permissions before consequential work; static validation is not
runtime verification. See [T3 Code threads](../.sw/workspace.md#t3-code-threads).

### First approved tasks

Start with a bounded task and state what the result should preserve. These
examples use the existing procedures and do not require another capability.

- **Writing:** "Edit the supplied paragraph for clarity. Preserve its meaning
  and factual claims; flag missing information rather than invent it. Return
  the revised paragraph and any unresolved questions." Check the result against
  the original for changed meaning or unsupported additions.
- **Research:** "Answer this question using only the supplied documents. Cite
  the supporting passages, distinguish weak evidence and reused sources, and
  retain disagreements the documents cannot resolve. Return a cited answer
  with uncertainty and open questions; ask before outside collection." Check
  each conclusion against its cited passage and keep unsupported claims open.
- **Software:** "Use `work` to make this approved, bounded behavior change.
  Find the owning source and callers, preserve unrelated work, discover and run
  the repository's appropriate checks, and obtain the required review. Report
  the change, exact check results and remaining limits." Follow the project's
  Git policy and distinguish automated checks from any unperformed acceptance.

## Updates and recovery

Updating the **kit clone** and updating an **installed project** are different:

1. Human receives/selects a reviewed kit revision with a clean clone and checks
   its hosted CI. There is no auto-update service or guaranteed stable channel.
2. From that clone, preview then apply an approved project update:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update ../ExistingProject -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update ../ExistingProject
```

3. Read the report. `kept-local` means your edit stays and the kit version did
   not change. `skip-modified` also supplies an ignored incoming version under
   `.sw/backup/<UTC>-<id>/incoming/`. Compare with the printed
   `git diff --no-index` command (exit 1 normally means differences), then
   resolve by intent. No automatic merge. `released` marks an edited retired
   kit output now owned by the project. Other modified files removed from the
   kit remain as `orphan-kept`; unchanged owned files removed from the kit are
   removed. `stale` means the file changed while you were confirming, so it was
   left exactly as found; the run ends `PARTIAL` with exit 1 and records no
   configuration choices. Find out what changed it, then preview again.
4. Revalidate the installation **and application**. Publish selected shared
   changes only after private-data review. Other contributors receive them,
   including the regenerated `.claude/` and `.codex/` files, through the host
   workflow.

Updates preserve existing Git/privacy/selection choices. Explicit
`update -GitPolicy host|workspace` or `-Records local|tracked` changes those
choices; review previews first. Choosing local does not untrack existing records
or remove past disclosures; the human decides any Git/history migration.
Choosing tracked can expose accumulated local records: review before
staging/publishing.

Kit downgrades stop unless you consciously pass `-Force`. Do not use that flag
to fix an unknown mismatch; first select the intended kit revision.
Managed-block errors and unsafe selection/LFS changes also stop; fix only with
separate approval. Before retrying any partial failure, inspect actual files,
Git state, manifest and recovery copies. There is no automatic rollback or
uninstall: restore/merge only the specific affected files you verified, keeping
unrelated work and the operation's backup. Never reset/clean/stash to recover.

### Recovery recipes and leaving

Each recipe starts the same way: name the last operation the owner approved,
then look at the actual files and Git state before choosing anything. Do not
restore over a file whose current edits you cannot account for; copy it aside
first.

**Which managed files are unedited.** `.sw/manifest.json` holds a SHA-256 for
each whole-file managed copy (UTF-8 text with CRLF read as LF). This read-only
check, run from the project root, prints `unchanged`, `edited`, `missing` or
`linked` (reached through a junction or symbolic link, or outside the project)
for each one:

```powershell
$root = (Get-Location).ProviderPath.TrimEnd('\', '/')
$m = Get-Content -Raw .sw/manifest.json | ConvertFrom-Json
$sha = [Security.Cryptography.SHA256]::Create()
foreach ($p in $m.files.PSObject.Properties) {
  $state = 'missing'
  if (Test-Path -LiteralPath $p.Name -PathType Leaf) {
    $full = (Resolve-Path -LiteralPath $p.Name).ProviderPath
    $linked = -not $full.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
    for ($d = $full; -not $linked -and $d; $d = [IO.Path]::GetDirectoryName($d)) {
      $linked = [bool]([IO.File]::GetAttributes($d) -band [IO.FileAttributes]::ReparsePoint)
    }
    if ($linked) { $state = 'linked' } else {
      $text = [IO.File]::ReadAllText($full).Replace("`r`n", "`n")
      $hash = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') })
      $state = if ($hash -eq $p.Value) { 'unchanged' } else { 'edited' }
    }
  }
  "$state  $($p.Name)"
}
```

Only `unchanged` proves a file is still the kit's copy inside this project.
Never delete through a `linked` path: it can lead to shared files elsewhere.
Managed blocks in `AGENTS.md`, `.gitignore` and `.gitattributes` are not
covered by this check.

**Interrupted task close.** `sw comms close` creates
`.sw/comms/archive/<task-id>/`, moves the whole task folder (all files, not
only Markdown) to `events/` inside it, and then writes `SUMMARY.md`. It refuses
to run when that archive folder already exists, so do not retry it blindly:

- Task folder still in `tasks/`, archive folder empty: the move did not happen.
  Remove only the empty archive folder, then close again.
- Archive has `events/` but no `SUMMARY.md` (or a partial one): the evidence
  is intact in `events/`. Keep it and write or finish `SUMMARY.md` by hand from
  those events; do not move them back and close again.
- Anything else (files in both places, unexpected contents): stop and ask the
  owner. Keep every copy until they decide.

**Kit clone or source missing.** The installed project keeps working without
the clone; only `update` needs one. Keep the installed files as they are and
use the check above to see which are still kit copies. To update later, obtain
a reviewed kit revision (the manifest records the version and commit it came
from) and follow the update steps above.

**Leaving SuperWorkspace.** There is no uninstall command. Remove it by hand,
in this order:

1. Decide what to keep: your own `AGENTS.md` sections, research and docs, task
   records (`.sw/comms/`, local or tracked), your choices in `.sw/config.json`,
   personal files such as `.claude/settings.local.json` and
   `.sw/models.local.md`, notices, and any skill you edited. Native app memory
   and host settings live outside the project and are not touched by removal.
2. Copy what you keep somewhere you choose. A copy on the same disk protects
   against your own deletion, not against losing the machine; an independent
   backup is a separate copy elsewhere.
3. Run the check above. Delete only files it reports `unchanged`. An `edited`
   file is yours: keep it, move it, or delete it as a deliberate choice. An
   edited skill left in `.agents/skills/` or `.claude/skills/` is still found
   and offered by the apps, so move it out if you no longer want it used.
4. In `AGENTS.md`, `.gitignore` and `.gitattributes`, remove the kit's managed
   blocks by reading them, keeping any of your lines inside them that you still
   want.
5. Do not delete `.sw/`, `.agents/` or `.claude/` wholesale: they can hold
   records, personal settings and edited files. Remove what remains only after
   you have looked at it. Leave the host repository's Git history, branches,
   remotes and settings alone; commit the removal like any other change.
6. If you also used global setup, remove each home's block from
   `<!-- sw:begin global -->` through `<!-- sw:end global -->`; the backups
   under `~/.sw/backups/` stay until you delete them. `global remove` strips
   the block but leaves a rules file the kit created in place, empty, and a
   later `global check` warns that the block is missing; delete the file if
   it is empty and you do not use it.

## Troubleshooting and support

- **Script blocked by execution policy:** keep `-ExecutionPolicy Bypass` in the
  command; if Group Policy still blocks it, ask your administrator. Check the
  shell with `$PSVersionTable.PSVersion` (5.1 or 7.x).
- **Kit command unavailable:** run root `sw.ps1` from the kit clone, not the
  target's `.sw/sw.ps1` (which contains project commands only).
- **Conflict / nested target:** refusal is expected; nothing is silently
  merged. Check [boundaries](#supported-boundaries), then make an
  owner-approved migration decision, not a blind retry with `-Adopt`.
- **Update refuses with a local Claude adapter:** see
  [Upgrading from 0.3](#upgrading-from-03).
- **Missing state/task:** complete bootstrap and explicit local selections; do
  not invent authority.
- **Doctor warnings:** optional tools, Codex trust and host Git workflow can
  warn; distinguish those from required tools reporting MISSING/FAILED.
  Runtime access is untested.
- **Edited managed file:** inspect the incoming copy and resolve by intent.
  Keep local edits.

[Support/diagnostics](../CONTRIBUTING.md#support) ·
[Private security reporting](../SECURITY.md). Do not post credentials, raw
private task records, local model tables or backup contents in public issues.
