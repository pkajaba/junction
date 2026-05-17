# Security Policy

## Supported versions

Junction is pre-v0.1. Once a stable release exists, only the latest released version will receive fixes. Earlier alpha/beta builds will not be patched.

| Version | Supported |
| ------- | --------- |
| pre-v0.1 | Best effort |
| (future) v0.x | Latest minor only |

## Reporting an issue

Please do **not** open a public issue for anything sensitive. Use one of:

1. **GitHub private advisory** — preferred. Open one at [github.com/pkajaba/junction/security/advisories/new](https://github.com/pkajaba/junction/security/advisories/new). This keeps the report private and gives us a place to coordinate the fix.
2. **Email** — see the maintainer's address in `git log`.

Please include:

- Affected version (commit SHA if from source)
- Steps to reproduce
- What an attacker could achieve
- Any suggested mitigation

## What we consider in scope

- Junction silently routing a URL to a browser the user did not intend
- Code execution via crafted URL or rules file
- Privilege escalation, sandbox escape, keychain access from a Junction component
- Tampering with the rules file or settings via another local user account

## Out of scope

- Vulnerabilities in the browsers Junction launches (report those upstream)
- Social-engineering attacks that require the user to install a malicious build
- Reports based solely on outdated dependencies without a working exploit

## Response timeline

We aim to acknowledge within 72 hours and provide a fix or mitigation plan within 14 days for confirmed reports. We will credit reporters in the release notes unless you ask us not to.
