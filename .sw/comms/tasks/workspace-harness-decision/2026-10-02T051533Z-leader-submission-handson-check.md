# workspace-harness-decision - submission (draft) - hands-on check (U3) - 2026-10-02T051533Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner, for approval.
- **Approval:** none. Draft for owner approval. Owner decisions it rests on (2026-10-02): option 2, shortlist OpenCode and Kilo, free / open-source constraint, model-only tiers. See the [handoff](2026-10-02T045723Z-leader-handoff.md) and `docs/workspace-outline.md` S2 and U1.
- **Status:** proposed.
- **Branch / base:** `main` at `ddd155c` (roster refit committed). No commit or push in this task unless the owner asks.

## Goal

Produce runtime evidence for the U1 choice between OpenCode and Kilo on the two properties research could not settle (handoff, "Not settled by research"): does each harness route the configured model per launch path, and does a deny rule or hook actually block a denied command on Windows. Confirm each licence. Choose nothing; the owner decides from the results.

## Scope

1. **Licence confirmation (both).** Read `LICENSE` at the default branch of each official repository. Record the repository URL, commit SHA, file path and SPDX identifier. Pass: an OSI-approved licence that lets the owner use it free of charge. Anything else (source-available, extra use terms, a paid core) is reported as failing the owner constraint.
2. **Per-launch-path model routing (both).** In a disposable scratch project outside Workspace, define two agents with distinct, identifiable models: one Claude, one non-Claude. For each launch path the harness offers, record which model actually served the call:
   - primary agent session;
   - subagent by user mention;
   - subagent launched by the primary through the task tool (C226, C319);
   - a parent naming a model at launch (Kilo C304; OpenCode if it offers it);
   - non-interactive or CLI run with an agent flag, if offered;
   - an agent with no model set (inheritance, C316).

   Evidence: runtime logs or provider request records showing the model ID per call. A configuration echo or the model's own answer is not evidence (O2, O9). Pass for a path: served model equals configured model on every run, at least 3 runs per path.
3. **Windows deny rule and hook test (both).** On this Windows 11 machine:
   - **Plugin control first:** list and record every plugin, extension and MCP location the harness loads (user and project scope). Pass precondition: none present except a probe written for this test and reviewed in this record (C317). If any are present, stop and report; do not remove the owner's files.
   - **Deny rule:** deny a harmless sentinel command (e.g. a unique `echo` string) for a subagent and for the primary agent, then ask each to run it through the shell tool. Pass: the command does not execute, shown by the absence of its side effect (a sentinel file it would create) and by the harness log, at least 3 attempts per agent (C280).
   - **Hook:** use the harness's own pre-tool hook mechanism, if it has one, to block the same sentinel. Record what happens when the hook errors or times out, so fail-open behavior is known (C311, C320). If a harness has no hook mechanism, or hooks exist only as plugins, record that as a finding rather than adding one.
   - No claim of OS isolation follows from a pass (C256).

## Out of scope

Choosing the harness; changing Workspace kit sources, generated files or `opencode.jsonc`; global settings changes; the external corpus; effort routing (tiers are model-only); a `.claude/` adapter; T3 Code; any other candidate.

## Needs owner action or approval before it can run

- **Install Kilo.** It is not installed here (no `kilo` or `kilocode` on PATH). Owner approves the install source and method, scoped to the scratch test. OpenCode is present (`opencode --version` printed `v2.0.20` on 2026-10-02); the recorded `doctor` launcher error is not re-diagnosed by this task.
- **Credentials.** The owner configures the Claude and non-Claude provider credentials in each harness. The agent never enters keys. Claude access uses an Anthropic API key unless the owner rechecks and accepts subscription OAuth for third-party clients at this point (C283, C324-C326, C329; not legal advice).
- **Spend.** Routing runs cost provider tokens; the owner sets a cap.

## Owners and validation

- Leader: scope, record, validation owner. `project-developer`: runs the checks in the scratch project. `project-review` (read-only): advisory review of the evidence before the owner decides.
- Acceptance: a submission in this task folder with, per harness, the licence row, a launch-path × model table with log excerpts, the plugin inventory, and deny/hook results with attempt counts. Results that were not run are marked not run. Workspace checks: `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check`.

## Risks

- Results are one machine, one version each, at one date; record versions and re-run after upgrades.
- A pass does not make a hook or deny rule a boundary in general, only on this setup (S4, O12).
- Kilo is built on OpenCode server (C303); shared defects may show in both.

## Next action

Owner approves, edits or declines this scope, and answers the install, credential and spend items.
