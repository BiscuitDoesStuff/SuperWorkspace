# workspace-harness-decision - handoff - 2026-10-02T045723Z - Leader

- **Author / audience:** AI-Research Project Leader (Claude Opus 5.5, Claude Code desktop), for the next Workspace Leader session and the owner, who takes the U1 harness decision.
- **Approval:** none new. The owner asked for this handoff on 2026-10-02. U1 (harness) is the owner's decision. Nothing here is a selection, an approval or a change to Workspace rules.
- **Status:** ready for decision. The research that U1 waited on is closed and reviewed: AI-Research Pass 9 (`harnesses-09`) and Pass 10 (`harnesses-10`).
- **Branch / base:** Workspace main at `05df1c0`, with the roster refit still uncommitted (see [workspace-roster-refit](../workspace-roster-refit/2026-10-02T021154Z-leader-submission.md)). This file is the only Workspace write. It is local and uncommitted.

## Sources (AI-Research, `C:\DevProjects\AI-Research [2]`)

| Pass | Report | Claims | Tag (resolve for SHA) |
| --- | --- | --- | --- |
| 9 | `docs/research/harnesses-09.md`: s3 options table, s4 Recs 1-8 | C263-C291 | `archive/2026-10-02-harnesses-09` |
| 10 | `docs/research/harnesses-10.md`: s3 options table, s4 Recs 1-9 | C292-C330 | `archive/2026-10-02-harnesses-10` |

The claim register is `docs/research-claims.md`. Every capability is graded *declared* (vendor-stated) unless noted. No harness was run hands-on.

## Decision to make

**U1 / S2 Harness row (open):** which harness hosts the workspace.

The owner criterion is that Claude models run in the same harness as every other model and role, not one harness for Claude and another for the rest.

Linked rows: S2 Tier rubric (effort), S2 Generator and layout (adapter), S4/O12 (Windows enforcement), O2/O9 (verification). The generator refit and the move of `project-research` to a profile role wait on this choice.

## Candidate set on current evidence

| Candidate | Meets criterion (per-agent Claude + non-Claude) | Per-agent effort | Windows | Main caveats |
| --- | --- | --- | --- | --- |
| Cursor | yes (C263) | yes | sandbox docs not current (C272, C273) | staff-confirmed routing override (C264); Auto-review advisory (C274) |
| GitHub Copilot CLI | yes (C265, C314 inferred) | **no** (C229) | OS sandbox preview, Insiders only (C276) | override reports (C266, C315); `preToolUse` fails closed but timeouts open (C311); Claude via Copilot plan or BYOK key (C287, C313); Fable ZDR exclusion (C328) |
| Factory Droid | yes (C267) | yes (C267) | runs natively; isolation is WSL2 only (C278, C323) | hooks fail open on non-2 exits (C320); `block` rules have no approval path (C322); reads AGENTS.md and CLAUDE.md (C321) |
| OpenCode | yes (C225, C316) | `#variant` only, effort mapping unstated (C316) | no OS isolation (C256) | subagent ignored its model (C226, C319); plugins can defeat rules (C317); the Windows deny bypass C280 was a stale plugin, withdrawn by its reporter |
| Kilo (new in Pass 10) | yes, sticky model per agent (C303) | not stated | not inspected | a parent agent can override the subagent model; the fix was closed not_planned (C304) |
| Goose | per recipe (C270) | not documented | none documented (C279) | thin evidence; Pass 10 depth not reached |

**Do not meet the criterion as host:**
- **Claude Code:** Anthropic does not support non-Claude models through it (C269).
- **Per-role or single-subagent-model only:** Amp (C305) and Zed (C307).
- **No documented per-agent model:** Cline (C308).
- **No documented Claude route:** Codex CLI and Gemini CLI (C309, C310).
- **Mid-session switch only:** Crush (C271).
- **Archived:** Roo, on 2026-05-15 (C301).
- **Front end, not a host:** T3 Code (C292-C299). It mixes models only across threads and leaves agents, model and effort to the provider. New threads default to Full access. It could sit on top of the chosen harness as a control surface.

## What the evidence settles and what it does not

- **Settled enough to decide on:** the candidate set above, and that per-agent effort is declared only by Cursor and Factory. Copilot has no effort field. OpenCode's mapping is unstated.
- **Not settled by research:**
  - No candidate has a demonstrated per-launch-path routing result. Every routed candidate has an override report.
  - Windows enforcement rests on single reports.
  - No measured Windows sandbox efficacy exists (C102).
- **Access and billing (as of 2026-06-16):**
  - Third-party app usage draws from Claude subscription limits, and the Agent SDK credit change is paused (C324).
  - No primary Anthropic page authorizes or bans a specific client (C325, C326).
  - OAuth forwarding through a gateway is unresolved against C093 (C329).
  - Recheck at decision time. This is not legal advice.

## Options for the owner

1. **Choose now among Cursor, Copilot CLI, Factory and OpenCode** on declared evidence, accepting the gaps above.
   - If per-agent effort is required, that leaves Cursor or Factory.
   - Alternatively, drop effort from the tier rubric for the chosen harness (Pass 9 Rec 2).
2. **Shortlist two or three, then approve a hands-on check before choosing.** Per Pass 10 s5, the check covers per-launch-path model and effort from runtime logs, plus a Windows deny-rule and hook test with plugins controlled. This is runtime work under U3 and needs its own scope and approval.
3. **Request more web research** on the remaining gaps: Goose and Crush depth, Cursor's Windows docs, Kilo first-party docs, and Copilot #221 and BYOK details (Pass 10 s5). This needs a new approved pass.

The Leader's view, as a recommendation only: option 2. The research has narrowed the field, but it cannot show which harness actually routes model and effort as configured, or which actually enforces deny rules on Windows. Those are the two properties the tier rubric and S4 depend on.

## Whatever is chosen

- **Verification:** verify model and effort per launch path from runtime logs, not configuration echoes (O2, O9).
- **Windows rules:** a deny rule or hook is not a boundary on Windows until a local test blocks a denied command, with no unreviewed plugin files present (S4, O12).
- **Fail-closed layer:** map each hard rule to a layer that fails closed in that harness. Do not rely on a hook alone where a timeout or crash would let the call through (C311, C320).
- **Approval modes:** classifier approval modes are not a boundary (C330, C274).
- **Generator refit:** emit model and effort fields per harness, because their formats differ (Pass 9 Rec 7).

## Next action

**Owner:** pick option 1, 2 or 3, and name the harness or shortlist.

**Next Workspace Leader, after that:**
1. Read the Workspace state Startup and confirm the base. The roster refit is still uncommitted; the owner decides whether to commit it first.
2. Record the owner's decision in `docs/workspace-outline.md`: the S2 Harness row and the U1 row. Cite the AI-Research tags and claim IDs above.
3. Then scope the generator refit, plus the hands-on check if option 2 was chosen, as separate submissions for approval.

**Done when** U1 records the owner's harness decision, or the owner's approved next step, and the dependent submissions are drafted.
