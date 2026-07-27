# The compounding surface

Everything else in this skill comes from CLIs measured in the corpus. This file does not: it comes from published work by people who ship agent-facing CLIs at a scale the corpus does not reach.

**Sources**, so you can weigh them yourself:

- Trevin Chow, [10 Principles for Agent-Friendly CLIs](https://trevinsays.com), which replaces an earlier set of seven.
- Cloudflare, [The CLI for all of Cloudflare](https://blog.cloudflare.com/cf-cli-local-explorer/) (2026-04-13). One TypeScript schema generates their CLI, SDKs, Terraform provider, and MCP server. Roughly 3,000 operations served in under 1,000 tokens.
- HeyGen's [CLI](https://github.com/heygen-com/heygen-cli) and its companion [skills repo](https://github.com/heygen-com/skills).

None of the three patterns below appear in the corpus, so treat them as informed recommendations rather than measured conventions. When you implement one, write the case and it graduates.

The framing worth stealing outright: the defensive layer keeps a CLI from breaking an agent. This layer makes the CLI **compound**, more useful the more agents use it.

---

## Async: `--wait` and a job ledger

The gap the corpus does not cover at all. Several CLIs in it wrap async operations and every one hands the poll loop to the caller.

A submit that returns a job id and stops produces two failure modes. Either the agent writes its own polling loop, spending tokens and getting backoff subtly wrong, or it skips polling and the next step runs before the result exists.

```bash
# Without --wait, the agent owns the loop
$ mycli video render --script=story.txt
{"job_id":"job_8f2a","status":"queued"}
$ mycli video status job_8f2a     # and again, and again

# With --wait, one call
$ mycli video render --script=story.txt --wait
{"job_id":"job_8f2a","status":"complete","url":"https://.../out.mp4"}
```

**`--wait` belongs on every command that submits an async operation.** Behind it: a poll loop with exponential backoff and jitter, and job state written to a local ledger.

**The ledger is what makes retries safe across the whole arc.** This skill already treats idempotency at submission as non-negotiable. Async widens the window: if a `--wait` invocation is killed mid-poll, the next invocation must find the in-flight job rather than submitting a second one. A JSONL ledger at `~/.<cli>/jobs.jsonl` covers it, and it composes with the audit log you already write.

Expose it:

```bash
mycli jobs list      # in-flight and recent
mycli jobs get <id>  # one job's state
mycli jobs prune     # clear old entries
```

Done when: `--wait` exists on every submitting command, a killed poll is recoverable from the ledger, and `jobs list` shows in-flight work.

---

## Vocabulary: enforced, not agreed

This skill already says noun-verb, consistently. The published work supplies the argument for why writing it down is insufficient.

Agents do not learn one CLI at a time. They carry a generalized model of what CLIs do, built from every CLI in training. A tool that says `info` where the rest of the world says `get` does not fail; it succeeds slowly, after the agent burns tokens on `--help`.

Cloudflare's rules, enforced at their schema layer:

- always `get`, never `info`
- always `list`, never `ls`
- always `--force`, never `--skip-confirmations`
- always `--json`, never `--format=json`

Their reason is the load-bearing part: **"manually enforcing consistency through reviews is Swiss cheese."**

So the convention belongs in CI, not in a style guide. A static check that fails the build on a banned verb or a flag alias catches what review lets through, and it keeps catching it after everyone forgets the rule existed.

The corpus supports this from the failure side. Two of its CLIs overload `--json` to mean JSON *input*, breaking the convention an agent arrives with, and they did it independently. Nobody decided that; it happened because nothing stopped it.

Done when: a check in CI fails on banned verbs and flag aliases, and the canonical set is documented in one place.

---

## Two-way I/O: `--deliver` and `feedback`

Two mechanisms, opposite directions, neither in the corpus.

**`--deliver` routes the artifact where it is actually needed**, instead of leaving the agent to move it:

```bash
$ mycli video create --script=story.txt --deliver=file:./out.mp4
{"delivered_to":"file:./out.mp4","bytes":4823091}

$ mycli video create --script=story.txt --deliver=webhook:https://example.com/hook
{"delivered_to":"webhook:https://example.com/hook","status":201}

$ mycli video create --script=... --deliver=s3:bucket/key
error: --deliver scheme must be one of: stdout, file:<path>, webhook:<url>
```

File sinks write atomically, which the corpus already demands for any state that must survive a crash. Webhook sinks surface the HTTP status. An unknown scheme returns a structured refusal naming the supported set, which is the same rule this skill applies to every enum rejection.

**`feedback` is the channel back.** Agents hit friction constantly: a flag rejected for the wrong reason, a race in an async path, an error that names the problem without the valid set. Almost none of it reaches the maintainer, because the agent retries, eventually succeeds, and nobody learns the call was painful.

```bash
$ mycli feedback "the --tier flag rejects 'enterprise' but the docs list it as valid"
feedback recorded locally (1 entry)
```

Local JSONL by default, with an optional upstream POST when an endpoint is configured. Surface in `schema` output whether the upstream channel exists, so the agent knows if reporting goes anywhere.

Done when: `--deliver` supports stdout, file, and webhook with a structured refusal on anything else, and `feedback` writes locally with a discoverable upstream.

---

## Why these are hard by hand and easy by generation

Vocabulary consistency, async detection, profile precedence, delivery routing: each is the kind of thing a human writes inconsistently across a dozen subcommands and a template writes identically every time.

That is why the schema is the load-bearing detail of Cloudflare's post rather than an implementation note. One source generating the CLI, the SDKs, and the MCP server is what holds a rule across thousands of operations without drift.

The corpus agrees from the other direction. Its convergences, the same audit-log shape and the same intent-token design arrived at independently, show that good patterns recur. Its anti-patterns, an unwired `--dry-run` and an audit module nothing calls, show what happens when nothing enforces them. Both point the same way: move enforcement out of review and into the build.

## One place the corpus is sharper

The published work treats runtime introspection as a baseline an agent should expect. The corpus measures how rare it is: a `schema` command appears in **3 of 14 CLIs**, all three among the most mature.

So it is simultaneously the most valuable agent-first convention and the least adopted. That makes the recommendation stronger, not weaker, and it is worth saying explicitly when you argue for building one.
