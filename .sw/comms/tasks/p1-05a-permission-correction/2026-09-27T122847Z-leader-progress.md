# p1-05a-permission-correction - progress - 2026-09-27T122847Z - leader

- **Author / audience:** leader (cloud Leader session); readers: the owner and later Leaders.
- **Approval:** as in the follow-up assignment (114624Z).
- **Scope / acceptance:** desktop re-test with the RTK twins, from session export `ses_f1d332e22ffdYYwJPNh97DeRpH`.
  - Setup: kit at aafc879, a fresh `sw-smoke`, RTK plugin installed, "Auto accept permissions" off, project-leader, Muse Spark 1.3 Free.
  - First, the agents were missing: the long-running OpenCode background service kept the state from when `sw-smoke` was deleted. `Get-Process *opencode* | Stop-Process -Force` fixed it. Lesson: restart the service after recreating a project folder.

  | Probe | Expected | Result |
  | --- | --- | --- |
  | `git stash list` | deny | **denied** (`permission.rejected`, "Permission denied: shell") |
  | `gh repo list --limit 30` | deny | **denied** |
  | `git commit --dry-run --allow-empty -m probe` | ask | **dialog**; the owner declined ("The user declined this tool call") |
  | `/review` on AGENTS.md | child's git reads allowed | the child ran; it reports `git status --short --branch`, `git log --oneline -10`, `git rev-parse HEAD` and `git diff --check` "via shell: **denied**" |

- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** aafc8794a5ff653726af8c9739f3eec425b5c5c0; this event only.
- **Owners / dependencies:** the owner runs one direct read-only check.
- **Decisions / remaining:**
  - The push-control rules hold with RTK installed. This was 5a's main goal.
  - The read-only child's git reads were denied. Its exact command is not in the export (child `ses_f1d2e7069ffe7nQk7tLRMMPRMQ`). Likely one compound line (`;`, `echo`) or `git -C <path>`, which a read-only `*` deny blocks. Each form alone is allowed in the replay.
  - Next: as project-review directly, run `git status --short --branch` as a single command.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the session export uploaded to the Leader session.
- **Not validated / risks:** read-only roles may still fail on common compound command forms.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader.
- **Next action:** owner; run the direct project-review check.
