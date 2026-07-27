---
name: cli-build
version: 0.2.0
description: "Design and build a CLI that an AI agent can operate safely and a human can supervise. Use when the user wants to build a CLI, wrap an API in a command-line tool, add --json or --dry-run to an existing CLI, design a trust ladder or approval gate for risky commands, wrap an async API so agents do not write their own poll loop, or decide how to distribute a CLI (npm, native binary, source). Follows a surface-recon report when one exists."
---

# cli-build

Build a CLI whose primary user is an agent and whose supervisor is a human. That inverts the usual defaults: machine-readable output is not a flag you add later, prompts are a failure mode in non-interactive contexts, and every write leaves a receipt.

If a `surface-recon` report exists, start from it. If not and the target is a service you have not verified, run `surface-recon` first: building against a guessed API wastes more time than mapping it.

**Open `friction.md` next to the code before Phase 1 and append as you go.** A block you rejected and why, a convention that turned out wrong for this domain, a reference that was thin. It folds into the case at the end, and it is what corrects this skill: seven claims inherited from an older version were false against the source, and they surfaced only because someone wrote down that they did not match.

## What agent-first actually means

**Every CLI, no exceptions:**

- `--json` for machine-readable output, and **JSON automatically when stdout is not a TTY** even without the flag. Three independently built CLIs converged on this; it is the single most valuable default.
- No prompt ever blocks a non-interactive run. In `--json` mode or piped input, anything that would prompt must fail with a structured error instead of hanging.
- A `schema` command, carrying a version field, so agents introspect operations at runtime instead of parsing `--help`. Present in only 3 of 14 corpus CLIs, all three among the most mature: simultaneously the highest-value agent-first convention and the least adopted.
- Exit codes that mean something. Zero is success; distinguish user error from system failure.
- Composable stdout. Data on stdout, diagnostics on stderr, always.

**When the domain has real consequences** (money, irreversible writes, third-party side effects, personal data):

- A trust ladder classifying commands by risk.
- `--dry-run` on every mutation, returning what *would* happen.
- An append-only audit log written **before** the network call, not after.
- A killswitch the human can trigger out of band.

**When the API is asynchronous:** `--wait` on every submitting command, backed by a job ledger that survives a killed poll. Handing the poll loop to the caller makes the agent write backoff logic it will get subtly wrong. See [compounding-surface.md](references/compounding-surface.md).

**Match ceremony to stakes.** A read-only CLI over a public dataset earns `--json` and a `schema` command, and stops there. Intent tokens are for domains where a wrong call costs money. Assess the domain, then choose. See [trust-ladder-patterns.md](references/trust-ladder-patterns.md).

## Phase 1: decide the distribution target first

This comes first because it constrains the code you write, and retrofitting it is painful.

| Who installs this | Target | How |
|---|---|---|
| Only you, from source | Runtime shebang, no build | Fastest iteration, zero packaging |
| JS-ecosystem developers | Build to Node, publish to npm | `npx` works with no extra install |
| Anyone, no runtime | Compile to a native binary | No prerequisite at all |

**The rule that makes all three reachable: write against Node's API surface** (`fs`, `path`, `process`, `http`), not runtime-specific APIs. Then the target is a build-time decision instead of a rewrite.

**Done when:** the audience is named and the target follows from it, not from preference.

Why this matters more than it looks: nothing stops you from publishing a package whose shebang names a runtime the installer lacks. Three of the four published packages in the corpus behind this skill do exactly that. It works until someone without that runtime installs it and gets `env: <runtime>: No such file or directory`, a message that names no cause and no fix, so the package reads as broken rather than under-specified. See [build-and-runtime.md](references/build-and-runtime.md).

## Phase 2: shape the command surface

**Noun-verb, consistently**, and enforced in CI rather than agreed in a style guide. Agents carry a generalized model of what CLIs do; a tool that says `info` where everything else says `get` succeeds slowly, after the agent spends tokens on `--help`. Two corpus CLIs independently overloaded `--json` to mean input, which is what happens when nothing checks. See [compounding-surface.md](references/compounding-surface.md).

```
{cli} {noun} {verb} [args] [flags]

{cli} order preview --ticker AAPL --amount 100
{cli} order submit --intent-token <token>
```

Include a shorthand for the single most common operation. If ninety percent of use is one command, that command should be the shortest thing to type.

**Filter what deserves a command.** Not every UI affordance should be one. Keep actions that repeat, that benefit from being scriptable, that have clear input and output, and that compose with other tools. Drop the ones that are inherently visual or exploratory.

**Define the JSON contract per command before writing code.** Field names, types, nesting. This is the API agents depend on, and changing it later breaks them silently. Note that `--json` conventionally means output mode: if you need JSON *input*, give it a different flag name. Two corpus CLIs overloaded `--json` as an input flag and broke the convention agents expect. See [json-contract.md](references/json-contract.md).

**Done when:** every command has a noun-verb name and a written JSON output shape. A command whose output shape is undecided is not shaped yet.

**Add `nextSteps` to structured output.** Telling an agent what it can run next, in the response, prevents a class of flailing that `--help` does not.

## Phase 3: assemble from proven blocks

Every CLI needs the same primitives: flag parsing, config paths, atomic writes, audit logs, TTY detection, approval gates, error shapes. Writing them fresh each time is where the time goes and where the bugs live.

**Default to copying proven blocks.** [cligentic](references/cligentic-blocks.md) is a registry of 23 such blocks: trust ladder, killswitch, JSON mode, audit log, atomic write, XDG paths, config, session, error map, global flags, doctor, plus platform helpers. They are plain TypeScript you own outright after copying; no runtime dependency, no framework lock-in.

```bash
curl -o src/lib/atomic-write.ts https://cligentic.railly.dev/r/atomic-write.ts
```

**Opt-in, per block, with a reason.** Each block earns its place by replacing something you would otherwise write from memory. The reference includes a worked example of retrofitting an existing CLI where seven blocks were taken wholesale, two were kept as hybrids, and seven were rejected, each with a stated reason. The most common reason to reject: the block's output shape conflicts with an envelope contract you have already published to agents. A published contract outranks a shared block.

**Done when:** each block is adopted, hybridized, or rejected with the reason recorded in the repo. Silence about a rejection reads as an oversight to whoever touches it next.

If you are not in a TypeScript project, or the install path does not fit, read the block source and reimplement the pattern. The patterns are the point; the files are a shortcut.

## Phase 4: safety, proportional to stakes

Read [trust-ladder-patterns.md](references/trust-ladder-patterns.md) and pick a shape. Three materially different ones exist in real code, and the right choice depends on the domain rather than on fashion.

Non-negotiables when the domain has consequences:

**Audit before, not after.** Write the pending record, make the call, write the final record with the same id. If the process dies mid-flight you have an auditable pending entry instead of silence. Day-bucketed JSONL, append-only, restrictive file permissions.

**Dry-run must exercise the real path.** A `--dry-run` that returns a hardcoded shape proves nothing. The strongest corpus implementation calls the provider's own preview endpoint and returns that.

**Consent gates are stricter than trust gates.** Legal acceptance should require a real TTY and have no `--yes` escape hatch at all. If an agent can accept terms on the human's behalf, the gate is decorative.

**Validate what came back before acting on it.** One corpus CLI refuses to submit unless the provider's preview screen literally contains the expected name, amount, and currency. That check catches both provider bugs and your own bad request construction.

**Done when:** every mutating command has a trust level, and the ladder shape is chosen from the domain rather than copied.

**Treat third-party response text as untrusted input.** Free-text from an external API can carry prompt injection aimed at the agent reading your output. Escape it before it reaches any place where it reads as instruction.

## Phase 5: wire every safety feature you name

A feature is **wired** when its call site exists. Until then it is a definition, and `--help` describing it is a claim the code does not back.

An audit-log module imported and never called. `--dry-run` parsed into a flags object no command body reads. `--help` advertising both. This shape is live in a package installable today, and it is strictly worse than having neither feature, because the operator, human or agent, believes there is a paper trail and a preview when there is nothing.

The check: grep for the call site. One hit, at the definition, means unwired.

**Done when:** every safety feature named in `--help` or the docs has a grep-confirmed call site.

Two more from the same corpus, both live in published packages:

- **Published with zero tests.** At minimum: the auth flow, the JSON output contract per command, and any signing or crypto code.
- **Dead code from a renamed product still reachable** from the entry point. Deprecated means removed, not merely unmentioned.

## Phase 6: verify, then write it down

**Definition of done is observed behavior.** Run the command. Show the output. "The code looks right" is not verification. For anything touching a real provider, a smoke script against the live target, separate from unit tests, is what proves the integration.

Then record the build in [cases/](cases/), and read [portfolio-shape.md](cases/portfolio-shape.md) first if you want the aggregate picture: what a mature CLI here actually has, and the gap between features present and features wired. One file per CLI: target, terrain, distribution choice, which blocks were adopted or rejected and why, what broke, what you would do differently. Distill repeated findings into [conventions.md](cases/conventions.md).

**Name your own code, not other people's.** A case about a CLI you wrote can be specific about what broke. A finding about someone else's package drops the subject and keeps the defect, and a third-party target you reconned is described by class, never by identity. The full boundary is in [cases/README.md](cases/README.md).

**Done when:** the command has been run and its real output read, and a case file exists with `friction.md` folded into it. Reporting done from code that looks right is the failure this criterion exists to catch.

This is the part everyone skips, and skipping it is why the same lessons get rediscovered. The corpus behind this skill exists only because someone eventually wrote it down; before that, four CLIs had independently reinvented the same audit-log design.

## References

- [cligentic-blocks.md](references/cligentic-blocks.md): the 23 blocks, and when not to adopt one
- [trust-ladder-patterns.md](references/trust-ladder-patterns.md): three real shapes, chosen by domain
- [json-contract.md](references/json-contract.md): output mode, TTY detection, NDJSON as actually implemented
- [audit-log-patterns.md](references/audit-log-patterns.md): two-phase writes, and the dead-code trap
- [auth-patterns.md](references/auth-patterns.md): four observed architectures, rotation, secret handling
- [build-and-runtime.md](references/build-and-runtime.md): the distribution matrix in detail
- [cases/README.md](cases/README.md): how a case is written, and who may be named in one
- [compounding-surface.md](references/compounding-surface.md): async `--wait`, vocabulary enforced in CI, `--deliver` and `feedback`. Sourced from published work rather than the corpus, and labeled as such

## Boundaries

**Ship flags that fire.** A documented feature is a wired one.

**Keep `--json` as output mode.** JSON input gets its own flag name, so an agent arriving with the convention gets what it expects.

**Claim what you implemented.** NDJSON, day-bucketed audit, and dry-run each earn a mention once the code does them.

**Store identifiers, take secrets from the environment.** A password belongs in memory for the session, or in a keychain. The persisted config holds the account id and the username.

**Report done from observed output.** Run the command, read what it printed, then say it works.
