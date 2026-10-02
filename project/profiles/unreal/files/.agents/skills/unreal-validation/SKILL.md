---
name: unreal-validation
description: Validate approved Unreal changes with portable engine discovery, one coordinated build, and exact test evidence.
---

# Unreal validation

Use when Unreal implementation needs validation or a build is explicitly requested.
Paths are repository-root relative. `AGENTS.md` (profile section) defines the
validation order; `.sw/workspace.md` defines coordination.

## Prepare one run

1. Inspect Git status, the checked SHA, and uncommitted changes in the target worktree.
2. Identify the `.uproject`, its `EngineAssociation`, and existing validation scripts.
3. Resolve the installed engine from local configuration, the Unreal installation
   registry, or a user-supplied path; verify the build and editor executables exist.
   Never hardcode another machine's path or silently pick a different engine version.
4. Agree on one build owner per checkout. Check for an active build or editor run;
   wait or coordinate rather than race or kill it.
5. Record the resolved engine, project path, target, configuration, and evidence location.

## Validate in order

- Build `<Project>Editor Win64 Development` with the resolved engine and project paths.
- Capture the exact command, working directory, exit code, and final result.
- On confirmed paging-memory exhaustion, retry once with `-MaxParallelActions=1`.
- Run relevant existing automation/smoke tests after a successful build; inspect
  results for actual execution and failures, not only the process exit code.
- Run interactive PIE only when genuinely available; label human-run checks as reported.
- Run `git diff --check` and inspect new/untracked files for trailing whitespace.

## Report evidence

Separate build, automated/headless, interactive, and source-check outcomes. Include
runner, timestamp with zone, branch/SHA, dirty-tree scope, exact commands, results,
and log locations; label local-only logs. Fix task-caused failures within scope;
report other blockers without broad repairs.
