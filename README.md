# Workspace

Research-led AI workspace based on the sibling `AI-Research [2]` corpus.
SuperWorkspace 0.3.0-dev is the inherited installation, not the target design.
Every project component can be modified, overhauled or replaced on evidence.

## Start here

- [Project instructions](AGENTS.md)
- [Current state and authorized work](docs/workspace-state.md)
- [Design rules, assumptions and current outline](docs/workspace-outline.md)
- [Workspace roles and verification](.sw/workspace.md)
- [Task records and collaboration](.sw/collaboration.md)
- [Contributor setup](.sw/onboarding.md)

The current kit source lives in `project/`, `lib/`, `global/`, and `sw.ps1`.
The inherited installation lives in `.sw/`, `.opencode/`, and `.agents/`.
Neither layout nor its policies have privileged preservation status. The design
register distinguishes approved requirements, current controls, proposals and
unknowns; current controls still apply until explicitly changed.

## Checks

Run from this directory:

```powershell
pwsh -NoProfile -File .sw/sw.ps1 validate
pwsh -NoProfile -File .sw/sw.ps1 doctor
git diff --check
```

Open a fresh session in this directory to use the installed agent and command
definitions. No model tier map or optional Claude adapter is configured by the
base initializer. Setup checks do not prove runtime permission enforcement.

The design register records the owner's research-led direction and the newer
reviewed Pass 7 status. The v0.2 outline is a historical snapshot, not a current
evidence cutoff or approved target architecture. No full updated design synthesis
or runtime overhaul has been performed; proposals do not authorize implementation.
