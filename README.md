# SuperWorkspace

A project-local AI workspace for OpenCode: reusable agent roles, on-demand
skills, approval/task handoffs and static checks. Install into a **new project**
or adopt it at an **existing repository root** using the same PowerShell kit.
It does not build your application, configure provider accounts or supply models.

## Start here

- [New project](docs/setup.md#new-project) or [existing project](docs/setup.md#existing-project): kit installation, previews and conflicts.
- [Joining an installed project](.sw/onboarding.md): clone the project, not the kit; no reinstallation required.
- [Setup guide](docs/setup.md): prerequisites, profiles, first task, updates and recovery.
- [Contributing and support](CONTRIBUTING.md) · [Security reports](SECURITY.md).

Requires Git and **PowerShell 7.2+** (`pwsh`, not Windows PowerShell 5.1).
OpenCode and your own provider/model access are needed for agent sessions, not
for installation or static validation. Windows and Linux have CI jobs;
macOS is not currently verified. Use a dedicated kit clone, separate from your
application. Review the [support boundaries](docs/setup.md#supported-boundaries)
before adoption.

```powershell
git clone https://github.com/BiscuitDoesStuff/SuperWorkspace.git
cd SuperWorkspace
# Example target outside the kit repository; preview creates nothing.
pwsh -NoProfile -File sw.ps1 init ../MyProject -Profile generic -WhatIf
# After reviewing the plan and conflicts:
pwsh -NoProfile -File sw.ps1 init ../MyProject -Profile generic
cd ../MyProject
pwsh -NoProfile -File .sw/sw.ps1 validate
```

**Before agent work:** fill the project-owned parts of `AGENTS.md`, name a
current Startup state file, and approve a first task. See
[bootstrap](docs/setup.md#bootstrap-and-first-session). A valid template is not
completed setup or task approval.

## Defaults and safety

- New installs preserve the host Git workflow (`gitPolicy: host`) and keep
  task/inbox/archive records local (`records: local`). Existing installs keep
  their choices; missing legacy fields mean workspace Git policy and tracked
  records. Git ignores do not remove existing tracked files or public history.
- Host configuration conflicts **stop before writes**. There is no automatic
  JSON/JSONC merge. `-Adopt` is an explicit **backup-and-replace** decision, not a
  preservation switch. Managed blocks update; project text outside them stays.
- Generic, research and Unreal presets select roles/skills; `research` and
  `provider-setup` are optional capabilities. Use `-NoGitHub` to omit GitHub
  scaffolding. Global setup, networking, Claude adapters and the multi-project
  manager are optional, separate operations, never quickstart prerequisites.
- Models/settings remain local. Context7 queries go to an external service;
  RTK is optional. Shell permission patterns are guardrails, **not a sandbox**;
  static/offline checks do not establish live permission enforcement.
- Agents do not push, publish releases or change repository settings. Humans
  own those actions. See [workspace contracts](.sw/workspace.md).

## Status and development

`VERSION` identifies the development kit; it is not a release tag or a claim of
green hosted CI. Use a clean, explicitly selected kit revision for repeatable
installs. The public-adoption delivery remains development-only and unreleased.
Observed 2026-10-12: implementation `ddd2c65` passed Windows/Linux Pester,
fresh-install/offline checks and workspace validation. Check the
[CI results](https://github.com/BiscuitDoesStuff/SuperWorkspace/actions) for your
chosen revision. Independent review was explicitly waived by the owner, not performed.
See [changelog](CHANGELOG.md) and
[validation/release gates](docs/development.md#validation).

Sources: `sw.ps1`, `lib/`, `project/`, `global/`. This repository also dogfoods
the generated `.sw/`, `.opencode/` and `.agents/` installation. Edit sources,
then regenerate; do not create competing managed copies.
[Development guide](docs/development.md) · [design register](docs/workspace-outline.md)
· [current project state](docs/workspace-state.md).

The [multi-project manager](project/manager/manager.md) is a separate optional
deployment, not an alternative project installer or execution approval.

## License

[MIT](LICENSE). Preserve [third-party notices](THIRD_PARTY_NOTICES.md), including
the installed `.sw/LICENSE` and `.sw/THIRD_PARTY_NOTICES.md`. Installing the kit
does not change your application's license.
