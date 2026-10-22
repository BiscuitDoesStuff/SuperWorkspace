---
name: minimal-change
description: Choose a reuse-first, narrowly scoped implementation for an approved change.
---

# Minimal change

Use when choosing or implementing an approved fix or feature (`work` step 5).
All paths below are repository-root relative. `AGENTS.md` is canonical. This
skill supplies an implementation method, not additional scope.

## Steps

1. Trace the behavior from its caller to its state owner and presentation.
2. Search for a working sibling implementation and reusable project contracts.
3. Choose the smallest rung (below) and the smallest seam that satisfies the
   acceptance criteria.
4. Make the change, matching nearby naming, idioms and error handling.
5. Review the diff against the acceptance criteria and remove accidental churn.

## Choose the smallest rung

Stop at the first rung that holds: does this need to exist at all (skip
speculative work)? Does an existing project helper or contract cover it? Does
the platform or standard library cover it? Does an already-used
dependency cover it? Can it be one line? Only then write the minimum new code.

- Fix a reported symptom at its shared root cause, not at one call site.
- Prefer deleting code to adding it.
- Prefer configuring existing data, then extending an existing abstraction,
  before introducing a new abstraction or subsystem.
- Mark a knowing shortcut with a `ponytail:` comment naming its ceiling and
  upgrade trigger.
- Leave one small runnable check behind for non-trivial logic.
- Never simplify away validation, data-loss handling, security, or accessibility.

Adapted from Ponytail (MIT), https://github.com/DietrichGebert/ponytail.

## Keep it bounded

- Keep state rules with their owner and presentation in its existing layer.
- Preserve existing public contracts and the behavior other code relies on.
- Check object lifetime, ownership, and concurrency where relevant.
- Prefer events or cached updates over new per-frame work or world scans.
- Preserve asset references and defaults unless their change is required.
- Keep generated files, plugins, and third-party assets within `AGENTS.md` limits.
- Avoid unrelated formatting, cleanup, speculative generality, and duplicate state.

## Decisions

- A new component is justified only when existing responsibilities cannot
  hold it cleanly; explain why.
- The small edit exposes a larger required change: stop, explain, and resolve
  scope first.
- Add regression coverage when it verifies a meaningful failure or boundary.

## Exit

The change meets its acceptance criteria with the defined check passing
(`validate`), committed per `AGENTS.md` Git. Report changed behavior, exact
checks, and remaining limitations concisely.
