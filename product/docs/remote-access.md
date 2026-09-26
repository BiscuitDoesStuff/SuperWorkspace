# Remote access (OpenCode over Tailscale)

This page has no secrets. The OpenCode service password lives only in
`service.json`. SuperWorkspace edits that file in place and never copies it.

## Target state

- The OpenCode service listens on `127.0.0.1:<port>`. The default port is 49374.
- `tailscale serve` publishes `https://<machine>.<tailnet>.ts.net/` to your
  tailnet only. Funnel stays off, so nothing is exposed to the internet.
- The OpenCode service password still applies.
- There is no LAN listener and there are no firewall rules pinned to one version.

**Exception:** a browser-only device that can't run Tailscale needs the LAN
bind. Use `-KeepLan` for it. The service then stays on `0.0.0.0`, protected by
its password.

## Setup (a human runs this; it changes network exposure)

```powershell
tailscale up                               # once; also enable HTTPS in the tailnet admin console
pwsh <kit-path>/sw.ps1 remote setup -WhatIf
pwsh <kit-path>/sw.ps1 remote setup          # or: remote setup -KeepLan
```

Then quit and reopen OpenCode Desktop so the service rebinds. If `setup`
prints LAN firewall rules, review them and remove them from an elevated shell.

## Check (after every OpenCode update, service change, or Tailscale change)

```powershell
pwsh <kit-path>/sw.ps1 remote check
```

This is what a healthy result looks like:

| Check | Expected result |
| --- | --- |
| Tailscale | `Running` |
| `serve status` | Shows the proxy to `http://127.0.0.1:<port>` |
| Tailnet HTTPS probe | HTTP 401 or 200 |
| LAN port | `closed`, unless you used `-KeepLan` |

From a second tailnet device, open the HTTPS URL and confirm the password
prompt appears.

## Roll back

- Set `hostname` back in `~/.config/opencode/service.json`.
- Run `tailscale serve reset`.
- Restart OpenCode.
