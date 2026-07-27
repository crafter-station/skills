# Trust ladder patterns

Three materially different shapes exist in production code. The generic T0–T3 table is a starting point, not the only answer. Pick by domain.

## First: does this CLI need one at all?

A trust ladder is a tax. It earns its keep only when commands have real consequences: money moves, data is destroyed, a third party is contacted, personal information is exposed, or an action cannot be undone.

**Read-only CLI over a public dataset:** no ladder. Say so explicitly in the design ("all commands are read-only, no gates") so the omission reads as a decision rather than an oversight.

**Everything else:** classify.

---

## Shape 1: tiered ladder with cryptographic intent tokens

The heaviest, for when a wrong command loses real money. Observed in a brokerage CLI.

| Tier | Friction |
|---|---|
| T0 | Runs silently. Reads, status checks. |
| T1 | Logged, no confirmation. |
| T2 | Preview, then requires `--yes`. |
| T3 | Requires a signed single-use intent token. |
| T4+ | Additional gates keyed on magnitude, not just command identity. |

The corpus implementation goes to T5, splitting the top tiers by transaction size and reserving the highest for cancel-all and liquidate.

**How the intent token works:**

1. A preview command computes exactly what will happen and returns a signed token.
2. The token is a JWS with a short TTL: five to fifteen minutes.
3. It binds a fingerprint of the specific operation. A token minted for one order cannot authorize a different one.
4. It carries a nonce enforced single-use by **atomic exclusive file creation**, the `wx` flag fails if the file exists, which makes replay a filesystem-level impossibility rather than a check-then-write race.

Two independent CLIs in the corpus converged on this design without sharing code. One used JWS HS256, the other an HMAC `v1.<id>.<sig>` format. Convergence like that is a strong signal the shape is right for the problem.

**When to use it:** irreversible financial or destructive operations where the cost of one wrong call is high and an agent will be driving.

**Cost:** the preview and submit steps must round-trip through the human or a supervising process. That is the entire point, and it is the right cost for the domain.

---

## Shape 2: binary agent mode with mandatory flags

Simpler, and better for domains where the risk is uniform rather than tiered.

An environment variable marks the process as agent-driven. In that mode, mutating commands require explicit flags that a human running interactively would never need to type, plus rate limiting. There are no tiers; the ladder is one step, and the step is "prove you meant this".

**When to use it:** when most write operations carry similar risk, and the useful distinction is human-versus-agent rather than cheap-versus-costly mistakes. Also when a tiered ladder would be theater: three tiers over four commands is bureaucracy.

---

## Shape 3: double flag plus a freshness-bounded health check

A different axis, from a tax-filing CLI where the risk is submitting something wrong to a government system.

Live operations require **two independent named flags together**, a generic `--yes` plus a domain-specific one naming the live target. Neither alone suffices. On top of that, a preflight environment check must have passed recently, with the result cached for a bounded window and re-run when stale.

The insight: two flags with different names cannot be typed by accident or filled in by pattern-matching. And the freshness bound means a health check from yesterday does not authorize today's submission.

**When to use it:** when the operation's safety depends on environment state; a browser session, a certificate, a network path: not just on intent. The health check is the real gate; the flags prevent accidents.

---

## Choosing

| Domain | Shape |
|---|---|
| Money, irreversible destruction, agent-driven | 1: tiered plus intent tokens |
| Uniform write risk, agent-versus-human is the axis | 2: binary agent mode |
| Safety depends on environment state | 3: double flag plus health check |
| Read-only | none, stated explicitly |

Shapes combine. A CLI can use tiered gates for writes and a freshness-bounded doctor check for the subset that depends on a live browser session.

---

## Rules that hold across all shapes

**In non-interactive mode, a gate throws: it never prompts.** A prompt in a piped context hangs forever. The agent sees a timeout and cannot tell it from a network failure. Throw a structured error naming the gate and what would satisfy it.

**Consent is not a trust tier.** Legal acceptance (terms of service, liability disclaimers) belongs outside the ladder and is stricter than any tier in it. The corpus implementation refuses to run unless stdin and stdout are both real TTYs, `--json` is absent, and no CI environment variable is set. **There is deliberately no `--yes` for consent.** If an agent can accept terms on the human's behalf, the acceptance is worthless.

That same implementation signs the stored consent record with a per-machine secret, so a hand-edited file backdating acceptance is detectable. Tamper-evidence, not just presence-checking.

**A killswitch is out-of-band and independent of the ladder.** A sentinel file in the app's directory that, when present, makes every write refuse regardless of tier or token. The human must be able to stop things without cooperating with the running process.

**Preview must exercise the real path.** A `--dry-run` returning a hardcoded shape proves nothing about what would happen. The strongest corpus implementation calls the provider's own preview endpoint and returns that response. Second best: run every validation and transformation, stop immediately before the mutating call, and return what you were about to send.

**Validate the provider's echo before committing.** One CLI refuses to submit unless the provider's own preview screen literally contains the expected name, amount, and currency. This catches provider bugs and your own malformed requests, and it is the check that turns a preview from decoration into a safeguard.

---

## The failure mode to avoid

A ladder that exists in the type system and nowhere else.

Check that the gate is wired: does `approveGate`, or whatever you named it, get called on the path that mutates? A `TrustLevel` enum with no enforcement documents an intention, and `--help` advertising a gate that does not fire is worse than no gate, because the operator stops watching.
