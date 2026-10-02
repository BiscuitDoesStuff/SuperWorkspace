# workspace-harness-decision - approval - generator refit (model-only tiers) - 2026-10-02T183500Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); executors and the next Leader session.
- **Approval:** owner in session, 2026-10-02: "Approved for the generator refit." This covers the [submission](2026-10-02T051533Z-leader-submission-generator-refit.md) and proposals 1-4 of the [U1 decision](2026-10-02T181644Z-leader-decision-u1-opencode.md).
- **Branch / base:** `main` at `ddd155c`, plus the uncommitted harness-decision documents. No commit or push unless the owner asks.

## Leader resolutions of open points (owner may revise)

- **Sequencing:** settled by U1. No Kilo emitter.
- **Claude adapter:** kept. The owner left the question unanswered; the current Leader session runs on this adapter; removal is a larger and destructive change. It emits `model:` with no `effort:`. The Claude model stays `opus` for every role: model-only tiers for Claude (for example light = sonnet) would need a separate owner decision.
- **Proposal 1 (launcher passes `-m`):** Workspace has no script that calls `opencode run`, so this becomes a documented launch rule in `.sw/workspace.md` Model tiers.
- **Proposal 3 (parents do not pass `model` to `subagent`):** documented as an advisory rule. It cannot be enforced (decision record, F2).
- **Proposal 4:** the existing hard shell denies (`git push|clean|reset --hard|stash`, `gh`, and their `rtk` forms) target git and GitHub effects that the `write`/`edit` tools cannot reach, so no new rules. Document the rule for future file-effect denies. `rtk.ts` gets a read-only review as part of the enforcement boundary (C317).

## Scope

1. Kit source `lib/Sw.Project.psm1`: remove `$script:ClaudeEffort`, the generated `effort:` line and its contract check.
2. Add contract checks that generated agent and command files, `opencode.jsonc` and the local tier map contain no `effort`, `reasoningEffort` or `#variant` field. Keep the existing check that shared files pin no model.
3. `.sw/workspace.md` Model tiers (through its kit source if it is managed):
   - drop "or the generated effort (Claude)";
   - add the launch rule (proposal 1), the subagent `model` rule (proposal 3) and the file-effect rule (proposal 4).
4. Regenerate through `sw update` (`-WhatIf` first). Do not hand-edit generated files.
5. `CHANGELOG.md` entry; update the S2 Generator and Tier rubric rows and the state Startup (Leader).

## Owners and validation

- `project-developer`: items 1-4 and the changelog. `project-review` (read-only): `rtk.ts` versus the deny list, plus an advisory review of the diff. Leader: register, state and validation owner.
- Acceptance:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` passes;
  - `pwsh -NoProfile -File sw.ps1 update . -WhatIf` reports no drift;
  - a grep finds no `effort`, `reasoningEffort` or `#variant` field in the generator output or the generated files;
  - `git diff --check` is clean.
