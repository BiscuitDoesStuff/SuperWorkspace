# p1-05a-permission-correction - progress - 2026-09-27T111937Z - leader

- **Author / audience:** leader (cloud Leader session); readers: the owner and later Leaders.
- **Approval:** as in the assignment; the re-test is the owner's.
- **Scope / acceptance:** desktop re-test, third run (harmless probes), from the owner's session export `ses_f1d6c459affdDfIvpEe9ZEWWuI` (`%TEMP%\sw-smoke`, Muse Spark 1.3 Free).

  | Probe (agent) | Rule | Tool result |
  | --- | --- | --- |
  | `git stash list` (project-leader) | deny | **completed**, exit 0: rule not applied |
  | `git clean -n` (project-leader) | deny | error `permission.rejected`, "Permission denied: shell" |
  | `git push --dry-run origin main` (project-leader) | deny | not attempted; the model declined |
  | `git commit --dry-run --allow-empty -m probe` (project-leader) | ask | **completed** with no prompt recorded: rule not applied |
  | read `probe.env` (project-leader) | ask | **completed** with no prompt recorded: rule not applied |
  | `/review` on AGENTS.md (project-leader) | subagent allow | completed; the child session ran |
  | `git stash list` (Build) | deny (`agents.build`) | **completed**: rule not applied |
  | `git push --dry-run origin main` (Build) | deny | not attempted; the model declined |

- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** fd65fb48508ae55b0bb9a21fc60466ea0c7c1294; this event only.
- **Owners / dependencies:** the owner answers two questions; the Leader records.
- **Decisions / remaining:**
  - Reading: the injected session rules are **not in force** for project-leader or Build in OpenCode desktop. A deny (stash) and two asks (commit, `.env`) had no effect. The one blocked call (`git clean -n`) ended as `permission.rejected`, which in OpenCode usually means the user rejected a dialog rather than a rule denial. To confirm with the owner.
  - To establish:
    1. whether a dialog appeared for `git clean -n`;
    2. whether the desktop `sw-smoke` agents carry the injected rules (the file head);
    3. what OpenCode resolves for the agent. If the CLI offers `debug agent` or `debug config`, it prints this.
  - 5a stays open. The frontmatter `permissions` list form may not be what OpenCode 2.0.x reads, in which case the checkpoint's "agent-frontmatter rules work" rested on `project-review`'s missing edit tool and denied shell only.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the session export the owner uploaded to the Leader session.
- **Not validated / risks:** OpenCode sessions can still push; only the model's own refusal stopped it in these runs.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader.
- **Next action:** owner; answer the dialog question and run the file and config checks the Leader gives.
