# Campaigns — narrative reference

Background context for each campaign in `iocs.json`. Read when the user wants to understand *why* a check exists, the technique chain, or the attacker's intent. The scanner does not load this file — it's for human comprehension.

## Mini Shai-Hulud (TeamPCP) — May 11–12, 2026

**Attribution.** TeamPCP, the same crew implicated in earlier "TheBeautifulSandsOfTime" intrusions. Linked by Wiz and Socket to the same OPSEC fingerprint (Session messenger drop, GitHub dead-drop repos under disposable accounts).

**Scope.** 172 unique packages across 403 malicious versions. Confirmed-affected scopes: `@tanstack` (42 packages, 84 versions), `@uipath` (66 packages), `@mistralai` (PyPI 2.4.6), `@opensearch-project/opensearch` (1.3M weekly downloads), `@squawk` (20 packages), `@guardrails-ai` (PyPI 0.10.1), plus `@tallyui`, `@beproduct`, `@draftlab`, `@draftauth`, `@taskflow-corp`, `@tolka`.

**Technique chain.**

1. **Initial access via `pull_request_target`.** Attackers found target repos whose CI used `on: pull_request_target` — a trigger that runs in the context of the *base* repo (with its secrets) but checks out the *PR* code. Combined with a shared cache, the PR can plant a malicious artifact that the next legitimate publish picks up.
2. **GitHub Actions cache poisoning.** Across the fork↔base trust boundary, the attacker overwrites a cache entry that the publish workflow reuses.
3. **OIDC token extraction.** A small Go helper running inside the poisoned cache reads the runner's memory and extracts the GitHub OIDC token used for npm `--provenance` publishes.
4. **Publish with valid SLSA provenance.** Because the malicious artifact rides the legitimate workflow's OIDC, npm signs it with valid provenance. Provenance verification *does not* protect against this.
5. **Smuggle the payload.** Each compromised tarball gets an `optionalDependencies` entry like `"@tanstack/setup": "github:tanstack/router#79ac49ee..."`. npm resolves the git ref, runs `prepare`, and `router_init.js` (≈2.3MB) executes.
6. **Persistence.** Install a LaunchAgent (`com.user.gh-token-monitor.plist`) or systemd user unit polling `api.github.com` every 60s with the stolen token. If the token returns 401 (i.e., the victim revoked it), the agent shells `rm -rf $HOME`.
7. **Exfiltration.** Three redundant channels: typosquat `git-tanstack.com`, Session messenger (`*.getsession.org`), and GitHub dead-drop repos created with the stolen PAT.

**Why bake-period defeats it.** The malicious tarballs were live 19:20–19:30 UTC. By 19:35 npm security had revoked publish rights. Any host with `minimumReleaseAge >= 1d` could not have resolved those versions — they didn't meet the age gate before being yanked.

## Shai-Hulud 2.0 — November 24, 2025

**Scope.** 796 unique packages, 1,092 versions. ~25,000 malicious GitHub repos created across ~350 attacker-controlled users. Major orgs hit: Zapier, PostHog, Postman, several Elastic dependencies.

**Technique chain.**

1. **`pull_request_target` exploit.** Same root-cause class as Mini Shai-Hulud — PostHog's `.github/workflows/auto-assign-reviewers.yml` ran external PR code with secrets in scope. Attacker landed a PR on Nov 18 that exfiltrated workflow secrets to a webhook.
2. **Preinstall execution.** Unlike most npm worms, payload ran on `preinstall` not `postinstall` — meaning it executes even when `npm install --ignore-scripts` is partially set, and inside CI where the dep tree is still being resolved.
3. **TruffleHog secret harvest.** Payload dropped `trufflehog` and scanned `$HOME`, `$GITHUB_WORKSPACE`, env vars, git history for high-entropy strings. Targeted: npm tokens, GitHub PATs, AWS/GCP/Azure keys, SSH private keys, crypto wallet seeds.
4. **Self-propagation.** Used harvested npm tokens to publish malicious versions of *other* packages the victim maintained. This is what created the 25K-repo blast radius.
5. **Disguise.** Payload files named `setup_bun.js` and `bun_environment.js` to masquerade as Bun installer scripts.

**Yanked by 9:30 UTC** (~5.3 hours after first malicious publish). Anyone who installed in that window should treat the host as compromised.

## Axios DPRK supply-chain hijack — March 31, 2026

**Attribution.** DPRK-nexus (Google TAG / Mandiant attribution). Same toolchain class as Lazarus 3CX-style supply-chain ops.

**Scope.** Two malicious versions of `axios` (millions of weekly downloads) plus a hidden dep `plain-crypto-js@4.2.1`.

**Technique chain.**

1. **Account takeover.** Attackers compromised the npm credentials of axios's primary maintainer (phishing + session token reuse, per the disclosure).
2. **Hidden dep injection.** Published versions included `plain-crypto-js@4.2.1` as a normal dep — non-obvious because it looks like a legitimate utility.
3. **Postinstall RAT drop.** `plain-crypto-js`'s postinstall pulled platform-specific RAT binaries from `sfrclak.com:8000`.
4. **Persistence (Windows).** Dropped `%PROGRAMDATA%\system.bat` and added `HKCU\...\Run\MicrosoftUpdate` to run at logon. macOS/Linux persistence vectors were also observed but less consistent — Windows was the primary target.

**Defense.** Pin axios to a known-good version. Audit any `plain-crypto-js` install (the package has no legitimate use case at this name).

## What ties them together

All three exploit the same structural weakness: **npm trust-on-first-use semantics**. A package's identity is its name + version; npm does not require the publisher's *identity* to remain stable across versions. Combine that with workflows that grant publish credentials to untrusted code (`pull_request_target`), and the registry becomes a viable distribution channel for compromise.

The 48h bake period is the single highest-leverage defense because attackers operate on a publish-fast/get-yanked cycle measured in minutes to hours. A 1-2 day gate makes the entire campaign class economically uninteresting.
