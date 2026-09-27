# p1-checkpoint-runtime - progress - 2026-09-27T082348Z - leader

- **Author / audience:** leader (cloud Leader session), recording the owner's results; readers: the owner and later Leaders.
- **Approval:** as in the assignment.
- **Scope / acceptance:** results since 2026-09-27T081333Z:
  - OpenCode version: desktop app, Settings > About, **2.0.17** (V2). No `opencode` CLI is on PATH.
  - **OpenCode A2 (read-only edit): PASS.** With `project-review` selected in the app, the agent had no edit tool (tools listed: read, glob, grep, question, skill). Its shell call `pwd && git status --short --branch && git log --oneline -10` was rejected with `{"error":"permission.rejected","message":"Permission denied: shell"}`. `git status --short` afterwards printed nothing.
  - Claude A2: not run yet. The Claude CLI fails to start on the desktop ("claude.exe ... not a valid application for this OS platform", from the npm install); the earlier Claude checks ran in the Claude desktop app.
- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** desktop at 6934e22; this event only.
- **Owners / dependencies:** the owner runs the checks. The Leader records them.
- **Decisions / remaining:**
  - The V1 hypothesis in 2026-09-27T081333Z is **refuted**. OpenCode is V2 and applies the kit's permission list, as the `project-review` denial shows.
  - The OpenCode push that ran is still unexplained. `project-leader` (the `default_agent`) adds no shell rules, so the base `git push *` deny should hold for it. The next question is which agent that push session used (for example a built-in `build` agent, or a global user config).
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the owner's screenshots.
- **Not validated / risks:** until the push cause is known, OpenCode's push deny is unconfirmed.
- **Publication:** `main-ahb0v0`; `main` is the owner's.
- **Next action:** owner; report the agent used in the OpenCode push session, and run Claude A2 in the Claude desktop app.
