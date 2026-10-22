---
name: validate
description: Run the checks the changed scope needs - sw validate, profile build and tests, diff and whitespace checks - and report exact results.
disable-model-invocation: true
---

# Validate

Use before review, before a commit that closes a step, or when the owner asks.
Validation does not change scope.

## Steps

1. Run `git status --short --branch` and classify the changed scope.
2. Workspace or docs only:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate`
   and `git diff --check`; say builds were not run.
3. Code: follow the validation order in the `AGENTS.md` profile section and
   load the skill it names, if any (`.sw/profile.json` `skills`). Run targeted
   tests first, then the suite. Run only existing tests and the ones written
   for this task.
4. Check new and untracked files for trailing whitespace; `git diff --check`
   does not cover them.
5. Fix failures your change caused when in scope.

## Decisions

- A failure your change did not cause: report it; no broad repair.
- A check needs an interactive session, a build owner or credentials you do
  not have: mark it not run and name who can run it.
- `sw validate` passing is a static check; it does not prove runtime
  enforcement.

## Exit

A report with separate lines for build, automated tests (exact counts),
manual checks or `not available`, `sw validate`, diff and whitespace checks,
the branch and SHA (or uncommitted paths), and remaining warnings.
