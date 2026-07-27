# Anti-bot: what blocks recon and what gets through

The central fact: **anti-bot layers block your recon tooling, not the service's real usage.** A human with a browser gets in fine. That asymmetry is what you exploit, and it is also why "I got a 403" is never the end of the investigation.

Observed across the corpus: CDN challenge pages, edge security checkpoints, bot-detection vendors, captcha widgets, and device fingerprinting. Six of the targets blocked plain automated fetching in some form.

## The ladder

Escalate only as far as you need. Each rung costs more.

**1. Plain fetch.** `curl`, or the skill's `read` command. Free and fast. Works for docs, specs, and static pages.

**2. Fetch with a real browser's headers.** Some checks are only a User-Agent string test. Copy the exact header set a real browser sends.

**3. Headless browser.** Gets past markup-level checks. Still detectable, and several corpus targets blocked headless specifically.

**4. Headed browser.** The reliable rung. A real browser profile with a visible window passes nearly everything short of a captcha. Two targets required headed for login and worked fine with plain fetch afterward.

**5. Headed browser with a persisted profile.** When the challenge only appears on a cold session, solve it once and reuse the profile.

```bash
SESSION="$(agent-browser session id --scope worktree --prefix recon)"
agent-browser --session "$SESSION" --restore open <url>
```

**Above that:** captcha and device fingerprinting. See the limits section.

## The pattern that works

**Headed for first contact, plain fetch for the rest.**

Anti-bot enforcement is almost always concentrated on the initial page load and login. Once a session exists, the API calls behind it are typically unguarded, because the service assumes anything with a valid session already passed the door.

So: log in headed, extract the session cookie or token, then do the actual mapping with cheap fetches. This is both faster and less fragile than driving a browser for every request.

## What each blocker looks like

**CDN challenge page.** A 403 with an interstitial, or a body that is a challenge script rather than your content. Headed browser clears it.

**Edge security checkpoint.** A 403 with a vendor-specific header naming the mitigation. Notable because in one corpus case it blocked *both* `curl` and a browser, which pushed the recon onto a different surface entirely; the team analyzed a downloaded output artifact instead and still reached a correct conclusion about the backend. When the front door is sealed, look at what the service already gave you.

**Bot-detection vendor script.** Present in the page, scoring you continuously. Sometimes it observes without enforcing: one target shipped a fingerprinting script and still accepted an out-of-browser replayed request. Document it as latent risk with a fallback plan, not as a hard block.

**Captcha.** A real wall. See limits.

**Masked or custom form inputs.** Not anti-bot exactly, but the same symptom: automation cannot type into the field. Custom components sometimes ignore synthetic events. If `fill()` silently does nothing, the input is a custom component, and you need real key events or direct state manipulation.

**Connection reset on a cold session.** One legacy portal reset the connection on a clean session while working normally on a warm one. Try a persisted profile before concluding the endpoint is dead.

## Rate limits: report what you measured

The corpus has a systematic honesty problem worth not repeating. Six reports state a polite default of roughly one request per second. **None of them measured anything.** The number was a convention, but written in a table it reads like a finding.

Write one of these, whichever is true:

- `Rate limit: X requests per Y, from response headers`, you read it.
- `Rate limit: throttling observed at approximately N concurrent requests`, you probed.
- `Rate limit: no limit headers observed. Not measured.`, you did neither.

The third is a perfectly good answer. Inventing the first is not.

If you do probe, probe gently and say you did. Do not hammer a public service to characterize its limiter.

## Limits

Some things this skill will not do, regardless of technique:

- **Solving captchas to get past an access control.** A captcha is the operator saying no to automation. Clicking a captcha by computed coordinates is a technique that appears in the corpus as *shipped production code*, with no tests, and it will break silently the moment the widget moves. It is listed here as a warning, not a recommendation.
- **Bypassing authentication you were not granted.** Recon maps a surface the user is entitled to use. No credential stuffing, no session hijacking, no privilege escalation.
- **Defeating paywalls or licensing.**
- **Harvesting personal data.** A public consultation form that returns individual records is a service to query for one lookup, not a dataset to enumerate.

If a target requires any of these, the recon verdict is "blocked", and the report says why. That is a legitimate outcome.

## Recording the blocker

Every blocker goes in the report with three parts:

1. **What you hit**, the exact status, header, or symptom.
2. **What got through**, the rung of the ladder that worked, or nothing.
3. **What it means for the build**, a captcha on the auth path means no unattended automation, ever. A headed-only login means the CLI needs a browser dependency. These are design constraints, not footnotes, and the implementer needs them before choosing an architecture.
