# Auth patterns

Four architectures observed in real CLIs, plus the failure modes that cost the most time.

## The four architectures

### 1. Static API key, stored in a profile file

The simplest, for services that issue long-lived keys.

Key lives in a config file under the app's directory, or comes from an environment variable that takes precedence. Support named profiles from day one: `default`, `staging`, `prod`, because the second environment always arrives, and retrofitting profiles means touching every call site.

**Default to the safe profile.** If the service has a sandbox or paper mode, that is the default, and reaching production requires naming it explicitly.

### 2. Environment-only secret plus browser automation

For portals with no API, where a password drives a real browser session.

The rule: **store identifiers, never the secret.** One corpus CLI persists the account id and username and takes the password only from an environment variable, held in memory for the session. The persisted config object literally omits the password field: verifiable by reading the object literal, not just claimed in a policy document.

This shape implies a browser dependency, which implies a `doctor` command, because "is a usable browser present and is the session live" is now a precondition for every operation.

### 3. OS keychain with a file fallback

For CLIs distributed to other people, where a plaintext token in a dotfile is not acceptable.

Keychain first, file fallback when the keychain is unavailable: headless Linux, CI. Say which one is in use in `doctor` output so the user is not guessing.

### 4. Shelling out to a browser tool for session extraction

When the target's auth cannot be reproduced with HTTP alone; a federated identity provider, a hard-to-replicate handshake; the CLI drives an external browser tool to log in, extracts the cookie, then uses plain fetches.

Honest about the cost: you now depend on a binary the user must install, and the login is interactive. In exchange, you get access that pure HTTP could not reach.

---

## Failure modes worth designing for

### Rotating session keys

Some servers return a fresh session key on every response and expect the next request to use it. Miss one rotation and every subsequent call fails, usually with an unhelpful error.

Three corpus CLIs hit this, in different forms: a session key header returned on each response and used as the signing key for the next request; a session token captured and replayed by the client; a framework session value that changes on each login and must be re-extracted from the page rather than cached.

**Design for it:** treat the session value as mutable state updated after every response, never as a constant read once at startup. During recon, check whether any response header differs between two identical calls.

### Signature schemes

If requests carry a signature, get the exact message construction and **verify by replaying outside the browser.** The corpus case that did this found the signed message was `timestamp + query-with-spaces-stripped + platform_os + app_version`, a shape nobody would guess.

Signing code is the highest-value place to have unit tests. It is pure, deterministic, and everything else depends on it. One corpus CLI has a dedicated test file for exactly this; it is the right instinct.

### Token refresh ambiguity

OAuth providers vary in whether a refresh returns a new refresh token. Handle both:

```ts
refresh_token: data.refresh_token ?? config.refresh_token
```

Assuming a new one always comes back means discarding the still-valid old one and forcing a re-login. Assuming one never comes back means ignoring rotation the provider expects.

### Scope creep

The scopes you request first are never enough. Build the upgrade path as its own verb early (`auth upgrade` or equivalent) rather than telling users to delete their config and start over.

A caution from the corpus: one CLI's `--upgrade` flag survived as a **deprecated no-op** after auth was changed to always request full scope. The flag is still parsed and the underlying parameter is never read. If a flag stops doing something, remove it; a no-op flag in `--help` is a lie with a long half-life.

### Multiple auth systems in one target

A single service can have two entirely different auth flows; a legacy portal and a modern one, or a main app plus a federated sub-app. One corpus target had exactly this and it was discovered mid-build, not during recon.

**Design auth as a per-surface strategy from the start** when the target shows any sign of being a portal composed of sub-applications. Retrofitting a second flow into code that assumed one is the expensive path.

### Second factors

OTP, an authenticator app, SMS. Each breaks unattended operation, which is the entire premise of an agent-first CLI.

Be explicit about what this means: a CLI whose auth requires a fresh OTP cannot run unattended, period. Either the session persists long enough to be useful between manual logins, or the CLI is human-initiated by design. Say which in the docs rather than letting the user discover it at 3am.

### Captcha on the auth path

Same conclusion, stronger. A captcha means no unattended automation.

Solving one by computed coordinates appears in the corpus as shipped production code, untested, and it will break silently the first time the widget moves. If a captcha sits on your auth path, the honest design is a human-initiated login that produces a durable session, with the CLI operating on that session afterward.

---

## Doctor

Any CLI with non-trivial auth needs one:

```bash
{cli} doctor --json
```

Checks: credentials present, credentials valid (a real cheap authenticated call, not just "the file exists"), required binaries installed, connectivity to the target, session freshness.

Two things that make it genuinely useful:

**Bound the freshness.** A doctor result cached for a bounded window, re-run when stale. One corpus CLI gates live operations on a passing check no older than thirty minutes: so a green result from yesterday cannot authorize today's submission.

**Structured output with per-check status.** An agent should be able to read which check failed and act on the hint, not parse prose.

---

## Do not

- Persist a password. Identifiers yes, secrets from the environment or a keychain.
- Log credentials in the audit trail. Redact before writing.
- Cache a session value the server rotates.
- Ship a signing implementation without tests.
- Leave a deprecated auth flag parsed and unread.
- Claim unattended operation when a second factor or captcha sits on the auth path.
