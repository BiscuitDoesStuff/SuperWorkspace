# p1-06-skills-move - summary

- **Outcome:** Package 6 (skills move), approved 2026-09-27. Runtime test 4: OpenCode 2.0.18 reads .opencode, .agents and .claude skills, lists a shared name once, precedence .opencode > .agents > .claude. Shipped: canonical skills (base and unreal-validation) moved to .agents/skills; rename-map prefix rule (.opencode/skills/ -> .agents/skills/) so update moves edited kit skills with their edits; validate reads .agents/skills and rejects a kit skill left in .opencode/skills (it would shadow the kit copy); the Claude adapter builds .claude/skills from .agents/skills; the CI whitespace step covers .agents; decisions.md entry supersedes 'OpenCode is canonical' for skills. BREAKING: users' own .opencode/skills no longer reach claude enable or validate. Not run: the OpenCode desktop check in the dogfood repo. Follow-ups: the compound-command follow-up (not authorized); the shadow check keys on the folder name, not the frontmatter name (unverified hypothesis). Note: the worker installed Pester 5.6.1 in the owner's CurrentUser scope.
- **Closed:** 2026-09-27 15:16:18Z by biscuitdoesstuff at 936964f02fed0a262eb6c12c0f934159bae88319
- **Events:** 5, kept in `events/` for evidence; read this summary instead.

- 2026-09-27T141549Z-leader-progress.md
- 2026-09-27T141823Z-leader-assignment.md
- 2026-09-27T143619Z-worker-submission.md
- 2026-09-27T144941Z-leader-review.md
- 2026-09-27T145304Z-leader-approval.md
