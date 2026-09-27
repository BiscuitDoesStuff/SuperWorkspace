# SuperWorkspace: agent instructions

This repository is the kit. `product/` is what ships; the root is its dev
workspace. Read `docs/development.md` for the layout. `docs/decisions.md`
records why things are the way they are; read it before changing a rule.

## Project identity

SuperWorkspace installs itself here to dogfood the kit. The implemented state
and the authorized work live in `docs/roadmap.md` (Phase 0 checklist); nothing
beyond that checklist is authorized.

## Rules for changing the kit

- **One owning source per rule.** The roles, commands and skills in
  `product/project/base/.opencode/` are canonical. Role metadata (tier,
  access, Claude tools) lives only in `product/project/roles.json`. GitHub
  tier rules live only in `Get-SwGhRules` and `Get-SwClaudeGhDeny` in
  `product/lib/Sw.Project.psm1`. OpenCode session rules live only in
  `Get-SwSessionRules` (same file); render prepends them to every agent. The Claude adapter is generated, so never add
  hand-written `.claude/` templates.
- **Keep the frontmatter parser strict.** The subset is: scalar keys, plus a
  `permissions` rule list. Anything else fails loudly. That includes YAML
  comments and apostrophes in unquoted scalars. If you need more, widen the
  parser on purpose and add tests.
- **Permission rules are ordered; the last match wins.** For example, the
  read-only roles re-allow `git log --oneline -10` after `git *--o*` is
  denied. That is deliberate, not a duplicate.
- **Templates must stay portable.** No model, provider or shell pins, and no
  absolute paths. `validate` enforces this in installed projects.
- **Every writing function supports `-WhatIf`.** Anything that touches the
  user profile backs up first. Backups never copy credential files (see
  `$script:SecretName`).
- **Pass `-Force` to `Get-ChildItem`, `Remove-Item` and `Copy-Item` on project
  paths.** On Linux and macOS, PowerShell treats dotfiles as hidden. Without
  `-Force` they are skipped or refused (CI runs on ubuntu).
- **The kit writes files; it never runs security or account changes.**
  Examples: firewall rules, GitHub writes, pushes. It prints the exact command
  for the human to run instead.
- **Keep startup context small.** Measure the per-role budget with
  `validate` on a fresh init. Don't grow `AGENTS.md` or role bodies without a
  reason.

## Checks before handing work back

```powershell
pwsh -NoProfile -c "Invoke-Pester tests -Output Detailed"
pwsh -NoProfile -File product/sw.ps1 init $env:TEMP\sw-check -Profile unreal -Name Check
pwsh -NoProfile -File $env:TEMP\sw-check\.sw\sw.ps1 validate
git diff --check
```

Bump `product/VERSION` and add a `product/CHANGELOG.md` entry for any change
that installed projects will receive through `update`.

<!-- sw:begin core -->
## Required startup

The harness auto-loads this file; do not re-read it. Before a meaningful change:

1. Read the project state file named in Project identity, startup section only.
2. Run `git status --short --branch` and `git log --oneline -10`; inspect the
   existing implementation relevant to the task before editing.
3. Confirm the work is authorized. A roadmap, backlog, or old record is not
   approval. If Git contradicts recorded state, stop instead of guessing.

## Principles

- Preserve working behavior before adding new behavior.
- Smallest independently testable change; reuse before writing; no unrelated
  refactors or speculative scope. Load `minimal-change` when implementing.
- Never claim a check, manual test, or publication that did not happen.
- No third-party assets, plugins, or dependencies without explicit approval.
- Do not add systems because they seem like the natural next step; new scope
  needs explicit planning and approval.

## Validation

Choose checks by changed scope. Workspace/docs-only work runs
`pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check`. Code work
follows the profile section below. Report exact commands and outcomes, and keep
automated, headless, and manual results separate. Fix failures your change
caused; report others without broad repairs.

## Git

- Only `main` and owner-designated `<user>/<user>-worktree` branches exist
  (solo projects: `main` only); no task, feature, review, sandbox, or automatic
  branches. Never work on another contributor's branch. Unexpected branches
  are reported, never deleted.
- Never discard, reset, stash, clean, or overwrite existing work. Commit only
  when explicitly asked. Agents never push; humans publish their own branch.
- GitHub writes follow the tier in `.sw/config.json` (see `.sw/workspace.md`).
- Stage selected paths only; never `git add .` in a shared checkout.

## Workspace

OpenCode is the shared harness; other harnesses are optional local adapters.
`.sw/workspace.md` owns roles, approved-plan execution, permissions, tiers, and
runtime checks. `.sw/collaboration.md` owns task records, messages, branches,
and integration. Credentials, machine paths, and model choices stay local.
<!-- sw:end core -->

<!-- sw:begin profile -->
## Profile: generic

Validation order for code changes: (1) the project's build or type check,
(2) its automated tests, targeted first, then the suite, (3) manual or
interactive checks only when a real session exists, (4) `git diff --check` and
trailing-whitespace checks on new files. Discover the actual commands from the
repository (README, package manifest, CI workflow) instead of assuming them.
<!-- sw:end profile -->
