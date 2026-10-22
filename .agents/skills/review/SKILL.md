---
name: review
description: Independent read-only review of a diff, branch or pull request (Codex by default, single-provider when the owner uses one provider) - rubric first, then findings by severity.
disable-model-invocation: true
---

# Review

Use for every review, audit or bug hunt, whoever wrote the work: after the
simplify pass in `work`, before enabling auto-merge, or when the owner asks.
The reviewer is Codex by default. A Claude or other cross-provider review runs
only when the request explicitly asks for it, and a
[single-provider review](#single-provider-review) only in a project whose owner
uses one provider. Review is advisory: it neither authorizes scope nor proves
integration.

## Steps

1. **Fix the target.** With no target, the uncommitted changes including
   untracked files; otherwise the named branch, pull request or SHA against
   its recorded base. Record the exact base and head SHA, or the dirty paths.
2. **Write the review prompt** (below) with the approved scope, acceptance
   criteria and checks already run. For a later round, add the previous
   findings, the author's responses and unresolved objections.
3. **Route to Codex.**
   - From a Claude thread: `orchestrator_capabilities`, then `delegate_task`
     with a Codex provider instance, `role: "review"`, `mode: "wait"` (or
     `async` for a large review), `runtimeMode` unset and a distinct
     `clientRequestId` per round. `delegate_task` has no read-only mode, so
     the prompt states it. If `delegate_task` is unavailable, run
     `codex exec -s read-only "<review prompt>"` from the checkout.
   - From a Codex thread: a fresh Codex subagent with the same prompt.
   - Single-provider project: see [below](#single-provider-review).
4. **Act on findings.** Fix confirmed defects (each fix is in scope only when
   it serves the approved task), answer disputed ones with evidence, and run
   another round, a new `delegate_task` call, for material fixes.

## Review prompt

```text
Read-only review. Do not edit, stage, commit, push or write files.
Target: <checkout path>, <base SHA>..<head SHA | working tree incl. untracked>.
Scope and acceptance: <approved outcome and criteria>.
Checks already run: <exact commands and results>.
Previous rounds: <findings, responses, objections | none>.
1. Rubric first: read AGENTS.md (including ## Code Review Rules) and the code
   around the change, then write a short checklist this change must satisfy.
2. Score the change against the rubric; run read-only checks where useful.
3. Report findings by severity (P0-P3) with file:line, failing condition,
   consequence and a bounded fix. Separate defects from risks and questions.
   Distinguish what you observed from what the author reported.
   If nothing is actionable, say so and state what you did not cover.
```

## Single-provider review

A project whose owner uses only one provider (Claude Code or Codex) states so
in a project-owned section of `AGENTS.md`, for example
`Review: single-provider (Claude Code only).` Its reviews then run on that
provider with fresh context: a delegated reviewer (`delegate_task` or a fresh
subagent) with no conversation history and the same review prompt. Label the
result "single-provider review" in the pull request and the task record. It
satisfies the review step wherever these rules require Codex review. It is a
standing owner choice, never a fallback.

## Decisions

- No Codex route works: stop and report; do not substitute a same-provider
  review unless the owner asks for one or has stated a single-provider
  project. A quota, rate-limit or permission failure on the Codex route means
  stop and ask the owner; never switch provider on your own to get around it.
- The reviewer changed files: report it and discard nothing yourself; the
  owner decides.
- A finding is out of scope: record it as follow-up, not as a fix.

## Exit

A report naming the reviewer (provider, model, route, and "single-provider
review" when it was one), target SHAs, rubric,
findings by severity and coverage limits, plus the action taken on each
finding.
