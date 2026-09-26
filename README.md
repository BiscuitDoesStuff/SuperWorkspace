# SuperWorkspace

A reusable foundation for AI-assisted projects. One PowerShell 7 CLI installs
a multi-agent workspace into any new or existing repository. The same CLI also
sets up your user-level AI tooling and your remote access. OpenCode is the
shared harness. Claude Code is an opt-in local adapter.

## What you get

| Layer | What SuperWorkspace provides |
| --- | --- |
| **Project** | `AGENTS.md` policy (with managed blocks), 9 roles, 9 commands, 8+ skills, `opencode.jsonc` with a permission model, an RTK plugin, and `.sw/` (workspace guide, collaboration rules, comms, validator) |
| **Profiles** | `generic` (any stack) and `unreal` (C++; LFS binary assets, binary-edit denies, UE validation skill) |
| **Collaboration** | Task records and inboxes in `.sw/comms/`, carried by git. Rules for contributor branches and fast-forward integration. Closed tasks are summarized so they stop costing context |
| **GitHub** | Tier 0 is read-only (the default). Tier 1 adds issues and draft PRs. Also issue forms, a PR template, labels, and a CI workflow that runs the validator |
| **Claude (opt-in)** | A generated, git-ignored `.claude/` with pointer agents and commands, copied skills, permission rules and a Leader hook. The validator reports drift |
| **Global** | Managed rule blocks in `~/.config/opencode/AGENTS.md` and `~/.claude/CLAUDE.md`, read-only `gh` allow rules, an RTK check, and backups that never copy credentials |
| **Remote** | OpenCode published to your tailnet through `tailscale serve`, plus a health check |
| **Usage** | A startup token budget per role, RTK savings, OpenCode stats, free-first model tiers, and a stop rule for 429 errors |

## Requirements

- PowerShell 7.2+ (`winget install Microsoft.PowerShell`)
- git, and optionally gh, RTK ≥ 0.48, OpenCode V2, Tailscale, and Claude Code
- Pester 5+ to run the kit's own tests

## Quick start

```powershell
git clone https://github.com/BiscuitDoesStuff/SuperWorkspace <kit-path>
$sw = '<kit-path>/product/sw.ps1'

pwsh $sw global check                        # what is installed on this machine
pwsh $sw global install -Claude -WhatIf      # preview user-level setup, then run without -WhatIf

pwsh $sw init <path>/MyGame -Profile unreal -Name MyGame          # new project
pwsh $sw init <path>/ExistingRepo -Profile generic -Adopt         # existing project
```

Then, inside the project:

```powershell
pwsh .sw/sw.ps1 validate                                   # static contract check
pwsh .sw/sw.ps1 doctor -User <you>                          # new contributor? see .sw/onboarding.md
pwsh .sw/sw.ps1 tiers -Reasoning <id> -Standard <id> -Fast <id>
pwsh .sw/sw.ps1 claude enable                              # optional Claude adapter
pwsh .sw/sw.ps1 user <name>                                # add a contributor
pwsh .sw/sw.ps1 comms send -To <name> -Subject "..." -Body "..."
```

Open the project in OpenCode. The default agent is `project-leader`; start with
`/work <task>`.

## Commands

Run `pwsh product/sw.ps1 help`. Every command that writes accepts `-WhatIf`.

| Command | Where | Purpose |
| --- | --- | --- |
| `init`, `update` | kit | Install, adopt, or re-apply the kit. Files you have modified are skipped and reported |
| `global install\|check\|backup` | kit | User-level config, a tool inventory, and backups |
| `remote setup\|check` | kit | OpenCode over Tailscale (`-KeepLan` keeps LAN access for devices that can't run Tailscale) |
| `validate` | project | Static checks: definitions, permission matrix, portability, startup budget, hygiene, Claude drift |
| `doctor` | project | Read-only setup check for a contributor (`-User <name>`); never installs or changes anything |
| `claude enable\|disable` | project | The local Claude adapter |
| `tiers` | project | The per-user model map (git-ignored) |
| `comms send\|inbox\|event\|close\|archive` | project | Messages and task records |
| `user <name>` | project | Record a contributor |
| `gh status\|labels` | project | Read-only GitHub summary; applying labels is done by a human |
| `usage` | project | RTK savings, OpenCode stats and the startup budget |

## How updates work

`init` records every file it manages in `.sw/manifest.json` with its hash.
`update` handles each managed file based on its current state:

- **Unchanged since install:** replaced with the new kit version.
- **Edited by you:** skipped and reported, never overwritten.
- **Dropped from the kit:** removed if you never edited it.

`AGENTS.md`, `.gitignore` and `.gitattributes` are shared with your project.
The kit only rewrites its own `<!-- sw:begin ... -->` / `# sw:begin` blocks.

## Layout

Everything that ships lives in `product/`:

```
product/sw.ps1                 CLI entry (the same file is copied to <project>/.sw/sw.ps1)
product/lib/Sw.Project.psm1    in-project commands (copied into projects)
product/lib/Sw.Kit.psm1        init/update, global, remote (kit only)
product/project/               everything installed into a project: base/, profiles/, github/, roles.json, opencode.base.json
product/global/rules.md        the managed global rules block
product/docs/                  user guides
```

See [product/docs/remote-access.md](product/docs/remote-access.md) for
Tailscale. Developing SuperWorkspace itself? See
[docs/development.md](docs/development.md).
