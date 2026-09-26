# Case study: MyMMO

An Unreal C++ game project whose workspace layer SuperWorkspace was harvested
from. It is an example, not a target: nothing in `product/` may depend on it.

## Cost setup (2026-09-26)

Claude runs one month at a time (about $20). Other access uses free
OpenCode/OpenRouter models and local LM Studio.

## Adoption (open)

Two contributors. A dry run on 2026-09-26 in a throwaway clone of HEAD found
no kit bugs. `init -Profile unreal -Adopt` backs up and replaces 20 files,
adds 19, and `validate` then fails only on the startup budget. Before the real adoption:
- Trim the old MyMMO sections of `AGENTS.md` (startup, validation and git
  rules) that the core block now owns. Keep identity, architecture and the
  invariants.
- Delete the superseded `mmo-manager`, `mmo-developer` and
  `mmo-world-worker` roles, which have no delegation entries.
- Delete the old workspace docs and scripts: `docs/{agent-workspace,ai-usage,
  WORKSPACE_USER_GUIDE,HANDOFF}.md`, `docs/collaboration/` and
  `scripts/*Workspace*.ps1`.
- The `.gitattributes` LFS lines get duplicated inside the managed block.
  This is harmless.
