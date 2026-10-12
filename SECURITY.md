# Security policy

## Reporting a vulnerability privately

Do **not** put vulnerability details, exploits, credentials or private logs in
public issues or discussions. The intended route is GitHub private vulnerability
reporting, **when the repository owner has enabled it**:

1. Open [SuperWorkspace Security](https://github.com/BiscuitDoesStuff/SuperWorkspace/security).
2. Choose **Report a vulnerability** and use the private form.

This file does not enable the feature. If that button is unavailable, open a
public issue requesting a private security contact **without sensitive details**
and wait for a private route before sharing them. The reporting entry was
verified available on 2026-10-12; no report was submitted or end-to-end handling
verified, and no response-time guarantee is offered.

Privately include affected kit version/commit, OS/tool versions, minimal steps,
impact and sanitized evidence. Do not send active secrets; revoke any exposed
credential through its provider. Do not run destructive actions to prove a bug.

## Scope and support

The development kit has no supported-release/backport matrix yet. Reports
against the current development revision are welcome; older versions do not
have a guaranteed security maintenance window.

Agent shell rules are guardrails, not a sandbox. Installation/static validation
does not audit credentials/history or prove effective runtime permissions.
Project/global instructions, local settings, plugins, provider access and
external MCP services form additional trust boundaries. See
[setup boundaries](docs/setup.md#supported-boundaries) and
[workspace permissions](.sw/workspace.md#permissions-and-portability).

Humans own repository settings, releases and coordinated disclosure. Enabling
private reporting is a separate GitHub setting; see
[GitHub's guide](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/configuring-private-vulnerability-reporting-for-a-repository).
