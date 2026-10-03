# p1-leader - handoff - 2026-09-27T124227Z - leader

- **Author / audience:** leader (cloud Leader session session_01GXr7vtrb4fGb6dTtRdQ72S); reader: the next Leader, a **local** Claude desktop session in `C:\DevProjects\SuperWorkspace`, then the owner. It supersedes 2026-09-27T091754Z. The owner asked (2026-09-27) to leave the cloud and work locally from now on.
- **Approval:** the owner approved the Phase 1 plan and order, packages 1-5, and package 5a (approved and closed 2026-09-27). Nothing after 5a is authorized. The next package needs an owner decision.
- **Scope / acceptance:** the local Leader's first task is to orient and bring the owner the next-step choice. It does not start a package.
- **Status:** in_progress
- **Branch / base:** published main 7a8eafafad1832320f4fdacfab1da1388d6eb85a (the owner fast-forwarded and pushed). From now on, work happens on local `main` only. `main-ahb0v0` was the cloud transport branch; the owner deletes it after pulling this event.
- **Checked revision / changed:** 7a8eafa, plus this event in the commit that follows.
- **Owners / dependencies:** the Leader owns the roadmap, records and review; the owner approves, commits when asked, and pushes. No worker is running. The cloud worker sessions are archived.
- **Decisions / remaining:**
  - **Done:**
    - Phase 0; Phase 1 packages 1-5 and 10; runtime tests 1-3; the desktop checkpoint;
    - package 5a: session rules injected into every OpenCode agent, `rtk ` twins of every shell rule, `validate` models agent files, wider read-only allowlist, harness-table fixes. Read `.sw/comms/archive/p1-05a-permission-correction/SUMMARY.md`.
  - **Key finding:** the kit's RTK plugin rewrites shell commands before OpenCode 2.0.18's permission check. The "project list is ignored" reading from the checkpoint was wrong (`docs/decisions.md`, 2026-09-27 entry).
  - **Open follow-up (not authorized):** read-only roles deny compound shell lines (`;`, `echo`) and `git -C`, so a `/review` child that batches git reads is refused.
  - **Next by the roadmap:**
    - package 6 (skills move to `.agents/skills`), gated by runtime test 4 (duplicate skills with both folders);
    - packages 7 and 9 are gated by runtime tests 5 and 6.

    Bring the owner the choice: runtime test 4 then package 6, or the read-only follow-up first.
  - **Local flow (replaces the cloud flow):**
    - the Leader works in `C:\DevProjects\SuperWorkspace` on `main`;
    - it writes events with `pwsh .sw/sw.ps1 comms event`;
    - it commits only when the owner asks, staging selected paths;
    - the owner pushes (AGENTS.md: agents never push);
    - Pester runs locally (`Invoke-Pester tests -Output Detailed`), and CI on the pushed commit confirms it.
  - **Lessons:**
    - desktop tests: use harmless commands that match the rule patterns, since models refuse destructive probes;
    - read evidence from the session export, not the model's words;
    - keep "Auto accept permissions" off;
    - after recreating a project folder, quit OpenCode and run `Get-Process *opencode* | Stop-Process -Force`, because the background service keeps stale agents;
    - `opencode-cli debug agents` shows the resolved rules; `run --standalone --print-logs` shows the executed command;
    - the OpenCode CLI is `%LOCALAPPDATA%\Programs\@opencodedesktop\resources\opencode-cli.exe`;
    - `sw` is not on PATH: call `pwsh -NoProfile -File C:\DevProjects\SuperWorkspace\product\sw.ps1 <cmd>`;
    - the owner's OpenRouter key is at its limit, so pass `--model opencode/muse-spark-1.3-contributor-free#xhigh` to CLI runs;
    - use the Claude desktop app, because the Claude CLI fails to start on this machine.
  - **Owner preferences:** short, plain replies; choices only for real decisions; step-by-step commands with absolute paths, and PowerShell 7 (a new window loses variables).
  - **Owner side topic:** adopting the kit into `C:\DevProjects\ModelAnalysis` (`init -Adopt`), which is on branch `biscuit`. That is the owner's own project, not kit work.
- **Validation:** `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS (2 known research-lint warnings) and `git diff --check` clean, cloud container, 2026-09-27 ~12:43 UTC.
- **Not validated / risks:** RTK twins cover only the `rtk ` prefix; another plugin that rewrites commands would bypass the rules.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader; the owner fast-forwards `main` and pushes. This cloud session makes no further commits.
- **Next action:** local Leader:
  1. Read AGENTS.md, `docs/development.md`, `docs/roadmap.md` Phase 1, this event, and the 5a SUMMARY.
  2. Run `git status --short --branch` and `git log --oneline -10`, and `validate`.
  3. Bring the owner the next-step choice.
