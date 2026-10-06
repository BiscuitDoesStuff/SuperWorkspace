---
description: Write a task event or a message so another person or model can continue
agent: project-leader
subagent: false
---

Hand off: $ARGUMENTS

Load `task-handoff`. For task progress, append a new event under
`.sw/comms/tasks/<task-id>/` using the fields in `.sw/collaboration.md`. For a
note to a person or model, write a message to `.sw/comms/inbox/<user>/` (or run
`sw comms send`). Name exact SHAs or dirty paths, validation, blockers, and one
concrete next action with its owner. Record process outcome (observed exit or
missing/unknown) and effects (confirmed occurred, confirmed did not occur, or
unknown) separately from artifact acceptance, as in the `/status` recovery card.
Never edit another author's file. A handoff is a local record, not native
delivery, acknowledgment or approval. Do not commit or push unless explicitly
asked; say the handoff is local until published.
