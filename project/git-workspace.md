- Branches are `main` plus T3 Code worktree-thread branches (`t3/<name>`, one
  per thread, created by T3 Code from published `main`). Agents never create,
  switch or delete branches themselves; other tools' automatic branches stay off.
  Never work on another thread's branch. Unexpected branches are reported,
  never deleted.
- Small, docs-only or solo work commits on `main`; a human publishes `main`.
  Code changes and anything published to the public product remote go through
  a `t3/<name>` worktree thread and a pull request (`.sw/workspace.md`, Git flow).
- Pull requests: at GitHub tier 2 the agent pushes its `t3/` branch, opens a
  draft pull request, links and watches it (`link_pull_request`,
  `watch_pull_request`), and fixes CI and conflicts. Drafts run no CI: after
  review (`review`: Codex, or a recorded single-provider review) it marks the
  pull request ready (`gh pr ready`), and enables auto-merge
  (`gh pr merge --auto`) only once the relevant
  CI checks on the current pull request revision have passed. If hosted CI
  cannot run for a quota or billing reason or because Actions is disabled
  (jobs not started), the gate is
  the full local test suite on every shell CI covers at that revision, plus
  `sw validate` and review, with exact commands and results in the pull
  request body and task record; hosted jobs are not rerun or worked around
  (Safety). Where the repository does not allow auto-merge, the owner merges
  once the gate passes. Below
  tier 2 the owner uses T3 Code's Git actions. Tiers: `.sw/config.json`,
  `.sw/workspace.md`.
