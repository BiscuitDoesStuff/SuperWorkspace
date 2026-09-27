# p1-05a-permission-correction - progress - 2026-09-27T113636Z - leader

- **Author / audience:** leader (cloud Leader session); readers: the owner and later Leaders.
- **Approval:** as in the assignment.
- **Scope / acceptance:** desktop re-test, fourth run. The owner turned off the app setting "Auto accept permissions" (it was on). Session export `ses_f1d5cf457ffec6rUcryz2klzBQ`, project-leader, Muse Spark 1.3 Free.

  | Probe | Rule | Result |
  | --- | --- | --- |
  | `git stash list` | deny | **completed** |
  | `git clean -n` (alone) | deny | turn interrupted, no tool result |
  | `git clean -n; echo ---; git commit --dry-run --allow-empty -m probe` | deny (clean) | **denied**: `permission.rejected`, "Permission denied: shell" (a rule deny) |
  | `gh repo list` | deny (`gh *`, no tier allow) | **completed**; listed the owner's repositories |
  | `git commit --dry-run --allow-empty -m probe` | ask | **completed, no dialog** |
  | read `probe.env` | ask | **dialog**; the owner declined |

- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** d42ba2b32eabb8fdc567eb71487456bbdb9ffb64; this event only.
- **Owners / dependencies:** the owner sends `debug agents` output and a listing of global agent files.
- **Decisions / remaining:**
  - Auto-approve explains the earlier missing `.env` prompts (OpenCode's own default ask, `schema/src/agent.ts`). It does not explain this run.
  - With auto-approve off, the kit's stash deny, `gh` deny and commit ask had no effect, and only `git clean` was denied. By the v2.0.18 engine (`permission.ts`, last match wins; `config/plugin/agent.ts`, project list then agent list), the kit's rules are **not in effect** for project-leader.
  - Leading hypothesis: the agent in use is not built from `sw-smoke/.opencode/agents/project-leader.md`. Either that file fails to decode (`decode` drops a document on a schema error), or another source defines project-leader (a global `~/.config/opencode` or `~/.opencode` agent from an older install).
  - The `debug agents` output decides.
  - The `.env` ask proves nothing about the kit, because OpenCode asks by default.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the session export uploaded to the Leader session.
- **Not validated / risks:** OpenCode sessions are not stopped from running `gh` or `git push` by the kit; only model refusals have stopped pushes so far.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader.
- **Next action:** owner; send `%TEMP%\oc-agents.txt` and the global agent-file listing.
