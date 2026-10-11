# Contributing and support

## Support

Start with [setup/adoption](docs/setup.md). For non-security installation bugs,
use the [public bug form](https://github.com/BiscuitDoesStuff/SuperWorkspace/issues/new?template=bug.yml).
Include expected/actual behavior, reproducible steps and **sanitized** diagnostics:

- OS, `pwsh --version`, Git and OpenCode versions (if relevant).
- Kit `VERSION`, clean/dirty status and `git rev-parse HEAD`; target manifest's
  kit version/commit (not its entire contents).
- Profile, capabilities, Git/privacy choices and the failing command/exit.
- Whether this is new setup, existing-project adoption, joining or update.
- A minimal synthetic fixture, not private application source or full logs.

Use `validate` and read-only `doctor` when installed; redact usernames, machine
paths, tokens, account details and private repository identifiers from output.
Never attach `.env`, local model/account configuration, backups or raw private
task records. Vulnerabilities go through [SECURITY.md](SECURITY.md), not issues.
Support is best-effort; no response-time or platform guarantee is promised.

## Development

Read [development and CI](docs/development.md) and the project's [AGENTS.md](AGENTS.md).
Discuss material changes before coding. Preserve existing work, edit generator
sources, regenerate managed copies and run scope-appropriate checks. Test with
isolated fixtures; no global/account/model activation is needed for offline
regression. No new dependency or external asset without owner approval.

Agents leave changes uncommitted unless explicitly asked and never push. Humans
publish selected reviewed paths under this project's Git workflow. Maintainers
control branches, settings, tags and releases. Static tests and lower-level
evidence must not be presented as runtime or hosted assurance.

Contributions are offered under [MIT](LICENSE); retain
[third-party attribution](THIRD_PARTY_NOTICES.md). Historical docs and local
task records are evidence, not approval for unrelated work.
