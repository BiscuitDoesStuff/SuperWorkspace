# workspace-harness-decision - submission (draft) - generator refit: model fields per harness - 2026-10-02T051533Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner, for approval.
- **Approval:** none. Draft for owner approval. The generator refit was approved in principle on 2026-10-02 ([roster assignment](../workspace-roster-refit/2026-10-02T020107Z-leader-assignment.md)); this scopes its model-field part after the owner's model-only tier decision (S2 Tier rubric; Pass 9 Rec 2, Rec 7).
- **Status:** proposed.
- **Branch / base:** `main` at `ddd155c`. No commit or push unless the owner asks.

## Current state (read 2026-10-02)

- `project/roles.json` gives each role a `tier` (`session`, `light`, `standard`).
- OpenCode: `Set-SwTiers` (`lib/Sw.Project.psm1`) writes a local, git-ignored `.opencode/opencode.jsonc` mapping role to `model` per tier. Shared files must not pin a model (contract on `model`, `small_model`, `provider`).
- Claude adapter: the generator writes `model: opus` plus `effort:` from `$script:ClaudeEffort` (`light=low`, `standard=medium`, `high=xhigh`), and the contracts require both.
- No Kilo output exists.

## Goal

Tiers resolve to a model only. The generator emits each harness's model field in that harness's own format and emits no effort fields.

## Scope

1. Remove `$script:ClaudeEffort`, the `effort:` frontmatter line and its contract check from `lib/Sw.Project.psm1`, then regenerate through `sw update` (dry run first, no hand edits to generated files).
2. Keep one harness-neutral tier map (role → tier in `project/roles.json`; tier → model ID per user, local only). Emit per harness:
   - **OpenCode:** the existing local `.opencode/opencode.jsonc` map from `Set-SwTiers`, with the model in OpenCode's `provider/model` form (C316). No `#variant`.
   - **Kilo:** only if the hands-on check confirms its agent model field and file location from runtime, or the owner chooses Kilo. Until then, no Kilo emitter.
   - **Claude adapter:** keep or drop is the owner's call (Claude Code is not a host candidate, C269). If kept, it emits `model:` only.
3. Contracts: assert no generated or local tier file contains an effort or variant field, and shared files still pin no model.
4. `CHANGELOG.md` entry; update the S2 Generator and Tier rubric rows and the state Startup.

## Out of scope

Choosing the harness; making `project-research` a profile role (needs per-profile roles; separate submission once the harness is chosen); the S1 layering refit; any runtime check; global settings; installs; the external corpus.

## Open questions for the owner

- Sequence: run this before the hands-on check (OpenCode and the effort removal only), or after it, so the Kilo emitter can be included in the same change?
- Keep or remove the Claude adapter path (`init -Claude`)?

## Owners and validation

- Leader: scope, register and state, validation owner. `project-developer`: generator, sources, regenerated files, changelog. `project-review` (read-only): advisory review.
- Acceptance:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` passes;
  - `pwsh -NoProfile -File sw.ps1 update . -WhatIf` reports no drift after regeneration;
  - a grep finds no `effort`, `reasoningEffort` or `#variant` field in generated agent and config files or in the generator that emits them;
  - `git diff --check` is clean.
- Not validated by this task: that either harness actually routes the emitted model (U3, hands-on check).

## Next action

Owner approves, edits or declines this scope, and answers the two open questions.
