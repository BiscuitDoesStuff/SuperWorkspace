# p0-research-08 - submission - 2026-09-27T041308Z - research-8

- **Author / audience:** research-8
- **Approval:** owner approved the Phase 0 plan 2026-09-26 and said "go topic 8" 2026-09-27 (leader assignment 2026-09-27T040306Z). R1-R8 are proposals, not approved.
- **Scope / acceptance:** `docs/research/08-permissions-safety.md` written: six sections, F1-F28, R1-R8, 8 open questions. Sub-questions 1-7 answered; gaps listed under Not covered. Only the owned file and this event were written; no product, test, roadmap, decisions or settings edits; no bypass attempts; no `gh` or GitHub API calls.
- **Status:** complete
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (per assignment; not re-fetched)
- **Checked revision / changed:** 0d593d03c265eb174ef0aa2204bd3a7c7696f944 plus uncommitted:  D .sw/comms/tasks/p0-research-07/2026-09-27T034623Z-leader-assignment.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035212Z-research-7-submission.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035254Z-leader-review.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035544Z-leader-correction.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035612Z-research-7-submission.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035630Z-leader-approval.md; ?? .sw/comms/archive/p0-research-07/; ?? .sw/comms/tasks/p0-research-08/; ?? docs/research/08-permissions-safety.md
- **Owners / dependencies:** research-8 owns the research file and this event; Leader owns everything else. Depends on topics 0-7 (done, 0d593d0).
- **Decisions / remaining:** Key findings: the 2.1.281 hook skip is documented (subagent frontmatter hooks need trust for the exact folder, F18); Claude rules match the command as written (`git -C . push` etc., F2, F26); Claude sandbox unsupported on native Windows (F13); Claude adapter only states markdown, worker, readonly-shell and `.env` limits that OpenCode enforces (F27); 05 R1 `disallowedTools: Agent` not yet generated. Budget: 14 research calls (cap 25), about 30 tool calls total.
- **Validation:** research-8, 2026-09-27 ~04:12Z: `pwsh -NoProfile -File .sw/sw.ps1 validate` -> PASS (contracts=1854; permission cases=380). `git diff --no-index --check /dev/null docs/research/08-permissions-safety.md` -> no whitespace errors (exit 1 = file differs, expected). Manual: every finding carries a URL or local file ref and a date.
- **Not validated / risks:** No runtime tests of any rule (forbidden); F3, F8, F17, F21 partly rest on absence (marked weak). Harness behaviour varies by version and OS: Claude 2.1.282 native Windows here.
- **Publication:** local-only until a human pushes
- **Next action:** Leader: review the file and relay Open questions 1-6 to the owner.
