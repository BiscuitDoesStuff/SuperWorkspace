# workspace-research-requests - submission - Claude corpus pass (R7) for AI-Research [2] - 2026-10-02T221029Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner, who carries the prompt below to an AI-Research [2] session.
- **Approval:** owner in session, 2026-10-02: research pass on Claude from Anthropic's own sites (platform docs, API reference, Claude Code docs, Help Center, terms, pricing; "everything", not limited to the named sites). Owner choices: run as an AI-Research [2] pass; full mirror in ignored scratch, cited pages only as evidence; output a Claude reference map, graded claims and R1-R3 answers. Approving and running the pass is decided in AI-Research [2] under its own protocol.
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`. Uncommitted.
- **Relation:** R7 subsumes R1-R3 of the [R1-R6 submission](2026-10-02T221500Z-leader-submission-research-requests.md); R4-R6 (OpenCode, OpenAI) stay there.

## R7 question

What do Anthropic's first-party sources state about Claude as of 2026-10: models, API, agents and tools, Claude Code, plans, terms and apps, admin and security, guidance and change history? Behavioural or contested points (R1-R3, limits, enforcement) also get independent sources. Serves: Claude-role launcher and routing (R1, R2), S4 enforcement parity (R3), and a reusable Claude reference for later Workspace decisions.

## Corpus (measured 2026-10-02, planning probes)

| Source | Index | Size |
| --- | --- | --- |
| platform.claude.com/docs (docs.claude.com redirects) | `llms.txt`, 756 links | `llms-full.txt` 41 MB |
| code.claude.com/docs | `llms.txt`, 231 links | `llms-full.txt` 8.7 MB |
| support.claude.com | `llms.txt`, 359 English `.md` articles | no full dump |
| anthropic.com/legal/*, claude.com/pricing, status.claude.com | HTML | none |

AI-Research evidence is about 162 of 200 MiB, so the mirror stays in scratch. Excluded: `platform.claude.com/dashboard` (login required), non-English Help Center copies.

## Proposed pass design (`claude-11`)

- **Phase M (mirror):** `pass.py fetch` rows built from the three indexes, both full dumps, the 359 Help Center articles, about 15 legal pages, pricing and status; about 380 calls into `.scratch/claude-11/mirror/`, not retained. Check page counts against the indexes (756/231/359); missing pages are gaps.
- **Phase K (research, local mirror reads plus calls for retention and independent sources):** K1 models and platform; K2 API surface; K3 agents and tools; K4 Claude Code with R2 and R3; K5 plans, terms and apps with R1; K6 admin and security; K7 guidance; K8 change history (dated notes on C093, C222-C231, C258, C283, C324-C326).
- **Budget:** M about 380 + K1-K8 12 each + 24 reserve (at most 4 per group); hard cap 500 calls; new evidence 20 MiB.
- **Deviations for owner approval:** bulk group M outside the per-sub-question depth rule; first-party docs primary for `declared`, with the three-family target only for behavioural or contested claims; as-of dates on volatile facts; extra non-report document `docs/research/claude-reference-map.md` (added to protocol section 10); claims from C331, source prefix K.
- **Sessions:** one mirror session, about six collection batches (K1+K7, K2, K3, K4, K5+K6, K8; at most two workers), one synthesis session, independent review; commit and tag only if the approval allows.
- **Out of scope:** writes to Workspace, logins, installs, runtime tests (R2 and R3 stay desk research), legal interpretation.

## Prompt for an AI-Research [2] session

```text
Workspace requests a bounded research pass (proposal; approve under the AI-Research research protocol before running).
Source: C:\DevProjects\Workspace\.sw\comms\tasks\workspace-research-requests\2026-10-02T221029Z-leader-submission-claude-corpus.md
R7: a Claude corpus pass (claude-11) over Anthropic's first-party sites (platform docs, API reference, Claude Code docs, Help Center, legal, pricing, status), with a full llms.txt-based mirror in .scratch, cited pages only as evidence, K1-K8 sub-questions, a claude-reference-map document, graded claims, and answers to R1-R3 from the earlier R1-R6 record.
Read the state Startup, turn the proposed design into a claude-11 submission for owner approval, then run it under the protocol. Desk research only; no logins, installs or runtime tests. Do not edit Workspace.
```
