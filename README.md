# SuperWorkspace

A project-local AI workspace used through [T3 Code](https://t3.codes), running
Claude (Claude Code) and Codex threads: shared core rules, workflow skills,
approval/task records, Git hard limits and static checks. Install into a **new project**
or adopt it at an **existing repository root** using the same PowerShell kit.
It does not build your application, configure provider accounts or supply models.

## Start here

- [New project](docs/setup.md#new-project) or [existing project](docs/setup.md#existing-project): kit installation, previews and conflicts.
- [Joining an installed project](.sw/onboarding.md): clone the project, not the kit; no reinstallation required.
- [Setup guide](docs/setup.md): prerequisites, profiles, first task, updates and recovery.
- [Contributing and support](CONTRIBUTING.md) · [Security reports](SECURITY.md).

Requires Windows and Git. The kit runs on the **Windows PowerShell 5.1** built
into Windows (`powershell`) and on PowerShell 7 (`pwsh`); nothing else to install.
T3 Code (required app, early-stage), Claude Code and/or Codex and your own
provider access are needed for agent sessions, not for installation or
static validation. The kit is Windows-only, and CI runs on Windows. Use a
dedicated kit clone, separate from your
application. Review the [support boundaries](docs/setup.md#supported-boundaries)
before adoption.

```powershell
git clone https://github.com/BiscuitDoesStuff/SuperWorkspace.git
cd SuperWorkspace
# Example target outside the kit repository; preview creates nothing.
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../MyProject -Profile generic -WhatIf
# After reviewing the plan and conflicts:
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init ../MyProject -Profile generic
cd ../MyProject
powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate
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
- Generic, research and Unreal presets select skills; all include the
  10-skill default catalogue, and `research` is an optional capability adding
  its guidance and checks. Use `-NoGitHub` to omit GitHub
  scaffolding. Global setup is an optional, separate operation, never a
  quickstart prerequisite. Claude and Codex files (`.claude/`, `.codex/`) are
  tracked generated files; no adapter step is needed. The kit configures no
  MCP servers; add them yourself in Claude Code or Codex.
- Models/settings remain local; no model is pinned in tracked files. MCP
  servers you add connect to external services; RTK is optional. The Git hard-limit
  rules are prefix guardrails, **not a sandbox**; static/offline checks do not
  establish live permission enforcement.
- Under workspace Git policy agents commit as they go; code and public product
  changes go through a `t3/` worktree thread and a pull request; auto-merge
  is enabled only after review (Codex by default, or a single-provider
  review where the owner uses one provider) and passing CI. Hard limits: no force-push, no push to `main`, no
  releases or repository-setting changes, no rewriting `main` history. Humans
  own branch protection, releases and settings. Set T3 Code's new-thread
  permissions to Auto or Full access, not Supervised. See
  [workspace contracts](.sw/workspace.md).

## Status and development

`VERSION` identifies the development kit; it is not a release tag or a claim of
green hosted CI. Use a clean, explicitly selected kit revision for repeatable
installs. Kit 0.4.0-dev (the T3-native rebuild) is development-only and
unreleased. It passed seven independent review rounds (six Codex, one Claude
by owner choice) and, at its publication commit, the hosted CI of that time
(run 38869117248, Windows and Linux); later commits are covered only by their
own checks. CI now runs Windows PowerShell 5.1 and PowerShell 7 jobs on
Windows, and a published revision must pass both. Check the
[CI results](https://github.com/BiscuitDoesStuff/SuperWorkspace/actions) for your
chosen revision.
See [changelog](CHANGELOG.md) and
[validation/release gates](docs/development.md#validation).

Sources: `sw.ps1`, `lib/`, `project/`, `global/`. This repository also dogfoods
the generated `.sw/`, `.agents/`, `.claude/` and `.codex/` installation. Edit sources,
then regenerate; do not create competing managed copies.
[Development guide](docs/development.md) · [design register](docs/workspace-outline.md)
· [current project state](docs/workspace-state.md).

## License

[MIT](LICENSE). Preserve [third-party notices](THIRD_PARTY_NOTICES.md), including
the installed `.sw/LICENSE` and `.sw/THIRD_PARTY_NOTICES.md`. Installing the kit
does not change your application's license.
