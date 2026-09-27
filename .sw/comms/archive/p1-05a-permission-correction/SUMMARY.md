# p1-05a-permission-correction - summary

- **Outcome:** Package 5a (permission correction), approved 2026-09-27. Root cause: the kit's RTK plugin rewrote shell commands (rtk git push ...) before OpenCode 2.0.18's permission check, so git/gh rules never matched; the project-level list was not ignored (checkpoint reading corrected in docs/decisions.md). Shipped: Get-SwSessionRules injected at the head of every agent's permissions and agents.build; Add-SwRtkTwins renders an 'rtk ' twin after every shell rule; validate models each agent file, checks drift and missing twins, and tests every shell case in both forms; wider read-only git allowlist; harness table and push-control wording corrected. Desktop-verified with RTK installed: stash and gh denied, commit asks, read-only git status allowed. Follow-up: read-only roles deny compound lines and git -C. Lessons: harmless pattern-matching probes, evidence from session exports, auto-approve off, restart the OpenCode background service after recreating a folder.
- **Closed:** 2026-09-27 12:30:39Z by claude at f5d467db80fca9430e9410e305f18e13226f712c
- **Events:** 14, kept in `events/` for evidence; read this summary instead.

- 2026-09-27T100559Z-leader-assignment.md
- 2026-09-27T103115Z-worker-p1-05a-submission.md
- 2026-09-27T104027Z-leader-review.md
- 2026-09-27T105459Z-leader-progress.md
- 2026-09-27T111402Z-leader-progress.md
- 2026-09-27T111937Z-leader-progress.md
- 2026-09-27T112758Z-leader-progress.md
- 2026-09-27T113636Z-leader-progress.md
- 2026-09-27T114325Z-leader-progress.md
- 2026-09-27T114624Z-leader-assignment.md
- 2026-09-27T120333Z-worker-p1-05a-rtk-submission.md
- 2026-09-27T120704Z-leader-review.md
- 2026-09-27T122847Z-leader-progress.md
- 2026-09-27T122954Z-leader-approval.md
