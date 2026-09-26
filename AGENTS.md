# SuperWorkspace: agent instructions

This repository is the kit, not a project that uses it. Read `README.md` for
the layout. `docs/decisions.md` records why things are the way they are; read
it before changing a rule.

## Rules for changing the kit

- **One owning source per rule.** The roles, commands and skills in
  `project/base/.opencode/` are canonical. Role metadata (tier, access, Claude
  tools) lives only in `project/roles.json`. GitHub tier rules live only in
  `Get-SwGhRules` and `Get-SwClaudeGhDeny` in `lib/Sw.Project.psm1`. The
  Claude adapter is generated, so never add hand-written `.claude/` templates.
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
- **The kit writes files; it never runs security or account changes.**
  Examples: firewall rules, GitHub writes, pushes. It prints the exact command
  for the human to run instead.
- **Keep startup context small.** Measure the per-role budget with
  `validate` on a fresh init. Don't grow `AGENTS.md` or role bodies without a
  reason.

## Checks before handing work back

```powershell
pwsh -NoProfile -c "Invoke-Pester tests -Output Detailed"
pwsh -NoProfile -File sw.ps1 init $env:TEMP\sw-check -Profile unreal -Name Check
pwsh -NoProfile -File $env:TEMP\sw-check\.sw\sw.ps1 validate
git diff --check
```

Bump `VERSION` and add a `CHANGELOG.md` entry for any change that installed
projects will receive through `update`.
