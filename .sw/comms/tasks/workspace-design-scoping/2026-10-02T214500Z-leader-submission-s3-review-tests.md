# workspace-design-scoping - submission (draft) - S3 review and acceptance tests - 2026-10-02T214500Z - Leader

- **Author / audience:** drafted by the `project-developer` subagent for the Workspace Project Leader; owner, for approval.
- **Approval:** none. Proposal, not approved. Implements nothing in the register on its own (outline S3; "revises O14 only once an approved change says so").
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`; this draft is uncommitted. No commit or push unless the owner asks.

## Current state (read 2026-10-02)

- Validation is static only: `Test-SwProject` (`lib/Sw.Project.psm1`) with `Require`, `Expect` (permission cases, 618 at the git-hardening closure), `NoEffort`, drift and link checks. Its output says "NOT runtime enforcement".
- Review: `project-review` (read-only, `.opencode/agents/project-review.md`; source `project/base/.opencode/agents/project-review.md`) is told to review "the assigned exact SHA or working diff". Repository exploration appears only in the `focused-review` skill step 3 ("surrounding implementation, including important callers"). `/review` (`.opencode/commands/review.md`) calls itself "Optional"; `.sw/workspace.md` says review in a plan "runs automatically but stays advisory". These two wordings differ (O14).
- No acceptance-case register or eval suite exists. Real failures are recorded in `.sw/comms/tasks/` (sources below).

## Goal

A small, failure-seeded case register (10 seed cases, growing toward 50) with deterministic checks first, so any change to instructions, skills, roles or routing can be re-checked. The reviewer's repository exploration is stated and checkable. No LLM judge yet.

## Scope (smallest independently testable change)

1. **Case register** `docs/workspace-acceptance-cases.md` (project-owned, not kit-managed): ID, source record, check kind (static / trace / manual), command, expected result, status. Seed cases, each from a record:
   - A1 `run --agent` without `-m` served an unconfigured default (opencode results, 2026-10-02T061500Z): static grep that documented launch commands carry `-m`.
   - A2 parent `model` argument overrides a subagent pin (same record; kilo results 2026-10-02T172033Z): trace check on `opencode session export` (runtime; deferred).
   - A3 shell deny did not stop the effect via `write` (opencode results section 4): static, hard-rule agents carry matching `write`/`edit` rules.
   - A4 plugin rewrite defeats a deny (C317; same record): static, rtk twin rules exist (`Test-SwRtkTwinned`, `Add-SwRtkTwins`).
   - A5 `git -C . push`, `bash -c`, `rtk proxy git push` passed every git rule (generator-refit closure 2026-10-02T191500Z): existing `Expect` matrix; keep as named cases.
   - A6 `free-models` skill produced `#variant` values (same closure): **gap found**, `Test-SwProject` calls `NoEffort` on agent and command frontmatter but not on skill bodies (`if ($kind -ne 'skills')`, about line 366). New static check.
   - A7 `NoEffort` regex missed `reasoning_effort` and `variant` keys (same closure): negative fixture case.
   - A8 records claimed an approved outline that did not exist (state-review correction 2026-10-01T084039Z): static, each `Approval:` link in a task event resolves (extends `-CheckLinks`).
   - A9 state said "uncommitted" while Git said otherwise (the outline S4 note read "uncommitted" while Git showed the work committed): static, commit hashes named in the state Startup exist (`git cat-file -e`).
   - A10 documented non-caught forms stay documented (git-hardening closure): static, `.sw/workspace.md` still states the guardrail limit.
2. **Static checks** for A1, A3, A6, A7, A9 added to `Test-SwProject` in `lib/Sw.Project.psm1` reusing `Require`, `NoEffort`, `Read-SwText`; regenerated through `sw update`, no hand edits to `.sw/lib/`.
3. **Reviewer wording** (`project/base/.opencode/agents/project-review.md`, `focused-review` skill): state that the reviewer reads callers and referenced files beyond the diff (C238), and align `/review` and workspace.md on "optional" vs "automatic". `CHANGELOG.md` entry.
4. **Review replay design only** (no run): choose a commit range, run `project-review` with and without the exploration wording, score findings against the recorded findings in A5-A7. Judge calibration (P4) is deferred until a qualitative rubric is needed.

## Out of scope

Any LLM judge or rubric; an evaluation platform; running a review at all; token-cost budget (needs a measured run, C237 notes about 4.5x in one study); multi-trial statistics (C167) until a runtime item is approved; Claude adapter cases (see S4); skill trials (see S6).

## Acceptance

- Static: `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` passes with the new checks; each new check fails on a negative fixture (a skill containing `#high`, an unresolved `Approval:` link, a missing commit hash); `pwsh -NoProfile -File sw.ps1 update . -WhatIf` shows no drift; `git diff --check` clean.
- Register: 10 cases, each citing an existing record file; none claims a result that was not run.
- Runtime (separate owner approval, free OpenCode models, cost cap set by the owner): A2 trace check; review replay; at least 3 isolated trials per cell. Not part of this change.

## Dependencies

- R4/R5 not needed for static work. R2 (Claude Code model routing per launch path) is needed only if replay runs on Claude.
- S4 and S6 reuse this register; this item goes first.

## Owner questions

1. Register location: project doc (proposed) or kit-shipped so other projects get the generic checks (A1, A3, A6, A7)?
2. Should "review runs automatically in a plan" stay, or become explicit and optional (O14)?
3. Is a replay of the git-hardening review worth the cost, given the pre-fix state is not a separate commit?
