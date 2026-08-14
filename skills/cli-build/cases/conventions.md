# Conventions

Findings that appeared in two or more **independent** builds; no shared code between them. Independent convergence is evidence; a single team's preference is not.

Each entry names how many builds it came from. When a case contradicts one of these, the case wins and this file gets corrected.

---

## Confirmed by convergence

### Non-TTY implies machine-readable output
**3 independent builds.** Each checks `stdout.isTTY` and falls back to JSON with no flag. Two read it per command; one resolves it once in a framework-level hook, which is the version that does not drift.

### Append-only JSONL audit, one file per UTC day, mode 0600
**4 builds, two with zero shared code.** Same directory shape, same permission, same day-bucketing. The convergence is strong enough to treat as the default rather than a choice.

### Two-phase audit around the mutating call
**3 builds.** A pending record before the call and a final record after, sharing an id. An orphan pending entry is the detectable signal that a process died mid-flight. One names the phases explicitly; another encodes `pending` in the result enum.

### Signed single-use intent token for the highest-risk tier
**2 builds, independently designed.** One used JWS HS256, the other an HMAC `v1.<id>.<sig>` format. Both bind a fingerprint of the specific operation, both carry a short TTL, and one enforces single use through atomic exclusive file creation so replay fails at the filesystem level.

### A `schema` introspection command
**3 builds.** The most consistently implemented agent-first convention in the corpus. Sources vary between bundled JSON schemas, a bundled OpenAPI document, and generation from the validation layer, but every mature CLI has one. Runtime introspection cannot go stale against the code the way a skill file can.

### Home-directory override for test isolation
**5 builds, four different variable names.** `{APP}_HOME` or equivalent, so tests and live smoke scripts do not write to the developer's real config and history. Every CLI in the corpus that has real tests has this; the ones without it have no tests.

### Atomic write for state files
**3 builds.** Temp file plus rename for anything that must survive a crash mid-write. One hand-rolled it with a comment explaining the data-loss avoidance; two took it from a shared block.

### Identifiers persisted, secrets never
**2 builds.** Account id and username to disk, password from the environment only, held in memory for the session. Verifiable at the object-literal level in one case, where the persisted object omits the field rather than relying on policy.

---

## Single-source but high confidence

These come from one build each. Included because the reasoning generalizes and the failure they prevent is severe. Promote when a second build confirms.

### Consent gates are stricter than any trust tier
Legal acceptance requires real TTY on both stdin and stdout, absence of `--json`, and no CI environment variable. **No `--yes` escape exists by design.** The same build signs the stored consent record with a per-machine secret, making a hand-edited backdated acceptance detectable. If an agent can accept terms for the human, the acceptance is worthless.

### Validate the provider's echo before committing
Refuses to submit unless the provider's own preview response literally contains the expected name, amount, and currency. Catches both provider bugs and malformed requests from your side, and turns a preview from decoration into a safeguard.

### Freshness-bounded environment check as a gate
Live operations require a passing preflight check no older than a bounded window. A green result from yesterday cannot authorize today's submission. Pairs with the double-flag pattern: two independently named flags plus a fresh doctor result.

### Write the accept/reject decision down when adopting shared blocks
Seven blocks taken wholesale, two kept as hybrids, seven rejected with stated reasons. The rejections are the valuable part. The strongest one: the CLI had already published an envelope contract to agents that the shared block's output shape would have broken. A published contract outranks a shared block.

### Polished human output is the default unless scope is explicitly reduced
One build passed its agent, safety, packaging, and live-device checks while still feeling visibly unfinished. The cause was rejecting `banner` and `style` only because the command surface was small. Adding a TTY-only banner, semantic color, ANSI-safe tables, readable metadata, and byte-level progress fixed the human surface without changing the machine contract. Keep this single-source until another independent build confirms it.

---

## Contradicted: do not follow

Each of these was stated as guidance somewhere and is false against the code.

### "Always compile with a bundler" / "never use a plain runtime shebang"
Both halves wrong. The correct axis is audience: source shebang for internal tools, build to Node for npm, native binary for everyone. Measured: 6 CLIs use a runtime shebang and 3 of them reached a registry, so nothing blocks publishing that way. What it costs is the installer seeing `env: <runtime>: No such file or directory`, which names no cause and no fix.

### "Layering must be commands → workflows → api → validation"
True in two builds, **false in the one cited as the pattern's origin**, which is flat: a commands directory plus a single flat lib directory, with the API client at the top level and validation inlined per command. It ships and works. Layer when the command count justifies it.

### "NDJSON over JSON arrays, always"
Only one build actually emits NDJSON. Four emit a single pretty-printed value. NDJSON wins for streams and unbounded sets; for a bounded in-memory collection an array is fine. Do not document NDJSON unless you emit it.

### "`--json` always means machine-readable output"
Two builds overload it as an *input* flag, one meaning "read from stdin as JSON" and one taking a file path. Both break the convention agents expect. Name JSON input something else, and know that this inconsistency exists in the wild.

### "Trust ladder is T0 through T3"
One build implements T0 through T5, splitting the top tiers by transaction magnitude. Another uses no tiers at all, just a binary agent-mode flag imposing mandatory-flag requirements on writes. Three distinct shapes; pick by domain.

---

## Anti-patterns observed in shipped code

All of these are live in published packages, not historical.

### Scaffolded safety that is never wired
An audit-log module imported and never called. `--dry-run` parsed into a flags object no command reads. `--help` advertises both. Worse than absent, because the operator stops watching. **Check: grep for the call site. If the only hit is the definition, the feature does not exist.**

### Published with zero tests
Two packages, both installable. Minimum bar: auth flow, JSON contract per command, any signing code.

### Dead code from a renamed product still reachable
A command directory and environment variables for a product name retired long ago, still wired to the entry point. Deprecated means removed.

### Captcha solved by computed coordinates, in production, untested
Clicks a point derived from a bounding rectangle. Breaks silently the moment the widget moves, with no test protecting it.

### Version drift between checkout and registry
Local manifest claims one version; the published package resolves to a much later one under a different name. Check the registry before assuming your checkout is authoritative.

### Orphan scaffold artifacts
A UI-framework config file in a CLI repo, present since the first commit, referenced by nothing. Usually left behind by a component installer that expects a web project.
