# Global workspace rules (SuperWorkspace)

Project policy lives in the project's `AGENTS.md`; SuperWorkspace projects add
`.sw/workspace.md` (tiers, opt-ins, runtime checks) and `.sw/collaboration.md`
(records, messages, branches). Those own the rules; this block only states how
work runs on this machine.

## Coordination
- T3 Code runs the threads (Claude Code or Codex). The main thread coordinates;
  there are no agent roles. Parallel packages run as T3 worktree threads.
- Every dispatch carries the task, exact scope, file ownership, acceptance
  criteria, and validation owner. Workers report back; they never spawn teams.
- When asking the human to do something, give the exact copy-paste commands,
  written to run from any directory: target the repository explicitly
  (`git -C <repo-path>`, `gh ... --repo <owner>/<repo>`), use absolute paths,
  and never rely on the shell's current directory.
- Procedures are the project's skills (`work`, `review`, `validate`, ...).
- Ordinary repair work gets at most three attempts, then stop and report. A
  quota, rate-limit or permission failure means stop at once: never retry
  around it or bypass it.

## Models and cost
- No tracked model pins. An optional local `.sw/models.local.md` maps the
  small, mid and top tiers to your models.
- Coordination and planning run on the mid-to-top tier at moderate effort;
  raise effort only for consequential or hard problems. Implementation from a
  written, scoped spec runs on the mid tier. Exploration and subagents run on
  the mid tier; the small tier is for non-agentic lookups only.
- Set model and effort explicitly on every thread and delegate launch; never
  inherit the coordinator's. No max effort and no fast or priority service
  modes by default. Use the top tier for hard work only after cheaper tiers
  fail.
- Never switch a running session's model.
- Smallest working change, shortest diff (`minimal-change`).
- Minimize tokens: batch tool calls, never re-read files already in context,
  terse replies, no unrequested prose.

## Review
- Codex reviews every change, audit and bug hunt (`review`), rubric first.
  A project whose owner uses one provider states so in `AGENTS.md` and uses
  the `review` skill's single-provider review instead. Never switch provider
  to get around a Codex failure. Other cross-provider review runs only when
  the prompt asks for it.

## Git and GitHub
- Conventional commits: feat/fix/docs/refactor/test/chore. Stage selected
  paths only.
- SuperWorkspace projects follow their `AGENTS.md` Git section (commit as you
  go; pull requests per the GitHub tier in `.sw/config.json`). Elsewhere,
  follow the project's own workflow and commit only when asked.
- Never discard, reset, stash, clean, or overwrite work you did not create.
- Hard limits everywhere: no force-push, no push to `main`, no `gh release`
  writes, no repository settings (`gh repo edit|delete|rename|archive`,
  `gh ruleset`, `gh secret`, `gh variable`), no rewriting `main` history,
  and on any branch no `git commit --amend`, `git rebase`, `git pull --rebase`
  or `git reset` that moves the branch (`--hard`, `--soft`, to another
  commit); make a new commit, merge instead of rebasing, and unstage with
  `git restore --staged`. Hand the human the exact command (Coordination)
  instead.
