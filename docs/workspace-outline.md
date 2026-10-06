# Workspace design rules, assumptions and outline

**Canonical project design register.** Owner requirements below are approved;
architecture recommendations are provisional. Updated 2026-10-02 (UTC).

## 1. Approved direction

The owner clarified these requirements directly in the current session;
execution record (local task record `workspace-state-review/2026-10-01T222130Z-leader-assignment.md`).

| ID | Requirement | Authority and revision |
| --- | --- | --- |
| D1 | **Workspace must be research-based.** Use the owner's research findings, current claims register, qualifications and corrections to inform design; do not retrofit findings around an assumed kit architecture. | Owner requirement. New evidence can revise recommendations; changing this requirement is an owner decision. |
| D2 | **Everything in this project can be modified, overhauled or replaced based on new research/data.** This includes instructions, rules, assumptions, kit sources, generated files, roles, harness choices, architecture, layouts and tooling. Nothing is privileged merely because it already exists or is kit-managed. | Owner requirement. An approved change can retain, revise or replace any project component. This is changeability, not authorization to make every change now. |
| D3 | **Document every identified rule or assumption that materially shapes Workspace, preferably here in one document.** Identify its source, status, limits and revision trigger; do not silently treat an inherited preference or uncertain inference as a requirement. | Owner requirement. Add newly identified shaping constraints here; the owner can revise the register or its organization. |
| D4 | **Install a tailored manager instance at the WS root, keeping the three projects independent.** Root owns cross-project planning/communication; bounded OpenCode session control first, Claude native/manual handoffs initially. No root Git repository or inherited default-agent/model override. Existing sessions opt in; project execution/research need their own approvals. | Owner approved the conversational plan, recorded in ws-manager (local task record `ws-manager/2026-10-04T051621Z-leader-assignment.md`). Installation/offline validation do not authorize live model calls. |

These supersede the earlier outline's preserve-base design premise. Preservation
within a bounded task protects unrelated work; it does not make any component
permanent. The external research corpus is a source, not part of this project's
changeable assets, and this task does not authorize editing or redistributing it.

## 2. How to use this register

- **Approved requirement (D):** directly specified by the owner above.
- **Current control (O):** an operative project/harness rule or installed choice,
  not necessarily a research-supported target design. Follow it until changed.
- **Provisional proposal (P):** an evidence-informed interpretation, not adoption.
- **Unresolved assumption (U):** missing evidence or a decision still required.
- **Synthesis decision (S):** an owner-directed or owner-confirmed design decision from the U5
  synthesis, with its evidence and open sub-points. It sets design direction;
  it does not by itself authorize implementation.

This is the single design-review view, not a second implementation of permission
patterns or a task/status ledger. [AGENTS](../AGENTS.md) applies project policy;
[state](workspace-state.md) owns implementation and authorization;
[workspace guidance](../.sw/workspace.md), [collaboration](../.sw/collaboration.md)
and the configuration linked below contain current operational detail.
For each change, revise the relevant register entry and its actual controlling
source together. No proposal, research update or recorded gap starts work by itself.

Project-owned controls can be replaced through an approved scope. Global/session
instructions and tool restrictions can also shape execution, but are outside this
repository: changing a project document cannot override or bypass them. Where a
control is enforced, a guardrail or merely stated, retain that distinction; static
documentation does not prove runtime behavior.

## 3. Current controls and inherited choices

The inventory below covers the identified material shaping constraints. Exact
permission cases and role procedures remain in the linked implementation; their
presence is not evidence that this design is optimal.

| ID / area | Current rule or assumption | Provenance, applicability and limits | Revision trigger / authority |
| --- | --- | --- | --- |
| O1 Purpose | Reusable, generic AI workspace for bounded project work. No particular application workload is selected. | Existing project brief and generic profile; a working scope, not a research-proven taxonomy or architecture. | Owner clarifies intended workloads; compare design against those needs. |
| O2 Installed base | SuperWorkspace 0.3.0-dev; v1 research profile + provider-setup, solo `users: []`, GitHub tier 0; OpenCode default Leader. | [Config](../.sw/config.json), [manifest](../.sw/manifest.json), [OpenCode configuration](../opencode.jsonc); local P2 opt-in (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`). These describe installation, not target requirements. | Any separately approved refit can change or replace the base/profile/harness. |
| O3 Generation | Kit sources currently live in `project/`, `lib/`, `global/` and `sw.ps1`; installed definitions are manifest-managed. Avoid silent competing copies while this generator is used. | [AGENTS](../AGENTS.md), manifest, workspace guidance. Source-generation consistency is conditional on retaining that mechanism. | Change upstream sources or explicitly migrate/replace the generator; no permanent kit-preservation rule. S2 sets the target (refit around S1 layers); this stays the current control until a scoped refit. |
| O4 Context ownership | Read Startup, inspect Git and relevant files, reconcile authorization before meaningful work; load detail/skills on demand. State and task records have distinct owners. | AGENTS; [skills](../.agents/skills/); [commands](../.opencode/commands/). No demonstrated universal task-success gain from this file scheme. | Approved context/continuity changes, measured loading failures or representative-task evidence. |
| O5 Scope and effects | Only approved work executes; a plan covers routine execution/checks/corrections, not new scope. No automatic installs, dependencies, external access or global configuration changes. | AGENTS and workspace guidance; this task authorizes documentation only. Research is advice, not permission. | Owner approves a bounded change and any consequential effects; global/session limits still apply. |
| O6 Change method | Preserve unrelated/uncommitted work and working behavior; reuse first, smallest independently testable change; avoid speculative refactors. | AGENTS and `minimal-change` skill; an execution method, not a veto on an approved overhaul. | An approved replacement/refit defines broader scope, preservation/migration and acceptance. |
| O7 Roles/access | Leader coordinates and plans inline; installed roles since 2026-10-02 (S2): `explore`, `project-review`, `project-developer` (single executor, also validation, docs and assigned-worktree work) and `project-research` (now selected through the research preset). Roles have assigned responsibilities, tool access and read-only/Markdown boundaries. Workers do not spawn teams; research dispatch is request-scoped. | [Agent definitions](../.opencode/agents/), [roles source](../project/roles.json), workspace guidance. Role count follows S2 (evidence-informed, not experimentally selected); five inherited roles were removed in `workspace-roster-refit/`. | Owner-approved orchestration/access redesign; do not bypass current role restrictions meanwhile. profile-selection-v1 (local task record `profile-selection-v1/2026-10-05T042035Z-leader-closure.md`) adds generator selection; Workspace P2 opt-in (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`) completed locally/uncommitted 2026-10-05 with the same roster/eight skills. Installed selection is not runtime loading evidence. |
| O8 Coordination | Explicit task/checkout/path ownership, dependencies and acceptance; independent reads may overlap; writers serialize unless disjoint; parallel executor work uses Leader-assigned separate worktrees; the executor's branch and worktree Git commands require approval (`ask`, contract-checked). One validation owner per checkout. | Agent definitions and workspace guidance. Child sessions do not isolate files. No fixed delegation requirement for every task. | Measured coordination need or failure; approved change must address shared-state/ownership risks. |
| O9 Tiers/budgets | Project planning/execution lanes, escalation rubric, three-failure/new-evidence rule, quota stop, no mid-session model switch. Startup budget is 12,100 bytes. | Workspace guidance, config and global/session instructions. Owner-selected temporary developer/reviewer local models were checked in bounded workspace-v1 acceptance (2026-10-03); other roles/routes remain unconfigured or unverified. This is not a tier-fit benchmark. Global harness guidance may add routing constraints. | Approved routing/budget change after task-level evidence; session-imposed limits require changes outside this repo. |
| O10 Cost/data setup | Free-first; no metered spend without opt-in. Model mappings and credentials stay local; shared files avoid machine paths/provider pins. Owner requirement (2026-10-02): every installing user configures their own tools, models and accounts locally. | Workspace guidance, validation contracts and global/session rules. These are current policy/portability choices, not evidence that cheapest-token models are best. | Owner-approved cost/data/portability policy; check actual terms and task-level effort first. |
| O11 Runtime configuration | Current configuration enables compaction (50k recent-token preservation, 32k reserve), watcher exclusions, RTK rewriting and context7 MCP. No optional Claude adapter is configured. | OpenCode configuration and [plugin](../.opencode/plugins/rtk.ts). Settings/plugin presence does not establish savings, compatibility, effective loading or trust. | Evidence of task/context/tool failure or an approved harness/tool change; verify versions and destinations. |
| O12 Safety | No credential probing or denied-action bypass. `.env` access prompts, per-role permissions and shell-pattern guardrails are distinct from isolation. Execution roles have host-user shell authority. | Agent frontmatter, workspace guidance and global/session controls. OpenCode has no configured sandbox; permission modes are not certified injection defences. | Approved threat-model/access/isolation change; project edits cannot disable external tool restrictions. |
| O13 Git/publication | Current solo work is on `main`; team branches are owner-designated contributor branches. No task/automatic branches, force-push, hard reset, clean, stash or discarding work. Commit only on request; agents never push; human publication/integration. | AGENTS, collaboration, global/session rules; tier 0 GitHub access is read-only. No research selects this branch/publication model. | Owner-approved project workflow revision, while session publication/data-loss constraints still apply. |
| O14 Records/review | Existing task events carry approval, progress, ownership and exact evidence; current append-only/author rules protect history. Resume reconciles records with Git. Planned review runs automatically and stays advisory. | Collaboration, agent definitions, task-handoff/review skills. Complete, committed and published are separate states. | Approved record/review migration can revise this mechanism; no silent history rewrite or duplicate memory ledger in the meantime. |
| O15 Checks | Docs: `sw validate` and `git diff --check`; code: discover build/type check, targeted tests then suite, actual manual checks only when available. Static/discovery/permission evaluation/workflow/review evidence stays separate. | Current AGENTS research profile/capability and workspace verification ladder. Untracked Git diffs and known ordinary-project-doc coverage gaps need explicit checks. | Approved validation change or demonstrated coverage gap; report unavailable checks rather than claim them. |
| O16 Optional capabilities | Other profiles, harness adapters, persistent memory, network exposure/connectors and remote setup are not enabled or authorized by their availability. | State, workspace guidance and inherited [remote-access procedure](remote-access.md). That procedure's target state is an optional kit example, not this project's adopted network design. | Concrete owner-selected need, permitted data and separately approved acceptance/security scope. |
| O17 Root manager | Separate non-Git installation, namespaced agents, project registry, immutable structured coordination events, exact native IDs, one session owner, explicit human approval and 1-20 message reservations. Planner denies shell/edits/delegation/external research; manager cannot grant its own approval. | [Manager source](../lib/Sw.Manager.psm1), [operator contract](../project/manager/manager.md), [offline tests](../tests/manager.ps1). These are bounded implementation choices, not evidence of runtime enforcement, semantic scope certification or an OS sandbox. Child project defaults remain unchanged; no root-wide model/provider/default-agent settings. | Owner-approved manager change and task-level validation; native API/routing/policy require separate live acceptance. |

## 4. Evidence-informed proposals, not a selected architecture

References E4-E8 name local corpus reports below; claim IDs resolve in its current
`docs/research-claims.md`, including later corrections. These are bounded design
interpretations. Neither research nor kit packaging selects an optimal Workspace.

| ID / area | Provisional direction | Evidence and limitation | Reconsider when |
| --- | --- | --- | --- |
| P1 Context/prompting | Keep necessary authority/constraints discoverable; test task/model-specific guidance rather than presume longer files, personas or prompt rituals improve outcomes. | E5 C112-C115: Python-task context-file success nulls, conflicting cost effects, model-specific tuning. E6 C152/C160-C161 are qualified. E7 C186-C193 do not establish prompting effects on models released in 2026; C111 remains a gap. | Representative-task or newer controlled evidence changes the trade-off. |
| P2 Orchestration | Choose inline/single-agent work or bounded delegation according to task decomposition and observed effort, not an obligatory roster or team framework. | E5 C089/C121: no general matched-compute multi-agent gain; task-dependent benefits remain. Spec-detail/workflow results C091/C153 are qualified, not a universal spec-first requirement. | A demonstrated coordination/decomposition need or matched-condition comparison. |
| P3 Models/cost | Compare model, harness, effort and tools as a configuration; measure successful-task cost and human correction effort, not token price alone. | E7 C164/C167-C168: leakage, run variance and harness effects; C197-C198: effort/token use affect cost per task. C202: measured agent total cost beyond tokens remains a gap. Benchmark cost is not the owner's workload cost. | Actual workload, versions, pricing/terms or accepted budget changes. No provider/model chosen here. |
| P4 Verification | Prefer executable outcome/constraint checks; record configuration and uncertainty. Validate any model judge against task-specific human labels and allow unknown results. | E7 C173-C185: criterion/dataset dependence and judge-specific biases; workspace/coding-trajectory judge efficacy C108 remains a gap. Small score gaps are not reliable single-run proof. | A chosen acceptance case or demonstrated need for a calibrated judge. No evaluation platform is adopted. |
| P5 Memory | Keep authoritative state distinguishable from retrieval; compare simple files/retrieval/full context before adding a memory service. Define provenance, write authority and correction/expiry for any persistence. | E5/E6 C076-C079/C117-C119: poisoning, staleness, mixed superiority and write-cost trade-offs; coding-file-memory efficacy remains a gap. Some adaptive defences retain bypass; no general safety guarantee. | Demonstrated retrieval/update failure and a bounded comparison with simpler baselines. |
| P6 Extensions/safety | Treat skills/plugins/MCP and supplied instructions as trust surfaces. Evaluate provenance, privileges, destinations, cost and recovery; don't mistake prompt rules for isolation. | E5/E6 C082/C088/C101-C102/C141-C156: differing risk measures and attacker positions; no approval-enabled skill exploit study or certified repository/tool-injection defence. Protocol portability is not compatibility certification. | Concrete missing capability or threat model, with approved harmless tests and controls. |
| P7 Value | Evaluate accepted outcomes, quality, rework and sustained utility—not agent count, survey popularity or generated output alone. | E7 C205-C212: self-selected/vendor-recruited survey trends, not population estimates. C213-C221: short-run field output gains, unresolved persistence and mixed controlled findings; no universal productivity promise. | Owner selects intended outcomes and appropriate observation horizon. |
| P8 Lifecycle/portability | Compare keeping, refitting and replacing components on evidence. Make preservation/recovery/loading tests proportionate to the chosen change. | E5/E6: differing harness loading/truncation semantics; C104 Windows reproducibility/removal remains a gap. Workspace manifest integrity does not establish whole-project recovery. | Approved lifecycle/harness change; source/adapter preservation is not an automatic preference. |

## 5. Design synthesis (U5, in progress)

Started 2026-10-02 (UTC) from the reviewed corpus: Passes 4-7 (E4-E7) and the
current claims register, read at corpus commit `5780567`. The reviewed Pass 8
report (E8; corpus tag `archive/2026-10-02-workspaces-08`, commit `1fcbc0d`) was
taken in later the same day: it revises S1's open points and informs S2-S6.
Its s4 maps findings to this register as recommendations. S1 and S2's harness,
roster and generator rows record owner answers; S2's tier and branching rows and
the S3-S6 contents were drafted by the Leader from E8 s4 and confirmed by the
owner on 2026-10-02. Grades are as in the corpus register at that tag. Each entry is
design direction; changing current controls (section 3) needs its own approved
scope; task record (local task record `workspace-design-synthesis/`).

### S1 Shared core plus per-project-type profiles

**Decision.** Workspace is one shared core plus a profile per project type
(coding and research are examples, not a fixed set). Source: the owner's stated
use, "an all-purpose workspace, that can be heavily adapted to fit the specific
project type" (corpus `.sw/comms/tasks/workspaces-08/2026-10-02T000100Z-leader-submission.md`),
and the owner's direction to start U5 with this decision. This is a design
direction, not research-proven superiority over alternatives.

**Layering rule.** A profile adds or narrows; it never loosens core controls.
Where layers conflict, the stricter rule applies to safety, approval, Git and
publication, and to data handling.

| Layer | Contents | Register links |
| --- | --- | --- |
| Core | Authority and approval; change method; Git and publication; task records and handoff; the shape of the validation contract (report exact checks, keep result kinds separate); safety and trust boundaries; cost/data portability policy. | O4-O6, O10, O12-O15; P6 |
| Profile | Validation commands and acceptance outcomes; which skills, context and instructions load; which roles are used; data sensitivity; project-type checks and evaluation cases. | O1, O7, O15; P1, P4, P7; U2 |
| Harness adapter (separate axis) | Per-harness loading files and settings. Not a profile: it varies by harness, not project type. | U1, O16, P8 |

**Evidence and how it shapes S1** (grades as in the current register):

- *Keep the core small; add profile guidance only for observed need.* Ordinary
  context files gave no task-success gain on Python tasks (C112, replicated
  direction, no non-Python study) and grow over a repository's life (C116,
  qualified). Tuned guidance helped one model and hurt another (C114, qualified),
  so profile guidance is per task and model and should be tested, not assumed.
- *Expect compliance to fall over a session.* C115 and C160 (both qualified)
  report declining instruction compliance as sessions lengthen. Hard core rules
  should be enforced by hooks, permissions or validation where available, not
  prose alone (E4 recommendation 3; the vendor advice in E4 s2.2 that
  instruction files are context, not enforcement, is declared only; see S4).
- *Layering semantics differ by harness.* Loading order, concatenation and
  instruction and settings precedence vary (C068, C146, C150, all declared).
  Truncation and silent drops exist (C147, C151, qualified), so each layer needs
  a size budget and loading must be verified from logs, not model answers (C069
  observed; C070 shows loading only; E4 recommendation 2). Cross-harness reading beyond AGENTS.md is declared, not
  demonstrated (C067).
- *Profiles do not imply more agents.* Role choice per profile follows P2: no
  general matched-compute multi-agent gain (C121, replicated direction; C089
  contradicted).
- *Non-code profiles lack outcome evidence.* Skills and shared spaces are
  spreading beyond code (E4 s2.7, declared), but whether knowledge workspaces
  improve non-code outcomes is a gap.
- *The workspace must supply the layering (E8).* No inspected harness documents
  a project-template feature (C233, declared; no template feature found); only Codex has named profiles, as file
  overlays; OpenCode and Claude Code layer by scope only (C233, declared). No
  empirical study of layering was found.

**Open points (revised 2026-10-02 with E8):**

- *Layering mechanism: decided.* A refitted generator produces the layers (S2).
  Inspected harnesses offer no templates, and only Codex has named profiles
  (C233), so the workspace supplies the layering (E8 s4 rec. 7); plain files
  would need hand-syncing per harness. Each layer's
  output must still be mapped to each harness's precedence (C068, C146, C150).
- *Size budgets and loading checks: partly settled.* Profile skills: one to
  three short ones (S6). Core constraints that must survive compaction live in
  files the harness re-injects (S5; C253). Numeric byte budgets per layer and
  harness remain open until the harness is chosen (U1); loading is verified from
  runtime logs, not model answers (S1 evidence above; C069), as a runtime check under U3.
- *Which profiles first, and their acceptance outcomes:* still open (U2). Each
  profile's acceptance cases follow S3.
- *Generic profile and `.sw/profile.json`:* their mapping to S1 is part of the
  S2 generator refit; that migration needs its own approved scope.

### S2 U1 partial resolution: roster, generator, harness criterion

**Current implementation update (2026-10-03, workspace-v1):** the
bounded owner approval (local task record `workspace-v1/2026-10-03T063903Z-leader-approval.md`)
now authorizes the launcher, superseding the older "not yet approved" table
wording below without erasing its history or the older uncommitted proposals.
P1 maps actual local worker models, imports canonical root rules with
`@../AGENTS.md` relative to `.claude/CLAUDE.md` (the historical `@AGENTS.md`
draft is not the implemented import), shares Git guardrails, and removes Bash
from the Claude reviewer. P2 provides one manual `sw session start` control
entry: explicit primary model, actual worker map, safe argv, OpenCode `mini`/`run`
or interactive Claude, current-adapter prechecks and immutable metadata events.
Mixed maps do not create cross-harness dispatch; non-Claude Claude commands STOP.
Parser/module and 226 offline assertions pass; native stubs are not runtime
loading, served-model, access, isolation or permission proof. P2 stopped at its
worker usage limit; the Leader reconciled and reran its offline checks. The owner
then selected an existing free OpenCode route and a temporary ignored two-role
map. P3 independent review ran; its variable-assignment finding was rebutted.
Owner accepted the conservative read-only shell-denial/API discrepancy as a known
limitation; no bypass or permission relaxation. P4 engineering artifact/checkpoint,
distinct fresh-session/hash reconciliation, six value/six Int64 tests and final
read-only artifact review passed on the selected headless OpenCode route. Claude
adapter absent; all four live starts used. This does not validate other routes,
interactive use, compaction, security isolation or empirical benefits. Exact evidence
belongs to workspace-v1 records (local task record `workspace-v1/`), not this
design register. The bounded v1 was published through the approved human
integration (push receipt (local task record `workspace-publication/2026-10-03T095714Z-leader-receipt.md`),
hosted-CI closure (local task record `workspace-publication/2026-10-03T100114Z-leader-closure.md`));
work after that integration, including the workspace-v1 review repairs
([state](workspace-state.md)), stays local until a human publishes it. No broader research-led overhaul is authorized by
this implementation.

| Component | Decision | Evidence and limits |
| --- | --- | --- |
| Harness | **Revised (owner, 2026-10-02; decision (local task record `workspace-harness-decision/2026-10-02T213000Z-leader-decision-control-surface.md`)): one control surface and one set of task records replace the one-harness criterion. Claude roles run in Claude Code on a subscription login (owner requirement; third-party subscription use barred, C093, C283); other roles run in OpenCode. Effort is not a requirement. The launcher is implemented and accepted on one route (workspace-v1, above).** Earlier: chosen: OpenCode (owner, 2026-10-02, after the U3 hands-on check; decision (local task record `workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md`)).** On the CLI path, only `-m` selects the primary model; the launcher must pass it. Kilo honours agent models but drops Workspace's V2 config without warning. Earlier: shortlisted (owner, 2026-10-02; E9, E10). Option 2: shortlist **OpenCode** and **Kilo**, then a hands-on check (U3) before choosing. Constraint: the harness must be free / open source, so Cursor, Factory Droid and GitHub Copilot CLI are out; Goose is excluded (models per recipe only, C270; thin evidence). OpenCode: per-agent Claude and non-Claude models (C225, C316); caveats: subagent model-override reports (C226, C319), plugins can defeat rules (C317), no OS isolation on Windows (C256). Kilo: sticky model per agent (C303); caveat: a parent can override the subagent model, fix closed not_planned (C304); Windows not inspected. Licences are not in the corpus: confirm from each repo's LICENSE. Claude still needs a subscription or API key; third-party subscription OAuth is unresolved (C283, C329), recheck at decision time. Owner criterion unchanged: Claude models usable in the same harness as every other model and role. | E8 selects no harness. Claude Code and Codex declare per-agent model and effort (C222, C227); OpenCode passes effort to the provider (C225); Copilot has no effort field (C229). Each of Claude Code, OpenCode and Codex has a report of per-agent routing being ignored (C223, C226, C228). Native Windows isolation: see S4. E8 did not examine which harnesses run Claude models alongside other providers, or the provider terms for doing so. |
| Role roster | **Small.** The Leader works inline by default; core optional roles are a read-only explorer, an independent repository-exploring reviewer (S3) and one executor (merging developer, build, documentation and worker). Research is a profile role, enabled by a research profile (S1). Planning and architecture fold into the Leader. Implemented 2026-10-02 except the research profile role (generator refit). Delegate for context isolation or separable work, not by default. Worktrees are file isolation only: serialize writers or check intended changes before parallel writes. | C234 (declared); C235, C236, C243 (qualified, task-dependent, not compute-matched); C121 (replicated direction); C241, C242 (qualified; C242 a feasibility check). No roster-size study exists. |
| Generator and layout | **Refit.** Model-field part implemented and committed 2026-10-02 (approval (local task record `workspace-harness-decision/2026-10-02T183500Z-leader-approval-generator-refit.md`)): no effort output, `validate` rejects effort and `#variant`, launch rules in `.sw/workspace.md`. One source generates the core, profile and per-harness adapter files (S1 layers). The current SuperWorkspace layout gets no preference. | See S1 open points (C233). Skill and instruction locations differ per harness (E8 note on C067; C068, C146, C150). |
| Tier rubric | **Model-only (owner, 2026-10-02; E9 Rec 2).** Tiers name a model, not a per-agent effort setting; Implemented by the generator refit (2026-10-02; committed). On OpenCode `run` only `-m` routes the primary model, so launches pass it. Whatever routing is configured, verify the model per launch path from runtime logs (S4, U3). | C222 alias caveat (E8 review): a family alias can resolve to the main model. Effort is dropped because neither shortlisted harness declares a usable per-agent effort field (OpenCode `#variant` mapping unstated, C316; Kilo not stated). |
| Branching | Retained (O13). No inspected evidence bears on it, and global/session rules also impose it. | None in E4-E8. |

**Decided:** the harness (U1) is OpenCode for non-Claude roles and Claude Code for Claude roles under one control surface (revised 2026-10-02); OpenCode was chosen after the hands-on check under U3
(task (local task record `workspace-harness-decision/`)). Corpus
Passes 9 and 10 (E9, E10) closed the research; no harness was run hands-on. The
roster reduction was approved and implemented the same day
(task (local task record `workspace-roster-refit/`)); `project-research`
becomes a profile role in the generator refit, which emits model fields per
harness and no effort fields (model-field part implemented and committed
2026-10-02); the research profile role is not yet scoped.

### S3 Review and acceptance tests

**Decision.** Use an independent review step for weaker executors and hard,
non-local tasks, with a reviewer that explores the repository rather than
reading only the diff. Budget its token cost and judge it by accepted outcomes,
not review activity (P7). Test configuration changes (instructions, skills,
roles, routing) like small evals: 10-50 cases from real failures (report s4 wording); deterministic
outcome or trace checks first and LLM rubrics only for qualitative checks, with
the judge calibrated (P4); negative controls for skill triggering; several
isolated trials; graduated cases kept as a regression suite.

**Evidence.** Review loops raised SWE-bench Verified resolve rates over
no-review baselines, with gains shrinking as the generator strengthens and a
reviewer stronger than every generator; about 4.5x zero-shot tokens in one
study (C237, qualified, one benchmark lineage). Repository-exploring review beat
diff-only review (C238, qualified). Agent PRs reviewed only by review agents
merged less often than human-reviewed ones (C240, qualified, observational).
The eval practice is vendor and practitioner guidance (C259-C262, declared);
run variance is measured (C167).

**Limits.** No equal-compute baseline for review loops. Whether such suites
catch configuration regressions is unmeasured (C108 gap). This revises O14's
"planned review runs automatically" only once an approved change says so.

### S4 Enforcement and isolation

**Decision.** Hard core rules go in enforced controls (settings, deny rules,
permissions, sandboxes) where the harness has them, not in prose. On Windows,
a hook is not a path boundary until a local acceptance test shows a denied write
is blocked. Shell-pattern denylists are guardrails, not isolation. Plugin-carried
agents do not carry enforcement. Native Windows OS isolation is a comparison
factor for the harness research question (S2 Open), not an owner criterion.

**Evidence.** Vendors declare instruction files advisory and settings, deny
rules, hooks or sandboxes enforced (C230, declared). One Windows desktop report
measured a PreToolUse hook exiting 2 while a subagent write still happened
(C258, qualified, one report, not vendor-confirmed). Denylists were bypassable
in 69.0-98.6% of cases by bypass class (C257, qualified, secondary relay).
Claude Code plugin subagents ignore hooks, mcpServers and permissionMode (C224,
declared). OpenCode ships no OS isolation and allows all in-project actions by
default (C256, qualified); Claude Code's sandbox needs WSL2 (C231). Of Claude
Code, OpenCode and Codex, only Codex declares a native Windows sandbox (C231,
C254); its unelevated fallback limits network only advisorily (C255). A source
survey of 11 harnesses also finds Gemini CLI (C256, qualified).

**Implemented (2026-10-02, committed; owner-approved "harden git rules"; runtime test deferred to workspace completion).**
The generated shell rules now also catch the git/gh prefix bypasses found in the
generator refit review: global flags (`git -C`), compounds, rtk runners, wrappers
(as asks), and `project-review` operator chaining. Checked statically only (618
matrix cases), not at runtime; see the closure (local task record `workspace-harness-decision/2026-10-02T200000Z-leader-closure-git-hardening.md`).
The guardrail limit stands: `$(...)`, wrappers behind a compound and scripts
written to a file still get through.

**Limits.** No shared-attacker comparison of isolation and access control (C102
gap). The hook test and the routing checks (S2 tier row) are runtime work under U3, each needing
its own approval.

### S5 Continuity and compaction

**Decision.** Constraints that must survive compaction live in files the
harness re-injects (its root instruction file) or in task records, not only in
conversation. Keep the task-record, progress and Git pattern. Measure
continuity changes by interaction cost as well as completion. No memory service
is added (P5 stands).

**Evidence.** Compactors kept 17% of conversation-only constraints on average
(C251, qualified; not a shipped harness). Claude Code re-reads project-root
CLAUDE.md after compaction while conversation-only instructions can be lost
(C253, declared). Anthropic's long-running pattern of progress file, JSON
feature list and Git matches the existing records (C250, declared, one demo).
Compression raised interaction cost while completion stayed unchanged (C252,
qualified). No memory substrate dominates (C078 stays contradicted).

**Limits.** No controlled evidence that task records or handoffs improve
continuity (C079 gap). Re-injection is documented here for Claude Code only;
Codex and OpenCode compaction docs were not inspected, and retention in a
shipped harness is untested.

### S6 Skills curation

**Decision.** Each profile gets one to three short, human-curated skills. No
auto-generated skills and no exhaustive procedure. Each skill is tested with
paired with/without runs on the profile's acceptance cases, including negative
trigger controls (S3). The generator emits skills to each harness's location
(S2).

**Evidence.** Curated skills raised mean pass rates across 18 model-harness
configurations (C244, qualified). One to three compact skills did better than
four or more or comprehensive docs; self-generated skills fell below the
no-skills baseline (C247, qualified). Excess procedure caused most efficiency
regressions (C248, qualified). Some skills lower success (C246, replicated
direction); the software-engineering gain is contested in magnitude (C245,
contradicted); token overhead ranged up to +451% (C249, qualified). Skill
directories differ per harness (E8 note on C067).

**Limits.** Mostly one benchmark family; the contrary SWE result used one small
model. No study of non-code profile skills.

## 6. Assumptions and decisions still open

| ID | Unresolved assumption / decision | Source / limit | Resolution trigger |
| --- | --- | --- | --- |
| U1 | Whether to retain, refit or replace SuperWorkspace, OpenCode, the role roster, file layout, tier rubric or branching model. | Existing implementation plus D1/D2; no inspected comparative evidence establishes these as the best architecture. | Evidence-led design proposal and owner decision, not inheritance. **Partly resolved 2026-10-02 from E8 (S2):** small roster and generator refit decided (owner); tier rubric held with the harness and branching retained (owner-confirmed). **Further resolved 2026-10-02 from E9 and E10 (S2):** option 2 chosen (owner): shortlist OpenCode and Kilo under a free / open-source constraint, then a hands-on check; tier rubric is model-only, no effort. **Harness resolved 2026-10-02:** OpenCode (owner), after the U3 hands-on check of OpenCode and Kilo (decision (local task record `workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md`)). |
| U2 | Intended workloads, data sensitivity, acceptance outcomes, cost/effort limits and target harnesses. | O1 is broad; no application workload was selected by this task. | Owner clarification when it materially affects a design choice; not a prerequisite to documenting research. |
| U3 | Actual runtime loading, routing, enforcement and resume behavior. | Workspace setup was statically checked; doctor has a recorded launcher failure (2026-10-01, not rechecked); an ignored local map selects developer/reviewer only. The headless OpenCode route passed bounded live acceptance in Workspace on 2026-10-03 (`workspace-v1/`); Claude, interactive and mixed routes and compaction remain unchecked. Routing and enforcement of OpenCode 2.0.20 and Kilo 7.8.3 were checked in scratch projects on 2026-10-02 (task (local task record `workspace-harness-decision/`)); a bounded fresh-session resume reconciliation passed on the headless OpenCode route only (workspace-v1); instruction loading beyond that, resume on other routes and compaction remain unchecked. | Separately approved diagnosis/runtime checks. CLI repair is not a mandatory precursor to design work. |
| U4 | Independent recovery baseline and migration/removal requirements. | Workspace history is committed and published to `origin` (2026-10-03, publication (local task record `workspace-publication/`)); corpus same-disk backup is not independent recovery. Full lifecycle preservation has not been demonstrated. | Owner chooses recovery/migration scope; no automatic commit, backup, cleanup or removal. |
| U5 | Complete updated design synthesis across the research corpus. | Earlier outline used an incomplete Pass 7 snapshot. This phase inventories rules and selected implications; it does not compare every design alternative or audit all originals. | A separately scoped synthesis/design task using current report/register/review evidence. In progress since 2026-10-02: S1-S6 recorded and owner-confirmed in section 5 (S2-S6 and the revised S1 open points from E8). |

## 7. Research provenance and freshness

**Source:** private research corpus (not redistributed), read-only in
this task. Locators are not Workspace paths or redistributed evidence.

| Ref | Source in the private research corpus (not redistributed) |
| --- | --- |
| E4 | Pass 4 workspaces report, sections 2.1-2.11 and 4 (analyst recommendations, not rules); reviewed and closed. |
| E5 | Pass 5 workspaces report, especially sections 2.1-2.7; use current claims-register notes rather than frozen grades alone. |
| E6 | Pass 6 workspaces report, sections 2.1-2.6; later corrections are in the claims register and the Pass 7 review. |
| E7 | Pass 7 frontier-breadth report, sections 2.1-2.6; reviewed and closed. |
| E8 | Pass 8 workspaces report (archived), sections 2.1-2.5 and 4 (analyst recommendations, not rules); reviewed and closed. |
| E9 | Pass 9 harnesses report (archived), section 3 options table and section 4 Recs 1-8; claims C263-C291. |
| E10 | Pass 10 harnesses report (archived), section 3 options table and section 4 Recs 1-9; claims C292-C330. Summarized for the owner in a local handoff record. |
| Register | Claims register; reviewed Pass 7 adds C163-C221, reviewed Pass 8 adds C222-C262, and Passes 9-10 add C263-C330, each with dated notes on earlier claims. |
| Broader context | Initial-pass overview, cross-dossier synthesis, AI-research foundation, frontier-depth-03 and the cumulative AI-engineering landscape; earlier outline source map is historical navigation, not a refreshed synthesis of these files. |

The [v0.2 reference](workspace-outline-v0.2.md) remains the historical outline
authored from the 08:50:45 UTC snapshot and 09:03 UTC recheck on 2026-10-01.
Its preliminary Pass 7 status and preserve-base premise are not current design
authority. The corpus now records reviewed closure at **19:15 UTC**, including
corrections narrowing C173 and qualifying C190. The frozen report's pending-review
header is stale; the review/closure and current register govern that status.

This documentation phase read local reports and review/closure records, not all
original studies or private data inputs. It ran no new research, source
audit, corpus integrity checks or Workspace runtime tests. Corpus reported checks
are not checks performed here. Independent review did not read every source;
prices C194-C195 remain unchecked by that review, and several dates/published
versions and manifest locators remain unresolved. Older archive/review limits
are retained in the historical reference and current corpus records, not certified
away by this document. Evidence remains local-only/no-redistribution.

## 8. Next action and change discipline

The three owner requirements are now the design direction. Current controls are
visible and revisable; provisional implications and unresolved choices are not
implementation approval. No compulsory keep-kit/readiness/expansion sequence is
adopted. Any next task needs its own outcome, scope, ownership and acceptance.

When evidence or owner direction changes a shaping rule/assumption, update its
entry, explain what it supersedes, and align the actual controlling files within
the approved scope. Keep historical evidence distinguishable from current policy.
For the design synthesis (section 5), assess retain/refit/replace on equal footing rather
than requiring changes to preserve the inherited kit.
