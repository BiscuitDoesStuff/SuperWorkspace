---
name: handoff
description: Record task progress or hand work to another thread, person or model so it can continue without the transcript.
disable-model-invocation: true
---

# Handoff

Use at the end of a worktree thread, before a break, when ownership moves, or
when the owner asks for a record. `.sw/collaboration.md` owns record fields
and naming.

## Steps

1. Check Git: branch, HEAD SHA, commits made, dirty paths, pull request.
2. Write the handoff content:
   - outcome, approved scope and acceptance, contributor and audience;
   - state per item (`pending`, `in_progress`, `complete`, `blocked`),
     dependencies and file owners;
   - exact SHAs or dirty paths; checks with commands and results, and what
     was not checked;
   - process outcome (observed exit, or missing/unknown) and effects
     (confirmed occurred, confirmed did not occur, unknown), kept separate
     from whether the artifact is accepted;
   - decisions, blockers, open questions and one next action with its owner.
3. Deliver it where it belongs:
   - Worktree thread: as the final message; the main thread records it
     (records are absent in worktrees).
   - Main checkout: append a new event under `.sw/comms/tasks/<task-id>/`,
     and update the ExecPlan `Progress` when there is one.
   - A note to a person: `sw comms send` or `.sw/comms/inbox/<user>/`.

## Decisions

- No task ID or approved scope: report that instead of inventing a record.
- Never edit another author's event; append a correction event.
- Never guess a future SHA or claim publication you did not observe.

## Exit

A record or final message that stands without the transcript and names one
next action. A handoff is a local record, not delivery, acknowledgment or
approval.
