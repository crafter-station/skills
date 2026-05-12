# Remediation playbook

Two paths depending on the scan verdict.

## CLEAN — preventive hardening

Set a 48-hour package bake period across every package manager you have installed. This blocks the publish-fast/get-yanked attack pattern that powers Mini Shai-Hulud, Shai-Hulud 2.0, and similar.

```bash
# npm 11+ (units: days)
npm config set min-release-age 2

# pnpm (units: minutes)
pnpm config set minimumReleaseAge 2880

# bun — append to ~/.bunfig.toml (units: seconds)
# create the file if it doesn't exist
[ -f ~/.bunfig.toml ] && echo "" >> ~/.bunfig.toml
printf '[install]\nminimumReleaseAge = 172800\n' >> ~/.bunfig.toml

# yarn berry (units: duration string)
yarn config set npmMinimalAgeGate 48h
```

**npm 10 caveat.** `min-release-age` was added in npm 11. On npm 10, the line in `.npmrc` is silently ignored. You can pre-stage it (`echo 'min-release-age=2' >> ~/.npmrc`) so it activates the moment you upgrade — but only the upgrade actually protects you.

**Additional preventive steps (one-time, low cost):**

- Audit your GitHub PATs at https://github.com/settings/tokens — revoke any you don't recognize or no longer need. Prefer fine-grained PATs over classic.
- Enable 2FA on npm (`npm profile enable-2fa auth-and-writes`).
- For any repo you publish from, audit `.github/workflows/` for `pull_request_target` usage. If present, either remove the trigger, or pin the checkout to `${{ github.event.pull_request.base.sha }}` so the trigger never runs PR code.
- Avoid shared GitHub Actions caches between publish workflows and PR-triggered workflows.

## POTENTIALLY COMPROMISED — incident response

**Order matters. Do not skip the first step.**

### Step 1: DO NOT REVOKE THE GITHUB PAT YET

The Mini Shai-Hulud / TeamPCP payload installs a watcher (`gh-token-monitor`) that polls `api.github.com` with the stolen token every 60 seconds. The moment the token returns 401 (revoked), the watcher runs `rm -rf $HOME`. Revoking blind on an infected host wipes your home directory.

**Instead:** open https://github.com/settings/tokens in a browser on a **different, known-clean machine**. Look at each PAT's last-used IP and User-Agent. Anything coming from an unfamiliar IP (especially DigitalOcean, Hetzner, OVH ranges) or from a non-browser User-Agent in the last 72 hours indicates active abuse.

### Step 2: Move work off the suspect host

Treat the host as untrusted. Don't run `git push`, don't open new SSH sessions to production, don't paste credentials anywhere. If you need files from it, copy them off via a one-way channel (USB, SCP *from* a clean host pulling) — not by logging *into* anything from the suspect host.

### Step 3: Kill persistence

From a terminal *on the suspect host* (read-only, no network calls):

```bash
# macOS — unload and remove the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.user.gh-token-monitor.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.user.gh-token-monitor.plist
rm -f ~/.local/bin/gh-token-monitor.sh
rm -rf ~/.config/gh-token-monitor
rm -f ~/.claude/setup.mjs ~/.vscode/setup.mjs
rm -f /tmp/tmp.ts018051808.lock

# Linux
systemctl --user stop gh-token-monitor.service 2>/dev/null
systemctl --user disable gh-token-monitor.service 2>/dev/null
rm -f ~/.config/systemd/user/gh-token-monitor.service
rm -f ~/.local/bin/gh-token-monitor.sh
rm -rf ~/.config/gh-token-monitor
```

Killing persistence *before* revoking removes the dead-man's-switch. After this, revocation is safe.

### Step 4: Rotate, in this order

From a clean machine:

1. **GitHub PATs** — now safe to revoke. Issue new ones with minimal scope.
2. **npm tokens** — `npm token list`, revoke all, re-publish any maintained packages from the clean machine.
3. **Cloud creds** — AWS access keys, GCP service-account keys, Azure SPs. Rotate root API keys too if you used them recently on the suspect host.
4. **SSH keys** — generate a fresh keypair, push to GitHub / GitLab / servers, remove the old `~/.ssh/id_*` files from the suspect host.
5. **Vault / Doppler / 1Password CLI sessions** — log out everywhere, revoke long-lived sessions.
6. **Crypto wallets** — if you have hot wallets on the suspect host, move funds to a fresh wallet on the clean machine. Shai-Hulud 2.0 specifically harvested wallet seeds.

### Step 5: Audit blast radius

For each rotated credential, check what was accessed in the 72h before discovery:

- GitHub: `https://github.com/settings/security-log` — filter for new repos created (Shai-Hulud creates public dead-drop repos), new tokens, new SSH keys, force-pushes to your repos.
- AWS: CloudTrail for `console-login`, `GetSecretValue`, `CreateAccessKey` from unfamiliar IPs.
- npm: check `npm audit signatures` and look at recent `npm publish` events for your packages.

### Step 6: Reinstall lockfiles from a clean lockfile baseline

On the previously-suspect host (or a fresh one):

```bash
# nuke any node_modules with potential payload residue
find . -name node_modules -type d -prune -exec rm -rf {} +

# reset to last known good lockfile
git checkout HEAD~ -- package-lock.json   # or pnpm-lock.yaml / bun.lock
# reinstall with the 48h bake period now in place
pnpm install
```

For globally-installed packages: `pnpm list -g` / `npm list -g --depth=0`, then reinstall from scratch.

### Step 7: Notify

If you're on a team or maintain published packages:

- Tell your team in-channel — they may share the toolchain.
- If you're an npm publisher, contact `security@npmjs.com` with the compromised package list.
- If you have a GitHub Enterprise / Org admin, they can audit org-wide PAT usage.

## What this skill does **not** do

- It does not clean up persistence for you (rm commands above are for you to run, knowingly).
- It does not call `npm audit` or any network-touching tool. Those can leak install state to the registry.
- It does not detect novel campaigns — only those in `iocs.json`. When a new disclosure drops, append it.
