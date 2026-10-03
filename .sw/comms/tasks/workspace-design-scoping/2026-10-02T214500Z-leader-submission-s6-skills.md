# workspace-design-scoping - submission (draft) - S6 skills curation - 2026-10-02T214500Z - Leader

- **Author / audience:** drafted by the `project-developer` subagent for the Workspace Project Leader; owner, for approval.
- **Approval:** none. Proposal, not approved.
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`; this draft is uncommitted. No commit or push unless the owner asks.

## Current state (read 2026-10-02)

- Eight base skills ship in `project/base/.agents/skills/` and `.agents/skills/` (full body sizes in bytes): `agent-documentation` 2171, `focused-review` 2154, `free-models` 3936, `minimal-change` 2725, `project-planning` 1940, `research` 2500, `structured-debugging` 2010, `task-handoff` 2342. Total about 19.8 KB.
- All eight are mandatory: `$script:Skills` in `lib/Sw.Project.psm1` (about line 222) is checked by `Test-SwProject` ("Missing skill"). Profile skills add to it: `generic` has none; `unreal` adds `unreal-validation` (`project/profiles/*/profile.json`).
- Only names and descriptions count toward the per-role startup budget (`startupBudgetBytes` 12,100, about line 462); bodies load on demand.
- Claude path: `Get-SwClaudeFiles` copies every `.agents/skills` file into `.claude/skills/`; OpenCode reads `.agents/skills` and the session rules allow `skill *`.
- Skills tied to a recorded need: `focused-review` (S3 reviewer), `task-handoff` (records, S5), `minimal-change` (AGENTS.md Principles). `free-models` is machine- and tier-specific (and produced `#variant` values once, see S3 A6). `research` belongs to the research role.
- No trial has ever compared a skill with its absence; trigger behaviour is untested.

## Goal

An inventory-based decision of one to three curated skills per profile (S6), and a with/without trial design that can show a skill earns its place or should go.

## Scope (smallest independently testable change)

1. **Inventory table** in `docs/workspace-outline.md` S6 or a project doc: skill, size, profile, role that loads it, recorded failure it addresses (cite the S3 case ID), keep / move / drop proposal. Proposal only, no deletions here.
2. **Trial design** (documented, not run): for each kept skill, paired runs with and without it on the S3 cases that cite it.
   - "Without" in OpenCode: a `skill` deny rule for that name in a scratch copy; in Claude: omit that directory from the generated `.claude/skills/`.
   - **Negative trigger controls:** 2 or more prompts per skill that must not load it (for example a one-line docs fix must not load `structured-debugging`); measure false-trigger rate.
   - Metrics: pass on the deterministic case check, tokens, trigger rate; at least 3 isolated trials per cell (C167); report C249's overhead range (up to +451%) as the cost to beat.
3. **Static contract** (only after the owner picks the target): `Test-SwProject` fails when a profile's loaded skill count exceeds 3. This needs `$script:Skills` and the profile `skills` arrays reduced through the generator sources and `sw update`; the generic skills moved out are removed or marked on-demand per owner choice.
4. `CHANGELOG.md` entry if step 3 is approved.

## Out of scope

Auto-generated skills (S6 forbids them); writing new skills; non-code profile skills (no study, S6 Limits); deleting any skill now; running trials; changing `free-models` content; the unreal profile skill.

## Acceptance

- Static: inventory table lists all 8 base and 1 profile skill with sizes matching `ls`/byte counts; `validate -CheckLinks` passes; `update -WhatIf` no drift (when step 3 is in); `git diff --check` clean. Negative fixture for the count contract: a profile listing 4 skills fails.
- Reported as not run: any trial, any trigger measurement, any Claude skill loading.
- Runtime (separate owner approval; free OpenCode models; Claude trials only with approval and subscription limits, C324): the paired trials above. A skill that does not beat "without" on its cited cases is a drop candidate. The evidence is mostly one benchmark family and the software-engineering gain is contested (C245), so the trial result, not the corpus, decides.

## Dependencies

- **S3** case register (cases and negative controls come from it); this item follows S3.
- **R2** (Claude Code per-launch behaviour): needed to confirm which skills load on a Claude launch.
- OpenCode skill discovery per location (E8 note on C067) is already checked by `sw` runtime discovery only on request; no R item needed for the static part.

## Owner questions

1. Target for `generic`: which one to three skills (proposal: `task-handoff`, `minimal-change`, `focused-review`; the rest become role-specific, on-demand or dropped)?
2. Is `research` a research-profile skill (S1/S2), and does `free-models` leave the default set?
3. Are trials worth the cost before a profile target is chosen, or should the target be chosen first from the inventory alone?
