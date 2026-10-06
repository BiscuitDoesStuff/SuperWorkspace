# Workspace

Development checkout of SuperWorkspace, a research-led optimized AI workspace
published as a public product. `origin` is `BiscuitDoesStuff/SuperWorkspace`;
`personal` is the owner's private instance (`personal` remote),
whose adaptations may be upstreamed here.
Every project component can be modified, overhauled or replaced on evidence.

## Start here

- [Project instructions](AGENTS.md)
- [Current state and authorized work](docs/workspace-state.md)
- [Design rules, assumptions and current outline](docs/workspace-outline.md)
- [Workspace roles and verification](.sw/workspace.md)
- [Task records and collaboration](.sw/collaboration.md)
- [Contributor setup](.sw/onboarding.md)

The current kit source lives in `project/`, `lib/`, `global/`, and `sw.ps1`.
The inherited installation lives in `.sw/`, `.opencode/`, and `.agents/`.
Neither layout nor its policies have privileged preservation status. The design
register distinguishes approved requirements, current controls, proposals and
unknowns; current controls still apply until explicitly changed.
Profile selection v1 (generic, research, Unreal presets plus additive `research`
and `provider-setup` capabilities) is the fresh-`init` default. This Workspace
opted into research + provider-setup locally (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`),
retaining its eight kit skills; other projects need their own migration approval. See
[development](docs/development.md) and `.sw/workspace.md`.
The former `product/` kit and removed roles are retained in Git history, not as
active duplicates. Older `docs/roadmap.md`, `docs/decisions.md`, `docs/research/`
and task archives are historical evidence; they do not override current policy
or approve new work. See [development and CI](docs/development.md) for root-layout
checks.

## Explicit session entry (workspace-v1)

Use an existing approved task and owner-selected local role map, not the old
unapproved launcher draft. Implementation and bounded one-route acceptance are
complete; other routes and assurance checks retain the limits below.

```powershell
pwsh -NoProfile -File .sw/sw.ps1 session start project-leader workspace-v1 -Model '<owner-selected-id>' -DryRun
pwsh -NoProfile -File .sw/sw.ps1 session start project-developer workspace-v1 -DryRun
```

Remove `-DryRun` only when launch/access is approved. The Leader requires explicit
`-Model`; a worker uses ignored `.opencode/opencode.jsonc` `agents[role].model`.
Claude models use interactive Claude Code and require a current local adapter;
other models use OpenCode `mini` with explicit model/role. `-Headless` supports
OpenCode `run` only, not Claude. No default model, hidden config activation,
automatic orchestration or blind retry is provided. Dry-run writes nothing.
See [native entry contracts](.sw/workspace.md#native-session-entry) for mixed maps,
Claude Leader setup and unknown-identity/effect recovery. Exit 0 never accepts an
artifact; inspect current approval, actual files and task records before resume.

No Workspace local map or adapter was activated during offline implementation.
Subsequent owner-selected local setup and bounded headless OpenCode engineering,
checkpoint/fresh-session and read-only acceptance passed; see
observed results and limits (local task record `workspace-v1/2026-10-03T081908Z-leader-submission.md`).
One conservative read-only Git denial remains documented; Claude and interactive
routes are untested. Local model choices remain ignored, not shared defaults.

## Multi-project manager instance

The owner-approved WS manager is developed here and installed separately at the
parent directory. It coordinates project priorities, dependencies and bounded
read-only OpenCode planning sessions; it does not merge repositories or approve
project execution. Claude coordination initially uses manual native handoffs.

```powershell
pwsh -NoProfile -File sw.ps1 manager install -Path '<manager-root>' -WhatIf
pwsh -NoProfile -File tests/manager.ps1
```

The installer does not initialize Git or copy the generic project defaults into
the parent. It installs only namespaced `ws-manager`/`ws-planner` agents, its CLI,
commands and manifest. Select the manager explicitly in a fresh root session.
Registry and coordination records stay local. Human planning approvals name the
project, explicit model, owner decision and message budget; install approval is
not live-session approval. See the [operator contract](project/manager/manager.md)
and execution evidence (local task record `ws-manager/`).

## Checks

Run from this directory:

```powershell
pwsh -NoProfile -File .sw/sw.ps1 validate
pwsh -NoProfile -File tests/workspace-v1.ps1
pwsh -NoProfile -File tests/manager.ps1
pwsh -NoProfile -Command 'Invoke-Pester -Path tests -CI'
pwsh -NoProfile -File .sw/sw.ps1 doctor
git diff --check
```

`sw.ps1 context -Task <id> -StateFile docs/workspace-state.md` is a read-only
context and evidence report: static size estimates and source pointers, not an
approval, and it does not observe runtime/global context.

Open a fresh session in this directory to use the installed agent and command
definitions. No model tier map or optional Claude adapter is configured by the
base initializer. Setup checks do not prove runtime permission enforcement.

The design register records the owner's research-led direction and the newer
reviewed Pass 7 status. The v0.2 outline is a historical snapshot, not a current
evidence cutoff or approved target architecture. No full updated design synthesis
or runtime overhaul has been performed; proposals do not authorize implementation.
