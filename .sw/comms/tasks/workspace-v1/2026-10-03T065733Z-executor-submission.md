# workspace-v1 - P1 submission - 2026-10-03T065733Z - executor

- **Author / audience:** project-developer executor (GPT-6.1 Sol); Project Leader and owner.
- **Approval:** [P1 assignment](2026-10-03T063903Z-leader-p1-assignment.md), [v1 approval](2026-10-03T063903Z-leader-approval.md), and [import correction](2026-10-03T064715Z-leader-correction.md). Default light mechanical contracts; existing running role/model unchanged.
- **Status:** complete for P1 implementation and offline acceptance; uncommitted draft, not published. P2/P3/P4 are not performed by this executor.
- **Checkout / base / checked revision:** solo `main`, `C:/DevProjects/Workspace`, `0701522023ce9bf4da8a0a2307ff9671d8c599a9`. No branch/worktree/staging/commit/publication operations.
- **Owners / dependencies:** executor alone owns assigned P1 source writes and validation. Leader owns coordination events. Import correction resolved the earlier blocker. No binary assets. P2 routing must consume explicit owner-selected models and retain fail-closed launch behavior.
- **Preservation:** protected outline/state and historical task drafts/events unchanged. Before actual regeneration, SHA-256 hashes were captured for both dirty docs and all then-untracked task events; all 16 observed paths matched afterwards. Generator dry-run reported only the three expected managed content updates, with no conflicts or unexpected paths. New task coordination events remain Leader-owned.
- **Publication:** local-only uncommitted work over the exact checked SHA; human publication separate.

## Changed paths (this executor only)

Canonical sources:

- `lib/Sw.Project.psm1`
- `project/roles.json`
- `project/base/.sw/workspace.md`
- New regression `tests/workspace-v1.ps1`

Installed/generated paths, changed only by root `sw.ps1 update .`:

- `.sw/lib/Sw.Project.psm1`
- `.sw/roles.json`
- `.sw/workspace.md`
- `.sw/manifest.json`

Local disposable fixtures, fixture-only `.gitignore` and evidence logs are
under `.scratch/workspace-v1/`. Only this new submission event was added in
this implementation batch; the earlier blocked submission and all other
historical events were left untouched. Existing dirty docs remain unrelated.
No actual Workspace `.claude/` adapter or `.opencode/opencode.jsonc` map was
activated; final existence checks for both returned false.

## Implemented contracts

1. `Get-SwClaudeFiles` reads the actual local `agents[role].model` map, including
   maps written by existing `Set-SwTiers`, rather than inventing a tier dictionary.
   Worker frontmatter is no longer hardpinned to `opus`.
2. Small exported `Get-SwClaudeModel` classifies explicit, documented Claude
   aliases/native IDs, strips `anthropic/` from full Claude IDs without guessing
   a family alias, returns null for ordinary non-Claude provider/model IDs, and
   rejects empty/ambiguous/default/inherit/variant/unsupported spellings.
   Classification is syntactic, not provider inventory or account validation.
3. Missing maps, malformed entries, and maps with no explicit Claude models
   reject generation. Unmapped/non-Claude workers are omitted; their commands
   are explicit STOP stubs, not dispatch or inline impersonation fallbacks.
   Built-in workers are not silently substituted. Main-session model selection
   remains a later explicit launcher responsibility.
4. `Get-SwClaudeGitRules` reuses the existing session list derived from
   `SessionGitVerbs`/`SessionWrappers`, plus existing RTK twinning. Claude rules
   cover the listed plain, global-flag, compound/runner and wrapper spellings,
   with bare no-argument forms as well. Commit/wrappers ask; destructive Git
   verbs deny. Presence checks are not a Claude permission evaluator.
5. Shared reviewer role data drops Bash from Claude tools. Its generated
   allowlist is `Read, Grep, Glob, Skill`; validator rejects readonly role data
   that includes Bash/Edit/Write/Agent. OpenCode behavior is unchanged.
6. The adapter generates exactly `@../AGENTS.md` in ignored
   `.claude/CLAUDE.md`. Validator resolves it relative to its containing file
   and requires canonical root AGENTS. No duplicate rules source is created.
7. Worker startup material reads its own role and distinguishes dispatched
   workers from a selected main executor. It no longer asserts AGENTS is
   already loaded. Removed the unconditional Leader SessionStart hook: Leader
   startup material is explicitly scoped to a selected Leader main session,
   not injected into workers. No new launcher CLI flags or hooks added.
8. Source workspace template documents alias/native/provider-ID handling,
   missing/unmapped behavior, map-dependent disable/drift checks, import
   semantics and guardrail/stated/live-loading limits. No user model pin in
   shared configuration. README/CHANGELOG/outline/state remain deferred to P2.

## Exact validation / evidence

Runner: sole P1 executor, PowerShell 7.6.6, UTC 2026-10-03. Reused current
official syntax and successful CLI metadata from the
[earlier inspection](2026-10-03T064435Z-executor-submission.md); no repeated
discovery, authentication reads or native/model calls in this batch.

| Command | Result | Evidence |
| --- | --- | --- |
| `pwsh -NoProfile -File tests/workspace-v1.ps1 -ParseOnly` | exit 0; source and regression parser checks, source module import | `.scratch/workspace-v1/p1-parse.log` |
| Initial `pwsh -NoProfile -File tests/workspace-v1.ps1` | exit 1; fixture missing a local ignore boundary, not an environmental CLI failure | fixture `.scratch/workspace-v1/20261003T065443827Z-d8296e3a/`; session output |
| `git -C .scratch/workspace-v1/20261003T065443827Z-d8296e3a check-ignore -v -- .opencode/opencode.jsonc` | exit 1; confirmed fixture config not ignored; fixture `.gitignore` absent | session output; diagnosis below |
| Corrected `pwsh -NoProfile -File tests/workspace-v1.ps1` | exit 0 twice; 179 targeted assertions each | `.scratch/workspace-v1/p1-targeted.log`; final fixture `.scratch/workspace-v1/20261003T065807508Z-16b1d5ae/` |
| `pwsh -NoProfile -File sw.ps1 update . -WhatIf` before regeneration | exit 0; 37 unchanged, expected module/roles/workspace updates only | session output |
| `pwsh -NoProfile -File sw.ps1 update .` | exit 0; three managed content updates, manifest regenerated; no conflicts | `.scratch/workspace-v1/p1-regenerate.log` |
| `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` | exit 0; 8765 contracts, 618 permission cases, 29 hygiene files, 0 local links | `.scratch/workspace-v1/p1-validate.log` |
| `pwsh -NoProfile -File sw.ps1 update . -WhatIf` afterwards | exit 0; 40 unchanged, 0 changed; normal manifest write proposed only | `.scratch/workspace-v1/p1-drift.log` |
| `git diff --check` | exit 0; only existing repository line-ending warnings | session output |
| New-file `Get-Content` / `Select-String -Pattern '[\t ]+$'` | regression file: 0 trailing-whitespace lines; event checked at final handoff | session output |
| `git diff --numstat`; scoped source diffs; `git rev-parse HEAD`; `git status --short --branch` | reviewed bounded source/generated dirty scope; unchanged checked SHA | session output |

Structured debugging of the only test failure: fixture generation inherited
the real repository but had no applicable local ignore file; existing
`Test-SwLocalOnly` correctly refused writing its model map. The discriminating
`check-ignore` returned 1 and `Test-Path` showed no fixture ignore file. Fixed
only the test setup by creating an ignore-all file inside its own disposable
subtree if absent, preserving any existing local file. No root/global ignore
or Git initialization change. The same targeted command then passed.

Additional handoff diagnostic: a raw-byte `Get-FileHash` comparison of source
and generated files exited 1 on the module. This comparison is not the kit's
content contract: `Read-SwText` and `Write-SwFile` explicitly normalize CRLF to
LF, whereas raw-byte hashing distinguishes them. The actual generator drift
check already passed. The appropriate discriminating check compares each
source/generated pair after that same newline normalization, without modifying
either file. Its exact outcome and checked SHA are retained in
`.scratch/workspace-v1/p1-normalized.log`. No source fix or regeneration is
justified solely by the raw-byte mismatch. Final `git diff --check` was exit 0
and both new regression/event files had 0 trailing-whitespace lines.

Targeted coverage includes documented aliases, native/provider-qualified Claude
IDs, non-Claude IDs, missing/invalid models and tier dictionary rejection;
actual Set-SwTiers output; readonly tools; no unconditional Leader hook or
settings model pin; required Git deny/ask entries; valid canonical import
path/content; negative wrong `@AGENTS.md`, missing global-flag rule, Bash-added
reviewer and wrong role model; non-Claude stale generated worker removal and
STOP dispatch; unmapped worker STOP inline command. Positive/negative fixture
validator cases ran serially. No destructive commands were executed.

## Not validated / remaining / next action

- Static generation/path/rule presence does not establish live instruction
  loading, compaction behavior, permission enforcement, model availability,
  account/subscription routing or actual runtime model. Those remain P4.
- Alias overrides and provider/runtime substitution can differ from requested
  models; no empirical or security-parity claim is made.
- Actual Workspace map/adapter setup remains off. No model sessions started,
  no agents/teams spawned, no installs/global repair/paid access/account changes.
- `Invoke-SwClaude` disable/drift behavior still depends on the current local
  map; documented explicitly, with no inferred default model to erase files.
- P1 offline criteria passed. Leader can dispatch a fresh serial P2 executor
  for the launcher/operating docs, reusing these exported helpers and evidence.
  Later review/live acceptance remains queued. This executor stops here.
