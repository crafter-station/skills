# Recon report template

Copy this, fill it, delete what does not apply. The frontmatter is what makes a set of reports queryable, so keep every field even when the answer is "none".

```markdown
---
type: surface-recon
target: {url or name}
created: {date}
terrain: {A-H}
auth: {none|api-key|cookie|oauth|jwt|hmac|certificate}
official-api: {yes|partial|no}
confidence: {high|medium|low}
---

# {Target}, Recon

## What it is
{1-2 sentences. What the service does, who uses it.}

## Official surface
{Spec URL, SDK, docs quality. Or: "None found. Searched: <queries>."}

## Authentication
{The exact flow, step by step. Header names and formats. Token lifetime.
Rotation behavior. Second factors. What you OBSERVED vs what you inferred.}

## Endpoints

| Method | Path | Purpose | Auth | Verified |
|---|---|---|---|---|
| GET | /api/v1/thing | List things | Bearer | observed |
| POST | /api/v1/thing | Create | Bearer | inferred from bundle |

For Terrain F and H there are no endpoints. Replace this section with the
schema (F) or the constraint set the implementer must satisfy (H): which
operations are accepted, which are silently substituted, required layouts
and formats, and how each one was verified.

## Blockers
{Anti-bot, captcha, rate limits, session expiry, required headers.
For each: what you hit, and what got past it; or that nothing did.}

## Gotchas
{The non-obvious things that cost time. Be specific enough to save the
next person the same hour. Wrong-looking names, double encoding, values
that must be re-read on every response, endpoints that lie about 200.}

## Needs verification
{Everything you could not confirm, and the exact step that would confirm it.}

## Evidence
{HAR file, screenshots, bundle hashes. Where they live.}
```

## Per-terrain variants

**Terrain F (a file format)** has no endpoints and no auth. Replace both sections with the schema: every field, which ones appear only sometimes, version drift between samples, and the encodings that break naive parsers.

**Terrain H (hardware or an accelerator)** has no endpoints either. Replace them with the constraint set the implementer must satisfy: which operations are accepted, which are silently substituted for something slower, required layouts and formats, and how each one was verified. Record the silicon, OS, and toolchain version, since a constraint true on one generation can be false on the next.

**Terrain D (a portal you cannot log into)** sets `confidence: low` and puts nearly everything under "Needs verification". The one line that matters is what would unblock it.
