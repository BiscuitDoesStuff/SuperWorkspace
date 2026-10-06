# Developing Workspace

The public SuperWorkspace repository now carries the research-led Workspace
project. The active kit is at the root; the old `product/` layout remains in
Git history, not as a second active generator.

| Path | Responsibility |
| --- | --- |
| `sw.ps1`, `lib/`, `project/`, `global/`, `VERSION` | Current kit sources |
| `.sw/`, `.opencode/`, `.agents/` | Generated installation used by this project |
| `tests/Sw.Tests.ps1` | Inherited lifecycle, validator, permission and adapter Pester coverage, adapted to current contracts |
| `tests/workspace-v1.ps1` | Dependency-free offline launcher/adapter regression, native CLIs stubbed |
| `lib/Sw.Manager.psm1`, `project/manager/`, `tests/manager.ps1` | Separate non-Git manager installation and bounded project planning coordination; native V2 API transport stubbed offline |
| `docs/workspace-state.md` | Current implemented state and authorization |
| `docs/workspace-outline.md` | Current design rules, assumptions and proposals |
| `docs/roadmap.md`, `docs/decisions.md`, `docs/research/`, `docs/case-studies/` | Retained pre-Workspace history/evidence, not current implementation authority |

## Workflow

Follow [AGENTS.md](../AGENTS.md), [workspace ownership](../.sw/workspace.md) and
[collaboration rules](../.sw/collaboration.md). The Leader owns the approved task
queue; specialists never spawn teams. Serialize writers and use one validation
owner per checkout. Commits require explicit owner approval; agents never push.
Solo work uses `main`; contributor branches require owner designation. Imported
cloud/task-branch procedures are historical, not an exception to current policy.

Edit the source rather than competing generated copies. Preview regeneration:

```powershell
pwsh -NoProfile -File sw.ps1 update . -WhatIf
```

Apply an approved update with `sw.ps1 update .`, then validate. Do not enable a
local Claude adapter or configure models/accounts merely to run checks; those
are separate owner opt-ins. Older nine-role, effort and implicit-model test
assumptions have been replaced by the implemented four-role/model-only contracts.

## Validation

PowerShell 7.2+ is required. The suite requires already-installed Pester 5.5+;
local dependency installation needs separate approval. CI uses isolated hosted
Windows/Linux runners and its inherited Pester setup.

```powershell
pwsh -NoProfile -File tests/workspace-v1.ps1 -ParseOnly
pwsh -NoProfile -File tests/workspace-v1.ps1
pwsh -NoProfile -File tests/manager.ps1
pwsh -NoProfile -Command 'Invoke-Pester -Path tests -CI'
pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks
pwsh -NoProfile -File sw.ps1 update . -WhatIf
git diff --check
```

Context-report and recovery-card regressions are the Pester block
`Context and recovery reporting` (`Invoke-Pester -Path tests -FullNameFilter
'Context and recovery reporting*'`). `sw context` and `sw validate` share
`Get-SwStartupBudget`; changing it changes both.

Profile selection v1 (`project/selection.json`, profile `composition`, the
`research` preset and `project/capabilities/`) is the Pester block `Profile
selection v1` (`-FullNameFilter 'Profile selection v1*'`). Fresh `init` defaults
to v1; an existing project without `selection` stays
legacy (all base components) on `update` unless `-SelectionV1` is passed. Its
fixtures use disposable projects and isolated kit copies; a real selection
migration needs separate approval. Selection controls installed files, not
runtime loading, global skills or measured savings.
This Workspace's research + provider-setup opt-in (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`)
is complete locally; other projects' migrations and native acceptance remain separate gates.

Use disposable fixture directories for fresh `init`/`update` checks. Pester and
offline regression do not exercise real model access or runtime permissions;
keep those results separate from the bounded v1 live evidence. After human
publication, verify the exact remote SHA and both GitHub workflows; local Windows
success is not proof of hosted Linux CI. No release/tag or account setup is
implied by a normal main-branch push.

## Manager deployment

`sw.ps1 manager install -Path <root>` deploys a manager-specific subset, not
`sw init`. It rejects unmanaged/modified target conflicts before writing and
backs up owned updates. `.sw/manager-manifest.json` owns generated manager files;
`.sw/manager/projects.json` is the local project registry. No Git, generic
defaults, plugins, MCPs, model mapping or Claude adapter is installed at the root.
Develop changes in these product sources and redeploy; do not hand-edit managed
copies. Root instructions/startup state are root-owned, not generator-owned.

Manager records are local structured events in its `.sw/comms/tasks/`, not Git
transport or project execution approvals. One session/task owner, explicit
operator approvals, bounded messages, immutable intent and native IDs protect
against accidental duplicate dispatch. Shell pattern rules are guardrails; a
separately approved live test must verify native routing and effective policy.
