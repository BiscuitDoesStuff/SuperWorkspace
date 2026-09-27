# p1-leader - handoff - 2026-09-27T091754Z - leader

- **Author / audience:** leader (cloud Leader session session_01Md93Aa7xjxkWfWqxHChXXM); reader: the next cloud Leader session, started at the owner's request ("Full hand off to new cloud LEADER session"), then the owner. It supersedes 2026-09-27T071314Z.
- **Approval:** the owner approved the Phase 1 plan and order (2026-09-27) and packages 1-5. On 2026-09-27 the owner asked for: (1) cleanup, (2) a full handoff to a new cloud Leader, (3) realignment with the whole plan, then a decision on what to do next. Nothing after package 9 is authorized.
- **Scope / acceptance:** the next Leader's first task is **realignment** (see "Next action"). It does not start a package until the owner decides.
- **Status:** in_progress
- **Branch / base:** cloud branch `main-ahb0v0` (transport only; `docs/development.md`); published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019. The owner's desktop `main` was fast-forwarded to 6934e22 during the checkpoint and is not pushed.
- **Checked revision / changed:** the checkpoint close commit, plus this event in the commit that follows.
- **Owners / dependencies:** the Leader owns the roadmap, records and review; the owner approves, owns `main` and publishes. No worker is running.
- **Decisions / remaining:**
  - **Done:**
    - Phase 0;
    - Phase 1 packages 1-5 (`archive/p1-01..05-*`, read the SUMMARY files);
    - the desktop checkpoint (`archive/p1-checkpoint-runtime/SUMMARY.md`; detail in its events, the results table in the last progress event).
  - **Checkpoint findings that change the plan:**
    - OpenCode desktop 2.0.17 and 2.0.18 ignore the project-level permission list in `opencode.jsonc` (V2 `permissions`; a V1 `permission` object was ignored too). As a result, as project-leader, `git push` ran, and commits and `.env` reads gave no prompt. Agent-frontmatter rules do work: `project-review` has no edit tool and its shell was denied. The built-in Build and Plan agents carry no kit rules.
    - Claude: `git push` denied (OK); `.env` read through `Bash` `cat` with no prompt, because `Read(**/.env)` covers only the Read tool.
    - The `.sw/workspace.md` harness table overstates both harnesses: OpenCode's session-wide rows, and Claude's `.env` row.
    - The read-only shell allowlist was too narrow in practice: the review child could not run `git status`.
    - No `$schema` warning: package 2's `$schema` item needs no action.
    - `opencode models --verbose` no longer exists (2.0.18 flags: `--standalone`, `--server`): package 8's CLI assumption changes. The desktop app's picker marks free models.
    - Runtime tests 1-3 are done; test 1 showed the bytes/4 estimate is fine and harness tools dominate. Tests 4-6 are still owed, and gate packages 6, 7 and 9.
  - **Open owner decision** (take it up in realignment): a permission correction package first (this Leader's recommendation), or package 6 as planned. The correction would:
    - repeat the session-wide denies and asks in every agent's frontmatter;
    - correct the harness table;
    - widen the read-only allowlist;
    - note the built-in agents;
    - end with a desktop re-test.
  - **Flow** (owner-approved):
    - one package at a time, owner approval after each;
    - the Leader writes the `assignment` (`sw comms event`), commits and pushes, then starts a worker with `create_session` (source `main-ahb0v0`, outcome branch `cloud/<task-id>`);
    - the Leader never commits while a writing worker runs;
    - on "done": fast-forward, read CI (Actions API; poll in a background loop), review inline against `project-review`, re-run the checks (validate; a fresh init, then validate, `claude enable`, validate; the behaviour against `product/lib`; `git diff --check`), fix small in-scope problems, write `review`, push, confirm CI, and report;
    - on approval: write `approval`, run `comms close`, commit, push.
  - **Lessons:**
    - test against `product/lib`, because of the CRLF checkout;
    - Pester and opencode.ai are blocked in the cloud, so CI is the Pester evidence;
    - a cloud worker can stop on a commit-permission prompt: check `get_session` before assuming it is done;
    - smoke prompts must ask the agent to *attempt* the action, or models decline and the rule is never reached;
    - give the owner step-by-step commands with absolute paths, because each new PowerShell window loses variables and the owner's default is `C:\WINDOWS\system32`, Windows PowerShell 5.1;
    - the owner's kit clone is `C:\DevProjects\SuperWorkspace`;
    - the owner's Claude CLI fails to start (npm `claude.exe` "not a valid application"), so use the Claude desktop app;
    - OpenCode is the desktop app, and its CLI is `%LOCALAPPDATA%\Programs\@opencodedesktop\resources\opencode-cli.exe`.
  - **Owner preferences:**
    - short, plain replies;
    - choices only for real owner decisions;
    - step-by-step instructions for desktop actions;
    - no OpenCode handoffs until asked.
- **Validation:** `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS (2 known research-lint warnings), `git diff --check` clean, cloud container, 2026-09-27 ~09:18 UTC. CI on the pushed tip is confirmed by this Leader before handing over.
- **Not validated / risks:**
  - The cause of the ignored OpenCode project list is unknown.
  - Until a correction lands, GitHub branch protection is the only push control for OpenCode sessions, and it is not set yet.
- **Publication:** pushed to origin/main-ahb0v0 by this cloud Leader. After the new Leader starts, this session makes no further commits.
- **Next action:** new Leader; realign, then bring the decision to the owner:
  1. Orient: AGENTS.md, `docs/development.md`, `docs/roadmap.md`, this event, and the archived checkpoint SUMMARY and its last progress event. Then `git status --short --branch`, `git log --oneline -10`; install pwsh; run `validate`.
  2. Draft the roadmap reconciliation, without editing yet:
     - runtime tests 1-3 done, with results;
     - package 2's `$schema` item: no action;
     - package 8: the CLI change;
     - package 10's smoke checklist done for both harnesses;
     - where a permission correction package fits.
  3. Present it to the owner with choices; edit `docs/roadmap.md` only after approval.

  Human actions open for the owner:
  - set the solo ruleset on `main` (`.sw/collaboration.md` "Protect main"), now urgent;
  - delete `cloud/p1-02..05-*`;
  - delete `%TEMP%\sw-smoke` on the desktop;
  - fast-forward and push `main` when ready;
  - archive this Leader session once the new one runs.
