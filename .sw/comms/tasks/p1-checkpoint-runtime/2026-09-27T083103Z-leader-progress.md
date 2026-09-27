# p1-checkpoint-runtime - progress - 2026 - leader

- **Author / audience:** leader (cloud Leader session), recording the owner's result; readers: the owner and later Leaders.
- **Approval:** as in the assignment.
- **Scope / acceptance:** commit probe, OpenCode desktop 2.0.17, agent project-leader, `sw-smoke`. `git commit --allow-empty -m probe` ran **with no permission prompt** ("ok 2065d04"). The base list sets `git commit *` to ask, so the probe **confirms** that OpenCode 2.0.17 does not apply the project-level `permissions` list in `opencode.jsonc`. Agent-frontmatter rules do apply (`project-review`'s shell denial, 082348Z).
- **Status:** in_progress
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** desktop at 6934e22; this event only.
- **Owners / dependencies:** the owner runs the checks. The Leader records them.
- **Decisions / remaining:**
  - **Plan-level finding.** In OpenCode, none of the kit's session-wide rules are in force: no push, reset, clean or stash deny; no commit ask; no `.env` ask; no `external_directory` ask. Only roles that carry their own rules (the read-only and markdown roles) are limited. The `.sw/workspace.md` table overstates OpenCode on every session-wide row. The static validator cannot catch this, because it models the documented V2 order rather than what 2.0.17 loads.
  - The exact cause is unknown. The file is read (`default_agent` works), but the list is not applied. Candidates are that the running build expects V1 `permission` in the project file, or a different key or schema. The next step is a throwaway experiment in `sw-smoke`; it needs the owner's go.
  - The fix is a correction package, owner-approved. Candidates: emit the working format; and/or repeat the critical denies in each agent's frontmatter; correct the harness table.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the owner's pasted result.
- **Not validated / risks:** until fixed, OpenCode sessions in real projects are not blocked from `git push`. The owner's GitHub branch protection (solo ruleset, still open) is the only server-side control.
- **Publication:** `main-ahb0v0`; `main` is the owner's.
- **Next action:** owner; undo the probe (`git reset --soft HEAD~1` in `sw-smoke`), then choose: run the format experiment now, or record and move on to runtime tests B1-B3.
