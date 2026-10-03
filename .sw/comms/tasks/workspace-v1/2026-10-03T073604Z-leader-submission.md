# workspace-v1 - recovered P2 offline submission - 2026-10-03T073604Z - Leader

- **Author / audience:** Project Leader (GPT-6.1 Sol), inline recovery executor/validator; owner and future independent reviewer.
- **Approval:** [v1 approval](2026-10-03T063903Z-leader-approval.md), [P2 contract](2026-10-03T070256Z-leader-p2-assignment.md), and owner "Continue" after the terminal worker usage-limit error. Ownership transferred in [continuation](2026-10-03T073016Z-leader-progress.md). No worker restarted or spawned into quota.
- **Status:** P2 implementation/offline acceptance complete after reconciliation; overall v1 blocked on P3 independent review and P4 owner configuration/live acceptance. This is not operational acceptance or publication.
- **Checkout / checked revision:** `C:\DevProjects\Workspace`, solo `main`, uncommitted draft over `0701522023ce9bf4da8a0a2307ff9671d8c599a9`. Staging empty at takeover; no stage/commit/branch/push actions. Existing drafts and immutable events preserved.
- **Owners / dependencies:** Leader is sole current source/docs/record writer and validation owner, same P2 scope; no binary assets. Prior P2 worker stopped, without a final submission. Independent reviewer owns no files; quota prevents dispatch. P4 cannot claim review or acceptance by reusing static tests.
- **Publication:** local-only.

## Reconciled implementation

P2's saved files add `Invoke-SwSession` in `lib/Sw.Project.psm1` and the `session`
dispatcher in `sw.ps1`, extend `tests/workspace-v1.ps1`, document operation in
`project/base/.sw/workspace.md` and README/CHANGELOG, and add precise current-state
updates to the previously dirty outline/state. Generated counterparts are
`.sw/lib/Sw.Project.psm1`, `.sw/sw.ps1`, `.sw/workspace.md`, and manifest; P1's
source/generated role changes remain part of combined review.

The launch contract has explicit primary/worker models, missing/conflicting
configuration rejection, Claude adapter drift checks, separated argument arrays,
interactive Claude only, explicit OpenCode `mini`/`run` routing, no-write dry-run,
and immutable metadata/failure events. Events distinguish requested model and
local correlation from unknown native identity/effects. They do not accept an
artifact or grant task authority. Saved non-model CLI help supports the selected
flags; actual model/account/loading behavior remains unverified.

Inline inspection found stale documentation still describing the removed
unconditional Claude Leader SessionStart hook. Corrected the owning workspace
template and regenerated its installed copy; no launcher/adapter code changed
in recovery. State/outline now report the stopped worker and independent-review
blocker instead of an active P2 owner. Inline inspection is **not independent review**.

## Exact checks

Runner: Leader alone, UTC 2026-10-03. Final evidence prefix:
`.scratch/workspace-v1/20261003T073509294Z-leader` (suffixes below).

| Command/check | Observed result | Evidence |
| --- | --- | --- |
| `pwsh -NoProfile -File tests/workspace-v1.ps1 -ParseOnly` | exit 0, parser/module import PASS | `-parse.log` |
| `pwsh -NoProfile -File tests/workspace-v1.ps1` | exit 0, 226 assertions; native stubs only, no model calls | `-targeted.log`; fixture `20261003T073510108Z-44a7f5e6/` |
| `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` | exit 0; 8765 contracts, 618 permission cases, 29 hygiene files, 0 local link targets in its workspace scope | `-validate.log` |
| `pwsh -NoProfile -File sw.ps1 update . -WhatIf`, before regeneration | exit 0; 39 unchanged, only `.sw/workspace.md` content update plus normal manifest write | tool output |
| `pwsh -NoProfile -File sw.ps1 update .` | exit 0; only that expected managed content update plus manifest regeneration | tool output |
| `pwsh -NoProfile -File sw.ps1 update . -WhatIf`, after regeneration | exit 0; 40 unchanged, 0 content drift; normal manifest write proposed only | `-drift.log` |
| Supplemental changed operating/status docs and task-record local target checks | PASS, 80 local link targets; URL/fragment anchors not verified | `-links.log` |
| SHA-256 input stability/protected events | 14 source/generated/docs/test inputs stable during final checks; all 21 P2-baseline historical events unchanged | `-inputs.json`, `-preservation.log` |
| `git diff --check`; explicit new-file trailing whitespace | exit 0; 14 regression/task files clean | `-diff-check.log`, `-whitespace.log` |
| `pwsh -NoProfile -File .scratch/workspace-v1/leader-offline-validation.ps1` | exit 0, serial orchestration of the checks above | tool output; disposable validation script |

An initial nested `pwsh -Command` transport attempt failed parsing because quote
characters were stripped before the inner script parsed; it ran no validation
or model invocation. Switched to the approved scratch `-File` script instead of
retrying that quoting form. Its first full run also passed 226 assertions and
all applicable checks before the documentation correction (prefix
`20261003T073300746Z-leader`); final run above supersedes it.

## Remaining acceptance / next action

- **P3 incomplete:** independent combined P1/P2 correctness/scope/simplicity
  review. Worker quota blocks dispatch; do not retry or portray inline inspection
  as independent. Use an owner-confirmed available route or wait for quota.
- **P4 incomplete:** exact owner-selected local model map/adapter setup and live
  engineering artifact, checkpoint, fresh-session resume and read-only artifact
  review. Actual Workspace map/adapter remain unactivated; four live starts
  reserved, zero used. Owner interaction may be necessary for native terminals.
- **Not validated:** served model/session identity, subscription/free access,
  live instruction loading/compaction, runtime permission behavior, other users
  or routes, security isolation, empirical reliability/efficiency benefits.
- **Next action / owner:** owner confirms a currently available existing route
  and explicit execution/review models; Leader coordinates independent review,
  then authorized local setup and bounded live workflow. No metered activation,
  installations, global changes, credentials inspection, publication or budget
  extension. Changes remain uncommitted; no cleanup deletes old work/evidence.
