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

## Explicit session entry (workspace-v1)

Use an existing approved task and owner-selected local role map, not the old
unapproved launcher draft. Implementation and bounded one-route acceptance are
complete; other routes and assurance checks retain the limits below.

```powershell
pwsh -NoProfile -File .sw/sw.ps1 session start project-leader workspace-v1 -Model '<owner-selected-id>' -DryRun
pwsh -NoProfile -File .sw/sw.ps1 session start project-developer workspace-v1 -DryRun
```

Remove `-DryRun` only when launch/access is approved. The Leader requires explicit
`-Model`; a worker uses ignored `.opencode/opencode.jsonc` `agents[role].model`.
Claude models use interactive Claude Code and require a current local adapter;
other models use OpenCode `mini` with explicit model/role. `-Headless` supports
OpenCode `run` only, not Claude. No default model, hidden config activation,
automatic orchestration or blind retry is provided. Dry-run writes nothing.
See [native entry contracts](.sw/workspace.md#native-session-entry) for mixed maps,
Claude Leader setup and unknown-identity/effect recovery. Exit 0 never accepts an
artifact; inspect current approval, actual files and task records before resume.

No Workspace local map or adapter was activated during offline implementation.
Subsequent owner-selected local setup and bounded headless OpenCode engineering,
checkpoint/fresh-session and read-only acceptance passed; see
[observed results and limits](.sw/comms/tasks/workspace-v1/2026-10-03T081908Z-leader-submission.md).
One conservative read-only Git denial remains documented; Claude and interactive
routes are untested. Local model choices remain ignored, not shared defaults.

## Checks

Run from this directory:

```powershell
pwsh -NoProfile -File .sw/sw.ps1 validate
pwsh -NoProfile -File tests/workspace-v1.ps1
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
