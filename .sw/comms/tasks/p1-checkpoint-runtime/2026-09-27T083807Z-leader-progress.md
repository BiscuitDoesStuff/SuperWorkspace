# p1-checkpoint-runtime - progress - 2026 - leader

- **Author / audience:** leader (cloud Leader session), recording the owner's result; readers: the owner and later Leaders.
- **Approval:** the owner chose to run the format experiment ("Option A, then lets get back on track").
- **Scope / acceptance:** format experiment, OpenCode desktop 2.0.17, `sw-smoke` only (a throwaway edit, not the kit):
  - A V1-style `"permission": { "bash": { "git commit *": "ask", "git push *": "deny" } }` was added to `sw-smoke/opencode.jsonc` next to the V2 list, and the app was restarted.
  - As project-leader, `git commit --allow-empty -m probe` still ran with **no prompt** ("ok d56f922").
  - So neither the V2 `permissions` list nor a V1 `permission` object at project level takes effect in the desktop app. Agent-frontmatter rules do.
- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** desktop at 6934e22; this event only.
- **Owners / dependencies:** the owner runs the checks. The Leader records them.
- **Decisions / remaining:**
  - Cause still unknown. Open possibilities:
    - the desktop app does not apply project-level permissions at all;
    - an app-level setting overrides them;
    - the key or location differs in this build.

    The proven path is agent frontmatter.
  - The correction package (owner approval needed) should put the session-wide denies and asks into every agent's own rules, and correct the `.sw/workspace.md` table. It needs a desktop re-test afterwards.
  - Back on track per the owner: runtime tests B1-B3 next.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the owner's pasted result.
- **Not validated / risks:** same as 2026-09-27T*-progress before this one; GitHub branch protection is the only push control for OpenCode sessions.
- **Publication:** `main-ahb0v0`; `main` is the owner's.
- **Next action:** owner; undo the probe and the `sw-smoke` config edit, then run B1-B3.
