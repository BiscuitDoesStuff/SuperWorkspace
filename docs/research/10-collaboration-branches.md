# 10: Collaboration, multi-user work and branch models

Status: complete; reviewed by the owner 2026-09-27; R1-R6 adopted (R3 text only).
Researched 2026-09-26 (local) by `project-research` (research-10, Claude Opus 5.5
via Claude Code, desktop app, native Windows). All sources accessed
2026-09-27 between 04:46Z and 04:49Z; page dates are given where the page
showed one (none of the fetched pages showed a date). Raw page text was
saved with `curl` to the session scratchpad (outside the repo). The Claude
page was fetched as its `.md` source and the git-lfs man page as raw
AsciiDoc; HTML pages were stripped to text. Every finding was re-checked
against that text. No finding is summary-based. Findings that rest on an
*absence* in the fetched text are marked **weak**. Kit code was read at
`fe10015`. Local experiments: one throwaway git repository in the
scratchpad (git 2.55.0.windows.5) and two read-only GitHub probes of this
repository (`gh repo view --json visibility`, and `git ls-remote`). No
GitHub settings were read or changed and no `gh api` call was made.

## 1. Question and scope

How do teams, and agents working for them, share one repository safely,
and what branch and coordination model should SuperWorkspace ship, fixed or
configurable?

Sub-questions:
1. Branch models (trunk-based, GitHub flow, long-lived per-contributor
   branches) and how agent tools create branches. Does `main` plus
   `<user>/<user>-worktree` fit or fight them?
2. Configurability: how comparable tools declare branch policy; the
   smallest config; what rules and generators would read it.
3. Shared coordination state: are timestamped append-only event files
   merge-safe; claims and locks; GitHub issues and draft PRs at tier 1;
   the comms inbox.
4. Mixed setups: different kit versions and harnesses; shared versus local;
   who runs `update` and when.
5. Protecting `main`: branch protection and rulesets for a solo owner and a
   team; the minimal setting; how the kit presents it.
6. Multi-human session tier: one Leader per human or per project; how
   records and messages cross humans.
7. Local analysis of `.sw/collaboration.md`, `sw user add`, the
   fast-forward-only integrate flow, and this repository's own practice.
8. Recommendation mapped onto the kit, and a verdict on the hypothesis
   "The branch model becomes configurable".

Carried inputs: 05 R4 (multi-human side of the session tier), 05-F3 and
05-F6 (Claude worktrees branch from the default branch; desktop worktree
branch prefix), 07 R2 (the manifest records the kit; who runs `update`),
08 R3 (branch protection is the real control; `main` found unprotected by
the owner on 2026-09-27), and the roadmap hypothesis above.

Out of scope, one line each: permissions design (topic 8, done);
lifecycle mechanics of `update` (topic 7, done); validation and CI
content (topic 9, done).

Not covered:
- Codex cloud's branch naming and whether it pushes a branch before the PR:
  the fetched pages say only that a task ends in a diff and an optional PR
  (F6). Not re-fetched to stay in budget.
- GitHub's pull-request merge methods (whether a PR merge can be a pure
  fast-forward). Not fetched; the recommendation avoids depending on it.
- GitLab, Bitbucket and Azure DevOps protection models.
- The owner's GitHub plan (Free or Pro); it decides F12 (open question 1).
- Actual protection state of `main`: reading it needs `gh api`, which the
  kit denies. The owner checked on 2026-09-27 that `main` is not protected
  (`.protected` false), before any ruleset was set.
- OpenCode's own automatic-worktree branch naming (topic 5 already covers
  the "turn it off" rule).

Budget: 17 research fetches (cap 25), plus 2 read-only probes of this
repository on GitHub and one local git experiment. Dropped: a GitHub
merge-methods page, the Codex cloud environments page, GitHub's
"linking a pull request to an issue" page, and a Gitflow primary source.

## 2. Findings

### Branch models

F1. **Trunk-based development: one shared branch; feature branches only if
short-lived and single-developer.** Summary line: developers "collaborate
on code in a single branch called 'trunk'" (main since 2020) "and resist
any pressure to create other long-lived development branches". Very small
teams "may commit direct to the trunk"; otherwise "a Pull-Request workflow
as long as those feature branches are short-lived and the product of a
single dev-workstation". Teams run a full pre-integrate build "before
committing/pushing for others (or bots) to see".
https://trunkbaseddevelopment.com/ (accessed 2026-09-27; no page date).

F2. **Short-lived feature branches: about two days, one developer, merge
either direction.** "One key rule is the length of life of the branch
before it gets merged and deleted ... Any longer than two days, and there
is a risk of the branch becoming a long-lived feature branch". "The
developer count should stay at one (or two if pair-programming)". The
page's "Merge directionality" section says bringing a branch up to date
with trunk is an ordinary merge. On team size: the cut-off for committing
"direct to the trunk" "is now up to 15 people. With 16 or more, the team
is more productive with short-lived feature branches".
https://trunkbaseddevelopment.com/short-lived-feature-branches/ (accessed
2026-09-27; no page date).

F3. **GitHub flow: one branch per set of unrelated changes, PR, merge,
delete.** "Make a separate branch for each set of unrelated changes."
"After you merge your pull request, delete your branch. This indicates
that the work on the branch is complete and prevents you or others from
accidentally using old branches." Draft PRs give early feedback; "Branch
protection settings may block merging" until reviews are met.
https://docs.github.com/en/get-started/using-github/github-flow (accessed
2026-09-27; no page date).

F4. **Long-running branches (Pro Git) are stability silos, not
per-person branches.** The pattern is "several branches that are always
open ... for different stages of your development cycle" (for example
`master` for stable code and `develop` or `next` for integration), with
"topic branches (short-lived branches ...)" pulled into them. The kit's
`<user>/<user>-worktree` is neither: it is long-lived by name but carries
one person's short work between integrations. **Weak** for the per-person
case: the page describes no per-contributor long-lived branch at all.
https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows (accessed
2026-09-27; no page date).

### How agent tools create branches

F5. **Claude Code `--worktree` creates a new branch per session, from the
remote default branch by default.** "By default, the worktree is created
under `.claude/worktrees/<name>/` at your repository root, on a new branch
named `worktree-<name>`". `worktree.baseRef`: `"fresh"` (default) branches
"from the repository's default branch on the remote, usually `main`";
`"head"` from local `HEAD`. "Subagent worktrees use the same base branch as
`--worktree`". Removing a worktree "deletes the worktree directory and its
branch". This confirms and extends 05-F3; the desktop app adds its own
configurable branch prefix (05-F6).
https://code.claude.com/docs/en/worktrees.md (accessed 2026-09-27; no page
date).

F6. **Codex cloud: each task runs in a cloud environment and ends in a diff
and an optional PR.** "Review the summary and diff. Ask Codex to make
follow-up changes, or open a pull request when the work is ready." Codex
code review posts "a standard GitHub code review" on PRs and follows
`AGENTS.md` review guidance. **Weak** on branch naming: neither page names
the branch Codex creates.
https://developers.openai.com/codex/cloud and
https://developers.openai.com/codex/integrations/github (both accessed
2026-09-27; no page date).

F7. **GitHub Copilot cloud agent: one agent-made branch and at most one PR
per task; incompatible rules block it.** "Copilot automates branch
creation, commit message writing, and pushing." "Copilot can only work on
one branch at a time and can open exactly one pull request to address each
task it is assigned." "If you have configured a ruleset or branch
protection rule that isn't compatible with Copilot cloud agent, access to
the agent will be blocked"; with rulesets "you can add Copilot as a bypass
actor".
https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent
(accessed 2026-09-27; no page date).

### Configurability in comparable tools

F8. **Git Town declares branch policy as a list of long-lived branches;
everything else is a short-lived feature branch.** "Perennial branches are
long-lived branches. Typical perennial branches are `main`, `master`,
`development`, `production`". In its config file: `perennials = ["branch",
"other-branch"]`, plus a naming-schema option for many such branches.
https://www.git-town.com/preferences/perennial-branches (accessed
2026-09-27; page labelled "Git Town 24.0").

F9. **Claude Code exposes one branch-policy knob per concern, not a model.**
`worktree.baseRef` (`fresh` or `head`) sets the base; the branch name is
derived from the worktree name (F5); the desktop prefix is a separate
setting (05-F6). Same page as F5.

### Coordination state, claims and locks

F10. **Local experiment: timestamped event files from different authors
merge without conflict; a list edited by two people does not; a close
racing an event does.** In a scratch repository, branches `a` and `b` each
added one event file to `.sw/comms/tasks/t1/` and each appended one user
to a multi-line `users` array in `config.json` (the shape
`ConvertTo-SwJson` writes). Merging `b` into `a`: the event file merged
cleanly; `config.json` stopped with `CONFLICT (content)`. A third branch
moved `t1` to `archive/t1/events/` (what `sw comms close` does); merging the
new events into it gave `CONFLICT (file location): ... added in a inside a
directory that was renamed in HEAD`, and git placed both late events in
`archive/t1/events/`. The files survive, but a human must resolve the
merge, and `SUMMARY.md` does not mention them. Local evidence, git
2.55.0.windows.5, run 2026-09-27.

F11. **Git itself refuses a non-fast-forward push, so integrating to
`main` is a compare-and-swap.** git-push output: "rejected: Git did not try
to send the ref at all, typically because it is not a fast-forward and you
did not force the update." The kit's Integrate flow (`merge --ff-only`,
then `push origin main`, never force) therefore lets only one of two racing
integrators win; the other must fetch and sees the first one's records.
https://git-scm.com/docs/git-push (accessed 2026-09-27; no page date).

F12. **The only real file lock in the git ecosystem is Git LFS's, and it
is server-side.** `git lfs lock` "Sets the given file path as 'locked'
against the Git LFS server, with the intention of blocking attempts by
other users to update the given path"; "LFS will verify that Git pushes do
not modify files locked by other users" (`lfs.<url>.locksverify`). Relevant
to the kit's "every binary asset has one named owner" rule (unreal
profile); nothing comparable exists for text records.
https://raw.githubusercontent.com/git-lfs/git-lfs/main/docs/man/git-lfs-lock.adoc
(accessed 2026-09-27; no page date).

F13. **GitHub assignees are a visible but advisory claim.** "Assignees
clarify who is working on specific issues and pull requests." "Anyone with
write access to a repository can assign"; "Both issues and pull requests
support up to 10 assignees." Nothing prevents two people from working the
same issue. Tier 1 today allows `gh issue edit` (`.sw/workspace.md`), which
is how an agent would set one.
https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/assigning-issues-and-pull-requests-to-other-github-users
(accessed 2026-09-27; no page date).

F14. **git's `union` merge driver would auto-resolve line lists, with a
warning.** It takes "lines from both versions, instead of leaving conflict
markers. This tends to leave the added lines in the resulting file in
random order and the user should verify the result. Do not use this if you
do not understand the implications." It is line-based, so it would break
JSON (a missing comma after the first array entry); not a fix for F10's
`users` conflict.
https://git-scm.com/docs/gitattributes (accessed 2026-09-27; no page date).

F15. **git refuses to check out one branch in two worktrees.** "By
default, add refuses to create a new worktree when `<commit-ish>` is a
branch name and is already checked out by another worktree" (unless
`--force`). This is the mechanism behind `.sw/workspace.md`'s "Git cannot
check out one branch twice, so coordinate instead of bypassing it".
https://git-scm.com/docs/git-worktree (accessed 2026-09-27; no page date).

### Protecting `main`

F16. **Branch protection and rulesets need a public repository or a paid
plan.** "Protected branches are available in public repositories with
GitHub Free and GitHub Free for organizations ... also available in public
and private repositories with GitHub Pro, GitHub Team, GitHub Enterprise
Cloud". Rulesets have the same availability sentence. Local probe
2026-09-27: `gh repo view --json visibility` returned `"visibility":
"PRIVATE"` for this repository. So on a GitHub Free personal account this
repository cannot be protected at all; with Pro it can. Update 2026-09-27:
the owner made the repository public; protection is now available on Free.
https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
and
https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
(both accessed 2026-09-27; no page date).

F17. **Protection defaults: no force-push, no deletion; admins bypass
unless told otherwise.** "By default, each branch protection rule disables
force pushes to the matching branches and prevents the matching branches
from being deleted." "By default, the restrictions of a branch protection
rule don't apply to people with admin permissions ... You can optionally
apply the restrictions to administrators". "Actors may only be added to
bypass lists when the repository belongs to an organization." A solo owner
is the admin, so a plain rule protects against agents and mistakes only if
"Do not allow bypassing the above settings" is on. Same page as F16.

F18. **Required status checks allow a direct push of a commit that already
passed.** "After all required status checks pass, any commits must either
be pushed to another branch and then merged or pushed directly to the
protected branch." Checks are "strict" by default: "The branch must be up
to date with the base branch before merging." The kit's flow (publish the
contributor branch, `sw-validate` runs on push, then fast-forward `main` to
that same SHA) fits both: the SHA has passed, and ff-only means it is up
to date. A solo owner committing straight to `main` would instead be
blocked until the commit passed on another branch. Same page as F16.

F19. **Requiring a pull request blocks the kit's local fast-forward push
unless the integrator can bypass.** From the rulesets rules page: "If
another protection requires changes to be made through a pull request, you
may also need bypass permissions to push the locally merged commit."
Rulesets also offer "Restrict deletions" (selected by default), "Block
force pushes", "Restrict creations" and "Restrict updates" by branch-name
pattern, and bypass lists of roles, teams or apps.
https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
(accessed 2026-09-27; no page date).

F20. **Rulesets layer; the most restrictive rule wins; anyone with read
access can see them.** "Multiple rulesets can apply to the same branch at
the same time, while only one branch protection rule applies." "If the same
rule is defined in different ways across the aggregated rulesets, the most
restrictive version of the rule applies." "Anyone with read access to a
repository can view its active rulesets." Same page as F16 (about
rulesets). The last point means a contributor could check protection
without admin rights, but only through the API or web UI; the kit denies
`gh api`.

### Local analysis (kit at `fe10015`)

F21. **The model is fixed in text in five places and in two checks.**
Text: `AGENTS.md` Git rules (template line 45), `.sw/collaboration.md`
"Branches", `.sw/workspace.md` "Assignment and result contract" (worktree
sentence), `docs/decisions.md` ("Turn off OpenCode Desktop automatic
worktrees"), and `sw user add`'s printed `git switch -c
<name>/<name>-worktree origin/main`. Checks: `Test-SwDoctor` warns unless
the current branch is `main` or `<user>/<user>-worktree`
(`Sw.Project.psm1` line 715); `Test-SwProject` asserts that `worker` roles
deny `git switch main`, `git branch probe` and `git worktree add probe`
(line 377). No rationale for "no task branches" is recorded in
`docs/decisions.md`. Local evidence.

F22. **Solo and team are already distinguishable from config: `users`.**
`Add-SwUser` appends to `users` in `.sw/config.json` and creates
`inbox/<name>/`; `init` writes `users: []`. Doctor reports "Recorded:
none" when it is empty. This repository has `users: []`, one committer
in the last 20 commits (`BiscuitDoesStuff`), a single local branch `main`,
and commits straight to `main`. That matches F1's "very small teams may
commit direct to the trunk", and doctor accepts it ("current branch" OK on
`main`), but `.sw/collaboration.md` "Branches" says "Each contributor
works, commits, and publishes only on their own branch", and "Integrate"
assumes a contributor branch. The text, not the practice, is what is
incomplete. Local evidence.

F23. **Shared versus local today.** Committed and shared: `.sw/config.json`
(profile, `githubTier`, `users`), `.sw/manifest.json` (`kitVersion`, file
hashes), the project CLI copy `.sw/sw.ps1` and `.sw/lib/`, `AGENTS.md`,
`.opencode/agents|commands|skills`, `opencode.jsonc`, and `.sw/comms/`.
Git-ignored and per person: `.opencode/opencode.jsonc` (tier map),
`.claude/` (the generated Claude adapter), `.sw/backup/`. So a Claude user
and an OpenCode user share every rule and record, and differ only in
generated or personal files. Local evidence (`git ls-files .sw`,
`.gitignore` managed block).

F24. **Task IDs are free text, so two humans can collide.** `sw comms
event -Task <id>` writes into `tasks/<id>/`; nothing checks that the ID is
unused on `origin/main`. Per F10, two humans who both create `p1-foo` on
different branches get one merged directory with two unrelated
assignments and no conflict. Local evidence (collaboration.md layout;
F10's clean merge of same-directory files).

## 3. Options compared

### Branch model

| Option | Fits | Fights | Kit cost |
| --- | --- | --- | --- |
| a. Keep fixed: `main` + `<user>/<user>-worktree`, ff-only integrate | F1-F2 in effect (one person's short work, merged often; F18 protection fits); F15 enforces one checkout per branch | F3 (branch per change; one open PR per head branch); F5, F7 (agent tools create their own branches) | none |
| b. a, plus an explicit solo mode derived from `users: []` (work on `main`, F1 direct-to-trunk) | this repository's practice (F22); F17 protection | same as a | two sentences in `collaboration.md`, one in `AGENTS.md` |
| c. Configurable pattern: one field, e.g. `"branches": "{user}/{user}-worktree"` (default) or `"{user}/*"` | F3, and agent-tool branches if the owner renames them to fit | F21's deny checks must read the field; F5/F7 names (`worktree-<name>`, Copilot's own) still do not match a `{user}/` pattern | doctor regex, worker deny rules, `user add` text, `AGENTS.md` and `collaboration.md` text, validate, tests, `VERSION` |
| d. Git Town style: list the long-lived branches; everything else is a short-lived task branch (F8) | F1-F3, F5-F7 all at once | the kit's "no task branches" rule and ff-only integrate of one branch per person | as c, plus a delete-after-merge rule and PR-per-task practice |

### Coordination and claims

| Option | Strength | Weakness |
| --- | --- | --- |
| i. Records in git only; the claim is the assignment event integrated to `main` (F11) | works at tier 0 and on every harness; git's ff rule is the arbiter | a claim is invisible until pushed and integrated |
| ii. i plus GitHub issue assignee at tier 1 (F13) | visible before integration | advisory; tier 1 only; a second source of truth unless the record links the issue |
| iii. LFS locks for binary assets (F12) | real server-side lock | LFS only; needs an LFS server; binary files only |

### Protection for `main` (only where F16 allows it)

| Setting | Solo owner | Team |
| --- | --- | --- |
| Block force pushes, restrict deletion (defaults, F17, F19) | yes | yes |
| Apply to admins / no bypass (F17) | yes, or agents with the owner's credentials are unprotected | yes |
| Required status check `validate` from `sw-validate.yml`, strict (F18) | no: blocks direct commits to `main` | yes: fits the ff-only flow |
| Require a pull request (F19) | no | optional; needs the integrator to bypass (F19; classic-rule bypass lists need an organization, F17) or integration through the PR merge button |

## 4. Recommendation

R1. **Keep the fixed model and write down its solo mode (option b); do not
make branches configurable now.** Verdict on the hypothesis "The branch
model becomes configurable": **not yet**. The two real modes are already
distinguishable from `users` (F22), so a new field would duplicate it. A
pattern field (option c) would not make agent-tool branches fit, because
their names are tool-chosen (F5, F7), and it would touch every place in
F21. Revisit when a team asks for task branches or a hosted agent (F6,
F7), and then prefer option d (list the long-lived branches, F8) over a
pattern, since that is the shape the comparable tool uses. Product text:
- `.sw/collaboration.md` "Branches", add: "With no recorded contributors
  (`users` is empty) the owner works on `main` directly; the integrate
  flow is not needed. Once `sw user add` records someone, everyone,
  including the owner, works on their own branch."
- `AGENTS.md` template Git rule: append "(solo projects: `main` only)" to
  the first bullet.
The practice in this repository does not change: it is the solo mode.

R2. **Keep agent-made branches off, and say why in one line.** 05 R5
already adds Claude's worktree options to the "turn off" sentence. Extend
the reason with F5 and F7: every hosted or worktree agent (Claude
`--worktree`, Codex cloud, Copilot cloud agent) creates its own branch per
task, so it is outside this model; a project that wants them needs option
d first. Hosted agents are not blocked by the kit anyway: they run on
GitHub, not through the kit's permissions.

R3. **Coordination: records in git (option i), with three small fixes.**
- Claims: document in `.sw/collaboration.md` that a task is claimed when
  its `assignment` event is on `main`; the ff-only push is the tie-break
  (F11). At tier 1, the assignment may name a GitHub issue and its
  assignee (F13), but the record stays the truth.
- Task-ID collisions (F24): in multi-user projects, task IDs start with
  the owner's user name (`<user>-<slug>`). One sentence; no code. Optional
  later: `sw comms event -Event assignment` refuses when `tasks/<id>/`
  exists on `origin/main`.
- Close races (F10): "close a task only after its last event is on
  `main`", one sentence under "Closing". The merge still preserves files,
  but it stops the summary from missing them.
- `users` conflicts (F10): expected and trivial; `sw user add` is an
  owner-only action, so say "run `sw user add` on `main` (owner)". No
  `union` driver (F14).
- Binary assets (unreal profile): mention `git lfs lock` as the optional
  enforcement of the one-owner rule (F12). Text only.

R4. **Mixed setups: one person runs `update`, as a normal task.** Shared
state is everything committed (F23), so `update` changes the whole team.
Rule for `.sw/collaboration.md` (or `.sw/workspace.md` "Claude adapter"):
"The owner (or a named contributor) runs `sw update` from the kit clone
on their branch as a task, validates, and integrates it like any change.
Others receive it; Claude users then run `sw claude enable` to regenerate
their local `.claude/`, which `validate` reports as drift until they do."
07 R2's downgrade refusal stops an older kit from undoing it. Harness mix
needs nothing new: rules and records are shared; only the tier map and
`.claude/` are local (F23).

R5. **Multi-human session tier: one Leader per human, never shared.**
Cross-session messaging is described only between one user's own
sessions (05-F5), and the desktop surface sees only the sessions that app
runs (05-F6); no source shows it crossing users (**weak**, an absence). Each human runs their own Leader on
their own branch; that Leader assigns only tasks its human owns. Across
humans, coordination travels as files: a message in `inbox/<user>/`, or a
task event, published by push and received by fetch (the existing
"Receive" section), or a GitHub issue comment at tier 1. Extend 05 R4's
"Multi-session work (optional)" paragraph with those two sentences.

R6. **Protect `main` as a human action the kit prints, never runs.**
- Solo (the minimal setting): one branch ruleset (or classic rule) on the
  default branch with force pushes blocked, deletion restricted, and no
  bypass for admins (F17, F19). No required checks or PRs, since both block
  direct commits to `main` (F18, F19).
- Team: add the required status check `validate` from `sw-validate.yml`,
  strict (F18). It fits the ff-only flow because the integrated SHA
  already passed on the contributor branch. Requiring PRs is optional and
  needs the integrator to bypass (F19), so the kit does not recommend it by
  default.
- Availability: on a private repository this needs GitHub Pro or an
  organization plan (F16). This repository is private (F16 probe); see open
  question 1.
- Presentation: a short "Protect main (human, once)" block in
  `.sw/collaboration.md` "Integrate" listing the settings above as web-UI
  steps. `sw doctor` adds one reminder line, like the existing OpenCode
  Desktop line: "Branch protection on main: not checked (needs `gh api`,
  which agents are denied); see .sw/collaboration.md". The kit runs no
  GitHub write and no `gh api` (AGENTS.md).
- Copilot cloud agent users: add Copilot as a ruleset bypass actor only if
  a rule blocks it (F7).

Mapping onto the kit:
- `.sw/collaboration.md` "Branches" (R1 solo sentence, R2 reason),
  "Task events"/"Closing" (R3 claim, ID and close sentences), "Integrate"
  (R6 protection block), "Receive" or `.sw/workspace.md` "Claude adapter"
  (R4), 05 R4's multi-session paragraph (R5).
- `AGENTS.md` template Git rules: R1 parenthesis.
- `product/lib/Sw.Project.psm1` `Test-SwDoctor`: one reminder line (R6).
  No change to `Add-SwUser`, `Test-SwProject` or `Get-SwClaudeFiles`.
- `.sw/config.json`: no new field (R1).
- `product/VERSION` and `product/CHANGELOG.md`: all of the above reach
  installed projects through `update`.
- `docs/decisions.md`: record the branch-model rationale (none exists,
  F21) and the "not configurable yet" verdict, if the owner adopts R1.
- Not kit work: the owner's GitHub protection settings (R6), a human
  action.

## 5. Open questions

Owner answers, 2026-09-27 (via the Leader session):
- Q1: the repository is now public, so protection is available on Free
  (F16 update). Setting the solo ruleset (R6) is a human action.
- Q2: open; the rationale is recorded when `docs/decisions.md` gets the
  branch entry.
- Q3: no hosted agent is planned.
- Q4: text only; no `sw comms event` collision check.
- Q5: yes, per R1.

Questions as submitted:

1. Is this repository on GitHub Free or Pro? On Free, private `main`
   cannot be protected at all (F16); the options are then making it public,
   upgrading, or relying on the local guardrails only (08 R3).
2. Why "no task branches"? No rationale is recorded (F21). If the reason
   was simplicity for non-technical contributors, R1 stands; if it was the
   one-checkout rule (F15), option d would also satisfy it.
3. Is a hosted agent (Copilot cloud agent, Codex cloud) expected in the
   next phase? If yes, option d becomes planned work rather than a
   revisit.
4. R3's task-ID prefix: text only, or also the optional
   `sw comms event` refusal?
5. Should the owner count as a contributor (`sw user add <owner>`) as soon
   as a second person joins, so the owner also stops committing to `main`?
   R1 assumes yes.

## 6. Supersedes / updates

- Updates 05 R4: adds the multi-human half (R5 here).
- Updates 05 R5: adds Codex cloud and Copilot cloud agent to the reason
  for the worktree-off rule (R2 here).
- Answers 07 R2's deferred "who runs `update`" (R4 here).
- Makes 08 R3's "branch protection is the real control" concrete, with
  the plan limit it did not note (F16, R6 here).
- Answers the `docs/roadmap.md` hypothesis "The branch model becomes
  configurable": not yet (R1).
