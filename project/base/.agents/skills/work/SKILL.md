---
name: work
description: Plan and carry out a task with the Workspace method - route by size, plan, check first, execute, simplify, review, close with evidence.
disable-model-invocation: true
---

# Work

Use when the owner asks for a task to be planned or done. The request that
invoked this skill is the task. `AGENTS.md` is canonical; this skill is the
method, not extra scope or approval. Provenance per step: topic 12 R1
(`docs/research/12-workflow-methods.md` in the SuperWorkspace kit).

## Steps

1. **Ground.** Run the `AGENTS.md` startup, inspect the relevant code, and
   find the task record in `.sw/comms/tasks/<task-id>/` if one exists. If an
   approved plan exists, continue it (`resume`) instead of re-planning.
2. **Route by size.**
   - Small and clear (one obvious change, inside approved scope): skip to
     step 5 with the check stated in one line.
   - Normal: a short plan in chat; the owner approves it before step 5.
   - Large or multi-session: an ExecPlan file (below) in the task record; the
     owner approves it before step 5.
3. **Clarify by interview** only when requirements are unclear: ask the few
   questions that change scope, ownership or a consequential decision, and
   keep inspecting while waiting. Not a mandatory preamble.
4. **Define the check before the change.** Name the command, test or
   observation that proves each outcome. Where the project has tests, write or
   extend the failing test first.
5. **Execute.** Inline by default, loading `minimal-change`; commit as you go
   (`AGENTS.md` Git). For a long plan, give each package a fresh worker: a T3
   worktree thread or subagent with the task, exact files owned, acceptance
   criteria and validation owner. Run independent packages in parallel; bulk
   sweeps, migrations or research may use a Claude dynamic workflow, bulk
   audits a Codex fan-out with one agent per area. Best-of-N attempts only on
   request, judged by tests and `review`.
6. **Simplify.** Reread the whole diff; remove churn, duplication and
   speculative code. Run `validate`.
7. **Review.** Run `review` (Codex by default): once at the end for normal work, per
   package inside a long plan. Fix or answer each finding.
8. **Close.** Record execution evidence (exact checks and results, commit
   SHAs, pull request) in the task record, or in the final message from a
   worktree thread (`handoff`). End the closing summary with one dated
   lessons line, `Lessons (YYYY-MM-DD): ...` or `Lessons: none`.

## ExecPlan shape

One Markdown file in the task record, self-contained so a fresh session can
restart from it alone, and kept current as work proceeds:

```text
# <task>: <outcome in one line>
Purpose: what the user can do afterwards that they cannot now.
Context: files, terms and state a newcomer needs; no outside references.
Plan: ordered packages; each has files owned, observable outcome, check.
Validation: exact commands and expected results.
Progress: - [x] YYYY-MM-DD HH:MMZ done item / - [ ] remaining item
Surprises & Discoveries: what differed from expectation, with evidence.
Decision Log: decision, reason, date, who decided.
Outcomes & Retrospective: what shipped, what did not, lessons line.
```

## Decisions

- Size is unclear: treat as normal and plan in chat.
- Scope, ownership or a requirement changes: stop and ask; record the answer
  in the Decision Log.
- A check cannot run here: say so, keep the step open, and name who can run it.
- A step keeps failing: at most three repair attempts, then stop and report.
  A quota, rate-limit or permission failure stops the work at once
  (`AGENTS.md` Safety).
- A finding is promoted into a rule, check or skill only after review, when it
  recurs or caused a failure. Lessons are never auto-loaded.

## Exit

The approved outcome is done, its checks pass with recorded evidence, review
findings are resolved or reported, and the closing summary ends with the
lessons line. Otherwise stop with the blocker and one next action.
