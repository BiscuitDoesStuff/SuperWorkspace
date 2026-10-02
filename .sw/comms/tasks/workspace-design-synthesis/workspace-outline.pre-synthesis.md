# Workspace design rules, assumptions and outline

**Canonical project design register.** Owner requirements below are approved;
architecture recommendations are provisional. Updated 2026-10-01.

## 1. Approved direction

The owner clarified these requirements directly in the current session;
[execution record](../.sw/comms/tasks/workspace-state-review/2026-10-01T222130Z-leader-assignment.md).

| ID | Requirement | Authority and revision |
| --- | --- | --- |
| D1 | **Workspace must be based on the research in sibling `AI-Research [2]`.** Use its findings, current claims register, qualifications and corrections to inform design; do not retrofit findings around an assumed kit architecture. | Owner requirement. New evidence can revise recommendations; changing this requirement is an owner decision. |
| D2 | **Everything in this project can be modified, overhauled or replaced based on new research/data.** This includes instructions, rules, assumptions, kit sources, generated files, roles, harness choices, architecture, layouts and tooling. Nothing is privileged merely because it already exists or is kit-managed. | Owner requirement. An approved change can retain, revise or replace any project component. This is changeability, not authorization to make every change now. |
| D3 | **Document every identified rule or assumption that materially shapes Workspace, preferably here in one document.** Identify its source, status, limits and revision trigger; do not silently treat an inherited preference or uncertain inference as a requirement. | Owner requirement. Add newly identified shaping constraints here; the owner can revise the register or its organization. |

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
| O2 Installed base | SuperWorkspace 0.3.0-dev; generic profile, solo `users: []`, GitHub tier 0; OpenCode default Leader. | [Config](../.sw/config.json), [manifest](../.sw/manifest.json), [OpenCode configuration](../opencode.jsonc). These describe installation, not target requirements. | Any separately approved refit can change or replace the base/profile/harness. |
| O3 Generation | Kit sources currently live in `project/`, `lib/`, `global/` and `sw.ps1`; installed definitions are manifest-managed. Avoid silent competing copies while this generator is used. | [AGENTS](../AGENTS.md), manifest, workspace guidance. Source-generation consistency is conditional on retaining that mechanism. | Change upstream sources or explicitly migrate/replace the generator; no permanent kit-preservation rule. |
| O4 Context ownership | Read Startup, inspect Git and relevant files, reconcile authorization before meaningful work; load detail/skills on demand. State and task records have distinct owners. | AGENTS; [skills](../.agents/skills/); [commands](../.opencode/commands/). No demonstrated universal task-success gain from this file scheme. | Approved context/continuity changes, measured loading failures or representative-task evidence. |
| O5 Scope and effects | Only approved work executes; a plan covers routine execution/checks/corrections, not new scope. No automatic installs, dependencies, external access or global configuration changes. | AGENTS and workspace guidance; this task authorizes documentation only. Research is advice, not permission. | Owner approves a bounded change and any consequential effects; global/session limits still apply. |
| O6 Change method | Preserve unrelated/uncommitted work and working behavior; reuse first, smallest independently testable change; avoid speculative refactors. | AGENTS and `minimal-change` skill; an execution method, not a veto on an approved overhaul. | An approved replacement/refit defines broader scope, preservation/migration and acceptance. |
| O7 Roles/access | Leader coordinates; nine installed project roles have assigned responsibilities, tool access and read-only/Markdown boundaries. Workers do not spawn teams; research dispatch is request-scoped. | [Agent definitions](../.opencode/agents/), [roles source](../project/roles.json), workspace guidance. Role count and names are inherited, not experimentally selected. | Owner-approved orchestration/access redesign; do not bypass current role restrictions meanwhile. |
| O8 Coordination | Explicit task/checkout/path ownership, dependencies and acceptance; independent reads may overlap; writers serialize unless disjoint; parallel project-workers use assigned separate worktrees. One validation owner per checkout. | Agent definitions and workspace guidance. Child sessions do not isolate files. No fixed delegation requirement for every task. | Measured coordination need or failure; approved change must address shared-state/ownership risks. |
| O9 Tiers/budgets | Project planning/execution lanes, escalation rubric, three-failure/new-evidence rule, quota stop, no mid-session model switch. Startup budget is 12,100 bytes. | Workspace guidance, config and global/session instructions. Local tiers are unconfigured; documented tiers do not prove actual child routing. Global harness guidance may add routing constraints. | Approved routing/budget change after task-level evidence; session-imposed limits require changes outside this repo. |
| O10 Cost/data setup | Free-first; no metered spend without opt-in. Model mappings and credentials stay local; shared files avoid machine paths/provider pins. | Workspace guidance, validation contracts and global/session rules. These are current policy/portability choices, not evidence that cheapest-token models are best. | Owner-approved cost/data/portability policy; check actual terms and task-level effort first. |
| O11 Runtime configuration | Current configuration enables compaction (50k recent-token preservation, 32k reserve), watcher exclusions, RTK rewriting and context7 MCP. No optional Claude adapter is configured. | OpenCode configuration and [plugin](../.opencode/plugins/rtk.ts). Settings/plugin presence does not establish savings, compatibility, effective loading or trust. | Evidence of task/context/tool failure or an approved harness/tool change; verify versions and destinations. |
| O12 Safety | No credential probing or denied-action bypass. `.env` access prompts, per-role permissions and shell-pattern guardrails are distinct from isolation. Execution roles have host-user shell authority. | Agent frontmatter, workspace guidance and global/session controls. OpenCode has no configured sandbox; permission modes are not certified injection defences. | Approved threat-model/access/isolation change; project edits cannot disable external tool restrictions. |
| O13 Git/publication | Current solo work is on `main`; team branches are owner-designated contributor branches. No task/automatic branches, force-push, hard reset, clean, stash or discarding work. Commit only on request; agents never push; human publication/integration. | AGENTS, collaboration, global/session rules; tier 0 GitHub access is read-only. No research selects this branch/publication model. | Owner-approved project workflow revision, while session publication/data-loss constraints still apply. |
| O14 Records/review | Existing task events carry approval, progress, ownership and exact evidence; current append-only/author rules protect history. Resume reconciles records with Git. Planned review runs automatically and stays advisory. | Collaboration, agent definitions, task-handoff/review skills. Complete, committed and published are separate states. | Approved record/review migration can revise this mechanism; no silent history rewrite or duplicate memory ledger in the meantime. |
| O15 Checks | Docs: `sw validate` and `git diff --check`; code: discover build/type check, targeted tests then suite, actual manual checks only when available. Static/discovery/permission evaluation/workflow/review evidence stays separate. | AGENTS generic profile and workspace verification ladder. Untracked Git diffs and known ordinary-project-doc coverage gaps need explicit checks. | Approved validation change or demonstrated coverage gap; report unavailable checks rather than claim them. |
| O16 Optional capabilities | Other profiles, harness adapters, persistent memory, network exposure/connectors and remote setup are not enabled or authorized by their availability. | State, workspace guidance and inherited [remote-access procedure](remote-access.md). That procedure's target state is an optional kit example, not this project's adopted network design. | Concrete owner-selected need, permitted data and separately approved acceptance/security scope. |

## 4. Evidence-informed proposals, not a selected architecture

References E5-E7 name local corpus reports below; claim IDs resolve in its current
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

## 5. Assumptions and decisions still open

| ID | Unresolved assumption / decision | Source / limit | Resolution trigger |
| --- | --- | --- | --- |
| U1 | Whether to retain, refit or replace SuperWorkspace, OpenCode, the role roster, file layout, tier rubric or branching model. | Existing implementation plus D1/D2; no inspected comparative evidence establishes these as the best architecture. | Evidence-led design proposal and owner decision, not inheritance. |
| U2 | Intended workloads, data sensitivity, acceptance outcomes, cost/effort limits and target harnesses. | O1 is broad; no application workload was selected by this task. | Owner clarification when it materially affects a design choice; not a prerequisite to documenting research. |
| U3 | Actual runtime loading, routing, enforcement and resume behavior. | Workspace setup was statically checked; doctor has a recorded launcher failure; local tiers are unconfigured. | Separately approved diagnosis/runtime checks. CLI repair is not a mandatory precursor to design work. |
| U4 | Independent recovery baseline and migration/removal requirements. | Workspace has no commits; corpus same-disk backup is not independent recovery. Full lifecycle preservation has not been demonstrated. | Owner chooses recovery/migration scope; no automatic commit, backup, cleanup or removal. |
| U5 | Complete updated design synthesis across the research corpus. | Earlier outline used an incomplete Pass 7 snapshot. This phase inventories rules and selected implications; it does not compare every design alternative or audit all originals. | A separately scoped synthesis/design task using current report/register/review evidence. |

## 6. Research provenance and freshness

**Source:** sibling `AI-Research [2]`, read-only in this task. Locators below are
relative to that corpus, not Workspace paths or redistributed evidence.

| Ref | Corpus-relative source |
| --- | --- |
| E5 | `docs/research/workspaces-05.md`, especially sections 2.1-2.7; use current claims-register notes rather than frozen grades alone. |
| E6 | `docs/research/workspaces-06.md`, sections 2.1-2.6; later corrections are in `docs/research-claims.md` and the Pass 7 review. |
| E7 | `docs/research/frontier-breadth-07.md`, sections 2.1-2.6; `.sw/comms/tasks/frontier-breadth-07/2026-10-01T185724Z-leader-review.md` and `2026-10-01T191500Z-leader-closure.md`. |
| Register | `docs/research-claims.md`; reviewed Pass 7 adds C163-C221 and dated notes on earlier claims. |
| Broader context | `docs/research/initial-pass-overview.md`, `cross-dossier-synthesis.md`, `ai-research-foundation.md`, `frontier-depth-03.md` and cumulative `ai-engineering-landscape.md`; earlier outline source map is historical navigation, not a refreshed synthesis of these files. |

The [v0.2 reference](workspace-outline-v0.2.md) remains the historical outline
authored from the 08:50:45 UTC snapshot and 09:03 UTC recheck on 2026-10-01.
Its preliminary Pass 7 status and preserve-base premise are not current design
authority. The corpus now records reviewed closure at **19:15 UTC**, including
corrections narrowing C173 and qualifying C190. The frozen report's pending-review
header is stale; the review/closure and current register govern that status.

This documentation phase read local reports and review/closure records, not all
original studies or private ModelAnalysis inputs. It ran no new research, source
audit, corpus integrity checks or Workspace runtime tests. Corpus reported checks
are not checks performed here. Independent review did not read every source;
prices C194-C195 remain unchecked by that review, and several dates/published
versions and manifest locators remain unresolved. Older archive/review limits
are retained in the historical reference and current corpus records, not certified
away by this document. Evidence remains local-only/no-redistribution.

## 7. Next action and change discipline

The three owner requirements are now the design direction. Current controls are
visible and revisable; provisional implications and unresolved choices are not
implementation approval. No compulsory keep-kit/readiness/expansion sequence is
adopted. Any next task needs its own outcome, scope, ownership and acceptance.

When evidence or owner direction changes a shaping rule/assumption, update its
entry, explain what it supersedes, and align the actual controlling files within
the approved scope. Keep historical evidence distinguishable from current policy.
For a future design synthesis, assess retain/refit/replace on equal footing rather
than requiring changes to preserve the inherited kit.
