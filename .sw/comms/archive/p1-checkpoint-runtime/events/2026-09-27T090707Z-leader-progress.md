# p1-checkpoint-runtime - progress - 2026 - leader

- **Author / audience:** leader (cloud Leader session); readers: the owner and later Leaders. This is the checkpoint results summary.
- **Approval:** as in the assignment; the owner asked to get back on track after the format experiment.
- **Scope / acceptance:** final results. Detail is in the earlier progress events of this task.
  - **B3 (OpenCode config and models):**
    - no config or `$schema` warning seen when opening `sw-smoke` (owner);
    - the model picker marks "Free": LongCat 2.5 Preview, MiMo-V2.6-Flash, Muse Spark 1.3 (group "Personal / OpenCode"); it also lists OpenAI GPT-6 Astra, Luna and Sol;
    - OpenCode updated itself to **2.0.18** during the checkpoint;
    - the CLI is `%LOCALAPPDATA%\Programs\@opencodedesktop\resources\opencode-cli.exe` (not on PATH); `opencode models --verbose` fails with "Unrecognized flag: --verbose" (flags: `--standalone`, `--server`), and plain `models` was not run.
  - **Commit probe re-run on 2.0.18:** `git commit --allow-empty -m probe` as project-leader ran with **no prompt** ("ok 674c0ae"), so the finding holds on 2.0.18. The owner undid it.

  Checkpoint summary:

  | Check | Claude Code (desktop app) | OpenCode desktop 2.0.17 / 2.0.18 |
  | --- | --- | --- |
  | A1 `git push` | denied by harness | **not denied** (project-leader) |
  | A2 read-only edit | no Edit/Write tool; Bash only by instruction | no edit tool; shell denied by the role's own rules |
  | A3 `.env` read | **no prompt** (`Bash` `cat`) | **no prompt** (read tool, including a `/review` child) |
  | B1 `/context` | 44.8k total; kit share ~2.3k; estimate fine | n/a |
  | B2 children | n/a | load `AGENTS.md`; no nesting; `subagent:` honoured both ways; no messaging |
  | B3 `$schema` / models | n/a | no warning; `--verbose` gone; free models shown in the picker |

- **Status:** complete
- **Branch / base:** `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** desktop at 6934e22 (the `sw-smoke` throwaway); this event only.
- **Owners / dependencies:** the Leader; the owner decides the next step.
- **Decisions / remaining:**
  - **Plan-level finding:** the project-level permission list (V2 `permissions`, and V1 `permission` in the experiment) is ignored by OpenCode desktop 2.0.17 and 2.0.18. Agent-frontmatter rules work. Proposed correction package, for the owner to approve:
    - repeat the session-wide denies and asks (push, reset, clean, stash, commit ask, `.env` ask, external directory) in every kit agent's frontmatter;
    - correct the `.sw/workspace.md` harness table, including Claude `.env` as guardrail only;
    - review the read-only shell allowlist, which was too narrow in practice;
    - note that the built-in Build and Plan agents carry no kit rules.
  - `$schema` (package 2 follow-up): no warning seen, so no evidence for a change. Record it as "no action".
  - Package 8's CLI assumption (`opencode models --verbose`) is wrong for 2.0.18; the model advisor must use the picker or plain `opencode models`.
- **Validation:** manual, owner's desktop, 2026-09-27; evidence is the owner's screenshots and pasted output in the Leader session.
- **Not validated / risks:**
  - The cause of the ignored project list is unknown.
  - Until the correction lands, OpenCode sessions are not blocked from pushing; GitHub branch protection is the only control.
- **Publication:** `main-ahb0v0`; `main` is the owner's.
- **Next action:** owner; approve closing this checkpoint and choose: the permission correction package first (recommended), or continue with package 6.
