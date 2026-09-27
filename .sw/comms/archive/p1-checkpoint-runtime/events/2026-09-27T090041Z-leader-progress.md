# p1-checkpoint-runtime - progress - 2026 - leader

- **Author / audience:** leader (cloud Leader session), recording the owner's results; readers: the owner and later Leaders.
- **Approval:** as in the assignment.
- **Scope / acceptance:** rest of B2, and part of B3, OpenCode desktop 2.0.17, `sw-smoke`:
  - **`/inbox` (`subagent: false`): honoured.** It ran in the current session: it checked `.sw/comms/inbox/` and reported no messages. So the `subagent:` flag is honoured both ways.
  - **Cross-session messaging: none found.** The owner sees no in-app way to message between sessions, other than copy and paste.
  - The agent picker lists: Project-Leader (default, checked), Build, Plan (OpenCode built-ins), Project-Architect, Project-Build, Project-Developer, Project-Documentation, Project-Plan, Project-Research and Project-Review. The built-in Build and Plan are selectable as primary agents and carry none of the kit's role rules; with the project list ignored, nothing limits them.
  - The home screen shows a worktree control ("New worktree", "from main"); the session ran in the local `sw-smoke` directory.
  - B3 `$schema` warning: none visible in the owner's screenshot of the opened project (owner to confirm).
  - B3 `opencode models --verbose`: `opencode` is not on the pwsh PATH either. Doctor also probes `opencode-cli`, which is the next try.
- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** desktop at 6934e22; this event only.
- **Owners / dependencies:** the owner runs the checks. The Leader records them.
- **Decisions / remaining:** B2 complete. B3 needs the `opencode-cli models --verbose` output and the model picker list.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the owner's screenshots and pasted output.
- **Not validated / risks:** as before.
- **Publication:** `main-ahb0v0`; `main` is the owner's.
- **Next action:** owner; the two remaining B3 items.
