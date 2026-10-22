---
name: structured-debugging
description: Investigate a reproducible failure using evidence, explicit hypotheses, and a focused root-cause fix.
---

# Structured debugging

Use for a concrete failure, regression, or unexplained behavior.
All paths below are repository-root relative. `AGENTS.md` is canonical.

## Steps

1. **Establish evidence.** Record expected behavior, actual behavior,
   reproduction steps and frequency. Capture the exact failing command or
   interaction, environment and useful logs. Inspect the active worktree and
   relevant existing changes. Keep observations, user reports and assumptions
   apart.
2. **Narrow the cause.** Trace the failing path through inputs, state
   ownership, lifetime and outputs; compare with a working path or known
   baseline without resetting anyone's work.
3. **Test one hypothesis at a time.** State it, predict the evidence that
   would support or reject it, and run the cheapest discriminating check.
   Use targeted logging or inspection only when it resolves a real
   uncertainty. Record rejected hypotheses briefly.
4. **Fix the root cause** with the smallest authorized change once evidence
   supports it (`minimal-change`). Turn the reproduction into a test first
   where the project has tests.
5. **Verify** the original reproduction and the affected boundary or
   regression path, then run `validate`. Remove temporary instrumentation you
   added.

## Decisions

- No reproduction: describe the gap; do not invent a confirmed cause.
- Reproduction needs a shared build, editor or tool: coordinate with its
  owner before running it.
- Do not bundle speculative repairs or hide a failure behind unrelated
  fallback behavior.
- Three fix attempts fail: stop and report the evidence and the next
  discriminating check (`AGENTS.md` Safety).
- A bug hunt across many areas goes to the `review` route (Codex by default),
  one agent per area.

## Exit

Report cause, fix, exact checks and any still-unverified behavior. If
blocked, record the next discriminating check and its owner (`handoff`).
