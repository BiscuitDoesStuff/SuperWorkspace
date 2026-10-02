# workspace-harness-decision - closure - generator refit (model-only tiers) - 2026-10-02T191500Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner.
- **Approval:** [approval](2026-10-02T183500Z-leader-approval-generator-refit.md) (owner, 2026-10-02).
- **Status:** complete and uncommitted. Nothing is committed or pushed.
- **Branch / base:** `main` at `ddd155c`.

## Changes

- **Kit source `lib/Sw.Project.psm1`** (installed into `.sw/lib/` by `sw update`):
  - removed `$script:ClaudeEffort` and the generated `effort:` line; Claude agents keep `model: opus`;
  - the effort contract check is replaced by `NoEffort`. It rejects `effort`, `reasoningEffort`, `reasoning_effort` and `variant` fields, and any `#variant` model suffix, in `opencode.jsonc`, the local tier map, agent and command frontmatter, and generated Claude agents;
  - `Set-SwTiers` (`sw tiers`) rejects a `#variant` suffix.
- **`project/base/.sw/workspace.md` → `.sw/workspace.md`:** Model tiers are model-only. Three rules added:
  - pass `-m` on `opencode run --agent`;
  - parents do not pass `model` to `subagent`;
  - a shell deny needs matching `write`/`edit` rules for file effects, and `rtk.ts` is part of the enforcement boundary.
  The evidence citation is generic, so other projects generated from the kit do not cite a Workspace-only path. It also notes that a session continued with `-s` keeps its `-m` model (G1 in the [multi-session exploration](../workspace-multi-session/2026-10-02T190000Z-leader-exploration.md)).
- **`project/base/.agents/skills/free-models/SKILL.md` → `.agents/skills/free-models/SKILL.md`:** tier fits are by model, not effort level. Variants are now described as an interactive, per-session choice only. This was a review fix; without it, the shipped skill and `sw tiers` produced configs the new check rejects.
- `CHANGELOG.md` (0.3.0-dev); `.sw/manifest.json` (hashes).
- Leader: S2 Generator and Tier rubric rows, and the state Startup.

## Validation (Leader, re-run after the review fixes)

| Check | Result |
| --- | --- |
| `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` | PASS |
| `pwsh -NoProfile -File sw.ps1 update . -WhatIf` | 40 unchanged, 0 changed (no drift) |
| `lib/` vs `.sw/lib/Sw.Project.psm1` (line endings ignored) | identical |
| Negative: `sw tiers -Light opencode/x#high -WhatIf` | throws "Tiers are model-only ..." |
| Negative: local tier map with `variant` and `reasoning_effort` | `validate` fails with the model-only error; the file was removed afterwards |
| `git diff --check` | clean (line-ending warnings only) |

Not exercised: the Claude generator path. `.claude/` is not enabled in this checkout, so `sw claude enable` was not run.

## Review (project-review, read-only)

- Every denied or ask shell pattern was checked against `rtk rewrite` (rtk 0.49.0, about 60 commands). **No rewrite escapes a deny or ask rule:** rtk either declines or prefixes `rtk `, which the twin rules cover. `rtk.ts` fails open in the safe direction (the command is left unchanged).
- Fixed in this change: the `free-models` skill and `sw tiers` produced `#variant` values (medium); the regex missed `reasoning_effort` and `variant` keys (low).
- **Owner item, not fixed (existed before this change):** shell denies match only a command prefix. These forms bypass every git deny and ask rule under the top-level `allow *`:
  - `git -C . push`, `git -c k=v reset --hard`, `git --no-pager push`;
  - `bash -c 'git push'`, `pwsh -c ...`;
  - rtk's own runners: `rtk proxy|run|err|summary git push`.
  This is the documented "a shell rule stops the call, not the effect" limit. Optional hardening: deny the rtk runner forms, or add `*git* push*`-style patterns. That needs its own approval, because it changes the permission matrix.
- **Upgrade note:** the rtk twin rules hold only while rtk rewrites to "`rtk ` + the original subcommand". Re-probe on each rtk upgrade.
