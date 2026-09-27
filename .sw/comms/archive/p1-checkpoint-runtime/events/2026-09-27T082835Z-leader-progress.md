# p1-checkpoint-runtime - progress - 2026 - leader

- **Author / audience:** leader (cloud Leader session), recording the owner's results; readers: the owner and later Leaders.
- **Approval:** as in the assignment.
- **Scope / acceptance:** results since 2026-09-27T082348Z:
  - The OpenCode push session (A1) ran as **project-leader**, the `default_agent`.
  - **Claude A2 (read-only edit): PASS as documented.** Run in the Claude desktop app. The `project-review` subagent reported tools Read, Grep, Glob, Bash, Skill and SubagentHandback, with no Edit or Write, and made no edit. `git status --short` printed nothing. As `.sw/workspace.md` states, its Bash is limited only by instruction.
- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** desktop at 6934e22; this event only.
- **Owners / dependencies:** the owner runs the checks. The Leader records them.
- **Decisions / remaining:**
  - New leading hypothesis for OpenCode: 2.0.17 does not load the project-level `permissions` list in `opencode.jsonc`, and only agent-frontmatter rules apply. That would explain all three results:
    - `project-leader` has no shell rules, so the push ran;
    - `.env` gave no prompt;
    - `project-review`'s own rules denied its shell call.

    Test: as `project-leader`, attempt `git commit --allow-empty -m probe`. The base list asks for commits, so a commit that runs without a prompt confirms the hypothesis. Runtime test 3 (a `$schema` or config warning at startup) is related.
  - Doc correction owed: the `.sw/workspace.md` harness table says Claude `.env` reads are "enforced (ask)", but a Bash `cat .env` read with no prompt (081333Z). The correct wording is "guardrail". OpenCode's rows wait on the test above.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the owner's pasted results.
- **Not validated / risks:** the OpenCode push deny and `.env` ask are unconfirmed.
- **Publication:** `main-ahb0v0`; `main` is the owner's.
- **Next action:** owner; run the commit probe as project-leader in OpenCode, and report any startup or config warning in the app.
