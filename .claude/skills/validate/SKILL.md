---
name: validate
description: Run the checks the changed scope needs - sw validate, profile build and tests, diff and whitespace checks - and report exact results.
disable-model-invocation: true
---

# Validate

Use before review, before a commit that closes a step, or when the owner asks.
Validation does not change scope. Choose checks by the behavior the change
can affect and the gates the project requires, not by habit. Method: topic 16
(`docs/research/16-public-capabilities.md` in the SuperWorkspace kit).

## Steps

1. Run `git status --short --branch` and `git rev-parse HEAD`, and classify
   the changed scope. Checks already recorded with exact results for this
   same revision and dirty state count; run only the required ones missing.
   Results from another revision are historical, not evidence for this one.
2. Workspace or docs only:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate`
   and `git diff --check`; say builds were not run. No product build or test
   suite unless the changed files are inputs those tests read.
3. Code: follow the validation order in the `AGENTS.md` profile section and
   load the skill it names, if any (`.sw/profile.json` `skills`). Run targeted
   tests first, then the suite, both on the changed revision. Run only existing
   tests and the ones written for this task. A regression test counts when it
   fails before the fix for the defect's reason and passes after; a test that
   restates the implementation proves nothing.
4. User-visible behavior: check it here when a browser preview or device is
   available; otherwise it is a manual check, not run.
5. Check new and untracked files for trailing whitespace; `git diff --check`
   does not cover them.
6. Fix failures your change caused when in scope.

## Decisions

- A failure your change did not cause: report it; no broad repair.
- A check needs an interactive session, a build owner or credentials you do
  not have: mark it not run and name who can run it.
- `sw validate` passing is a static check; it does not prove runtime
  enforcement. Report static, automated or headless, and manual results
  separately; an automated or headless run is runtime evidence only for the
  behavior it exercised, and never a manual result.
- Never invent a manual check to fill the report; an unavailable one stays
  `not run`.

## Exit

A report with separate lines for build, automated tests (exact counts),
manual checks or `not available`, `sw validate`, diff and whitespace checks,
the branch and SHA (or uncommitted paths), and remaining warnings.
