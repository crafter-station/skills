---
name: supply-chain-audit
description: Read-only audit of a developer machine for npm/PyPI supply-chain compromise. Checks for known IOCs from the 2025-2026 wave — Shai-Hulud 2.0 (Nov 2025), Mini Shai-Hulud / TeamPCP (May 2026), Axios DPRK (Mar 2026), and any future campaigns added to the IOC pack. Scans persistence artifacts (LaunchAgent / systemd unit / Windows Run key / gh-token-monitor), payload files (router_init.js, setup_bun.js, bun_environment.js), compromised package versions in every node_modules under the user's project roots, C2 / typosquat domain strings (git-tanstack.com, api.masscan.cloud, sfrclak.com, getsession.org), malicious commit hashes (79ac49ee), payload SHA256s, optionalDependencies pointing at git refs, and files written during the published attack windows. Produces a PASS/FAIL verdict, IOC checklist, at-risk package list, phase summary, and 48h bake-period remediation. Use this skill whenever the user asks "am I affected by the npm attack", "scan my machine", "check if I'm infected", "is package X compromised", "audit my coworker's machine", mentions Shai-Hulud / TanStack hack / TeamPCP / Mini Shai-Hulud / pull_request_target compromise / npm worm / axios attack / Bun installer malware / TruffleHog secret theft, asks about IOCs or supply chain risk, or wants to verify a host after a security disclosure. Trigger even when the user uses informal phrasing ("estoy chiveado?", "ya me hackearon?", "this safe?"). Never modifies files.
---

# supply-chain-audit

A read-only forensics scanner for npm / PyPI supply-chain compromise. Runs three IOC phases against the local machine and produces a clean PASS/FAIL verdict.

## When to invoke

The user asked about supply-chain risk, a recently disclosed npm/PyPI compromise, whether their machine is affected, or wants to share this check with coworkers. Triggers reliably for both technical phrasing ("scan for IOCs", "audit my host") and casual phrasing ("am I cooked?", "is this safe?", "ya me hackearon?").

## How it works

The IOC pack lives in `iocs.json` — a versioned list of campaigns, each with its persistence paths, payload filenames, payload hashes, C2/typosquat strings, optional-dependency markers, compromised package scopes, and attack windows. The scanner script `scripts/scan.sh` reads that file and runs three phases:

- **Phase A — persistence**: artifacts that survive reboot (LaunchAgent / systemd / Windows Run key / `~/.local/bin` shims, dropper files in `~/.claude/setup.mjs` / `~/.vscode/setup.mjs`, named lock files).
- **Phase B — code & cache**: package versions present in any `node_modules` under the configured project roots, payload filenames anywhere on disk, malicious commit hashes / typosquat domains / payload SHA256s in lockfiles and source, optionalDependencies entries that resolve to a GitHub git ref (the TeamPCP smuggling pattern).
- **Phase C — time window**: any file written under any `node_modules` during a campaign's published attack window. A clean Phase C is the strongest single signal a host avoided exposure.

Every check is `find` / `grep` / `jq` / `stat` / `shasum`. The scanner never writes to the target machine.

## Invocation flow

1. Read `iocs.json` to understand the current campaign list. If `--list` is requested, summarize the campaigns and stop.
2. Determine project roots. Default: `$HOME`, but prefer narrower paths the user mentions (e.g. `~/Clerk`, `~/Programming`). Ask once if ambiguous and >50GB of code is in scope.
3. Run `bash scripts/scan.sh [root1 root2 ...]`. The script emits a structured markdown report to stdout. Capture it.
4. Parse the report. Verdict logic: **only FAIL rows count toward POTENTIALLY COMPROMISED**. A FAIL means an unambiguous compromise signal — persistence artifact present, payload filename found, payload SHA256 matched, string IOC in lockfile, optionalDependencies git-ref smuggle, or Phase C time-window hit. Inventory rows ("you have a copy of `@tanstack/query-core` in your tree") are emitted as **REVIEW** and do *not* flip the verdict — having `@tanstack/*` installed in February 2026 says nothing about whether you got the May 2026 malicious versions. Phase C answers that. If FAIL_COUNT > 0 → POTENTIALLY COMPROMISED. Otherwise CLEAN, even if REVIEW > 0.
5. Present the report to the user following the output format below.

## Output format

ALWAYS use this exact structure:

```
# Supply-chain audit — <hostname> — <timestamp>

## Verdict: CLEAN  (or  POTENTIALLY COMPROMISED)

## IOC checklist
| Campaign | Check | Result |
|----------|-------|--------|
| ...      | ...   | PASS/FAIL/REVIEW/skipped |

## Inventory — packages from compromised scopes (REVIEW, not FAIL)
(only if Phase B found compromised scopes installed; list `name@version`, install date, path)

## Phase summary
- Phase A (persistence): N fail(s)
- Phase B (code & cache): N fail(s), M review(s)
- Phase C (time window): N fail(s) — authoritative exposure signal
- Total: P PASS / F FAIL / R REVIEW / S skipped

## Next steps
<remediation block — see references/remediation.md>
```

When summarizing REVIEW rows to the user, cross-check the install timestamp against the campaign's attack window from `iocs.json`. If install date is outside the window AND Phase C is clean → these packages are safe, mention briefly. If install date overlaps the window → escalate the row to "needs manual version check against the disclosed malicious version list."

If verdict is **POTENTIALLY COMPROMISED**, the Next steps block MUST lead with:

> **Do NOT revoke any GitHub PAT yet.** The Mini Shai-Hulud / TeamPCP payload installs a dead-man's-switch that watches the stolen token and runs `rm -rf ~/` the moment it sees a 401 from `api.github.com`. First audit token activity at https://github.com/settings/tokens (look for unfamiliar IPs and User-Agents in the last 72h). Then rotate from a separate clean machine: npm publish tokens, cloud creds (AWS/GCP), SSH keys, Vault tokens. Only revoke the suspect PAT after you've moved off the suspect host.

If verdict is **CLEAN**, the Next steps block recommends the 48h bake period:

```
npm config set min-release-age 2            # npm 11+
pnpm config set minimumReleaseAge 2880      # minutes
echo -e "[install]\nminimumReleaseAge = 172800" >> ~/.bunfig.toml   # seconds
yarn config set npmMinimalAgeGate 48h
```

Full remediation prose lives in `references/remediation.md`. Read that file when the user asks for more detail.

## Updating the IOC pack

When a new campaign is disclosed, append a new entry to `iocs.json` following the schema. The scanner picks it up automatically — no edits to the skill body needed. Schema reference: see the top of `iocs.json` itself. Bump the `version` field to today's date.

If the user is reporting a brand-new campaign that isn't in the IOC pack, offer to add it. Ask for: campaign name, disclosure date, affected scopes/packages, payload filenames, payload hashes (SHA256), C2 / typosquat domains, persistence paths, attack window (UTC). Then write the new entry and re-run the scan.

## Platform support

- **macOS**: full support (LaunchAgent paths native).
- **Linux**: full support (systemd-user paths).
- **Windows**: best-effort. Run via WSL or Git Bash. The Windows Run-key check uses `reg query` if available, otherwise marked `skipped` rather than `pass`.

## Hard constraints

- **Read-only.** Allowed tools: `find`, `grep`, `jq`, `stat`, `ls`, `shasum`, `awk`, `sed -n` (print-only), `reg query` (Windows). Forbidden: any redirect that writes outside `/tmp/supply-chain-audit-*` workdir, any package-manager command that resolves dependencies (`npm install`, `pnpm install`, `bun install`), any network call to `api.github.com` or registries.
- **No credential touching.** Never read `~/.npmrc`, `~/.ssh/`, `~/.aws/`, or environment variables containing token-like strings. The point is to detect malware, not exfiltrate the user's own secrets while doing so.
- **No revocation suggestions on FAIL until the dead-man's-switch warning has been delivered.** This is non-negotiable — premature revocation on an infected host wipes `~/`.

## References

- `iocs.json` — versioned IOC pack, the single source of truth.
- `references/campaigns.md` — narrative descriptions of each campaign, attribution, technique chains.
- `references/remediation.md` — full bake-period setup, post-compromise playbook, credential-rotation order.
- `scripts/scan.sh` — the scanner itself. Read it if you need to extend coverage.
